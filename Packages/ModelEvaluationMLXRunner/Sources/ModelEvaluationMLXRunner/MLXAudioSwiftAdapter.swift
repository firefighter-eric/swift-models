import Foundation
import HuggingFace
import MLXAudioCore
import MLXAudioSTT
import ModelEvaluationCore

public struct MLXAudioSwiftAdapter: InferenceFrameworkAdapter {
    public let frameworkId = "mlxaudioswift"

    public init() {}

    public func supports(repositoryId: String) -> Bool {
        repositoryId == MLXAudioSwiftModelBridge.repositoryId
    }

    public func run(_ invocation: EvaluationInvocation) async throws -> EvaluationResult {
        guard supports(repositoryId: invocation.repository) else {
            throw ModelEvaluationError.unsupportedFramework(
                repository: invocation.repository,
                framework: frameworkId
            )
        }

        let startedAt = CFAbsoluteTimeGetCurrent()
        let cacheRoot = FileManager.default.temporaryDirectory.appendingPathComponent(
            "model-eval-mlxaudioswift-\(UUID().uuidString)",
            isDirectory: true
        )

        do {
            let bridgedModelDirectory = try MLXAudioSwiftModelBridge.prepareCacheRoot(
                localModelDirectory: invocation.modelDir,
                cacheRoot: cacheRoot
            )
            defer {
                try? FileManager.default.removeItem(at: cacheRoot)
            }

            let audioURL = URL(fileURLWithPath: invocation.audioPath)
            let (_, audioData) = try loadAudioArray(from: audioURL)
            let model = try await Qwen3ASRModel.fromPretrained(
                invocation.repository,
                cache: HubCache(cacheDirectory: cacheRoot)
            )
            let language = MLXAudioSwiftModelBridge.normalizedLanguage(invocation.language)
            let output = if let language {
                model.generate(
                    audio: audioData,
                    maxTokens: invocation.maxNewTokens,
                    language: language
                )
            } else {
                model.generate(
                    audio: audioData,
                    maxTokens: invocation.maxNewTokens
                )
            }

            let transcript = output.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !transcript.isEmpty else {
                throw ModelEvaluationError.runtime("MLX Audio Swift inference finished but returned an empty transcript")
            }

            return EvaluationResult(
                repository: invocation.repository,
                artifact: invocation.artifact,
                framework: invocation.framework,
                modelDir: invocation.modelDir,
                input: invocation.audioPath,
                transcript: transcript,
                elapsedMs: (CFAbsoluteTimeGetCurrent() - startedAt) * 1000,
                status: .succeeded,
                error: nil,
                metadata: [
                    "framework": frameworkId,
                    "language": language ?? "auto",
                    "maxNewTokens": String(invocation.maxNewTokens),
                    "mlxAudioSwiftVersion": "0.1.2",
                    "modelSource": "local-bridged-cache",
                    "cacheRoot": cacheRoot.path,
                    "stagedModelDir": bridgedModelDirectory.path,
                ]
            )
        } catch let error as ModelEvaluationError {
            throw error
        } catch {
            throw ModelEvaluationError.runtime(error.localizedDescription)
        }
    }
}

enum MLXAudioSwiftModelBridge {
    static let repositoryId = "mlx-community/Qwen3-ASR-0.6B-4bit"

    private static let requiredEntries = [
        ".gitattributes",
        "chat_template.json",
        "config.json",
        "generation_config.json",
        "merges.txt",
        "preprocessor_config.json",
        "tokenizer_config.json",
        "vocab.json",
    ]

    private static let languageAliases: [String: String] = [
        "zh": "Chinese",
        "chinese": "Chinese",
        "mandarin": "Chinese",
        "yue": "Cantonese",
        "cantonese": "Cantonese",
        "en": "English",
        "english": "English",
        "de": "German",
        "german": "German",
        "es": "Spanish",
        "spanish": "Spanish",
        "fr": "French",
        "french": "French",
        "it": "Italian",
        "italian": "Italian",
        "pt": "Portuguese",
        "portuguese": "Portuguese",
        "ru": "Russian",
        "russian": "Russian",
        "ko": "Korean",
        "korean": "Korean",
        "ja": "Japanese",
        "japanese": "Japanese",
    ]

    static func normalizedLanguage(_ language: String?) -> String? {
        guard let language else { return nil }
        let trimmed = language.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return languageAliases[trimmed.lowercased()] ?? trimmed
    }

    @discardableResult
    static func prepareCacheRoot(localModelDirectory: String, cacheRoot: URL) throws -> URL {
        let modelDirectory = URL(fileURLWithPath: localModelDirectory, isDirectory: true)
        guard FileManager.default.fileExists(atPath: modelDirectory.path) else {
            throw ModelEvaluationError.fileNotFound(localModelDirectory)
        }

        let missing = missingEntries(in: modelDirectory)
        guard missing.isEmpty else {
            throw ModelEvaluationError.invalidModelLayout(
                repository: repositoryId,
                artifact: "4bit",
                missing: missing
            )
        }

        let destination = cacheRoot
            .appendingPathComponent("mlx-audio", isDirectory: true)
            .appendingPathComponent(repositoryId.replacingOccurrences(of: "/", with: "_"), isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        for fileName in requiredFileNames(in: modelDirectory) {
            let source = modelDirectory.appendingPathComponent(fileName)
            let target = destination.appendingPathComponent(fileName)
            try bridgeItem(at: source, to: target)
        }

        return destination
    }

    static func missingEntries(in modelDirectory: URL) -> [String] {
        var missing = requiredEntries.filter { entry in
            !FileManager.default.fileExists(atPath: modelDirectory.appendingPathComponent(entry).path)
        }

        let safetensorFiles = (try? FileManager.default.contentsOfDirectory(
            at: modelDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ))?
            .filter { $0.pathExtension == "safetensors" }
            .map(\.lastPathComponent) ?? []

        if safetensorFiles.isEmpty {
            missing.append("model.safetensors")
        }

        return missing.sorted()
    }

    static func requiredFileNames(in modelDirectory: URL) -> [String] {
        let safetensorFiles = (try? FileManager.default.contentsOfDirectory(
            at: modelDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ))?
            .filter { $0.pathExtension == "safetensors" }
            .map(\.lastPathComponent)
            .sorted() ?? []

        let optionalEntries = [
            "model.safetensors.index.json",
        ].filter {
            FileManager.default.fileExists(atPath: modelDirectory.appendingPathComponent($0).path)
        }

        return (requiredEntries + optionalEntries + safetensorFiles).sorted()
    }

    private static func bridgeItem(at source: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        do {
            try fileManager.createSymbolicLink(at: destination, withDestinationURL: source)
        } catch {
            try fileManager.copyItem(at: source, to: destination)
        }
    }
}
