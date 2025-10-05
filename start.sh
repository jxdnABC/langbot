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

# 检查 Plugin Runtime
if ps -p $PLUGIN_PID > /dev/null 2>&1; then
    echo "✓ Plugin Runtime is running"
    if netstat -tln 2>/dev/null | grep -q ":5401"; then
        echo "✓ Plugin Runtime listening on port 5401"
    fi
else
    echo "! Plugin Runtime may have issues"
    tail -20 /app/data/plugin_runtime.log 2>/dev/null || true
fi

echo ""
echo "Step 2: Starting LangBot with modified plugin runtime URL..."

# 启动 LangBot，然后立即修改配置文件
uv run python3 main.py &
LANGBOT_PID=$!

# 等待配置文件生成
echo "Waiting for config.yaml to be generated..."
for i in {1..30}; do
    if [ -f data/config.yaml ] || [ -f /app/data/config.yaml ]; then
        echo "✓ Config file found"
        sleep 2  # 等待写入完成
        
        # 查找配置文件
        CONFIG_FILE=""
        if [ -f data/config.yaml ]; then
            CONFIG_FILE="data/config.yaml"
        elif [ -f /app/data/config.yaml ]; then
            CONFIG_FILE="/app/data/config.yaml"
        fi
        
        if [ -n "$CONFIG_FILE" ]; then
            echo "Modifying $CONFIG_FILE..."
            
            # 显示原始内容
            echo "--- Original config (first 20 lines) ---"
            head -20 "$CONFIG_FILE"
            
            # 替换 plugin runtime URL
            sed -i 's|ws://langbot_plugin_runtime:5400/control/ws|ws://127.0.0.1:5401/control/ws|g' "$CONFIG_FILE"
            sed -i 's|langbot_plugin_runtime:5400|127.0.0.1:5401|g' "$CONFIG_FILE"
            
            echo ""
            echo "--- Modified config (grep plugin/runtime) ---"
            grep -i "plugin\|runtime" "$CONFIG_FILE" || echo "No plugin/runtime config found"
            
            echo ""
            echo "Restarting LangBot to apply changes..."
            kill $LANGBOT_PID
            sleep 2
            exec uv run python3 main.py
        fi
        break
    fi
    sleep 1
done

echo "Config file not generated in time, continuing anyway..."
wait $LANGBOT_PID
