#!/bin/bash
set -euo pipefail
# scriptsディレクトリに移動
cd "$(dirname "$0")"
# 1つ上のディレクトリに移動
cd ..
# コマンドを実行

# test
poetry run pytest
# lint
poetry run mypy
# check format
poetry run isort --check .
poetry run black --check .
