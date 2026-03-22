import Foundation

public enum OutputFormatter {
    public static func formatText(_ result: EvaluationResult) -> String {
        let transcript = result.transcript ?? ""
        return """
        repository: \(result.repository)
        artifact: \(result.artifact)
        framework: \(result.framework)
        modelDir: \(result.modelDir)
        input: \(result.input)
        status: \(result.status.rawValue)
        elapsedMs: \(String(format: "%.2f", result.elapsedMs))
        transcript: \(transcript)
        """
    }

    public static func formatJSON(_ result: EvaluationResult) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(result)
        guard let string = String(data: data, encoding: .utf8) else {
            throw ModelEvaluationError.runtime("Failed to render JSON output")
        }
        return string
    }
}
