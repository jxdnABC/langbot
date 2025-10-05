#!/bin/bash
set -e

echo "📦 Installing dependencies (this may take a minute on first run)..."
pip install --upgrade pip
pip install langbot langbot-plugin

echo "✅ Installation complete!"
pip list | grep -i langbot

echo "🧠 Starting LangBot Plugin Runtime..."
nohup python3 -m langbot_plugin.cli rt --port 5401 > /app/data/plugin.log 2>&1 &

# 等待插件运行时启动
sleep 5

echo "🤖 Starting LangBot main service..."
exec python3 -m langbot.cli --port ${PORT:-5300}
