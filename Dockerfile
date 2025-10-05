FROM rockchin/langbot:latest

ENV TZ=Asia/Shanghai
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && \
    apt-get install -y procps && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /app/data /app/plugins

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 5300
EXPOSE 5400

CMD ["/bin/bash", "/app/start.sh"]
