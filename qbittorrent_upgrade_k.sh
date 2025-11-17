#!/bin/bash

echo "开始qBittorrent升级..."

# 检测系统架构
ARCH=$(uname -m)
echo "检测到系统架构: $ARCH"

# 根据架构选择下载链接
if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
    DOWNLOAD_URL="https://alist.zswnet.com:8443/d/OneDrive/Per/%E9%99%84%E4%BB%B6/qbittorrent-nox_x64-504"
    echo "使用 x86_64 架构版本"
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    DOWNLOAD_URL="https://alist.zswnet.com:8443/d/OneDrive/Per/%E9%99%84%E4%BB%B6/qbittorrent-nox_arm64_504"
    echo "使用 ARM64 架构版本"
else
    echo "错误：不支持的架构 $ARCH"
    echo "支持的架构: x86_64, amd64, aarch64, arm64"
    exit 1
fi

# 停止qBittorrent服务
echo "正在停止qBittorrent服务..."
systemctl stop qbittorrent-nox@xiaopi.service
echo "服务已停止"

# 下载新版本并替换原文件
echo "正在从以下链接下载新版本qBittorrent..."
echo "$DOWNLOAD_URL"
curl -L -o /usr/bin/qbittorrent-nox "$DOWNLOAD_URL"

# 检查下载是否成功
if [ $? -eq 0 ]; then
    chmod +x /usr/bin/qbittorrent-nox
    echo "文件下载和替换完成"
else
    echo "错误：下载失败，正在恢复服务..."
    systemctl start qbittorrent-nox@xiaopi.service
    exit 1
fi

# 启动qBittorrent服务
echo "正在启动qBittorrent服务..."
systemctl start qbittorrent-nox@xiaopi.service
echo "服务已启动"

echo "qBittorrent升级完成！"
