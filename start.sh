#!/bin/bash
set -e

echo "🚀 Starting LangBot with uv..."
echo "Port: ${PORT}"

# 使用 uv 运行 langbot（镜像已经预装）
exec uv run -m langbot --port ${PORT:-5300}
