#!/bin/bash
set -e

echo "=== LangBot 配置调试 ==="

echo ""
echo "📄 查找配置文件..."
find /app -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "config*" 2>/dev/null | head -10

echo ""
echo "📄 查看 pyproject.toml..."
grep -i port /app/pyproject.toml 2>/dev/null || echo "未找到 port 相关配置"

echo ""
echo "📄 查看 main.py 中的端口配置..."
grep -i "port\|PORT" /app/main.py | head -20

echo ""
echo "📄 查看环境变量..."
env | sort

echo ""
echo "🔍 查看 LangBot 文档中的端口相关代码..."
grep -r "http.*port\|web.*port" /app/pkg/ 2>/dev/null | head -10 || echo "未找到"

echo ""
echo "🚀 尝试启动 LangBot（默认配置）..."
export LANGBOT_HTTP_PORT=${PORT}
export LANGBOT_WEB_PORT=${PORT}
export PORT=${PORT}

exec uv run python3 main.py
