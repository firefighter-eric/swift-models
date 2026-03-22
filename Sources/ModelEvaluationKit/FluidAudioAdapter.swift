import FluidAudio
import Foundation

@available(macOS 15, iOS 18, *)
public struct FluidAudioAdapter: InferenceFrameworkAdapter {
    public let frameworkId = "fluidaudio"

    public init() {}

    public func supports(repositoryId: String) -> Bool {
        repositoryId == "FluidInference/qwen3-asr-0.6b-coreml"
    }

    public func run(_ invocation: EvaluationInvocation) async throws -> EvaluationResult {
        guard supports(repositoryId: invocation.repository) else {
            throw ModelEvaluationError.unsupportedFramework(
                repository: invocation.repository,
                framework: frameworkId
            )
        }

        let startedAt = CFAbsoluteTimeGetCurrent()
        let stagedDirectory = try stageQwen3Artifact(from: URL(fileURLWithPath: invocation.modelDir, isDirectory: true))
        let audioURL = URL(fileURLWithPath: invocation.audioPath)
        let audioSamples = try AudioConverter().resampleAudioFile(audioURL)

        let manager = Qwen3AsrManager()
        try await manager.loadModels(from: stagedDirectory)
        let transcript = try await manager.transcribe(
            audioSamples: audioSamples,
            language: invocation.language,
            maxNewTokens: invocation.maxNewTokens
        )

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
                "stagedModelDir": stagedDirectory.path,
                "language": invocation.language ?? "auto",
                "maxNewTokens": String(invocation.maxNewTokens),
            ]
        )
    }

    private func stageQwen3Artifact(from sourceDirectory: URL) throws -> URL {
        let fileManager = FileManager.default
        let stagingRoot = fileManager.temporaryDirectory.appendingPathComponent(
            "model-eval-fluid-qwen3-\(UUID().uuidString)",
            isDirectory: true
        )
        try fileManager.createDirectory(at: stagingRoot, withIntermediateDirectories: true)

        let entriesToLink = [
            "qwen3_asr_decoder_stateful.mlmodelc",
            "qwen3_asr_embeddings.bin",
            "vocab.json",
            "metadata.json",
            "config.json",
        ]

        for entry in entriesToLink {
            let source = sourceDirectory.appendingPathComponent(entry)
            if fileManager.fileExists(atPath: source.path) {
                try linkItem(at: source, to: stagingRoot.appendingPathComponent(entry))
            }
        }

        let preferredEncoder = sourceDirectory.appendingPathComponent("qwen3_asr_audio_encoder_v2.mlmodelc")
        let legacyEncoder = sourceDirectory.appendingPathComponent("qwen3_asr_audio_encoder.mlmodelc")
        let encoderSource: URL
        if fileManager.fileExists(atPath: preferredEncoder.path) {
            encoderSource = preferredEncoder
        } else if fileManager.fileExists(atPath: legacyEncoder.path) {
            encoderSource = legacyEncoder
        } else {
            throw ModelEvaluationError.invalidModelLayout(
                repository: "FluidInference/qwen3-asr-0.6b-coreml",
                artifact: "int8",
                missing: ["qwen3_asr_audio_encoder.mlmodelc"]
            )
        }

        try linkItem(
            at: encoderSource,
            to: stagingRoot.appendingPathComponent("qwen3_asr_audio_encoder_v2.mlmodelc")
        )

        return stagingRoot
    }

    private func linkItem(at source: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        do {
            try fileManager.createSymbolicLink(at: destination, withDestinationURL: source)
        } catch {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
                try fileManager.createSymbolicLink(at: destination, withDestinationURL: source)
            } else {
                throw error
            }
        }
    }
}
