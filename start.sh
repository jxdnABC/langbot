#!/bin/bash
set -e

echo "====== Plugin Runtime 调试 ======"

echo ""
echo "1. 查找 plugin 相关的可执行文件:"
find /app/.venv/bin -name "*plugin*" -type f 2>/dev/null || echo "None"

echo ""
echo "2. 查找 plugin 相关的 Python 模块:"
find /app/.venv/lib -name "*plugin*" -type d 2>/dev/null | head -10

echo ""
echo "3. 已安装的 plugin 包:"
uv pip list | grep -i plugin

echo ""
echo "4. 尝试导入 langbot_plugin:"
python3 -c "import langbot_plugin; print('Location:', langbot_plugin.__file__); print('Contents:', dir(langbot_plugin))" 2>&1 || echo "Failed"

echo ""
echo "5. 查看 langbot_plugin 的 cli 模块:"
python3 -c "from langbot_plugin import cli; print(dir(cli))" 2>&1 || echo "No cli module"

echo ""
echo "6. 尝试运行 plugin runtime:"
echo "   Trying: uv run langbot-plugin rt --port 5401"
timeout 5 uv run langbot-plugin rt --port 5401 2>&1 || echo "Failed"

echo ""
echo "   Trying: uv run -m langbot_plugin.cli rt --port 5401"
timeout 5 uv run -m langbot_plugin.cli rt --port 5401 2>&1 || echo "Failed"

echo ""
echo "   Trying: python3 -m langbot_plugin rt --port 5401"
timeout 5 python3 -m langbot_plugin rt --port 5401 2>&1 || echo "Failed"

echo ""
echo "====== 保持运行 60 秒以查看日志 ======"
sleep 60
