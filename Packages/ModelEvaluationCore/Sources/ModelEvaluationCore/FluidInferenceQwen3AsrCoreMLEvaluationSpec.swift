import Foundation

public struct FluidInferenceQwen3AsrCoreMLEvaluationSpec: RepositoryEvaluationSpec {
    public let repositoryId = "FluidInference/qwen3-asr-0.6b-coreml"
    public let supportedArtifacts: Set<String> = ["int8", "int8-v2", "f32"]

    private let defaultAudioPath: String
    private let defaultLanguage: String?
    private let defaultMaxNewTokens: Int
    private let supportedFrameworks: Set<String>

    public init(
        defaultAudioPath: String = "data/sound_examples/qwen3_asr_test_audio.wav",
        defaultLanguage: String? = "zh",
        defaultMaxNewTokens: Int = 512,
        supportedFrameworks: Set<String> = ["fluidaudio"]
    ) {
        self.defaultAudioPath = defaultAudioPath
        self.defaultLanguage = defaultLanguage
        self.defaultMaxNewTokens = defaultMaxNewTokens
        self.supportedFrameworks = supportedFrameworks
    }

    public func makeInvocation(from cli: CLIOptions) throws -> EvaluationInvocation {
        let repository = try require(cli.repository, flag: "--repository")
        guard repository == repositoryId else {
            throw ModelEvaluationError.unknownRepository(repository)
        }

        let artifact = try require(cli.artifact, flag: "--artifact")
        guard supportedArtifacts.contains(artifact) else {
            throw ModelEvaluationError.unsupportedArtifact(repository: repositoryId, artifact: artifact)
        }

        let framework = try require(cli.framework, flag: "--framework")
        guard supportedFrameworks.contains(framework) else {
            throw ModelEvaluationError.unsupportedFramework(repository: repositoryId, framework: framework)
        }

        let modelDir = try require(cli.modelDir, flag: "--model-dir")
        let audioPath = cli.audioPath ?? defaultAudioPath

        try ensureFileExists(modelDir)
        try ensureFileExists(audioPath)
        try validateLocalArtifact(modelDir: modelDir, artifact: artifact)

        return EvaluationInvocation(
            repository: repositoryId,
            artifact: artifact,
            framework: framework,
            modelDir: modelDir,
            audioPath: audioPath,
            language: cli.language ?? defaultLanguage,
            maxNewTokens: cli.maxNewTokens ?? defaultMaxNewTokens,
            extra: [:]
        )
    }

    public func validate(_ result: EvaluationResult) throws {
        guard result.repository == repositoryId else {
            throw ModelEvaluationError.invalidResult("repository mismatch")
        }
        guard supportedArtifacts.contains(result.artifact) else {
            throw ModelEvaluationError.invalidResult("unexpected artifact \(result.artifact)")
        }
        guard result.framework == "fluidaudio" else {
            throw ModelEvaluationError.invalidResult("unexpected framework \(result.framework)")
        }
        guard result.status == .succeeded else {
            throw ModelEvaluationError.invalidResult("evaluation did not succeed")
        }
        let transcript = result.transcript?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !transcript.isEmpty else {
            throw ModelEvaluationError.invalidResult("transcript is empty")
        }
    }

    private func require(_ value: String?, flag: String) throws -> String {
        guard let value, !value.isEmpty else {
            throw ModelEvaluationError.missingArgument(flag)
        }
        return value
    }

    private func ensureFileExists(_ path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw ModelEvaluationError.fileNotFound(path)
        }
    }

    private func validateLocalArtifact(modelDir: String, artifact: String) throws {
        let directory = URL(fileURLWithPath: modelDir, isDirectory: true)
        let encoderCandidates = [
            "qwen3_asr_audio_encoder.mlmodelc",
            "qwen3_asr_audio_encoder_v2.mlmodelc",
        ]
        let requiredEntries = [
            "qwen3_asr_decoder_stateful.mlmodelc",
            "qwen3_asr_embeddings.bin",
            "vocab.json",
        ]

        var missing = requiredEntries.filter { entry in
            !FileManager.default.fileExists(atPath: directory.appendingPathComponent(entry).path)
        }
        let hasEncoder = encoderCandidates.contains { entry in
            FileManager.default.fileExists(atPath: directory.appendingPathComponent(entry).path)
        }
        if !hasEncoder {
            missing.append(encoderCandidates[0])
        }

        guard missing.isEmpty else {
            throw ModelEvaluationError.invalidModelLayout(
                repository: repositoryId,
                artifact: artifact,
                missing: missing
            )
        }
    }
}
