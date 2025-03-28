#!/bin/sh

# ==================== 功能 1：安装基本工具包 ====================
info "开始安装基本工具包"
echo -e "正在安装 curl, screen, vim, unzip..."
apt update -y &&
apt upgrade -y &&
apt install curl -y &&
apt install screen -y &&
apt install vim -y &&
apt install unzip -y

if [ $? -eq 0 ]; then
    info_3 "基本工具包安装成功"
else
    fail_3 "基本工具包安装失败"
fi
seperator

# ==================== 功能 2：安装Docker ====================
info "开始安装Docker"
echo -e "正在下载并安装Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh &&
sh get-docker.sh

if [ $? -eq 0 ]; then
    info_3 "Docker安装成功"
else
    fail_3 "Docker安装失败"
fi
seperator

# ==================== 功能 3：安装qBittorrent ====================
info "开始安装qBittorrent"
echo -e "正在创建目录并安装qBittorrent Docker容器..."
mkdir -p /root/qbittorrent/config
mkdir -p /home/ahaopt/qbittorrent/Downloads
chmod 777 /home/ahaopt/qbittorrent/Downloads

docker run -d \
  --name=qbittorrent \
  --network host \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Shanghai \
  -e WEBUI_PORT=6767 \
  -e TORRENTING_PORT=26666 \
  -v /root/qbittorrent/config:/config \
  -v /home/ahaopt/qbittorrent/Downloads:/home/ahaopt/qbittorrent/Downloads \
  --restart unless-stopped \
  lscr.io/linuxserver/qbittorrent:5.0.4

if [ $? -eq 0 ]; then
    info_3 "qBittorrent Docker容器安装成功"
    boring_text "qBittorrent WebUI: http://$publicip:6767"
else
    fail_3 "qBittorrent Docker容器安装失败"
fi
seperator

# ==================== 功能 4：下载并解压qBittorrent配置文件包 ====================
info "开始下载qBittorrent配置文件包"
echo -e "正在下载并解压qBittorrent配置文件包到/root路径..."
curl -o /root/qbittorrent.tar.gz https://raw.githubusercontent.com/Smart-zsw/Seedbox/main/qbittorrent.tar.gz &&
tar -xzvf /root/qbittorrent.tar.gz -C /root/

if [ $? -eq 0 ]; then
    info_3 "qBittorrent配置文件包下载并解压成功"
else
    fail_3 "qBittorrent配置文件包下载并解压失败"
fi
seperator

