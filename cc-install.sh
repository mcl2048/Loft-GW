#!/usr/bin/env bash

# ==============================================================================
# 脚本说明: 从 GitHub 克隆 Loft-Gateway 仓库并推送到 Clever Cloud
# 质量保证: 生产级别 (启用 Strict Mode, 阅后即焚 SSH 密钥, 强制安全权限, 自动清理机制)
# ==============================================================================

set -euo pipefail

# --- 配置项 ---
REPO_OWNER="mcl2048"
REPO_NAME="Loft-Gateway"
REMOTE_PREFIX="git+ssh://"
TEMP_DIR=""

# --- 日志记录函数 ---
log_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

# --- 资源清理机制 ---
cleanup() {
    local exit_code=$?
    if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
        log_info "正在清理临时工作区 (包含代码及临时 SSH 密钥) : ${TEMP_DIR} ..."
        rm -rf "${TEMP_DIR}"
        log_success "清理完成，环境已恢复纯净。"
    fi
    exit "${exit_code}"
}
trap cleanup EXIT INT TERM

# --- 主执行逻辑 ---
main() {
    echo -e "\033[1;36m===================================================\033[0m"
    echo -e "准备部署项目到 Clever Cloud"
    echo -e "\033[1;36m===================================================\033[0m"
    
    # 1. 收集 Clever Cloud Git 地址
    read -r -p "请输入 Clever Cloud 的 Git SSH 地址 (例如: git@push-n3...): " CLEVER_GIT_URL
    if [[ -z "${CLEVER_GIT_URL// /}" ]]; then
        log_error "Git 地址不能为空，脚本已终止。"
        exit 1
    fi
    CLEVER_GIT_URL="${CLEVER_GIT_URL#git+ssh://}"

    # 2. 收集 GitHub 鉴权信息
    echo -e "\n\033[1;33m[关于 GitHub 仓库的读取权限]\033[0m"
    echo "如果你在 Codespaces 中运行，且目标仓库是公开的，请直接按回车；"
    echo "如果目标仓库是私有的，请输入你的 GitHub PAT (Personal Access Token)。"
    read -r -s -p "GitHub PAT (选填): " GITHUB_PAT
    echo -e "\n"

    # 3. 安全创建临时目录
    TEMP_DIR=$(mktemp -d -t loft-gateway-deploy-XXXXXX)
    log_info "已创建安全的临时工作目录: ${TEMP_DIR}"

    # 4. 生成阅后即焚的临时 SSH 密钥
    local ssh_key_path="${TEMP_DIR}/cc_temp_ed25519"
    log_info "正在生成临时的部署 SSH 密钥..."
    ssh-keygen -t ed25519 -C "clever-deploy-temp" -f "${ssh_key_path}" -q -N ""

    # 【核心修复点】：强制收缩私钥权限，满足 SSH 客户端的安全要求 (仅属主可读写)
    chmod 600 "${ssh_key_path}"

    echo -e "\n\033[1;35m>>>>>>>>>> [ 等待操作: 绑定 SSH Key ] >>>>>>>>>>\033[0m"
    echo "请将以下公钥内容完整复制，并添加到 Clever Cloud 的 SSH Keys 设置中："
    echo "------------------------------------------------------------------"
    echo -e "\033[1;32m$(cat "${ssh_key_path}.pub")\033[0m"
    echo "------------------------------------------------------------------"
    echo -e "\033[1;35m<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\033[0m\n"
    
    read -r -p "确认已在 Clever Cloud 绑定好公钥后，请按回车键 (Enter) 继续..."

    # 5. 根据输入构造克隆命令
    log_info "正在从 GitHub 克隆代码..."
    if [[ -n "${GITHUB_PAT}" ]]; then
        git clone --quiet "https://${GITHUB_PAT}@github.com/${REPO_OWNER}/${REPO_NAME}.git" "${TEMP_DIR}/repo"
    else
        git -c credential.helper= clone --quiet "https://github.com/${REPO_OWNER}/${REPO_NAME}.git" "${TEMP_DIR}/repo"
    fi
    log_success "代码克隆成功。"

    # 6. 进入代码目录并配置远端
    cd "${TEMP_DIR}/repo"
    local full_remote_url="${REMOTE_PREFIX}${CLEVER_GIT_URL}"
    log_info "正在添加远端 clever 节点: ${full_remote_url}"
    git remote add clever "${full_remote_url}"

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # 7. 携带临时密钥推送到 Clever Cloud
    log_info "正在将本地的 '${current_branch}' 分支推送到 Clever Cloud 的 'master' 分支..."
    
    # 注入临时 SSH 密钥，并自动接受新的 host key
    export GIT_SSH_COMMAND="ssh -i ${ssh_key_path} -o StrictHostKeyChecking=accept-new"
    
    git push -u clever "${current_branch}:master"

    log_success "代码已成功推送到 Clever Cloud 平台！"
}

main "$@"
