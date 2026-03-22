#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_MODEL_DIR="$REPO_DIR/data/models/mlx-community/Qwen3-ASR-0.6B-4bit"
DEFAULT_AUDIO_PATH="$REPO_DIR/data/sound_examples/qwen3_asr_test_audio.wav"

MODEL_DIR="${1:-$DEFAULT_MODEL_DIR}"
AUDIO_PATH="${2:-$DEFAULT_AUDIO_PATH}"

cd "$REPO_DIR"

swift run model-test \
  --repository mlx-community/Qwen3-ASR-0.6B-4bit \
  --artifact 4bit \
  --framework mlxswift \
  --model-dir "$MODEL_DIR" \
  --audio "$AUDIO_PATH" \
  --json
