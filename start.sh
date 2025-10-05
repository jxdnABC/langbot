#!/bin/bash
set -e

echo "======================================"
echo "Starting LangBot with Plugin Runtime"
echo "======================================"

mkdir -p /app/data /app/plugins

# 启动 Plugin Runtime（使用默认 5400 端口）
echo "Starting Plugin Runtime on default port 5400..."
nohup uv run -m langbot_plugin.cli.__init__ rt > /app/data/plugin_runtime.log 2>&1 &
PLUGIN_PID=$!
echo "Plugin Runtime PID: $PLUGIN_PID"

# 等待并检查
echo "Waiting for Plugin Runtime to start..."
sleep 5

# 详细诊断
echo ""
echo "=== Diagnostic Info ==="
echo "Process status:"
ps aux | grep -E "langbot_plugin|rt" || echo "No plugin runtime process found"

echo ""
echo "Listening ports:"
netstat -tln 2>/dev/null | grep LISTEN || ss -tln 2>/dev/null | grep LISTEN || echo "Cannot detect ports"

echo ""
echo "Plugin Runtime log:"
tail -30 /app/data/plugin_runtime.log 2>/dev/null || echo "No log available"

echo ""
if ps -p $PLUGIN_PID > /dev/null; then
    echo "✓ Plugin Runtime process is alive"
else
    echo "✗ Plugin Runtime process died!"
    exit 1
fi

# 检查 5400 端口
if netstat -tln 2>/dev/null | grep -q ":5400" || ss -tln 2>/dev/null | grep -q ":5400"; then
    echo "✓ Port 5400 is listening"
else
    echo "⚠ Port 5400 is NOT listening"
    echo "This might be normal if plugin runtime uses a different mechanism"
fi

echo "======================="
echo ""

# 创建配置修补脚本（改用 localhost 而不是主机名）
cat > /app/patch_config.py << 'PATCHER_EOF'
import os, time, sys

OLD_HOSTNAME = 'langbot_plugin_runtime'
NEW_HOSTNAME = '127.0.0.1'
paths = ['/app/data/config.yaml', 'data/config.yaml']

print('[Patcher] Starting config watcher...')
for attempt in range(150):
    for p in paths:
        if os.path.exists(p):
            try:
                with open(p, 'r') as f:
                    c = f.read()
                
                if OLD_HOSTNAME in c:
                    print(f'[Patcher] Found config at {p}, patching...')
                    # 只替换主机名，保持端口 5400
                    c = c.replace(OLD_HOSTNAME, NEW_HOSTNAME)
                    
                    with open(p, 'w') as f:
                        f.write(c)
                    
                    print(f'[Patcher] ✓ Patched {p}')
                    print('[Patcher] Killing LangBot to reload config...')
                    os.system("pkill -f 'python3 main.py'")
                    sys.exit(0)
            except Exception as e:
                print(f'[Patcher] Error: {e}')
    time.sleep(1)

print('[Patcher] Timeout - config file not found or already patched')
PATCHER_EOF

# 启动配置修补脚本
python3 /app/patch_config.py > /app/data/patcher.log 2>&1 &
PATCHER_PID=$!

# 循环启动 LangBot
for attempt in {1..3}; do
    echo "Starting LangBot (attempt $attempt)..."
    uv run python3 main.py &
    LANGBOT_PID=$!
    
    wait $LANGBOT_PID 2>/dev/null || true
    
    # 检查配置是否已修补
    if grep -q "127.0.0.1:5400" /app/data/config.yaml 2>/dev/null || \
       grep -q "127.0.0.1:5400" data/config.yaml 2>/dev/null; then
        echo "✓ Config patched! Final start..."
        kill $PATCHER_PID 2>/dev/null || true
        exec uv run python3 main.py
    fi
    
    sleep 3
done

echo "Starting LangBot anyway..."
kill $PATCHER_PID 2>/dev/null || true
exec uv run python3 main.py
