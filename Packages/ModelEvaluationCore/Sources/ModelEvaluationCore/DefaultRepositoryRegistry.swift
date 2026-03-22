import Foundation

public enum DefaultRepositoryRegistry {
    public static func make() -> RepositoryRegistry {
        RepositoryRegistry(specs: [
            AufklarerQwen3AsrCoreMLEvaluationSpec(),
            FluidInferenceQwen3AsrCoreMLEvaluationSpec(),
            MLXCommunityQwen3Asr4BitEvaluationSpec(),
        ])
    }
}
