#!/bin/bash

set -euo pipefail

REPO_DIR="/Users/eric/projects/swift-models"
DEFAULT_MODEL_DIR="$REPO_DIR/data/models/FluidInference/qwen3-asr-0.6b-coreml/int8"
DEFAULT_AUDIO_PATH="$REPO_DIR/data/sound_examples/qwen3_asr_test_audio.wav"

MODEL_DIR="${1:-$DEFAULT_MODEL_DIR}"
AUDIO_PATH="${2:-$DEFAULT_AUDIO_PATH}"

cd "$REPO_DIR"

swift run model-test \
  --repository FluidInference/qwen3-asr-0.6b-coreml \
  --artifact int8 \
  --framework fluidaudio \
  --model-dir "$MODEL_DIR" \
  --audio "$AUDIO_PATH" \
  --json
