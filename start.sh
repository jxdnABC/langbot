#!/bin/bash
set -e

echo "====== 环境检查 ======"
echo "Python 版本:"
python3 --version

echo -e "\n已安装的 langbot 相关包:"
pip list | grep -i langbot || echo "未找到 langbot"

echo -e "\n虚拟环境中的可执行文件:"
ls -la /app/.venv/bin/ | grep -E "(langbot|bot)" || echo "未找到相关文件"

echo -e "\nlangbot 包的位置:"
python3 -c "import langbot; print(langbot.__file__)" 2>/dev/null || echo "无法导入 langbot"

echo -e "\nlangbot 包的内容:"
python3 -c "import langbot; print(dir(langbot))" 2>/dev/null || echo "无法列出内容"

echo -e "\n====== 尝试启动 ======"
echo "如果上面显示了正确的信息，请根据实际情况修改启动命令"
sleep 5

# 尝试启动（根据上面的输出结果修改这里）
echo "🧠 Starting LangBot Plugin Runtime..."
nohup python3 -m langbot_plugin.cli rt --port 5401 > /app/data/plugin.log 2>&1 &

sleep 3

echo "🤖 Starting LangBot main service..."
exec python3 -m langbot.cli --port ${PORT:-5300}
