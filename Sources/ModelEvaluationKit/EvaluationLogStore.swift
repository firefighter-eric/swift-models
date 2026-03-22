import Foundation

public struct EvaluationLogStore: Sendable {
    private let logsDirectory: URL

    public init(logsDirectory: URL) {
        self.logsDirectory = logsDirectory
    }

    @discardableResult
    public func write(_ result: EvaluationResult) throws -> URL {
        try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

        let fileURL = logsDirectory.appendingPathComponent(fileName(for: result))
        let data = try formattedJSONData(for: result)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func fileName(for result: EvaluationResult) -> String {
        let repository = sanitize(result.repository)
        let artifact = sanitize(result.artifact)
        return "\(repository)__\(artifact).json"
    }

    private func sanitize(_ value: String) -> String {
        let invalidCharacters = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "-_."))
            .inverted
        return value
            .components(separatedBy: invalidCharacters)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }

    private func formattedJSONData(for result: EvaluationResult) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(result)
    }
}
