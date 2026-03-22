import Foundation

public struct EvaluationRunner: Sendable {
    private let repositoryRegistry: RepositoryRegistry
    private let frameworkRegistry: FrameworkRegistry

    public init(
        repositoryRegistry: RepositoryRegistry,
        frameworkRegistry: FrameworkRegistry
    ) {
        self.repositoryRegistry = repositoryRegistry
        self.frameworkRegistry = frameworkRegistry
    }

    public func run(cli: CLIOptions) async throws -> EvaluationResult {
        let repositoryId = try required(cli.repository, flag: "--repository")
        let frameworkId = try required(cli.framework, flag: "--framework")

        guard let spec = repositoryRegistry.spec(for: repositoryId) else {
            throw ModelEvaluationError.unknownRepository(repositoryId)
        }
        guard let adapter = frameworkRegistry.adapter(for: frameworkId) else {
            throw ModelEvaluationError.unknownFramework(frameworkId)
        }
        guard adapter.supports(repositoryId: repositoryId) else {
            throw ModelEvaluationError.unsupportedFramework(repository: repositoryId, framework: frameworkId)
        }

        let invocation = try spec.makeInvocation(from: cli)
        let result = try await adapter.run(invocation)
        try spec.validate(result)
        return result
    }

    private func required(_ value: String?, flag: String) throws -> String {
        guard let value, !value.isEmpty else {
            throw ModelEvaluationError.missingArgument(flag)
        }
        return value
    }
}
