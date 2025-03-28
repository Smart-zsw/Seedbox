#!/bin/sh
tput sgr0; clear

## Load Seedbox Components
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/seedbox_installation.sh)
# Check if Seedbox Components is successfully loaded
if [ $? -ne 0 ]; then
	echo "Component ~Seedbox Components~ failed to load"
	echo "Check connection with GitHub"
	exit 1
fi

## Load loading animation
source <(wget -qO- https://raw.githubusercontent.com/Silejonu/bash_loading_animations/main/bash_loading_animations.sh)
# Check if bash loading animation is successfully loaded
if [ $? -ne 0 ]; then
	fail "Component ~Bash loading animation~ failed to load"
	fail_exit "Check connection with GitHub"
fi
# Run BLA::stop_loading_animation if the script is interrupted
trap BLA::stop_loading_animation SIGINT

## Install function
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

## Installation environment Check
info "Checking Installation Environment"
# Check Root Privilege
if [ $(id -u) -ne 0 ]; then
    fail_exit "This script needs root permission to run"
fi

# Linux Distro Version check
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

if [[ ! "$OS" =~ "Debian" ]] && [[ ! "$OS" =~ "Ubuntu" ]]; then	#Only Debian and Ubuntu are supported
	fail "$OS $VER is not supported"
	info "Only Debian 10+ and Ubuntu 20.04+ are supported"
	exit 1
fi

if [[ "$OS" =~ "Debian" ]]; then	#Debian 10+ are supported
	if [[ ! "$VER" =~ "10" ]] && [[ ! "$VER" =~ "11" ]] && [[ ! "$VER" =~ "12" ]]; then
		fail "$OS $VER is not supported"
		info "Only Debian 10+ are supported"
		exit 1
	fi
fi

if [[ "$OS" =~ "Ubuntu" ]]; then #Ubuntu 20.04+ are supported
	if [[ ! "$VER" =~ "20" ]] && [[ ! "$VER" =~ "22" ]] && [[ ! "$VER" =~ "23" ]]; then
		fail "$OS $VER is not supported"
		info "Only Ubuntu 20.04+ is supported"
		exit 1
	fi
fi

## Read input arguments
while getopts "u:p:c:q:l:rbvx3oh" opt; do
  case ${opt} in
	u ) # process option username
		username=${OPTARG}
		;;
	p ) # process option password
		password=${OPTARG}
		;;
	c ) # process option cache
		cache=${OPTARG}
		#Check if cache is a number
		while true
		do
			if ! [[ "$cache" =~ ^[0-9]+$ ]]; then
				warn "Cache must be a number"
				need_input "Please enter a cache size (in MB):"
				read cache
			else
				break
			fi
		done
		#Converting the cache to qBittorrent's unit (MiB)
		qb_cache=$cache
		;;
	q ) # process option cache
		qb_install=1
		qb_ver=("qBittorrent-${OPTARG}")
		;;
	l ) # process option libtorrent
		lib_ver=("libtorrent-${OPTARG}")
		#Check if qBittorrent version is specified
		if [ -z "$qb_ver" ]; then
			warn "You must choose a qBittorrent version for your libtorrent install"
			qb_ver_choose
		fi
		;;
	r ) # process option autoremove
		autoremove_install=1
		;;
	b ) # process option autobrr
		autobrr_install=1
		;;
	v ) # process option vertex
		vertex_install=1
		;;
	x ) # process option bbr
		unset bbrv3_install
		bbrx_install=1
		;;
	3 ) # process option bbr
		unset bbrx_install
		bbrv3_install=1
		;;
	o ) # process option port
		if [[ -n "$qb_install" ]]; then
			need_input "Please enter qBittorrent port:"
			read qb_port
			while true
			do
				if ! [[ "$qb_port" =~ ^[0-9]+$ ]]; then
					warn "Port must be a number"
					need_input "Please enter qBittorrent port:"
					read qb_port
				else
					break
				fi
			done
			need_input "Please enter qBittorrent incoming port:"
			read qb_incoming_port
			while true
			do
				if ! [[ "$qb_incoming_port" =~ ^[0-9]+$ ]]; then
						warn "Port must be a number"
						need_input "Please enter qBittorrent incoming port:"
						read qb_incoming_port
				else
					break
				fi
			done
		fi
		if [[ -n "$autobrr_install" ]]; then
			need_input "Please enter autobrr port:"
			read autobrr_port
			while true
			do
				if ! [[ "$autobrr_port" =~ ^[0-9]+$ ]]; then
					warn "Port must be a number"
					need_input "Please enter autobrr port:"
					read autobrr_port
				else
					break
				fi
			done
		fi
		if [[ -n "$vertex_install" ]]; then
			need_input "Please enter vertex port:"
			read vertex_port
			while true
			do
				if ! [[ "$vertex_port" =~ ^[0-9]+$ ]]; then
					warn "Port must be a number"
					need_input "Please enter vertex port:"
					read vertex_port
				else
					break
				fi
			done
		fi
		;;
	h ) # process option help
		info "Help:"
		info "Usage: ./Install.sh -u <username> -p <password> -c <Cache Size(unit:MiB)> -q <qBittorrent version> -l <libtorrent version> -b -v -r -3 -x -p"
		info "Example: ./Install.sh -u jerry048 -p 1LDw39VOgors -c 3072 -q 4.3.9 -l v1.2.19 -b -v -r -3"
		source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent_install.sh)
		seperator
		info "Options:"
		need_input "1. -u : Username"
		need_input "2. -p : Password"
		need_input "3. -c : Cache Size for qBittorrent (unit:MiB)"
		echo -e "\n"
		need_input "4. -q : qBittorrent version"
		need_input "Available qBittorrent versions:"
		tput sgr0; tput setaf 7; tput dim; history -p "${qb_ver_list[@]}"; tput sgr0
		echo -e "\n"
		need_input "5. -l : libtorrent version"
		need_input "Available qBittorrent versions:"
		tput sgr0; tput setaf 7; tput dim; history -p "${lib_ver_list[@]}"; tput sgr0
		echo -e "\n"
		need_input "6. -r : Install autoremove-torrents"
		need_input "7. -b : Install autobrr"
		need_input "8. -v : Install vertex"
		need_input "9. -x : Install BBRx"
		need_input "10. -3 : Install BBRv3"
		need_input "11. -p : Specify ports for qBittorrent, autobrr and vertex"
		need_input "12. -h : Display help message"
		exit 0
		;;
	\? )
		info "Help:"
		info_2 "Usage: ./Install.sh -u <username> -p <password> -c <Cache Size(unit:MiB)> -q <qBittorrent version> -l <libtorrent version> -b -v -r -3 -x -p"
		info_2 "Example ./Install.sh -u jerry048 -p 1LDw39VOgors -c 3072 -q 4.3.9 -l v1.2.19 -b -v -r -3"
		exit 1
		;;
	esac
