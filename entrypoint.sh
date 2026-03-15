#!/bin/bash

set -e

# 检查环境变量 tunnelid 是否存在
if [ -z "$tunnelid" ]; then
  echo "[FATAL] 环境变量 'tunnelid' 未设置。容器即将退出。"
  exit 1
fi

echo "[INFO] 环境变量加载成功。"
echo "[INFO] 数据持久化卷已挂载至 /root 目录。"
echo "[INFO] 准备启动 Supervisord 进行进程守护..."

# 将控制权交给 supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
