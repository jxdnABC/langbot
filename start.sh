#!/bin/bash
set -e

echo "🧠 Starting LangBot Plugin Runtime..."
nohup langbot rt --port 5401 > /app/data/plugin.log 2>&1 &

echo "🤖 Starting LangBot main service..."
exec langbot run --port ${PORT:-5300}
