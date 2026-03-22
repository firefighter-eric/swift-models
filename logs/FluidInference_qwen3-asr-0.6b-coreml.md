# First Model Test Result

- Date: 2026-03-22
- Model: `FluidInference/qwen3-asr-0.6b-coreml`
- Artifact: `int8`
- Framework: `fluidaudio`

## Summary

The first registered model in this repository is `FluidInference/qwen3-asr-0.6b-coreml`.
Project tests passed successfully.

## Executed Test

Command:

```bash
swift test
```

Result:

```text
[0/1] Planning build
Building for debugging...
[0/4] Write swift-version--1AB21518FC5DEDBE.txt
Build complete! (12.35s)
◇ Test run started.
↳ Testing Library Version: 0.99.0
◇ Suite ModelEvaluationKitTests started.
◇ Test cliParsesRepositoryFirstArguments() started.
◇ Test specRejectsUnsupportedArtifact() started.
◇ Test runnerCanUseMockRegistriesWithoutMainFlowChanges() started.
✔ Test cliParsesRepositoryFirstArguments() passed after 0.001 seconds.
✔ Test runnerCanUseMockRegistriesWithoutMainFlowChanges() passed after 0.001 seconds.
✔ Test specRejectsUnsupportedArtifact() passed after 0.003 seconds.
✔ Suite ModelEvaluationKitTests passed after 0.003 seconds.
✔ Test run with 3 tests passed after 0.003 seconds.
```

## Note

The sample audio file exists at `data/sound_examples/qwen3_asr_test_audio.wav`, but the local Core ML model artifact files required for a full inference run were not found in the repository at the time of testing.

## 官方说明

根据 FluidAudio 官方文档《Qwen3-ASR》，该实现目前仍处于持续开发阶段。由于 CoreML 本身的限制，其识别准确率（WER/CER）可能低于原始 PyTorch 版本，因此当前仓库中的评测结果应视为 CoreML 落地效果，而不是与原始 PyTorch 模型完全等价的精度结论。

官方文档同时说明，完整的 30 种语言 FLEURS 基准结果应参考 `Benchmarks.md`。

来源：

- <https://github.com/FluidInference/FluidAudio/blob/main/Documentation/ASR/Qwen3-ASR.md>
