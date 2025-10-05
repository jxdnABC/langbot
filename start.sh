#!/bin/bash
set -e

echo "🔍 Checking installation..."
python3 -c "import langbot; print(f'LangBot version: {langbot.__version__}')" || echo "LangBot check failed"

echo "🧠 Starting LangBot Plugin Runtime..."
nohup python3 -m langbot_plugin.cli rt --port 5401 > /app/data/plugin.log 2>&1 &

sleep 2

echo "🤖 Starting LangBot main service on port ${PORT}..."
exec python3 -m langbot.cli --port ${PORT:-5300}
