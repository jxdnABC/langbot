FROM rockchin/langbot:latest

ENV TZ=Asia/Shanghai

WORKDIR /app

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV PORT=5300

EXPOSE 5300

CMD ["/bin/bash", "/app/start.sh"]
