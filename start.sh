#!/bin/bash
set -e

echo "======================================"
echo "Starting LangBot with Plugin Runtime"
echo "======================================"

# 确保目录存在
mkdir -p /app/data /app/plugins

# 配置连接地址
export PLUGIN_RUNTIME_URL="ws://127.0.0.1:5401/control/ws"

echo ""
echo "Starting Plugin Runtime on port 5401..."
nohup uv run -m langbot_plugin.cli.__init__ rt --port 5401 > /app/data/plugin_runtime.log 2>&1 &
PLUGIN_PID=$!

sleep 5

echo "Plugin Runtime PID: $PLUGIN_PID"
if ps -p $PLUGIN_PID > /dev/null 2>&1; then
    echo "Plugin Runtime is running"
    echo "Recent logs:"
    tail -20 /app/data/plugin_runtime.log 2>/dev/null || echo "No logs yet"
else
    echo "Plugin Runtime may have failed, logs:"
    cat /app/data/plugin_runtime.log 2>/dev/null || echo "No log file"
fi

echo ""
echo "Starting LangBot main service..."
exec uv run python3 main.py
