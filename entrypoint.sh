#!/bin/bash

# 开启 strict 模式，遇到错误立刻停止脚本
set -e

# 1. 检查环境变量 tunnelid 是否存在
if [ -z "$tunnelid" ]; then
  echo "[FATAL] 环境变量 'tunnelid' 未设置。容器即将退出。"
  exit 1
fi

echo "[INFO] 环境变量加载成功，准备启动服务..."

# 2. 启动 loftgw (放在后台)
echo "[INFO] 启动 loftgw..."
./loftgw &
LOFTGW_PID=$!

# 3. 启动 cloudflared (放在后台，使用正确的前台运行参数)
echo "[INFO] 启动 cloudflared tunnel..."
./cloudflared tunnel --no-autoupdate run --token "$tunnelid" &
CLOUDFLARED_PID=$!

# 4. 捕获容器的关闭信号 (SIGTERM/SIGINT)，优雅地关闭子进程
trap "echo '[INFO] 收到停止信号，正在关闭服务...'; kill -TERM $LOFTGW_PID $CLOUDFLARED_PID; wait $LOFTGW_PID $CLOUDFLARED_PID" SIGTERM SIGINT

# 5. 关键点：等待任意一个后台进程退出
# 如果 loftgw 或 cloudflared 意外崩溃，wait -n 会立刻解除阻塞
wait -n

# 6. 一旦解除阻塞，说明有服务挂了，退出脚本，让 Northflank 重启容器
echo "[ERROR] 其中一个服务已经意外退出，正在结束容器以触发重启机制。"
exit 1
