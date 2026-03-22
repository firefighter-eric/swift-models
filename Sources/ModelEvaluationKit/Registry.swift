import Foundation

public struct RepositoryRegistry: Sendable {
    private let specs: [String: any RepositoryEvaluationSpec]

    public init(specs: [any RepositoryEvaluationSpec]) {
        self.specs = Dictionary(uniqueKeysWithValues: specs.map { ($0.repositoryId, $0) })
    }

    public func spec(for repositoryId: String) -> (any RepositoryEvaluationSpec)? {
        specs[repositoryId]
    }
}

public struct FrameworkRegistry: Sendable {
    private let adapters: [String: any InferenceFrameworkAdapter]

    public init(adapters: [any InferenceFrameworkAdapter]) {
        self.adapters = Dictionary(uniqueKeysWithValues: adapters.map { ($0.frameworkId, $0) })
    }

    public func adapter(for frameworkId: String) -> (any InferenceFrameworkAdapter)? {
        adapters[frameworkId]
    }
}
