import Foundation
import Testing
@testable import ModelEvaluationKit

struct ModelEvaluationKitTests {
    @Test
    func cliParsesRepositoryFirstArguments() throws {
        let options = try CLIParser.parse(arguments: [
            "--repository", "FluidInference/qwen3-asr-0.6b-coreml",
            "--artifact", "int8",
            "--framework", "fluidaudio",
            "--model-dir", "fixtures/model",
            "--audio", "fixtures/audio.wav",
            "--language", "zh",
            "--max-new-tokens", "128",
            "--json",
        ])

        #expect(options.repository == "FluidInference/qwen3-asr-0.6b-coreml")
        #expect(options.artifact == "int8")
        #expect(options.framework == "fluidaudio")
        #expect(options.outputJSON)
        #expect(options.maxNewTokens == 128)
    }

    @Test
    func specAcceptsF32Artifact() throws {
        let spec = FluidInferenceQwen3AsrCoreMLEvaluationSpec()
        let tempDirectory = try makeRelativeFixtureDirectory()
        defer { try? FileManager.default.removeItem(atPath: tempDirectory) }

        let requiredEntries = [
            "qwen3_asr_audio_encoder.mlmodelc",
            "qwen3_asr_decoder_stateful.mlmodelc",
            "qwen3_asr_embeddings.bin",
            "vocab.json",
        ]
        for entry in requiredEntries {
            FileManager.default.createFile(atPath: tempDirectory + "/" + entry, contents: Data(), attributes: nil)
        }

        let audioPath = tempDirectory + "/sample.wav"
        FileManager.default.createFile(atPath: audioPath, contents: Data(), attributes: nil)

        var options = CLIOptions()
        options.repository = "FluidInference/qwen3-asr-0.6b-coreml"
        options.artifact = "f32"
        options.framework = "fluidaudio"
        options.modelDir = tempDirectory
        options.audioPath = audioPath

        let invocation = try spec.makeInvocation(from: options)
        #expect(invocation.repository == "FluidInference/qwen3-asr-0.6b-coreml")
        #expect(invocation.artifact == "f32")
        #expect(invocation.framework == "fluidaudio")
    }

    @Test
    func specAcceptsV2EncoderLayout() throws {
        let spec = FluidInferenceQwen3AsrCoreMLEvaluationSpec()
        let tempDirectory = try makeRelativeFixtureDirectory()
        defer { try? FileManager.default.removeItem(atPath: tempDirectory) }

        let requiredEntries = [
            "qwen3_asr_audio_encoder_v2.mlmodelc",
            "qwen3_asr_decoder_stateful.mlmodelc",
            "qwen3_asr_embeddings.bin",
            "vocab.json",
        ]
        for entry in requiredEntries {
            FileManager.default.createFile(atPath: tempDirectory + "/" + entry, contents: Data(), attributes: nil)
        }

        let audioPath = tempDirectory + "/sample.wav"
        FileManager.default.createFile(atPath: audioPath, contents: Data(), attributes: nil)

        var options = CLIOptions()
        options.repository = "FluidInference/qwen3-asr-0.6b-coreml"
        options.artifact = "f32"
        options.framework = "fluidaudio"
        options.modelDir = tempDirectory
        options.audioPath = audioPath

        let invocation = try spec.makeInvocation(from: options)
        #expect(invocation.modelDir == tempDirectory)
    }

    @Test
    func specAcceptsInt8V2Artifact() throws {
        let spec = FluidInferenceQwen3AsrCoreMLEvaluationSpec()
        let tempDirectory = try makeRelativeFixtureDirectory()
        defer { try? FileManager.default.removeItem(atPath: tempDirectory) }

        let requiredEntries = [
            "qwen3_asr_audio_encoder_v2.mlmodelc",
            "qwen3_asr_decoder_stateful.mlmodelc",
            "qwen3_asr_embeddings.bin",
            "vocab.json",
        ]
        for entry in requiredEntries {
            FileManager.default.createFile(atPath: tempDirectory + "/" + entry, contents: Data(), attributes: nil)
        }

        let audioPath = tempDirectory + "/sample.wav"
        FileManager.default.createFile(atPath: audioPath, contents: Data(), attributes: nil)

        var options = CLIOptions()
        options.repository = "FluidInference/qwen3-asr-0.6b-coreml"
        options.artifact = "int8-v2"
        options.framework = "fluidaudio"
        options.modelDir = tempDirectory
        options.audioPath = audioPath

        let invocation = try spec.makeInvocation(from: options)
        #expect(invocation.artifact == "int8-v2")
        #expect(invocation.modelDir == tempDirectory)
    }

