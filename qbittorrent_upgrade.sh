#!/bin/bash

echo "开始qBittorrent升级..."

# 停止qBittorrent服务
echo "正在停止qBittorrent服务..."
systemctl stop qbittorrent-nox@ahaopt.service
echo "服务已停止"

# 下载新版本并替换原文件
echo "正在下载新版本qBittorrent..."
curl -L -o /usr/bin/qbittorrent-nox https://alist.zswnet.com:8443/d/OneDrive/Per/%E9%99%84%E4%BB%B6/qbittorrent-nox_x64-504
chmod +x /usr/bin/qbittorrent-nox
echo "文件替换完成"

# 启动qBittorrent服务
echo "正在启动qBittorrent服务..."
systemctl start qbittorrent-nox@ahaopt.service
echo "服务已启动"

echo "qBittorrent升级完成！"
