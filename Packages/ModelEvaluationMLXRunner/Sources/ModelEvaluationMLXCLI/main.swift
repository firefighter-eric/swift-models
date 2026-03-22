import Foundation
import ModelEvaluationCore
import ModelEvaluationMLXRunner

@main
struct ModelEvaluationMLXMain {
    static func main() async {
        var parsedOptions: CLIOptions?

        do {
            let options = try CLIParser.parse(arguments: Array(CommandLine.arguments.dropFirst()))
            parsedOptions = options

            let runner = EvaluationRunner(
                repositoryRegistry: DefaultRepositoryRegistry.make(),
                frameworkRegistry: DefaultRegistries.frameworkRegistry()
            )
            let result = try await runner.run(cli: options)
            print(try OutputFormatter.formatJSON(result))
            Foundation.exit(EXIT_SUCCESS)
        } catch {
            if
                let options = parsedOptions,
                let failedResult = EvaluationResult.failed(from: options, error: error),
                let rendered = try? OutputFormatter.formatJSON(failedResult)
            {
                print(rendered)
            }
            fputs("\(error.localizedDescription)\n", stderr)
            if case let ModelEvaluationError.runtime(message) = error, message == CLIParser.usage {
                fputs("\(CLIParser.usage)\n", stderr)
            }
            Foundation.exit(EXIT_FAILURE)
        }
    }
}
