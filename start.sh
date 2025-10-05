#!/bin/bash
set -e

echo "======================================"
echo "LangBot + Plugin Runtime for Render"
echo "======================================"

mkdir -p /app/data /app/plugins

# 关键：立即启动一个假的 HTTP 服务占住 5300 端口
# 这样 Render 就不会超时
echo "Starting placeholder HTTP service on port 5300..."
cat > /tmp/placeholder.py << 'PLACEHOLDER_EOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b'<h1>LangBot is starting...</h1><p>Please wait 1-2 minutes.</p>')
    def log_message(self, format, *args):
        pass
HTTPServer(('0.0.0.0', 5300), Handler).serve_forever()
PLACEHOLDER_EOF

python3 /tmp/placeholder.py &
PLACEHOLDER_PID=$!
echo "Placeholder server started (PID: $PLACEHOLDER_PID)"

# 等待端口真正监听
for i in {1..10}; do
    if netstat -tln 2>/dev/null | grep -q ":5300" || ss -tln 2>/dev/null | grep -q ":5300"; then
        echo "✓ Port 5300 is ready - Render will detect this"
        break
    fi
    sleep 1
done

# 现在可以慢慢启动真正的服务了
echo ""
echo "Starting Plugin Runtime..."
nohup uv run -m langbot_plugin.cli.__init__ rt > /app/data/plugin_runtime.log 2>&1 &
PLUGIN_PID=$!
echo "Plugin Runtime PID: $PLUGIN_PID"

sleep 5

# 检查 Plugin Runtime
echo "Checking Plugin Runtime..."
if ps -p $PLUGIN_PID > /dev/null; then
    echo "✓ Plugin Runtime is running"
    tail -10 /app/data/plugin_runtime.log
else
    echo "⚠ Plugin Runtime may have issues"
    cat /app/data/plugin_runtime.log 2>/dev/null || true
fi

# 配置修补脚本
cat > /app/patch.py << 'PATCH_EOF'
import os, time, sys
for _ in range(120):
    for p in ['/app/data/config.yaml', 'data/config.yaml']:
        if os.path.exists(p):
            with open(p) as f: c = f.read()
            if 'langbot_plugin_runtime' in c:
                c = c.replace('langbot_plugin_runtime', '127.0.0.1')
                with open(p, 'w') as f: f.write(c)
                print(f'[Patch] ✓ {p}')
                os.system("kill -9 $(pgrep -f 'python3 main.py') 2>/dev/null")
                sys.exit(0)
    time.sleep(1)
PATCH_EOF

python3 /app/patch.py &

# 启动 LangBot（会被 patcher 杀死并重启）
echo ""
echo "Starting LangBot (first run)..."
timeout 120 uv run python3 main.py || true

sleep 3

# 检查配置是否已修补
if grep -q "127.0.0.1:5400" /app/data/config.yaml 2>/dev/null || \
   grep -q "127.0.0.1:5400" data/config.yaml 2>/dev/null; then
    echo "✓ Config patched!"
else
    echo "⚠ Config not patched, manually patching..."
    for p in /app/data/config.yaml data/config.yaml; do
        [ -f "$p" ] && sed -i 's/langbot_plugin_runtime/127.0.0.1/g' "$p"
    done
fi

# 杀掉占位服务
echo ""
echo "Stopping placeholder server..."
kill $PLACEHOLDER_PID 2>/dev/null || true

# 最终启动
echo "Starting LangBot (final)..."
exec uv run python3 main.py