done

# System Update & Dependencies Install
info "Start System Update & Dependencies Install"
update

## Install Seedbox Environment
tput sgr0; clear
info "Start Installing Seedbox Environment"
echo -e "\n"


# qBittorrent
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent_install.sh)
# Check if qBittorrent install is successfully loaded
if [ $? -ne 0 ]; then
	fail_exit "Component ~qBittorrent install~ failed to load"
fi

if [[ ! -z "$qb_install" ]]; then
	## Check if all the required arguments are specified
	#Check if username is specified
	if [ -z "$username" ]; then
		warn "Username is not specified"
		need_input "Please enter a username:"
		read username
	fi
	#Check if password is specified
	if [ -z "$password" ]; then
		warn "Password is not specified"
		need_input "Please enter a password:"
		read password
	fi
	## Create user if it does not exist
	if ! id -u $username > /dev/null 2>&1; then
		useradd -m -s /bin/bash $username
		# Check if the user is created successfully
		if [ $? -ne 0 ]; then
			warn "Failed to create user $username"
			return 1
		fi
	fi
	chown -R $username:$username /home/$username
	#Check if cache is specified
	if [ -z "$cache" ]; then
		warn "Cache is not specified"
		need_input "Please enter a cache size (in MB):"
		read cache
		#Check if cache is a number
		while true
		do
			if ! [[ "$cache" =~ ^[0-9]+$ ]]; then
				warn "Cache must be a number"
				need_input "Please enter a cache size (in MB):"
				read cache
			else
				break
			fi
		done
		qb_cache=$cache
	fi
	#Check if qBittorrent version is specified
	if [ -z "$qb_ver" ]; then
		warn "qBittorrent version is not specified"
		qb_ver_check
	fi
	#Check if libtorrent version is specified
	if [ -z "$lib_ver" ]; then
		warn "libtorrent version is not specified"
		lib_ver_check
	fi
	#Check if qBittorrent port is specified
	if [ -z "$qb_port" ]; then
		qb_port=8080
	fi
	#Check if qBittorrent incoming port is specified
	if [ -z "$qb_incoming_port" ]; then
		qb_incoming_port=45000
	fi

	## qBittorrent & libtorrent compatibility check
	qb_install_check

	## qBittorrent install
	install_ "install_qBittorrent_ $username $password $qb_ver $lib_ver $qb_cache $qb_port $qb_incoming_port" "Installing qBittorrent" "/tmp/qb_error" qb_install_success
