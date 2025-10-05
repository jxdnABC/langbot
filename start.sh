#!/bin/bash
set -e

echo "🚀 Starting LangBot on port ${PORT}..."

# 使用 uv 的虚拟环境运行
exec uv run main.py --port ${PORT:-5300}
