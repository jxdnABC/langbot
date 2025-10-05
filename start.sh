#!/bin/bash
set -e

echo "======================================"
echo "Starting LangBot with Standalone Plugin Runtime"
echo "======================================"

mkdir -p /app/data /app/plugins

# 使用 --standalone-runtime 参数启动，这样 plugin runtime 会在同一进程中运行
echo "Starting LangBot with standalone runtime mode..."
exec uv run python3 main.py --standalone-runtime
