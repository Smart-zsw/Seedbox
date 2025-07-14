#!/bin/bash

# 停止qBittorrent服务
systemctl stop qbittorrent-nox@ahaopt.service

# 下载新版本并替换原文件
curl -L -o /usr/bin/qbittorrent-nox https://alist.zswnet.com:8443/d/OneDrive/Per/%E9%99%84%E4%BB%B6/qbittorrent-nox_x64-504
chmod +x /usr/bin/qbittorrent-nox

# 启动qBittorrent服务
systemctl start qbittorrent-nox@ahaopt.service
