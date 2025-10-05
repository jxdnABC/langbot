#!/bin/bash
set -e

echo "🔍 Checking Python environment..."
which python3
python3 --version
uv --version || echo "uv not found"

echo "🔍 Checking installed packages..."
uv pip list || pip list

echo "🧠 Starting LangBot Plugin Runtime..."
nohup uv run -m langbot_plugin.cli.__init__ rt --port 5401 > /app/data/plugin.log 2>&1 &

# 等待插件运行时启动
sleep 3

echo "🤖 Starting LangBot main service..."
exec uv run -m langbot --port ${PORT:-5300}
