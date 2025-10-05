FROM rockchin/langbot:latest

ENV TZ=Asia/Shanghai
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# 安装网络工具用于调试
RUN apt-get update && \
    apt-get install -y net-tools netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Plugin Runtime 配置
ENV PLUGIN_RUNTIME_URL=ws://127.0.0.1:5401/control/ws

EXPOSE 5300
EXPOSE 5401

CMD ["/bin/bash", "/app/start.sh"]
