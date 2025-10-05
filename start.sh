#!/bin/bash
set -e

echo "======================================"
echo "Starting LangBot with Plugin Runtime"
echo "======================================"

# 确保目录存在
mkdir -p /app/data /app/plugins

echo ""
echo "Step 1: Starting Plugin Runtime on port 5401..."
nohup uv run -m langbot_plugin.cli.__init__ rt --port 5401 > /app/data/plugin_runtime.log 2>&1 &
PLUGIN_PID=$!

echo "Plugin Runtime PID: $PLUGIN_PID"
sleep 3

# 检查 Plugin Runtime 是否启动
if ps -p $PLUGIN_PID > /dev/null 2>&1; then
    echo "Plugin Runtime is running"
else
    echo "Plugin Runtime may have issues, checking logs..."
    tail -20 /app/data/plugin_runtime.log 2>/dev/null || echo "No logs"
fi

echo ""
echo "Step 2: Configuring LangBot to use local Plugin Runtime..."

# 等待配置文件生成
if [ ! -f /app/data/config.yaml ]; then
    echo "First run detected, initializing config..."
    timeout 10 uv run python3 main.py &
    INIT_PID=$!
    sleep 8
    kill $INIT_PID 2>/dev/null || true
    sleep 2
fi

# 修改配置文件中的 plugin runtime 地址
if [ -f /app/data/config.yaml ]; then
    echo "Updating plugin runtime URL in config..."
    
    # 备份配置
    cp /app/data/config.yaml /app/data/config.yaml.bak
    
    # 修改或添加 plugin runtime 配置
    if grep -q "plugin_runtime_url:" /app/data/config.yaml; then
        sed -i 's|plugin_runtime_url:.*|plugin_runtime_url: ws://127.0.0.1:5401/control/ws|' /app/data/config.yaml
    else
        echo "" >> /app/data/config.yaml
        echo "plugin_runtime_url: ws://127.0.0.1:5401/control/ws" >> /app/data/config.yaml
    fi
    
    echo "Config updated:"
    grep -A 2 "plugin_runtime" /app/data/config.yaml || echo "plugin_runtime_url: ws://127.0.0.1:5401/control/ws"
fi

echo ""
echo "Step 3: Starting LangBot main service..."
exec uv run python3 main.py
