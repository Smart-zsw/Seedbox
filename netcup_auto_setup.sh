#!/bin/bash

# ========================================
# NetCup 服务器自动配置脚本
# 托管在 GitHub，由 NetCup 重装接口调用
# ========================================

set -e  # 遇到错误立即退出（除非特别处理）

# 日志文件
LOG_FILE="/var/log/netcup_auto_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=========================================="
log "开始执行 NetCup 自动配置脚本"
log "=========================================="

# 从环境变量读取配置（由启动脚本传入）
SEEDBOX_USER="${SEEDBOX_USER:-ahaopt}"
SEEDBOX_PASSWORD="${SEEDBOX_PASSWORD:-}"
SEEDBOX_CACHE="${SEEDBOX_CACHE:-4096}"
SEEDBOX_QB_VERSION="${SEEDBOX_QB_VERSION:-4.6.7}"
SEEDBOX_LIBTORRENT_VERSION="${SEEDBOX_LIBTORRENT_VERSION:-v2.0.11}"

# 探针配置
NZ_SERVER="${NZ_SERVER:-}"
NZ_TLS="${NZ_TLS:-true}"
NZ_CLIENT_SECRET="${NZ_CLIENT_SECRET:-}"
NZ_UUID="${NZ_UUID:-}"

# SSH 端口配置
SSH_PORT="${SSH_PORT:-1001}"

log "配置参数："
log "  Seedbox 用户: $SEEDBOX_USER"
log "  探针 UUID: ${NZ_UUID:0:8}***"
log "  目标 SSH 端口: $SSH_PORT"

# ========================================
# 步骤 1: 安装 Seedbox
# ========================================
install_seedbox() {
    log "步骤 1/4: 安装 Seedbox..."

    if [ -z "$SEEDBOX_PASSWORD" ]; then
        log "警告: 未提供 Seedbox 密码，跳过安装"
        return 0
    fi

    local install_cmd="bash <(wget -qO- https://raw.githubusercontent.com/jerry048/Dedicated-Seedbox/main/Install.sh)"
    install_cmd="$install_cmd -u $SEEDBOX_USER"
    install_cmd="$install_cmd -p $SEEDBOX_PASSWORD"
    install_cmd="$install_cmd -c $SEEDBOX_CACHE"
    install_cmd="$install_cmd -q $SEEDBOX_QB_VERSION"
    install_cmd="$install_cmd -l $SEEDBOX_LIBTORRENT_VERSION"
    install_cmd="$install_cmd -o"

    if eval "$install_cmd"; then
        log "✓ Seedbox 安装成功"
        return 0
    else
        log "✗ Seedbox 安装失败，错误码: $?"
        return 1
    fi
}

# ========================================
# 步骤 2: 升级 qBittorrent
# ========================================
upgrade_qbittorrent() {
    log "步骤 2/4: 升级 qBittorrent..."

    if curl -sSL https://raw.githubusercontent.com/Smart-zsw/Seedbox/main/qbittorrent_upgrade.sh | sudo bash; then
        log "✓ qBittorrent 升级成功"
        return 0
    else
        log "✗ qBittorrent 升级失败，错误码: $?"
        return 1
    fi
}

# ========================================
# 步骤 3: 安装哪吒监控探针
# ========================================
install_probe() {
    log "步骤 3/4: 安装哪吒监控探针..."

    if [ -z "$NZ_UUID" ] || [ -z "$NZ_CLIENT_SECRET" ]; then
        log "警告: 未提供探针配置，跳过安装"
        return 0
    fi

    local agent_script="/tmp/nezha_agent_install.sh"

    if curl -L https://raw.githubusercontent.com/nezhahq/scripts/main/agent/install.sh -o "$agent_script" && \
       chmod +x "$agent_script" && \
       env NZ_SERVER="$NZ_SERVER" \
           NZ_TLS="$NZ_TLS" \
           NZ_CLIENT_SECRET="$NZ_CLIENT_SECRET" \
           NZ_UUID="$NZ_UUID" \
           "$agent_script"; then
        log "✓ 探针安装成功"
        rm -f "$agent_script"
        return 0
    else
        log "✗ 探针安装失败，错误码: $?"
        rm -f "$agent_script"
        return 1
    fi
}

# ========================================
# 步骤 4: 修改 SSH 端口
# ========================================
change_ssh_port() {
    log "步骤 4/4: 修改 SSH 端口到 $SSH_PORT..."

    local sshd_config="/etc/ssh/sshd_config"
    local backup_config="${sshd_config}.backup.$(date +%s)"

    # 备份原始配置
    if ! cp "$sshd_config" "$backup_config"; then
        log "✗ 备份配置文件失败"
        return 1
    fi
    log "已备份配置文件: $backup_config"

    # 修改端口配置
    if grep -q "^Port " "$sshd_config"; then
        # 已有未注释的 Port 配置
        sed -i "s/^Port .*/Port $SSH_PORT/" "$sshd_config"
        log "已更新现有 Port 配置"
    elif grep -q "^#Port " "$sshd_config"; then
        # 有注释的 Port 配置
        sed -i "s/^#Port .*/Port $SSH_PORT/" "$sshd_config"
        log "已取消注释并设置 Port $SSH_PORT"
    else
        # 没有 Port 配置，添加到文件开头
        sed -i "1i Port $SSH_PORT" "$sshd_config"
        log "已添加 Port $SSH_PORT 配置"
    fi

    # 验证配置文件语法
    if ! sshd -t 2>&1; then
        log "✗ SSH 配置文件语法检查失败，恢复备份"
        mv "$backup_config" "$sshd_config"
        return 1
    fi
    log "SSH 配置文件语法检查通过"

    # 重启 SSH 服务
    if systemctl restart sshd; then
        log "✓ SSH 服务重启成功，端口已改为 $SSH_PORT"
        return 0
    else
        log "✗ SSH 服务重启失败，恢复备份配置"
        mv "$backup_config" "$sshd_config"
        systemctl restart sshd
        return 1
    fi
}

# ========================================
# 主流程
# ========================================
main() {
    local exit_code=0

    # 执行所有步骤，记录失败但不中断
    install_seedbox || exit_code=$((exit_code + 1))
    upgrade_qbittorrent || exit_code=$((exit_code + 2))
    install_probe || exit_code=$((exit_code + 4))
    change_ssh_port || exit_code=$((exit_code + 8))

    log "=========================================="
    if [ $exit_code -eq 0 ]; then
        log "✓ 所有步骤执行成功"
    else
        log "⚠ 部分步骤执行失败，退出码: $exit_code"
        log "  1: Seedbox 安装失败"
        log "  2: qBittorrent 升级失败"
        log "  4: 探针安装失败"
        log "  8: SSH 端口修改失败"
    fi
    log "详细日志: $LOG_FILE"
    log "=========================================="

    return 0  # 即使部分失败也返回 0，避免影响系统安装
}

main
