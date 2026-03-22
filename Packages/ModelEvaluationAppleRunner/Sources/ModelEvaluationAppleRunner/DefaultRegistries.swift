import Foundation
import ModelEvaluationCore

public enum DefaultRegistries {
    public static func frameworkRegistry() -> FrameworkRegistry {
        if #available(macOS 15, iOS 18, *) {
            return FrameworkRegistry(adapters: [
                FluidAudioAdapter(),
                SpeechSwiftAdapter(),
            ])
        }

        return FrameworkRegistry(adapters: [])
    }
}
