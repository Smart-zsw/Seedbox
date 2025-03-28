#!/bin/sh
tput sgr0; clear

## 私有化配置 - 自定义参数设置
# 用户设置
USERNAME="ahaopt"                    # 用户名
PASSWORD="PV6pA8FWHdlcziPi"              # 密码

# qBittorrent 设置
INSTALL_QBITTORRENT=true            # 是否安装 qBittorrent
QB_VERSION="5.0.3"                  # qBittorrent 版本
LIB_VERSION="v2.0.11"               # libtorrent 版本
CACHE_SIZE="2048"                   # 缓存大小(MiB)
QB_PORT="6767"                      # qBittorrent WebUI 端口
QB_INCOMING_PORT="26666"            # qBittorrent 连入端口

# 附加组件设置
INSTALL_AUTOBRR=true                # 是否安装 autobrr
AUTOBRR_PORT="26667"                 # autobrr 端口

INSTALL_VERTEX=false                 # 是否安装 vertex
VERTEX_PORT="5666"                  # vertex 端口

INSTALL_AUTOREMOVE=true             # 是否安装 autoremove-torrents

# 网络优化设置
INSTALL_BBRX=true                  # 是否安装 BBRx
INSTALL_BBRV3=false                  # 是否安装 BBRv3

## 加载Seedbox组件
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/seedbox_installation.sh)
# 检查Seedbox组件是否成功加载
if [ $? -ne 0 ]; then
	echo "Component ~Seedbox Components~ failed to load"
	echo "Check connection with GitHub"
	exit 1
fi

## 加载动画
source <(wget -qO- https://raw.githubusercontent.com/Silejonu/bash_loading_animations/main/bash_loading_animations.sh)
# 检查bash加载动画是否成功加载
if [ $? -ne 0 ]; then
	fail "Component ~Bash loading animation~ failed to load"
	fail_exit "Check connection with GitHub"
fi
# 如果脚本中断，运行BLA::stop_loading_animation
trap BLA::stop_loading_animation SIGINT

## 安装函数
install_() {
info_2 "$2"
BLA::start_loading_animation "${BLA_classic[@]}"
$1 1> /dev/null 2> $3
if [ $? -ne 0 ]; then
	fail_3 "FAIL"
else
	info_3 "Successful"
	export $4=1
fi
BLA::stop_loading_animation
}

## 检查安装环境
info "检查安装环境"
# 检查Root权限
if [ $(id -u) -ne 0 ]; then
    fail_exit "此脚本需要root权限运行"
fi

# Linux发行版本检查
if [ -f /etc/os-release ]; then
	. /etc/os-release
	OS=$NAME
	VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
	OS=$(lsb_release -si)
	VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
	. /etc/lsb-release
	OS=$DISTRIB_ID
	VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
	OS=Debian
	VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
	OS=SuSe
elif [ -f /etc/redhat-release ]; then
	OS=Redhat
else
	OS=$(uname -s)
	VER=$(uname -r)
fi

if [[ ! "$OS" =~ "Debian" ]] && [[ ! "$OS" =~ "Ubuntu" ]]; then	#仅支持Debian和Ubuntu
	fail "$OS $VER 不支持"
	info "仅支持Debian 10+和Ubuntu 20.04+"
	exit 1
fi

if [[ "$OS" =~ "Debian" ]]; then	#支持Debian 10+
	if [[ ! "$VER" =~ "10" ]] && [[ ! "$VER" =~ "11" ]] && [[ ! "$VER" =~ "12" ]]; then
		fail "$OS $VER 不支持"
		info "仅支持Debian 10+"
		exit 1
	fi
fi

if [[ "$OS" =~ "Ubuntu" ]]; then #支持Ubuntu 20.04+
	if [[ ! "$VER" =~ "20" ]] && [[ ! "$VER" =~ "22" ]] && [[ ! "$VER" =~ "23" ]]; then
		fail "$OS $VER 不支持"
		info "仅支持Ubuntu 20.04+"
		exit 1
	fi
fi

# 系统更新和依赖安装
info "开始系统更新和依赖安装"
update

## 安装Seedbox环境
tput sgr0; clear
info "开始安装Seedbox环境"
echo -e "\n"

# 加载qBittorrent安装脚本
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent_install.sh)
# 检查qBittorrent安装脚本是否成功加载
if [ $? -ne 0 ]; then
	fail_exit "Component ~qBittorrent install~ failed to load"
