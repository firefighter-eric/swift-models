#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

swift build --package-path Packages/ModelEvaluationMLXRunner
