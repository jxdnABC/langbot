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

sleep 5

if ps -p $PLUGIN_PID > /dev/null; then
    echo "✓ Plugin Runtime is running"
else
    echo "✗ Plugin Runtime failed!"
    cat /app/data/plugin_runtime.log 2>/dev/null || true
    exit 1
fi

# Step 2: 启动配置监控和修补脚本（后台）
cat > /app/patch_config.py << 'PATCHER_EOF'
import os, time, sys
OLD = 'ws://langbot_plugin_runtime:5400/control/ws'
NEW = 'ws://127.0.0.1:5401/control/ws'
paths = ['/app/data/config.yaml', 'data/config.yaml']

print('[Patcher] Starting...')
for _ in range(150):
    for p in paths:
        if os.path.exists(p):
            try:
                with open(p, 'r') as f: c = f.read()
                if OLD in c or 'langbot_plugin_runtime' in c:
                    c = c.replace(OLD, NEW).replace('langbot_plugin_runtime:5400', '127.0.0.1:5401')
                    with open(p, 'w') as f: f.write(c)
                    print(f'[Patcher] ✓ Patched {p}')
                    # 杀死 LangBot 让它重启
                    os.system("pkill -f 'python3 main.py'")
                    sys.exit(0)
            except: pass
    time.sleep(1)
print('[Patcher] Timeout')
PATCHER_EOF

python3 /app/patch_config.py > /app/data/patcher.log 2>&1 &
PATCHER_PID=$!
echo "Config patcher started (PID: $PATCHER_PID)"

# Step 3: 循环启动 LangBot
attempt=0
while [ $attempt -lt 3 ]; do
    echo ""
    echo "Starting LangBot (attempt $((attempt + 1)))..."
    uv run python3 main.py &
    LANGBOT_PID=$!
    
    # 等待进程结束或被杀死
    wait $LANGBOT_PID 2>/dev/null || true
    
    # 检查配置是否已被修改
    if grep -q "127.0.0.1:5401" /app/data/config.yaml 2>/dev/null || \
       grep -q "127.0.0.1:5401" data/config.yaml 2>/dev/null; then
        echo "✓ Config patched! Starting final instance..."
        kill $PATCHER_PID 2>/dev/null || true
        exec uv run python3 main.py
    fi
    
    attempt=$((attempt + 1))
    sleep 3
done

echo "Failed to start properly, but continuing anyway..."
exec uv run python3 main.py
