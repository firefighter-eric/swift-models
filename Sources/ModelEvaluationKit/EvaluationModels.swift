import Foundation

public struct CLIOptions: Equatable, Sendable {
    public var repository: String?
    public var artifact: String?
    public var framework: String?
    public var modelDir: String?
    public var audioPath: String?
    public var language: String?
    public var maxNewTokens: Int?
    public var outputJSON = false

    public init() {}
}

public struct EvaluationInvocation: Equatable, Sendable {
    public let repository: String
    public let artifact: String
    public let framework: String
    public let modelDir: String
    public let audioPath: String
    public let language: String?
    public let maxNewTokens: Int
    public let extra: [String: String]

    public init(
        repository: String,
        artifact: String,
        framework: String,
        modelDir: String,
        audioPath: String,
        language: String?,
        maxNewTokens: Int,
        extra: [String: String] = [:]
    ) {
        self.repository = repository
        self.artifact = artifact
        self.framework = framework
        self.modelDir = modelDir
        self.audioPath = audioPath
        self.language = language
        self.maxNewTokens = maxNewTokens
        self.extra = extra
    }
}

public enum EvaluationStatus: String, Codable, Sendable {
    case succeeded
    case failed
}

public struct EvaluationResult: Codable, Equatable, Sendable {
    public let repository: String
    public let artifact: String
    public let framework: String
    public let modelDir: String
    public let input: String
    public let transcript: String?
    public let elapsedMs: Double
    public let status: EvaluationStatus
    public let error: String?
    public let metadata: [String: String]

    public init(
        repository: String,
        artifact: String,
        framework: String,
        modelDir: String,
        input: String,
        transcript: String?,
        elapsedMs: Double,
        status: EvaluationStatus,
        error: String?,
        metadata: [String: String]
    ) {
        self.repository = repository
        self.artifact = artifact
        self.framework = framework
        self.modelDir = modelDir
        self.input = input
        self.transcript = transcript
        self.elapsedMs = elapsedMs
        self.status = status
        self.error = error
        self.metadata = metadata
    }
}
