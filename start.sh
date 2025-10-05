#!/bin/bash
set -e

echo "Starting LangBot with Plugin Runtime..."

mkdir -p /app/data /app/plugins

# 启动 Plugin Runtime (默认端口 5400)
echo "[1/3] Starting Plugin Runtime on port 5400..."
uv run -m langbot_plugin.cli.__init__ rt > /app/data/plugin_runtime.log 2>&1 &
echo "✓ Plugin Runtime started (PID: $!)"

# 等待 Plugin Runtime 启动
sleep 3

# 后台任务：监控并修改配置文件
(
    echo "[2/3] Monitoring for config file..."
    for i in {1..180}; do
        for cfg in /app/data/config.yaml data/config.yaml; do
            if [ -f "$cfg" ]; then
                # 检查是否需要修改
                if grep -q "langbot_plugin_runtime" "$cfg" 2>/dev/null; then
                    echo "      Found config at $cfg, patching..."
                    sed -i 's/langbot_plugin_runtime/127.0.0.1/g' "$cfg"
                    echo "      ✓ Config patched successfully!"
                    exit 0
                fi
            fi
        done
        sleep 1
    done
    echo "      (Config monitoring timeout - may already be correct)"
) &

# 启动 LangBot (前台运行)
echo "[3/3] Starting LangBot on port 5300..."
echo ""
exec uv run python3 main.py
