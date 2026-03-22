import Foundation
import ModelEvaluationKit

@main
struct ModelTestMain {
    static func main() async {
        var parsedOptions: CLIOptions?

        do {
            let options = try CLIParser.parse(arguments: Array(CommandLine.arguments.dropFirst()))
            parsedOptions = options
            let runner = EvaluationRunner(
                repositoryRegistry: DefaultRegistries.repositoryRegistry(),
                frameworkRegistry: DefaultRegistries.frameworkRegistry()
            )
            let result = try await runner.run(cli: options)
            let logStore = EvaluationLogStore(
                logsDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
                    .appendingPathComponent("logs", isDirectory: true)
            )
            _ = try logStore.write(result)
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
            }
            fputs("\(error.localizedDescription)\n", stderr)
            if case let ModelEvaluationError.runtime(message) = error, message == CLIParser.usage {
                fputs("\(CLIParser.usage)\n", stderr)
            }
            Foundation.exit(EXIT_FAILURE)
        }
    }
}
