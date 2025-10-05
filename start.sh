#!/bin/bash
set -e

echo "======================================"
echo "🚀 Starting LangBot with Plugin Runtime"
echo "======================================"

# 配置 Plugin Runtime 连接地址
export PLUGIN_RUNTIME_URL="ws://127.0.0.1:5401/control/ws"

echo ""
echo "🧠 Starting Plugin Runtime on port 5401..."

# 使用 uv run 在虚拟环境中运行
cd /app
nohup uv run python3 -m langbot_plugin.cli rt --port 5401 > /app/data/plugin_runtime.log 2>&1 &
PLUGIN_PID=$!
echo "   Plugin Runtime PID: $PLUGIN_PID"

# 等待启动
echo "   Waiting for Plugin Runtime..."
sleep 5

# 检查是否启动成功
if ps -p $PLUGIN_PID > /dev/null; then
    echo "   ✅ Plugin Runtime process is running"
    
    # 检查端口
    if netstat -tln 2>/dev/null | grep -q ":5401 "; then
        echo "   ✅ Plugin Runtime is listening on port 5401"
    else
        echo "   ⚠️  Port 5401 not yet bound, checking logs..."
        tail -20 /app/data/plugin_runtime.log
    fi
else
    echo "   ❌ Plugin Runtime process died, checking logs..."
    cat /app/data/plugin_runtime.log
fi

echo ""
echo "🤖 Starting LangBot main service..."
exec uv run python3 main.py