fi

# 设置变量
username=$USERNAME
password=$PASSWORD
cache=$CACHE_SIZE
qb_cache=$CACHE_SIZE

# 根据配置设置安装选项
if [ "$INSTALL_QBITTORRENT" = true ]; then
	qb_install=1
	qb_ver=("qBittorrent-${QB_VERSION}")
	lib_ver=("libtorrent-${LIB_VERSION}")
	qb_port=$QB_PORT
	qb_incoming_port=$QB_INCOMING_PORT
fi

if [ "$INSTALL_AUTOREMOVE" = true ]; then
	autoremove_install=1
fi

if [ "$INSTALL_AUTOBRR" = true ]; then
	autobrr_install=1
	autobrr_port=$AUTOBRR_PORT
fi

if [ "$INSTALL_VERTEX" = true ]; then
	vertex_install=1
	vertex_port=$VERTEX_PORT
fi

if [ "$INSTALL_BBRX" = true ]; then
	unset bbrv3_install
	bbrx_install=1
fi

if [ "$INSTALL_BBRV3" = true ]; then
	unset bbrx_install
	bbrv3_install=1
fi

if [[ ! -z "$qb_install" ]]; then
	## 检查是否指定了所有必需的参数
	# 创建用户（如果不存在）
	if ! id -u $username > /dev/null 2>&1; then
		useradd -m -s /bin/bash $username
		# 检查用户是否成功创建
		if [ $? -ne 0 ]; then
			warn "创建用户 $username 失败"
			return 1
		fi
	fi
	chown -R $username:$username /home/$username

	## qBittorrent和libtorrent兼容性检查
	qb_install_check

	## 安装qBittorrent
	install_ "install_qBittorrent_ $username $password $qb_ver $lib_ver $qb_cache $qb_port $qb_incoming_port" "正在安装qBittorrent" "/tmp/qb_error" qb_install_success
fi

# 安装autobrr
if [[ ! -z "$autobrr_install" ]]; then
	install_ install_autobrr_ "正在安装autobrr" "/tmp/autobrr_error" autobrr_install_success
fi

# 安装vertex
if [[ ! -z "$vertex_install" ]]; then
	install_ install_vertex_ "正在安装vertex" "/tmp/vertex_error" vertex_install_success
fi

# 安装autoremove-torrents
if [[ ! -z "$autoremove_install" ]]; then
	install_ install_autoremove-torrents_ "正在安装autoremove-torrents" "/tmp/autoremove_error" autoremove_install_success
fi

seperator

## 系统优化
info "开始进行系统优化"
install_ tuned_ "安装tuned" "/tmp/tuned_error" tuned_success
install_ set_txqueuelen_ "设置txqueuelen" "/tmp/txqueuelen_error" txqueuelen_success
install_ set_file_open_limit_ "设置文件打开限制" "/tmp/file_open_limit_error" file_open_limit_success

# 检查虚拟环境，因为某些优化在虚拟机中可能不起作用
systemd-detect-virt > /dev/null
if [ $? -eq 0 ]; then
	warn "检测到虚拟化环境，跳过部分优化"
	install_ disable_tso_ "禁用TSO" "/tmp/tso_error" tso_success
else
	install_ set_disk_scheduler_ "设置磁盘调度器" "/tmp/disk_scheduler_error" disk_scheduler_success
	install_ set_ring_buffer_ "设置环形缓冲区" "/tmp/ring_buffer_error" ring_buffer_success
fi
install_ set_initial_congestion_window_ "设置初始拥塞窗口" "/tmp/initial_congestion_window_error" initial_congestion_window_success
install_ kernel_settings_ "设置内核参数" "/tmp/kernel_settings_error" kernel_settings_success

# 安装BBRx
if [[ ! -z "$bbrx_install" ]]; then
	# 检查是否已安装Tweaked BBR
	if [[ ! -z "$(lsmod | grep bbrx)" ]]; then
		warn "Tweaked BBR已安装"
	else
		install_ install_bbrx_ "安装BBRx" "/tmp/bbrx_error" bbrx_install_success
	fi