fi

# autobrr Install
if [[ ! -z "$autobrr_install" ]]; then
	install_ install_autobrr_ "Installing autobrr" "/tmp/autobrr_error" autobrr_install_success
fi

# vertex Install
if [[ ! -z "$vertex_install" ]]; then
	install_ install_vertex_ "Installing vertex" "/tmp/vertex_error" vertex_install_success
fi

# autoremove-torrents Install
if [[ ! -z "$autoremove_install" ]]; then
	install_ install_autoremove-torrents_ "Installing autoremove-torrents" "/tmp/autoremove_error" autoremove_install_success
fi

seperator

## Tunning
info "Start Doing System Tunning"
install_ tuned_ "Installing tuned" "/tmp/tuned_error" tuned_success
install_ set_txqueuelen_ "Setting txqueuelen" "/tmp/txqueuelen_error" txqueuelen_success
install_ set_file_open_limit_ "Setting File Open Limit" "/tmp/file_open_limit_error" file_open_limit_success

# Check for Virtual Environment since some of the tunning might not work on virtual machine
systemd-detect-virt > /dev/null
if [ $? -eq 0 ]; then
	warn "Virtualization is detected, skipping some of the tunning"
	install_ disable_tso_ "Disabling TSO" "/tmp/tso_error" tso_success
else
	install_ set_disk_scheduler_ "Setting Disk Scheduler" "/tmp/disk_scheduler_error" disk_scheduler_success
	install_ set_ring_buffer_ "Setting Ring Buffer" "/tmp/ring_buffer_error" ring_buffer_success
fi
install_ set_initial_congestion_window_ "Setting Initial Congestion Window" "/tmp/initial_congestion_window_error" initial_congestion_window_success
install_ kernel_settings_ "Setting Kernel Settings" "/tmp/kernel_settings_error" kernel_settings_success



# BBRx
if [[ ! -z "$bbrx_install" ]]; then
	# Check if Tweaked BBR is already installed
	if [[ ! -z "$(lsmod | grep bbrx)" ]]; then
		warn echo "Tweaked BBR is already installed"
	else
		install_ install_bbrx_ "Installing BBRx" "/tmp/bbrx_error" bbrx_install_success
	fi
fi

# BBRv3
if [[ ! -z "$bbrv3_install" ]]; then
	install_ install_bbrv3_ "Installing BBRv3" "/tmp/bbrv3_error" bbrv3_install_success
fi

## Configue Boot Script
info "Start Configuing Boot Script"
touch /root/.boot-script.sh && chmod +x /root/.boot-script.sh
cat << EOF > /root/.boot-script.sh
#!/bin/bash
sleep 120s
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/seedbox_installation.sh)
# Check if Seedbox Components is successfully loaded
if [ \$? -ne 0 ]; then
	exit 1
fi
set_txqueuelen_
# Check for Virtual Environment since some of the tunning might not work on virtual machine
systemd-detect-virt > /dev/null
if [ \$? -eq 0 ]; then
	disable_tso_
else
	set_disk_scheduler_
	set_ring_buffer_
fi
set_initial_congestion_window_
EOF
# Configure the script to run during system startup
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

## Finalizing the install
info "Seedbox Installation Complete"
publicip=$(curl -s https://ipinfo.io/ip)

# Display Username and Password
# qBittorrent
if [[ ! -z "$qb_install_success" ]]; then
	info "qBittorrent installed"
	boring_text "qBittorrent WebUI: http://$publicip:$qb_port"
	boring_text "qBittorrent Username: $username"
	boring_text "qBittorrent Password: $password"
	echo -e "\n"
fi
# autoremove-torrents
if [[ ! -z "$autoremove_install_success" ]]; then
	info "autoremove-torrents installed"
	boring_text "Config at /home/$username/.config.yml"
	boring_text "Please read https://autoremove-torrents.readthedocs.io/en/latest/config.html for configuration"
	echo -e "\n"
fi
# autobrr
if [[ ! -z "$autobrr_install_success" ]]; then
	info "autobrr installed"
	boring_text "autobrr WebUI: http://$publicip:$autobrr_port"
	echo -e "\n"
fi
# vertex
if [[ ! -z "$vertex_install_success" ]]; then
	info "vertex installed"
	boring_text "vertex WebUI: http://$publicip:$vertex_port"
	boring_text "vertex Username: $username"
	boring_text "vertex Password: $password"
	echo -e "\n"
fi
# BBR
if [[ ! -z "$bbrx_install_success" ]]; then
	info "BBRx successfully installed, please reboot for it to take effect"
fi

if [[ ! -z "$bbrv3_install_success" ]]; then
	info "BBRv3 successfully installed, please reboot for it to take effect"
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