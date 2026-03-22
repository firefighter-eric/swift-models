import Foundation

public protocol RepositoryEvaluationSpec: Sendable {
    var repositoryId: String { get }
    var supportedArtifacts: Set<String> { get }
    func makeInvocation(from cli: CLIOptions) throws -> EvaluationInvocation
    func validate(_ result: EvaluationResult) throws
}

public protocol InferenceFrameworkAdapter: Sendable {
    var frameworkId: String { get }
    func supports(repositoryId: String) -> Bool
    func run(_ invocation: EvaluationInvocation) async throws -> EvaluationResult
}
