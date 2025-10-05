# 基于官方 LangBot 镜像
FROM rockchin/langbot:latest

# 设置时区
ENV TZ=Asia/Shanghai

# 创建数据目录（Render 可挂载）
RUN mkdir -p /app/data /app/plugins

# 拷贝启动脚本
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# 默认端口
ENV PORT=5300
ENV PLUGIN_RUNTIME_URL=ws://127.0.0.1:5401/control/ws
ENV LANGBOT_DB_TYPE=sqlite
ENV LANGBOT_DB_PATH=/app/data/langbot.db
ENV LANGBOT_DEBUG=true

EXPOSE 5300
EXPOSE 5401

# 启动 LangBot 主程序和插件运行时
CMD ["/bin/bash", "/app/start.sh"]
