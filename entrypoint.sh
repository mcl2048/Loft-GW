#!/bin/bash

set -e

# 1. 检查环境变量 tunnelid 是否存在
if [ -z "$tunnelid" ]; then
  echo "[FATAL] 环境变量 'tunnelid' 未设置。容器即将退出。"
  exit 1
fi

echo "[INFO] 环境变量加载成功，准备启动 Supervisord 进行进程守护..."

# 2. 使用 exec 启动 supervisord。
# exec 的作用是让 supervisord 替代当前 shell 成为 PID 1 进程。
# 这样当 Northflank 发送停止信号时，supervisord 能直接收到并优雅关闭它底下的 2 个子进程。
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
