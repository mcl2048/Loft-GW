FROM debian:bookworm-slim

# 明确指定使用 root 运行（虽然 Debian 镜像默认就是 root，但显式声明更严谨）
USER root

# 安装基础依赖：增加 supervisor 进程管理工具
RUN apt-get update && \
    apt-get install -y wget ca-certificates supervisor && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 下载指定的两个二进制文件
RUN wget -O cloudflared https://pub-f5b0abd28a434c48b6436e1206527fd4.r2.dev/cloudflared-linux-amd64 && \
    wget -O loftgw https://pub-f5b0abd28a434c48b6436e1206527fd4.r2.dev/loftgw

# 赋予可执行权限
RUN chmod +x cloudflared loftgw

# 复制配置文件和启动脚本
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /app/entrypoint.sh

# 赋予启动脚本执行权限
RUN chmod +x /app/entrypoint.sh

# 暴露可能需要的端口
EXPOSE 8080

ENTRYPOINT ["/app/entrypoint.sh"]
