import Foundation

public enum DefaultRegistries {
    public static func repositoryRegistry() -> RepositoryRegistry {
        RepositoryRegistry(specs: [
            FluidInferenceQwen3AsrCoreMLEvaluationSpec(),
            MLXCommunityQwen3Asr4BitEvaluationSpec(),
        ])
    }

    public static func frameworkRegistry() -> FrameworkRegistry {
        if #available(macOS 15, iOS 18, *) {
            return FrameworkRegistry(adapters: [
                FluidAudioAdapter(),
                MLXSwiftAdapter(),
            ])
        }

        return FrameworkRegistry(adapters: [
            MLXSwiftAdapter(),
        ])
    }
}
