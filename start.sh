#!/bin/bash
set -e

echo "🧠 Starting LangBot Plugin Runtime..."
nohup uv run -m langbot_plugin.cli.__init__ rt --port 5401 > /app/data/plugin.log 2>&1 &

echo "🤖 Starting LangBot main service..."
exec uv run -m langbot.__main__ --port ${PORT:-5300}
