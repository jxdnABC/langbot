#!/bin/bash
set -e

echo "🚀 Starting LangBot..."
echo "Port: ${PORT}"

# 直接运行 LangBot 主程序
# 官方镜像已经配置好了所有东西
cd /LangBot
exec python3 main.py --port ${PORT:-5300}
