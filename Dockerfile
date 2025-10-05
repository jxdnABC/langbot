FROM rockchin/langbot:latest

ENV TZ=Asia/Shanghai
ENV PYTHONUNBUFFERED=1

# 关键：设置 Plugin Runtime 连接地址
ENV PLUGIN_RUNTIME_HOST=127.0.0.1
ENV PLUGIN_RUNTIME_PORT=5401
ENV PLUGIN_RUNTIME_URL=ws://127.0.0.1:5401/control/ws

WORKDIR /app

RUN apt-get update && \
    apt-get install -y net-tools netcat-openbsd procps iproute2 && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /app/data /app/plugins

# 预安装 Python 标准库确保 http.server 可用
RUN python3 -c "import http.server; print('HTTP server module ready')"

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 5300
EXPOSE 5401

CMD ["/bin/bash", "/app/start.sh"]
