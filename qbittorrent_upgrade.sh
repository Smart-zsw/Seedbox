#!/bin/bash

echo "开始qBittorrent升级..."

# 检测系统架构
ARCH=$(uname -m)
echo "检测到系统架构: $ARCH"

# 根据架构选择下载链接
if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
    DOWNLOAD_URL="https://alist.zswclub.com/d/qb_upgrade/qbittorrent-nox_x64-504"
    echo "使用 x86_64 架构版本"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    DOWNLOAD_URL="https://alist.zswclub.com/d/qb_upgrade/qbittorrent-nox_arm64_504"
    echo "使用 ARM64 架构版本"
else
    echo "错误:不支持的架构 $ARCH"
    echo "支持的架构: x86_64, amd64, aarch64, arm64"
    exit 1
fi

# 自动检测qBittorrent服务名称
echo "正在检测qBittorrent服务..."
QB_SERVICE=$(systemctl list-units --type=service --all | grep -o 'qbittorrent-nox@[^[:space:]]*\.service' | head -n 1)

if [ -z "$QB_SERVICE" ]; then
    echo "警告:未找到运行中的qBittorrent服务,尝试查找所有已安装的服务..."
    QB_SERVICE=$(systemctl list-unit-files | grep -o 'qbittorrent-nox@[^[:space:]]*\.service' | head -n 1)
fi

if [ -z "$QB_SERVICE" ]; then
    echo "错误:未找到qBittorrent服务"
    echo "请手动指定服务名称,或确认qBittorrent已正确安装"
    exit 1
fi

echo "检测到qBittorrent服务: $QB_SERVICE"

# 检查服务状态
SERVICE_STATUS=$(systemctl is-active "$QB_SERVICE" 2>/dev/null)
echo "当前服务状态: $SERVICE_STATUS"

# 停止qBittorrent服务
echo "正在停止qBittorrent服务..."
systemctl stop "$QB_SERVICE"
sleep 2

# 确认服务已停止
if systemctl is-active --quiet "$QB_SERVICE"; then
    echo "警告:服务未能完全停止,强制停止..."
    systemctl kill "$QB_SERVICE"
    sleep 2
fi
echo "服务已停止"

# 备份原文件(可选)
if [ -f /usr/bin/qbittorrent-nox ]; then
    echo "正在备份原文件..."
    cp /usr/bin/qbittorrent-nox /usr/bin/qbittorrent-nox.backup.$(date +%Y%m%d_%H%M%S)
    echo "备份完成"
fi

# 下载新版本并替换原文件
echo "正在从以下链接下载新版本qBittorrent..."
echo "$DOWNLOAD_URL"
curl -L -o /usr/bin/qbittorrent-nox "$DOWNLOAD_URL"

# 检查下载是否成功
if [ $? -eq 0 ]; then
    chmod +x /usr/bin/qbittorrent-nox
    echo "文件下载和替换完成"
else
    echo "错误:下载失败,正在恢复服务..."
    systemctl start "$QB_SERVICE"
    exit 1
fi

# 启动qBittorrent服务
echo "正在启动qBittorrent服务..."
systemctl start "$QB_SERVICE"
sleep 2

# 检查服务是否成功启动
if systemctl is-active --quiet "$QB_SERVICE"; then
    echo "服务已成功启动"
    systemctl status "$QB_SERVICE" --no-pager -l
else
    echo "错误:服务启动失败,请检查日志"
    echo "查看日志命令: journalctl -u $QB_SERVICE -n 50"
    exit 1
fi

echo "qBittorrent升级完成!"
