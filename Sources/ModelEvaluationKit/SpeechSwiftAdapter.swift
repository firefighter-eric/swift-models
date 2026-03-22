import AudioCommon
import CoreML
import Foundation
import Qwen3ASR

@available(macOS 15, iOS 18, *)
public struct SpeechSwiftAdapter: InferenceFrameworkAdapter {
    public let frameworkId = "speechswift"

    private let tokenizerRepositoryId = "aufklarer/Qwen3-ASR-0.6B-MLX-4bit"

    public init() {}

    public func supports(repositoryId: String) -> Bool {
        repositoryId == "aufklarer/Qwen3-ASR-CoreML"
    }

    public func run(_ invocation: EvaluationInvocation) async throws -> EvaluationResult {
        guard supports(repositoryId: invocation.repository) else {
            throw ModelEvaluationError.unsupportedFramework(
                repository: invocation.repository,
                framework: frameworkId
            )
        }

        let startedAt = CFAbsoluteTimeGetCurrent()
        let modelDirectory = URL(fileURLWithPath: invocation.modelDir, isDirectory: true)
        let audioURL = URL(fileURLWithPath: invocation.audioPath)

        let audioSamples = try AudioFileLoader.load(url: audioURL, targetSampleRate: 16000)
        let tokenizer = try await loadTokenizer(from: modelDirectory)
        let transcript = try transcribe(
            audioSamples: audioSamples,
            modelDirectory: modelDirectory,
            tokenizer: tokenizer,
            language: invocation.language,
            maxTokens: invocation.maxNewTokens
        )

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
                "tokenizerRepository": tokenizerRepositoryId,
                "language": invocation.language ?? "auto",
                "maxNewTokens": String(invocation.maxNewTokens),
            ]
        )
    }

    private func transcribe(
        audioSamples: [Float],
        modelDirectory: URL,
        tokenizer: Qwen3Tokenizer,
        language: String?,
        maxTokens: Int
    ) throws -> String {
        let encoder = try CoreMLASREncoder.load(from: modelDirectory, computeUnits: .cpuAndNeuralEngine)
        let decoder = try CoreMLTextDecoder.load(from: modelDirectory, computeUnits: .cpuOnly)
        let featureExtractor = WhisperFeatureExtractor()

        let melFeatures = featureExtractor.process(audioSamples, sampleRate: 16000)
        let audioEmbeddings = try encoder.encode(melFeatures)
        let audioTokenCount = audioEmbeddings.dim(1)

        decoder.resetCache()

        let imStartId: Int32 = 151644
        let imEndId: Int32 = 151645
        let audioStartId: Int32 = 151669
        let audioEndId: Int32 = 151670
        let asrTextId: Int32 = 151704
        let newlineId: Int32 = 198
        let systemId: Int32 = 8948
        let userId: Int32 = 872
        let assistantId: Int32 = 77091

        var prefixTokens: [Int32] = [imStartId, systemId, newlineId, imEndId, newlineId]
        prefixTokens += [imStartId, userId, newlineId, audioStartId]

        var suffixTokens: [Int32] = [audioEndId, imEndId, newlineId, imStartId, assistantId, newlineId]
        if let language, !language.isEmpty {
            let languageTokens = tokenizer.encode("language \(language)")
            suffixTokens += languageTokens.map(Int32.init)
        }
        suffixTokens.append(asrTextId)

        var lastLogits: MLMultiArray?

        for token in prefixTokens {
            let embedding = try decoder.embed(tokenId: token)
            lastLogits = try decoder.decoderStep(embedding: embedding)
        }

        for index in 0..<audioTokenCount {
            let embedding = try decoder.audioEmbeddingToMultiArray(audioEmbeddings, at: index)
            lastLogits = try decoder.decoderStep(embedding: embedding)
        }

        for token in suffixTokens {
            let embedding = try decoder.embed(tokenId: token)
            lastLogits = try decoder.decoderStep(embedding: embedding)
        }

        guard var logits = lastLogits else {
            throw ModelEvaluationError.runtime("speech-swift CoreML decoder returned no logits")
        }

        var generatedTokens: [Int32] = []
        var nextToken = decoder.argmax(logits: logits)
        generatedTokens.append(nextToken)

        if maxTokens > 1 {
            for _ in 1..<maxTokens {
                if nextToken == imEndId { break }

                let embedding = try decoder.embed(tokenId: nextToken)
                logits = try decoder.decoderStep(embedding: embedding)
                nextToken = decoder.argmax(logits: logits)
                generatedTokens.append(nextToken)
            }
        }

        let rawText = tokenizer.decode(tokens: generatedTokens.map(Int.init))
        if let range = rawText.range(of: "<asr_text>") {
            return String(rawText[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return rawText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadTokenizer(from modelDirectory: URL) async throws -> Qwen3Tokenizer {
        let tokenizer = Qwen3Tokenizer()
        let localVocabURL = modelDirectory.appendingPathComponent("vocab.json")
        if FileManager.default.fileExists(atPath: localVocabURL.path) {
            try tokenizer.load(from: localVocabURL)
            return tokenizer
        }

        let tokenizerDirectory = try HuggingFaceDownloader.getCacheDirectory(for: tokenizerRepositoryId)
        try await HuggingFaceDownloader.downloadWeights(
            modelId: tokenizerRepositoryId,
            to: tokenizerDirectory,
            additionalFiles: ["vocab.json", "merges.txt", "tokenizer_config.json"]
        )
        try tokenizer.load(from: tokenizerDirectory.appendingPathComponent("vocab.json"))
        return tokenizer
    }
}
