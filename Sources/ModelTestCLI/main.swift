import Foundation
import ModelEvaluationCore

@main
struct ModelTestMain {
    static func main() async {
        var parsedOptions: CLIOptions?

        do {
            let options = try CLIParser.parse(arguments: Array(CommandLine.arguments.dropFirst()))
            parsedOptions = options

            let result = try runDelegatedEvaluation(options: options)
            let logStore = EvaluationLogStore(
                logsDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
                    .appendingPathComponent("logs", isDirectory: true)
            )
            _ = try logStore.write(result)

            if result.status == .failed {
                if options.outputJSON {
                    print(try OutputFormatter.formatJSON(result))
                } else if let error = result.error {
                    fputs("\(error)\n", stderr)
                }
                Foundation.exit(EXIT_FAILURE)
            }

            let rendered = try options.outputJSON
                ? OutputFormatter.formatJSON(result)
                : OutputFormatter.formatText(result)
            print(rendered)
            Foundation.exit(EXIT_SUCCESS)
        } catch {
            if
                let options = parsedOptions,
                let failedResult = EvaluationResult.failed(from: options, error: error)
            {
                let logStore = EvaluationLogStore(
                    logsDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
                        .appendingPathComponent("logs", isDirectory: true)
                )
                _ = try? logStore.write(failedResult)
                if options.outputJSON {
                    if let json = try? OutputFormatter.formatJSON(failedResult) {
                        print(json)
                    }
                }
            }
            fputs("\(error.localizedDescription)\n", stderr)
            if case let ModelEvaluationError.runtime(message) = error, message == CLIParser.usage {
                fputs("\(CLIParser.usage)\n", stderr)
            }
            Foundation.exit(EXIT_FAILURE)
        }
    }

    private static func runDelegatedEvaluation(options: CLIOptions) throws -> EvaluationResult {
        let framework = try required(options.framework, flag: "--framework")
        let runner = try runnerConfiguration(for: framework)

        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "swift",
            "run",
            "--quiet",
            "--package-path",
            runner.packagePath,
            runner.executableName,
        ] + forwardedArguments(for: options, forceJSON: true)
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(decoding: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let stderr = String(decoding: stderrPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let result = try decodeEvaluationResult(from: stdout)

        guard process.terminationStatus == 0 else {
            if result.status == .failed {
                return result
            }
            let detail = [stderr.trimmingCharacters(in: .whitespacesAndNewlines), stdout.trimmingCharacters(in: .whitespacesAndNewlines)]
                .first { !$0.isEmpty } ?? "runner failed for framework \(framework)"
            throw ModelEvaluationError.runtime(detail)
        }

        return result
    }

    private static func decodeEvaluationResult(from stdout: String) throws -> EvaluationResult {
        guard let data = stdout.data(using: .utf8) else {
            throw ModelEvaluationError.runtime("Runner did not emit UTF-8 output")
        }
        do {
            return try JSONDecoder().decode(EvaluationResult.self, from: data)
        } catch {
            throw ModelEvaluationError.runtime("Runner emitted invalid JSON result")
        }
    }

    private static func runnerConfiguration(for framework: String) throws -> RunnerConfiguration {
        let currentDirectory = FileManager.default.currentDirectoryPath
        switch framework {
        case "fluidaudio", "speechswift":
            return RunnerConfiguration(
                packagePath: currentDirectory + "/Packages/ModelEvaluationAppleRunner",
                executableName: "model-test-apple"
            )
        case "mlxswift", "mlxaudioswift":
            return RunnerConfiguration(
                packagePath: currentDirectory + "/Packages/ModelEvaluationMLXRunner",
                executableName: "model-test-mlx"
            )
        default:
            throw ModelEvaluationError.unknownFramework(framework)
        }
    }

    private static func forwardedArguments(for options: CLIOptions, forceJSON: Bool) -> [String] {
        var arguments: [String] = []

        if let repository = options.repository {
            arguments += ["--repository", repository]
        }
        if let artifact = options.artifact {
            arguments += ["--artifact", artifact]
        }
        if let framework = options.framework {
            arguments += ["--framework", framework]
        }
        if let modelDir = options.modelDir {
            arguments += ["--model-dir", modelDir]
        }
        if let audioPath = options.audioPath {
            arguments += ["--audio", audioPath]
        }
        if let language = options.language {
            arguments += ["--language", language]
        }
        if let maxNewTokens = options.maxNewTokens {
            arguments += ["--max-new-tokens", String(maxNewTokens)]
        }
        if forceJSON || options.outputJSON {
            arguments.append("--json")
        }

        return arguments
    }

    private static func required(_ value: String?, flag: String) throws -> String {
        guard let value, !value.isEmpty else {
            throw ModelEvaluationError.missingArgument(flag)
        }
        return value
    }
}

private struct RunnerConfiguration {
    let packagePath: String
    let executableName: String
}
