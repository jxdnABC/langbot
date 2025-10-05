FROM python:3.11-slim

ENV TZ=Asia/Shanghai
ENV PYTHONUNBUFFERED=1

WORKDIR /app
RUN mkdir -p /app/data /app/plugins

# 先安装依赖（构建时完成，不会超时）
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir langbot langbot-plugin

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV PORT=5300
ENV PLUGIN_RUNTIME_URL=ws://127.0.0.1:5401/control/ws
ENV LANGBOT_DB_TYPE=sqlite
ENV LANGBOT_DB_PATH=/app/data/langbot.db
ENV LANGBOT_DEBUG=true

EXPOSE 5300
EXPOSE 5401

CMD ["/bin/bash", "/app/start.sh"]
