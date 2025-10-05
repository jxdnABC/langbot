#!/bin/bash
set -e

echo "======================================"
echo "Starting LangBot + Plugin Runtime"
echo "======================================"

mkdir -p /app/data /app/plugins

# 1. 启动 Plugin Runtime（默认端口 5400）
echo "Starting Plugin Runtime..."
uv run -m langbot_plugin.cli.__init__ rt > /app/data/plugin_runtime.log 2>&1 &
PLUGIN_RT_PID=$!
echo "Plugin Runtime PID: $PLUGIN_RT_PID"

# 等待 Plugin Runtime 启动
sleep 3

# 2. 修改配置文件的后台监控脚本
cat > /tmp/config_fixer.sh << 'EOF'
#!/bin/bash
for i in {1..180}; do
    for cfg in /app/data/config.yaml data/config.yaml; do
        if [ -f "$cfg" ] && grep -q "langbot_plugin_runtime" "$cfg"; then
            echo "[Fixer] Patching $cfg..."
            sed -i 's/langbot_plugin_runtime/127.0.0.1/g' "$cfg"
            echo "[Fixer] Done!"
            exit 0
        fi
    done
    sleep 1
done
EOF

chmod +x /tmp/config_fixer.sh
/tmp/config_fixer.sh &

# 3. 直接启动 LangBot（前台运行）
echo "Starting LangBot..."
exec uv run python3 main.py
