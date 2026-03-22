import Foundation
import ModelEvaluationCore

public struct MLXSwiftAdapter: InferenceFrameworkAdapter {
    public let frameworkId = "mlxswift"

    public init() {}

    public func supports(repositoryId: String) -> Bool {
        repositoryId == "mlx-community/Qwen3-ASR-0.6B-4bit"
    }

    public func run(_ invocation: EvaluationInvocation) async throws -> EvaluationResult {
        guard supports(repositoryId: invocation.repository) else {
            throw ModelEvaluationError.unsupportedFramework(
                repository: invocation.repository,
                framework: frameworkId
            )
        }

        let startedAt = CFAbsoluteTimeGetCurrent()
        let outputDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "model-eval-mlx-qwen3-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let command = makeRunnerCommand(invocation: invocation, outputDirectory: outputDirectory)
        let execution = try runShellCommand(command)
        let transcript = try loadTranscript(from: outputDirectory, fallbackStdout: execution.stdout)

        return EvaluationResult(
            repository: invocation.repository,
            artifact: invocation.artifact,
            framework: invocation.framework,
            modelDir: invocation.modelDir,
            input: invocation.audioPath,
            transcript: transcript,
            elapsedMs: (CFAbsoluteTimeGetCurrent() - startedAt) * 1000,
            status: .succeeded,
            error: nil,
            metadata: [
                "framework": frameworkId,
                "runnerCommand": command,
                "outputDirectory": outputDirectory.path,
                "language": invocation.language ?? "auto",
                "maxNewTokens": String(invocation.maxNewTokens),
            ]
        )
    }

    private func makeRunnerCommand(invocation: EvaluationInvocation, outputDirectory: URL) -> String {
        let environment = ProcessInfo.processInfo.environment
        if let customRunner = environment["MODEL_EVAL_MLXSWIFT_RUNNER"], !customRunner.isEmpty {
            return customRunner
                .replacingOccurrences(of: "{model_dir}", with: shellQuoted(invocation.modelDir))
                .replacingOccurrences(of: "{audio_path}", with: shellQuoted(invocation.audioPath))
                .replacingOccurrences(of: "{output_dir}", with: shellQuoted(outputDirectory.path))
                .replacingOccurrences(of: "{language}", with: shellQuoted(invocation.language ?? ""))
                .replacingOccurrences(of: "{max_new_tokens}", with: "\(invocation.maxNewTokens)")
        }

        var components = [
            "python3 -m mlx_audio.stt.generate",
            "--model \(shellQuoted(invocation.modelDir))",
            "--audio \(shellQuoted(invocation.audioPath))",
            "--output-path \(shellQuoted(outputDirectory.path))",
            "--format txt",
            "--max-tokens \(invocation.maxNewTokens)",
        ]
        if let language = invocation.language, !language.isEmpty {
            components.append("--language \(shellQuoted(language))")
        }
        return components.joined(separator: " ")
    }

    private func runShellCommand(_ command: String) throws -> CommandExecution {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(decoding: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let stderr = String(decoding: stderrPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)

        guard process.terminationStatus == 0 else {
            let detail = [stderr.trimmingCharacters(in: .whitespacesAndNewlines), stdout.trimmingCharacters(in: .whitespacesAndNewlines)]
                .first { !$0.isEmpty } ?? "command failed: \(command)"
            throw ModelEvaluationError.runtime(detail)
        }

        return CommandExecution(stdout: stdout, stderr: stderr)
    }

    private func loadTranscript(from outputDirectory: URL, fallbackStdout: String) throws -> String {
        let fileManager = FileManager.default
        let entries = (try? fileManager.contentsOfDirectory(
            at: outputDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []

        if let transcriptURL = entries.first(where: { $0.pathExtension == "txt" }) {
            let transcript = try String(contentsOf: transcriptURL, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !transcript.isEmpty {
                return transcript
            }
        }

        let fallback = fallbackStdout
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .last(where: { !$0.isEmpty }) ?? ""
        guard !fallback.isEmpty else {
            throw ModelEvaluationError.runtime("MLX runner finished but did not produce transcript output")
        }
        return fallback
    }

    private func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

private struct CommandExecution {
    let stdout: String
    let stderr: String
}
