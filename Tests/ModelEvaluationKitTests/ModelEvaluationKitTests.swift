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
    func specRejectsUnsupportedArtifact() {
        let spec = FluidInferenceQwen3AsrCoreMLEvaluationSpec()
        var options = CLIOptions()
        options.repository = "FluidInference/qwen3-asr-0.6b-coreml"
        options.artifact = "f32"
        options.framework = "fluidaudio"
        options.modelDir = "/tmp/model"
        options.audioPath = "/tmp/audio.wav"

        #expect(throws: ModelEvaluationError.unsupportedArtifact(
            repository: "FluidInference/qwen3-asr-0.6b-coreml",
            artifact: "f32"
        )) {
            _ = try spec.makeInvocation(from: options)
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
        options.modelDir = "/tmp/mock-model"
        options.audioPath = "/tmp/mock-audio.wav"

        let result = try await runner.run(cli: options)
        #expect(result.repository == spec.repositoryId)
        #expect(result.framework == adapter.frameworkId)
        #expect(result.transcript == "mock transcript")
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
