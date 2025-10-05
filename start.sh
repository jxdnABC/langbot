#!/bin/bash
set -e

echo "🔍 调试信息..."
echo "工作目录: $(pwd)"
echo "Python: $(which python3)"
echo "uv: $(which uv)"

echo ""
echo "查找 langbot..."
uv pip list | grep langbot || pip list | grep langbot || echo "未找到"

echo ""
echo "🚀 尝试启动..."

# 尝试多种启动方式
if uv run langbot --help &>/dev/null; then
    echo "使用 uv run langbot"
    exec uv run langbot --port ${PORT:-5300}
elif uv run -m langbot --help &>/dev/null; then
    echo "使用 uv run -m langbot"
    exec uv run -m langbot --port ${PORT:-5300}
elif python3 -m langbot --help &>/dev/null; then
    echo "使用 python3 -m langbot"
    exec python3 -m langbot --port ${PORT:-5300}
else
    echo "❌ 无法找到启动方式，显示环境信息..."
    ls -la /app/ || true
    find / -name "main.py" 2>/dev/null | head -5 || true
    sleep 60
    exit 1
fi
