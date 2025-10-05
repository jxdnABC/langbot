#!/bin/bash
set -e

echo "======================================"
echo "Starting LangBot with Plugin Runtime"
echo "======================================"

mkdir -p /app/data /app/plugins

# Step 1: 启动 Plugin Runtime
echo "Starting Plugin Runtime on port 5401..."
nohup uv run -m langbot_plugin.cli.__init__ rt --port 5401 > /app/data/plugin_runtime.log 2>&1 &
PLUGIN_PID=$!
echo "Plugin Runtime PID: $PLUGIN_PID"

# 等待 Plugin Runtime 完全启动
echo "Waiting for Plugin Runtime to be ready..."
for i in {1..30}; do
    if netstat -tln 2>/dev/null | grep -q ":5401" || ss -tln 2>/dev/null | grep -q ":5401"; then
        echo "✓ Plugin Runtime is listening on port 5401"
        break
    fi
    sleep 1
done

# Step 2: 检查是否存在旧的配置文件，如果存在则先修改
for config_path in "data/config.yaml" "/app/data/config.yaml"; do
    if [ -f "$config_path" ]; then
        echo "Found existing config: $config_path"
        echo "Updating plugin runtime URL..."
        sed -i 's|ws://langbot_plugin_runtime:5400/control/ws|ws://127.0.0.1:5401/control/ws|g' "$config_path"
        sed -i 's|langbot_plugin_runtime:5400|127.0.0.1:5401|g' "$config_path"
        echo "✓ Config updated"
    fi
done

# Step 3: 启动 LangBot（配置会在首次运行时生成）
echo ""
echo "Starting LangBot..."
uv run python3 main.py &
LANGBOT_PID=$!

# Step 4: 监控配置文件生成并立即修改
echo "Monitoring for config file generation..."
for i in {1..60}; do
    for config_path in "data/config.yaml" "/app/data/config.yaml"; do
        if [ -f "$config_path" ] && [ ! -f "${config_path}.modified" ]; then
            echo "✓ New config detected: $config_path"
            sleep 1  # 等待写入完成
            
            # 修改配置
            sed -i 's|ws://langbot_plugin_runtime:5400/control/ws|ws://127.0.0.1:5401/control/ws|g' "$config_path"
            sed -i 's|langbot_plugin_runtime:5400|127.0.0.1:5401|g' "$config_path"
            
            # 标记已修改
            touch "${config_path}.modified"
            
            echo "Config modified, restarting LangBot..."
            kill $LANGBOT_PID 2>/dev/null || true
            sleep 2
            
            # 重新启动
            exec uv run python3 main.py
        fi
    done
    sleep 1
done

# 如果配置文件一直没生成，继续运行
echo "Config monitoring timeout, continuing with current process..."
wait $LANGBOT_PID
