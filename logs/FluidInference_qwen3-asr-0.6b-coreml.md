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