fi

# 安装BBRv3
if [[ ! -z "$bbrv3_install" ]]; then
	install_ install_bbrv3_ "安装BBRv3" "/tmp/bbrv3_error" bbrv3_install_success
fi

## 配置启动脚本
info "开始配置启动脚本"
touch /root/.boot-script.sh && chmod +x /root/.boot-script.sh
cat << EOF > /root/.boot-script.sh
#!/bin/bash
sleep 120s
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/seedbox_installation.sh)
# 检查Seedbox组件是否成功加载
if [ \$? -ne 0 ]; then
	exit 1
fi
set_txqueuelen_
# 检查虚拟环境，因为某些优化在虚拟机中可能不起作用
systemd-detect-virt > /dev/null
if [ \$? -eq 0 ]; then
	disable_tso_
else
	set_disk_scheduler_
	set_ring_buffer_
fi
set_initial_congestion_window_
EOF
# 配置脚本在系统启动时运行
cat << EOF > /etc/systemd/system/boot-script.service
[Unit]
Description=boot-script
After=network.target

[Service]
Type=simple
ExecStart=/root/.boot-script.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
systemctl enable boot-script.service

seperator

## 完成安装
info "Seedbox安装完成"
publicip=$(curl -s https://ipinfo.io/ip)

# 显示用户名和密码
# qBittorrent
if [[ ! -z "$qb_install_success" ]]; then
	info "qBittorrent已安装"
	boring_text "qBittorrent WebUI: http://$publicip:$qb_port"
	boring_text "qBittorrent用户名: $username"
	boring_text "qBittorrent密码: $password"
	echo -e "\n"
fi
# autoremove-torrents
if [[ ! -z "$autoremove_install_success" ]]; then
	info "autoremove-torrents已安装"
	boring_text "配置文件位于 /home/$username/.config.yml"
	boring_text "请阅读 https://autoremove-torrents.readthedocs.io/en/latest/config.html 了解如何配置"
	echo -e "\n"
fi
# autobrr
if [[ ! -z "$autobrr_install_success" ]]; then
	info "autobrr已安装"
	boring_text "autobrr WebUI: http://$publicip:$autobrr_port"
	echo -e "\n"
fi
# vertex
if [[ ! -z "$vertex_install_success" ]]; then
	info "vertex已安装"
	boring_text "vertex WebUI: http://$publicip:$vertex_port"
	boring_text "vertex用户名: $username"
	boring_text "vertex密码: $password"
	echo -e "\n"
fi
# BBR
if [[ ! -z "$bbrx_install_success" ]]; then
	info "BBRx安装成功，请重启系统使其生效"
fi

if [[ ! -z "$bbrv3_install_success" ]]; then
	info "BBRv3安装成功，请重启系统使其生效"
fi

# ==================== 附加功能 1：安装基本工具包 ====================
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

# ==================== 附加功能 2：安装Docker ====================
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

# ==================== 附加功能 3：安装Vertex Docker容器 ====================
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

# ==================== 附加功能 4：下载Vertex备份文件 ====================
info "开始下载Vertex备份文件"
echo -e "正在下载备份文件..."
curl -o /root/Vertex-backups.tar.gz https://raw.githubusercontent.com/Smart-zsw/Seedbox/main/Vertex-backups.tar.gz

if [ $? -eq 0 ]; then
    info_3 "Vertex备份文件下载成功"
else
    fail_3 "Vertex备份文件下载失败"
fi
seperator

# ==================== 附加功能 5：解压Vertex备份文件 ====================
info "开始解压Vertex备份文件"
echo -e "正在解压备份文件到/root/目录..."
tar -xzvf /root/Vertex-backups.tar.gz -C /root/

if [ $? -eq 0 ]; then
    info_3 "Vertex备份文件解压成功"
else
    fail_3 "Vertex备份文件解压失败"
fi
seperator

# ==================== 附加功能 6：安装Filebrowser ====================
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

# ==================== 附加功能 7：系统重启 ====================
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