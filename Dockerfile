# 使用 Debian 作为基础镜像，兼容性比 Alpine 更好（避免 glibc 缺失问题）
FROM debian:bookworm-slim

# 安装基础依赖：wget 用于下载，ca-certificates 用于 HTTPS 请求
RUN apt-get update && \
    apt-get install -y wget ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 下载指定的两个二进制文件（已更新 cloudflared 的正确链接）
RUN wget -O cloudflared https://pub-f5b0abd28a434c48b6436e1206527fd4.r2.dev/cloudflared-linux-amd64 && \
    wget -O loftgw https://pub-f5b0abd28a434c48b6436e1206527fd4.r2.dev/loftgw

# 赋予可执行权限
RUN chmod +x cloudflared loftgw

# 复制启动脚本并赋予执行权限
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# 暴露可能需要的端口（Northflank 通常需要容器至少监听一个端口以通过健康检查）
# 假设你的 loftgw 监听了某个端口（如 8080），请根据实际情况修改；若纯出站请在后台关闭健康检查
EXPOSE 8080

# 运行启动脚本
ENTRYPOINT ["/app/entrypoint.sh"]
