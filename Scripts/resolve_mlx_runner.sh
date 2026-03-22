#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

swift package resolve --package-path Packages/ModelEvaluationMLXRunner
