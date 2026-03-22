import Foundation
import ModelEvaluationCore

public enum DefaultRegistries {
    public static func frameworkRegistry() -> FrameworkRegistry {
        FrameworkRegistry(adapters: [
            MLXAudioSwiftAdapter(),
            MLXSwiftAdapter(),
        ])
    }
}
