FROM rockchin/langbot:latest

ENV TZ=Asia/Shanghai

WORKDIR /app
RUN mkdir -p /app/data /app/plugins

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# 环境变量（Render 控制台可覆盖）
ENV PORT=5300
ENV PLUGIN_RUNTIME_URL=ws://127.0.0.1:5401/control/ws
ENV LANGBOT_DB_TYPE=sqlite
ENV LANGBOT_DB_PATH=/app/data/langbot.db
ENV LANGBOT_DEBUG=true

EXPOSE 5300
EXPOSE 5401

CMD ["/bin/bash", "/app/start.sh"]
