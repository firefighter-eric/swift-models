import Foundation

public enum CLIParser {
    public static func parse(arguments: [String]) throws -> CLIOptions {
        var options = CLIOptions()
        var index = 0

        func requireValue(for flag: String) throws -> String {
            let nextIndex = index + 1
            guard nextIndex < arguments.count else {
                throw ModelEvaluationError.missingArgument(flag)
            }
            return arguments[nextIndex]
        }

        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--repository":
                options.repository = try requireValue(for: argument)
                index += 2
            case "--artifact":
                options.artifact = try requireValue(for: argument)
                index += 2
            case "--framework":
                options.framework = try requireValue(for: argument)
                index += 2
            case "--model-dir":
                options.modelDir = try requireValue(for: argument)
                index += 2
            case "--audio":
                options.audioPath = try requireValue(for: argument)
                index += 2
            case "--language":
                options.language = try requireValue(for: argument)
                index += 2
            case "--max-new-tokens":
                let value = try requireValue(for: argument)
                guard let intValue = Int(value), intValue > 0 else {
                    throw ModelEvaluationError.invalidValue(flag: argument, value: value)
                }
                options.maxNewTokens = intValue
                index += 2
            case "--json":
                options.outputJSON = true
                index += 1
            case "--help", "-h":
                throw ModelEvaluationError.runtime(Self.usage)
            default:
                throw ModelEvaluationError.invalidValue(flag: "argument", value: argument)
            }
        }

        return options
    }

    public static let usage = """
    Usage:
      swift run model-test \\
        --repository <repository-id> \\
        --artifact <artifact-id> \\
        --framework <framework-id> \\
        --model-dir <path> \\
        --audio <path> \\
        [--language <code>] \\
        [--max-new-tokens <n>] \\
        [--json]

    Example:
      swift run model-test \\
        --repository mlx-community/Qwen3-ASR-0.6B-4bit \\
        --artifact 4bit \\
        --framework mlxaudioswift \\
        --model-dir data/models/mlx-community/Qwen3-ASR-0.6B-4bit \\
        --audio data/sound_examples/qwen3_asr_test_audio.wav \\
        --json
    """
}