    @Test
    func mlxSpecAccepts4BitArtifact() throws {
        let spec = MLXCommunityQwen3Asr4BitEvaluationSpec()
        let tempDirectory = try makeRelativeFixtureDirectory()
        defer { try? FileManager.default.removeItem(atPath: tempDirectory) }

        let requiredEntries = [
            "config.json",
            "preprocessor_config.json",
            "tokenizer_config.json",
            "vocab.json",
            "model.safetensors",
        ]
        for entry in requiredEntries {
            FileManager.default.createFile(atPath: tempDirectory + "/" + entry, contents: Data(), attributes: nil)
        }

        let audioPath = tempDirectory + "/sample.wav"
        FileManager.default.createFile(atPath: audioPath, contents: Data(), attributes: nil)

        var options = CLIOptions()
        options.repository = "mlx-community/Qwen3-ASR-0.6B-4bit"
        options.artifact = "4bit"
        options.framework = "mlxswift"
        options.modelDir = tempDirectory
        options.audioPath = audioPath

        let invocation = try spec.makeInvocation(from: options)
        #expect(invocation.repository == "mlx-community/Qwen3-ASR-0.6B-4bit")
        #expect(invocation.artifact == "4bit")
        #expect(invocation.framework == "mlxswift")
    }

    @Test
    func aufklarerSpecAcceptsCoreMLArtifact() throws {
        let spec = AufklarerQwen3AsrCoreMLEvaluationSpec()
        let tempDirectory = try makeRelativeFixtureDirectory()
        defer { try? FileManager.default.removeItem(atPath: tempDirectory) }

        let requiredEntries = [
            "encoder.mlmodelc",
            "embedding.mlmodelc",
            "decoder.mlmodelc",
            "config.json",
        ]
        for entry in requiredEntries {
            FileManager.default.createFile(atPath: tempDirectory + "/" + entry, contents: Data(), attributes: nil)
        }

        let audioPath = tempDirectory + "/sample.wav"
        FileManager.default.createFile(atPath: audioPath, contents: Data(), attributes: nil)

        var options = CLIOptions()
        options.repository = "aufklarer/Qwen3-ASR-CoreML"
        options.artifact = "coreml"
        options.framework = "speechswift"
        options.modelDir = tempDirectory
        options.audioPath = audioPath

        let invocation = try spec.makeInvocation(from: options)
        #expect(invocation.repository == "aufklarer/Qwen3-ASR-CoreML")
        #expect(invocation.artifact == "coreml")
        #expect(invocation.framework == "speechswift")
    }

    @Test
    func mlxAdapterSupportsRegisteredRepository() {
        let adapter = MLXSwiftAdapter()
        #expect(adapter.frameworkId == "mlxswift")
        #expect(adapter.supports(repositoryId: "mlx-community/Qwen3-ASR-0.6B-4bit"))
        #expect(!adapter.supports(repositoryId: "FluidInference/qwen3-asr-0.6b-coreml"))
    }

