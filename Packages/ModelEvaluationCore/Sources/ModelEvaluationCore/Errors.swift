import Foundation

public enum ModelEvaluationError: LocalizedError, Equatable {
    case missingArgument(String)
    case invalidValue(flag: String, value: String)
    case unknownRepository(String)
    case unknownFramework(String)
    case unsupportedArtifact(repository: String, artifact: String)
    case unsupportedFramework(repository: String, framework: String)
    case fileNotFound(String)
    case invalidModelLayout(repository: String, artifact: String, missing: [String])
    case invalidResult(String)
    case runtime(String)

    public var errorDescription: String? {
        switch self {
        case let .missingArgument(flag):
            return "Missing required argument: \(flag)"
        case let .invalidValue(flag, value):
            return "Invalid value for \(flag): \(value)"
        case let .unknownRepository(repository):
            return "Unknown repository: \(repository)"
        case let .unknownFramework(framework):
            return "Unknown framework: \(framework)"
        case let .unsupportedArtifact(repository, artifact):
            return "Repository \(repository) does not support artifact \(artifact)"
        case let .unsupportedFramework(repository, framework):
            return "Repository \(repository) is not supported by framework \(framework)"
        case let .fileNotFound(path):
            return "File not found: \(path)"
        case let .invalidModelLayout(repository, artifact, missing):
            return "Invalid model layout for \(repository) artifact \(artifact). Missing: \(missing.joined(separator: ", "))"
        case let .invalidResult(message):
            return "Invalid evaluation result: \(message)"
        case let .runtime(message):
            return message
        }
    }
}
