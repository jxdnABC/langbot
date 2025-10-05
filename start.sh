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

echo ""
echo "Step 2: Generating initial config if needed..."
if [ ! -f /app/data/config.yaml ]; then
    echo "First run - generating config..."
    timeout 10 uv run python3 main.py &
    INIT_PID=$!
    sleep 8
    kill $INIT_PID 2>/dev/null || true
    sleep 2
fi

echo ""
echo "Step 3: Checking and modifying config.yaml..."
if [ -f /app/data/config.yaml ]; then
    echo "Current config.yaml content:"
    cat /app/data/config.yaml
    echo ""
    echo "---"
    
    # 备份
    cp /app/data/config.yaml /app/data/config.yaml.bak
    
    # 查找所有可能的 plugin runtime 相关配置
    echo "Searching for plugin runtime config..."
    grep -i "plugin" /app/data/config.yaml || echo "No 'plugin' found"
    grep -i "runtime" /app/data/config.yaml || echo "No 'runtime' found"
    grep -i "5400" /app/data/config.yaml || echo "No '5400' found"
    grep -i "langbot_plugin_runtime" /app/data/config.yaml || echo "No 'langbot_plugin_runtime' found"
    
    echo ""
    echo "Attempting to fix config..."
    
    # 替换所有可能的旧地址
    sed -i 's|ws://langbot_plugin_runtime:5400/control/ws|ws://127.0.0.1:5401/control/ws|g' /app/data/config.yaml
    sed -i 's|langbot_plugin_runtime:5400|127.0.0.1:5401|g' /app/data/config.yaml
    sed -i 's|:5400|:5401|g' /app/data/config.yaml
    
    echo ""
    echo "Modified config.yaml:"
    cat /app/data/config.yaml
    
else
    echo "WARNING: config.yaml not found at /app/data/config.yaml"
    echo "Checking other locations..."
    find /app -name "config.yaml" -o -name "config.yml" 2>/dev/null || echo "No config files found"
fi

echo ""
echo "Step 4: Starting LangBot..."
exec uv run python3 main.py