    @Test
    func speechSwiftAdapterSupportsRegisteredRepository() {
        if #available(macOS 15, iOS 18, *) {
            let adapter = SpeechSwiftAdapter()
            #expect(adapter.frameworkId == "speechswift")
            #expect(adapter.supports(repositoryId: "aufklarer/Qwen3-ASR-CoreML"))
            #expect(!adapter.supports(repositoryId: "FluidInference/qwen3-asr-0.6b-coreml"))
        }
    }

    @Test
    func runnerCanUseMockRegistriesWithoutMainFlowChanges() async throws {
        let spec = MockRepositorySpec()
        let adapter = MockAdapter()
        let runner = EvaluationRunner(
            repositoryRegistry: RepositoryRegistry(specs: [spec]),
            frameworkRegistry: FrameworkRegistry(adapters: [adapter])
        )

        var options = CLIOptions()
        options.repository = spec.repositoryId
        options.artifact = "mock-artifact"
        options.framework = adapter.frameworkId
        options.modelDir = "fixtures/mock-model"
        options.audioPath = "fixtures/mock-audio.wav"

        let result = try await runner.run(cli: options)
        #expect(result.repository == spec.repositoryId)
        #expect(result.framework == adapter.frameworkId)
        #expect(result.transcript == "mock transcript")
    }

    @Test
    func logStoreWritesOneFilePerModelArtifact() throws {
        let logsDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: logsDirectory) }

        let store = EvaluationLogStore(logsDirectory: logsDirectory)
        let result = EvaluationResult(
            repository: "FluidInference/qwen3-asr-0.6b-coreml",
            artifact: "f32",
            framework: "fluidaudio",
            modelDir: "fixtures/model",
            input: "fixtures/audio.wav",
            transcript: "测试转写",
            elapsedMs: 12.5,
            status: .succeeded,
            error: nil,
            metadata: ["framework": "fluidaudio"]
        )

        let fileURL = try store.write(result)

        #expect(fileURL.lastPathComponent == "FluidInference_qwen3-asr-0.6b-coreml__f32.json")
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        let data = try Data(contentsOf: fileURL)
        let decoded = try JSONDecoder().decode(EvaluationResult.self, from: data)
        #expect(decoded == result)
    }

    @Test
    func failedResultCapturesErrorForLogOutput() {
        var options = CLIOptions()
        options.repository = "FluidInference/qwen3-asr-0.6b-coreml"
        options.artifact = "f32"
        options.framework = "fluidaudio"
        options.modelDir = "fixtures/model"
        options.audioPath = "fixtures/audio.wav"

        let result = EvaluationResult.failed(
            from: options,
            error: ModelEvaluationError.runtime("ASR inference failed")
        )

        #expect(result?.repository == "FluidInference/qwen3-asr-0.6b-coreml")
        #expect(result?.artifact == "f32")
        #expect(result?.status == .failed)
        #expect(result?.transcript == nil)
        #expect(result?.error == "ASR inference failed")
    }
}

private struct MockRepositorySpec: RepositoryEvaluationSpec {
    let repositoryId = "example/mock-repo"
    let supportedArtifacts: Set<String> = ["mock-artifact"]

    func makeInvocation(from cli: CLIOptions) throws -> EvaluationInvocation {
        EvaluationInvocation(
            repository: repositoryId,
            artifact: "mock-artifact",
            framework: "mock-framework",
            modelDir: cli.modelDir ?? "fixtures/mock-model",
            audioPath: cli.audioPath ?? "fixtures/mock-audio.wav",
            language: nil,
            maxNewTokens: 1
        )
    }

    func validate(_ result: EvaluationResult) throws {
        guard result.transcript == "mock transcript" else {
            throw ModelEvaluationError.invalidResult("unexpected mock transcript")
        }
    }
}

private func makeRelativeFixtureDirectory() throws -> String {
    let directory = ".build/test-fixtures/\(UUID().uuidString)"
    try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
    return directory
}

private struct MockAdapter: InferenceFrameworkAdapter {
    let frameworkId = "mock-framework"

    func supports(repositoryId: String) -> Bool { repositoryId == "example/mock-repo" }

    func run(_ invocation: EvaluationInvocation) async throws -> EvaluationResult {
        EvaluationResult(
            repository: invocation.repository,
            artifact: invocation.artifact,
            framework: invocation.framework,
            modelDir: invocation.modelDir,
            input: invocation.audioPath,
            transcript: "mock transcript",
            elapsedMs: 1,
            status: .succeeded,
            error: nil,
            metadata: [:]
        )
    }
}
