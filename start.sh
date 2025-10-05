#!/bin/bash
set -e

# 用系统 Python（不是 .venv 里的）
PYTHON=/usr/local/bin/python3

echo "🧠 Starting LangBot Plugin Runtime..."
nohup $PYTHON -m langbot_plugin.cli.__init__ rt --port 5401 > /app/data/plugin.log 2>&1 &

echo "🤖 Starting LangBot main service..."
exec $PYTHON -m langbot.__main__ --port ${PORT:-5300}
