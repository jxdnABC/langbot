# 使用官方 Python 镜像（LangBot 依赖 uv 工具）
FROM python:3.12-slim

# 设置时区和基础依赖
ENV TZ=Asia/Shanghai
RUN apt-get update && apt-get install -y git curl && \
    pip install --upgrade pip uv && \
    rm -rf /var/lib/apt/lists/*

# 工作目录
WORKDIR /app

# 安装 LangBot
RUN pip install rockchin-langbot

# 创建必要目录
RUN mkdir -p /app/data /app/plugins

# 拷贝启动脚本
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# 环境变量（可在 Render 控制台覆盖）
ENV PORT=5300
ENV LANGBOT_DB_TYPE=sqlite
ENV LANGBOT_DB_PATH=/app/data/langbot.db
ENV PLUGIN_RUNTIME_URL=ws://127.0.0.1:5401/control/ws
ENV LANGBOT_DEBUG=true

# 暴露端口
EXPOSE 5300
EXPOSE 5401

# 启动主程序和插件运行时
CMD ["/bin/bash", "/app/start.sh"]
