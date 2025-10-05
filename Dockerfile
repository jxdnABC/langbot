FROM rockchin/langbot:latest

ENV TZ=Asia/Shanghai
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# LangBot 配置环境变量
ENV LANGBOT_HTTP_PORT=${PORT}
ENV LANGBOT_WEB_PORT=${PORT}

EXPOSE 5300

CMD ["/bin/bash", "/app/start.sh"]
