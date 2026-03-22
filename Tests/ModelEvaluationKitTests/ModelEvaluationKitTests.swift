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
            "--model-dir", "/tmp/model",
            "--audio", "/tmp/audio.wav",
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
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let requiredEntries = [
            "qwen3_asr_audio_encoder.mlmodelc",
            "qwen3_asr_decoder_stateful.mlmodelc",
            "qwen3_asr_embeddings.bin",
            "vocab.json",
        ]
        for entry in requiredEntries {
            let fileURL = tempDirectory.appendingPathComponent(entry)
            FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
        }

        let audioURL = tempDirectory.appendingPathComponent("sample.wav")
        FileManager.default.createFile(atPath: audioURL.path, contents: Data(), attributes: nil)

        var options = CLIOptions()
        options.repository = "FluidInference/qwen3-asr-0.6b-coreml"
        options.artifact = "f32"
        options.framework = "fluidaudio"
        options.modelDir = tempDirectory.path
        options.audioPath = audioURL.path

        let invocation = try spec.makeInvocation(from: options)
        #expect(invocation.repository == "FluidInference/qwen3-asr-0.6b-coreml")
        #expect(invocation.artifact == "f32")
        #expect(invocation.framework == "fluidaudio")
    }

    @Test
    func specAcceptsV2EncoderLayout() throws {
        let spec = FluidInferenceQwen3AsrCoreMLEvaluationSpec()
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let requiredEntries = [
            "qwen3_asr_audio_encoder_v2.mlmodelc",
            "qwen3_asr_decoder_stateful.mlmodelc",
            "qwen3_asr_embeddings.bin",
            "vocab.json",
        ]
        for entry in requiredEntries {
            let fileURL = tempDirectory.appendingPathComponent(entry)
            FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
        }

        let audioURL = tempDirectory.appendingPathComponent("sample.wav")
        FileManager.default.createFile(atPath: audioURL.path, contents: Data(), attributes: nil)

        var options = CLIOptions()
        options.repository = "FluidInference/qwen3-asr-0.6b-coreml"
        options.artifact = "f32"
        options.framework = "fluidaudio"
        options.modelDir = tempDirectory.path
        options.audioPath = audioURL.path

        let invocation = try spec.makeInvocation(from: options)
        #expect(invocation.modelDir == tempDirectory.path)
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
        options.modelDir = "/tmp/mock-model"
        options.audioPath = "/tmp/mock-audio.wav"

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
            modelDir: "/tmp/model",
            input: "/tmp/audio.wav",
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
        options.modelDir = "/tmp/model"
        options.audioPath = "/tmp/audio.wav"

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
            modelDir: cli.modelDir ?? "/tmp/mock-model",
            audioPath: cli.audioPath ?? "/tmp/mock-audio.wav",
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
