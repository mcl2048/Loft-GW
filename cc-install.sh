#!/usr/bin/env bash

# ==============================================================================
# 脚本说明: 从 GitHub 克隆 Loft-Gateway 仓库并推送到 Clever Cloud
# 质量保证: 生产级别 (启用 Strict Mode, 安全的临时目录管理, 自动清理机制)
# ==============================================================================

# 启用严格模式：遇到错误、未定义变量或管道错误立即退出
set -euo pipefail

# --- 配置项 ---
SOURCE_REPO="https://github.com/mcl2048/Loft-Gateway.git"
REMOTE_PREFIX="git+ssh://"
TEMP_DIR=""

# --- 日志记录函数 ---
log_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

# --- 资源清理机制 ---
# 使用 trap 捕获退出信号 (正常退出或 Ctrl+C 中断)，确保临时目录一定会被彻底清除
cleanup() {
    local exit_code=$?
    if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
        log_info "正在清理临时文件空间: ${TEMP_DIR} ..."
        rm -rf "${TEMP_DIR}"
        log_success "清理完成，保持环境干净。"
    fi
    exit "${exit_code}"
}
trap cleanup EXIT INT TERM

# --- 主执行逻辑 ---
main() {
    # 1. 交互式获取用户输入
    echo -e "\033[1;36m===================================================\033[0m"
    echo -e "准备部署项目到 Clever Cloud"
    echo -e "\033[1;36m===================================================\033[0m"
    read -r -p "请输入 Clever Cloud 的 Git SSH 地址 (例如: git@push-n3...): " CLEVER_GIT_URL

    # 校验输入是否为空
    if [[ -z "${CLEVER_GIT_URL// /}" ]]; then
        log_error "Git 地址不能为空，脚本已终止。"
        exit 1
    fi

    # 容错处理：如果用户不小心连同 git+ssh:// 一起复制了，则将其剥离
    CLEVER_GIT_URL="${CLEVER_GIT_URL#git+ssh://}"

    # 2. 安全创建临时目录
    # mktemp 确保目录名称随机且具有唯一性，避免并发冲突
    TEMP_DIR=$(mktemp -d -t loft-gateway-deploy-XXXXXX)
    log_info "已创建安全的临时工作目录: ${TEMP_DIR}"

    # 3. 克隆仓库
    log_info "正在从 ${SOURCE_REPO} 克隆代码..."
    git clone --quiet "${SOURCE_REPO}" "${TEMP_DIR}"
    log_success "代码克隆成功。"

    # 进入克隆好的目录
    cd "${TEMP_DIR}"

    # 4. 配置 Clever Cloud 远程仓库并推送
    local full_remote_url="${REMOTE_PREFIX}${CLEVER_GIT_URL}"
    log_info "正在添加远端 clever 节点: ${full_remote_url}"
    git remote add clever "${full_remote_url}"

    # 探测当前克隆下来的主分支名称（兼容 main 或 master）
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    log_info "正在将本地的 '${current_branch}' 分支推送到 Clever Cloud 的 'master' 分支..."
    # 注意：Clever Cloud 通常需要推送到 master 分支触发部署，使用 <本地>:<远端> 语法是最稳妥的做法
    git push -u clever "${current_branch}:master"

    log_success "代码已成功推送到 Clever Cloud 平台！"
    
    # 脚本执行到这里将正常退出，并自动触发 trap 注册的 cleanup 函数清理临时文件
}

# 启动主函数
main "$@"
