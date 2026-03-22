import Foundation
import ModelEvaluationKit

@main
struct ModelTestMain {
    static func main() async {
        do {
            let options = try CLIParser.parse(arguments: Array(CommandLine.arguments.dropFirst()))
            let runner = EvaluationRunner(
                repositoryRegistry: DefaultRegistries.repositoryRegistry(),
                frameworkRegistry: DefaultRegistries.frameworkRegistry()
            )
            let result = try await runner.run(cli: options)
            let rendered = try options.outputJSON
                ? OutputFormatter.formatJSON(result)
                : OutputFormatter.formatText(result)
            print(rendered)
            Foundation.exit(EXIT_SUCCESS)
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            if case let ModelEvaluationError.runtime(message) = error, message == CLIParser.usage {
                fputs("\(CLIParser.usage)\n", stderr)
            }
            Foundation.exit(EXIT_FAILURE)
        }
    }
}
