FROM rockchin/langbot:latest

ENV TZ=Asia/Shanghai
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# 安装必要工具并创建数据目录
RUN apt-get update && \
    apt-get install -y net-tools netcat-openbsd procps && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /app/data /app/plugins

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Plugin Runtime 配置
ENV PLUGIN_RUNTIME_URL=ws://127.0.0.1:5401/control/ws

EXPOSE 5300
EXPOSE 5401

CMD ["/bin/bash", "/app/start.sh"]