# ==================== 功能 5：运行Dedicated-Seedbox安装脚本 ====================
info "开始运行Dedicated-Seedbox安装脚本"
echo -e "正在下载并运行Dedicated-Seedbox安装脚本..."
bash <(wget -qO- https://raw.githubusercontent.com/jerry048/Dedicated-Seedbox/main/Install.sh) -x

if [ $? -eq 0 ]; then
    info_3 "Dedicated-Seedbox安装脚本运行成功"
else
    fail_3 "Dedicated-Seedbox安装脚本运行失败"
fi
seperator

# ==================== 功能 6：安装Vertex Docker容器 ====================
info "开始安装Docker版Vertex"
echo -e "正在安装apparmor，设置时区，并启动Vertex容器..."
apt install apparmor apparmor-utils -y &&
timedatectl set-timezone Asia/Shanghai &&
mkdir -p /root/vertex &&
chmod 777 /root/vertex &&
docker run -d --name vertex --restart unless-stopped --network host -v /root/vertex:/vertex -e TZ=Asia/Shanghai -e PORT=5666 lswl/vertex:stable

if [ $? -eq 0 ]; then
    info_3 "Docker版Vertex安装成功"
    boring_text "Vertex WebUI: http://$publicip:5666"
else
    fail_3 "Docker版Vertex安装失败"
fi
seperator

# ==================== 功能 7：下载Vertex备份文件 ====================
info "开始下载Vertex备份文件"
echo -e "正在下载备份文件..."
curl -o /root/Vertex-backups.tar.gz https://raw.githubusercontent.com/Smart-zsw/Seedbox/main/Vertex-backups.tar.gz

if [ $? -eq 0 ]; then
    info_3 "Vertex备份文件下载成功"
else
    fail_3 "Vertex备份文件下载失败"
fi
seperator

# ==================== 功能 8：解压Vertex备份文件 ====================
info "开始解压Vertex备份文件"
echo -e "正在解压备份文件到/root/目录..."
tar -xzvf /root/Vertex-backups.tar.gz -C /root/

if [ $? -eq 0 ]; then
    info_3 "Vertex备份文件解压成功"
else
    fail_3 "Vertex备份文件解压失败"
fi
seperator

# ==================== 功能 9：安装Filebrowser ====================
info "开始安装Filebrowser"
echo -e "正在执行Filebrowser安装脚本..."

# 颜色定义
red='\e[91m'
green='\e[92m'
yellow='\e[93m'
none='\e[0m'
# 用户名和密码变量定义
FB_USERNAME="ahaopt"
FB_PASSWORD="PV6pA8FWHdlcziPi"
# 检查是否为 root 用户
[[ $(id -u) != 0 ]] && echo -e "\n${red}错误：${none}请使用 root 用户运行此脚本\n" && exit 1
echo -e "${yellow}开始安装 Filebrowser...${none}"
cmd="apt-get"
sys_bit=$(uname -m)
# 检测系统类型
if [[ -f /usr/bin/apt-get || -f /usr/bin/yum ]] && [[ -f /bin/systemctl ]]; then
    if [[ -f /usr/bin/yum ]]; then
        cmd="yum"
    fi
else
    echo -e "\n${red}错误：${none}不支持的系统类型\n" && exit 1
fi
# 检测系统架构
if [[ $sys_bit == "i386" || $sys_bit == "i686" ]]; then
    filebrowser="linux-386-filebrowser.tar.gz"
elif [[ $sys_bit == "x86_64" ]]; then
    filebrowser="linux-386-filebrowser.tar.gz"
elif [[ $sys_bit == "aarch64" ]]; then
    filebrowser="linux-arm64-filebrowser.tar.gz"
else
    echo -e "\n${red}错误：${none}不支持的系统架构\n" && exit 1
fi
# 获取 IP 地址
get_ip() {
    ip=$(curl -s ipinfo.io/ip)
}
# 安装过程
echo -e "正在安装依赖..."
$cmd install wget -y > /dev/null 2>&1
echo -e "获取 Filebrowser 最新版本..."
ver=$(curl -s https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep 'tag_name' | cut -d\" -f4)
Filebrowser_download_link="https://github.com/filebrowser/filebrowser/releases/download/$ver/$filebrowser"
echo -e "下载 Filebrowser ${ver}..."
mkdir -p /tmp/Filebrowser
if ! wget --no-check-certificate --no-cache -O "/tmp/Filebrowser.tar.gz" $Filebrowser_download_link > /dev/null 2>&1; then
    echo -e "${red}下载 Filebrowser 失败！${none}" && exit 1
fi
echo -e "解压安装文件..."
tar zxf /tmp/Filebrowser.tar.gz -C /tmp/Filebrowser > /dev/null 2>&1
cp -f /tmp/Filebrowser/filebrowser /usr/bin/filebrowser
chmod +x /usr/bin/filebrowser
if [[ -f /usr/bin/filebrowser ]]; then
    echo -e "配置服务..."
    cat >/lib/systemd/system/filebrowser.service <<-EOF
[Unit]
Description=Filebrowser Service
After=network.target
Wants=network.target
[Service]
Type=simple
PIDFile=/var/run/filebrowser.pid
ExecStart=/usr/bin/filebrowser -c /etc/filebrowser/filebrowser.json
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
    mkdir -p /etc/filebrowser
    cat >/etc/filebrowser/filebrowser.json <<-EOF
{
    "port": 9184,
    "baseURL": "",
    "address": "0.0.0.0",
    "log": "stdout",
    "database": "/etc/filebrowser/database.db",
    "root": "/home/ahaopt/qbittorrent/Downloads",
    "scope": "/",
    "allowCommands": true,
    "allowEdit": true,
    "allowNew": true
}
EOF
    get_ip
    echo -e "启动服务..."
    systemctl enable filebrowser > /dev/null 2>&1
    systemctl start filebrowser
    echo -e "\n${green}✓ Filebrowser 安装成功！${none}\n"
    echo -e "访问地址：${yellow}http://${ip}:9184/${none}"
    echo -e "用户名：${green}${FB_USERNAME}${none}"
    echo -e "密码：${green}${FB_PASSWORD}${none}"
    echo -e "\n${yellow}重要提示：${none}请立即登录并修改默认密码\n"
else
    echo -e "\n${red}安装失败，请检查系统环境后重试${none}\n"
fi
# 清理临时文件
rm -rf /tmp/Filebrowser
rm -rf /tmp/Filebrowser.tar.gz
seperator

# ==================== 功能 10：系统重启 ====================
info "所有安装和配置已完成，系统将在5秒后重启"
echo -e "5秒后系统将自动重启以应用所有设置..."
sleep 1
echo -e "4..."
sleep 1
echo -e "3..."
sleep 1
echo -e "2..."
sleep 1
echo -e "1..."
sleep 1
reboot
exit 0