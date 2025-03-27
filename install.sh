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

# Pre-set the parameters
username="ahaopt"
password='9nNG9e^rJaGinD*8'
cache="2048"
qb_cache="2048"
qb_install=1
qb_ver=("qBittorrent-5.0.3")
lib_ver=("libtorrent-v2.0.11")
autoremove_install=1
autobrr_install=1
vertex_install=1
bbrx_install=1
bbrv3_install=1
qb_port=6767
qb_incoming_port=26666
autobrr_port=26667
vertex_port=5666

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

	## qBittorrent & libtorrent compatibility check
	qb_install_check

	## qBittorrent install
	install_ "install_qBittorrent_ $username $password $qb_ver $lib_ver $qb_cache $qb_port $qb_incoming_port" "Installing qBittorrent" "/tmp/qb_error" qb_install_success
fi

# autobrr Install
if [[ ! -z "$autobrr_install" ]]; then
	install_ install_autobrr_ "Installing autobrr" "/tmp/autobrr_error" autobrr_install_success
fi

# Custom install_vertex_ function with host network mode
install_vertex_host_() {
	info "Installing vertex"
	# Install Docker if not already installed
	if ! command -v docker &> /dev/null; then
		apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
		mkdir -p /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
		apt-get update
		apt-get install -y docker-ce docker-ce-cli containerd.io
	fi

	# Create vertex directory
	mkdir -p /opt/vertex
	
	# Create vertex docker-compose.yml file with host network mode
	cat > /opt/vertex/docker-compose.yml << EOF
version: '3.7'
services:
  vertex:
    container_name: vertex
    image: ghcr.io/vertex-app/vertex:latest
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=UTC
      - BASE_URL=
      - PORT=${vertex_port}
      - PROXY_PREFIX=
    volumes:
      - /opt/vertex/config:/config
EOF

	# Pull and start vertex container
	cd /opt/vertex
	docker-compose pull
	docker-compose up -d

	# Create vertex systemd service
	cat > /etc/systemd/system/vertex.service << EOF
[Unit]
Description=vertex container
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/vertex
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down

[Install]
WantedBy=multi-user.target
EOF

	systemctl daemon-reload
	systemctl enable vertex.service
	
	# Wait for vertex to start
	sleep 10
	
	# Check if vertex is running
	if ! docker ps | grep -q vertex; then
		fail "Failed to start vertex container"
		return 1
	fi
	
	info "vertex installed successfully"
	return 0
}

# vertex Install (host mode)
if [[ ! -z "$vertex_install" ]]; then
	install_ install_vertex_host_ "Installing vertex (host mode)" "/tmp/vertex_error" vertex_install_success
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
	info "vertex installed (host mode)"
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

## 添加Vertex备份恢复功能
info "开始配置Vertex备份"
boring_text "正在下载Vertex备份文件..."
curl -o /root/Vertex-backups.tar.gz https://raw.githubusercontent.com/Smart-zsw/Seedbox/main/Vertex-backups.tar.gz

boring_text "正在解压Vertex备份文件..."
tar -xzvf /root/Vertex-backups.tar.gz -C /root/

boring_text "正在重启Vertex容器..."
docker restart vertex

info "Vertex备份配置完成"
echo -e "\n"

#!/bin/bash

# 在seedbox安装完成后，继续安装Filebrowser
info "开始安装Filebrowser文件管理器"

# 函数：获取公网IP
get_ip() {
    ip=$(curl -s ipinfo.io/ip)
}

# 颜色定义（保持一致性）
red='\e[91m'
green='\e[92m'
yellow='\e[93m'
none='\e[0m'

# 确定包管理器
cmd="apt-get"
if [[ -f /usr/bin/yum ]]; then
    cmd="yum"
fi

# 检测系统架构
sys_bit=$(uname -m)
if [[ $sys_bit == "i386" || $sys_bit == "i686" ]]; then
    filebrowser="linux-386-filebrowser.tar.gz"
elif [[ $sys_bit == "x86_64" ]]; then
    filebrowser="linux-amd64-filebrowser.tar.gz"  # 修正为amd64版本
elif [[ $sys_bit == "aarch64" ]]; then
    filebrowser="linux-arm64-filebrowser.tar.gz"
else
    fail "不支持您的系统架构：$sys_bit"
    exit 1
fi

boring_text "下载Filebrowser组件..."
$cmd install wget -y

# 获取最新版本并下载
ver=$(curl -s https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep 'tag_name' | cut -d\" -f4)
Filebrowser_download_link="https://github.com/filebrowser/filebrowser/releases/download/$ver/$filebrowser"

# 创建临时目录并下载
mkdir -p /tmp/Filebrowser
if ! wget --no-check-certificate --no-cache -O "/tmp/Filebrowser.tar.gz" $Filebrowser_download_link; then
    fail "下载Filebrowser失败！"
    exit 1
fi

boring_text "安装Filebrowser..."
# 解压和安装
tar zxf /tmp/Filebrowser.tar.gz -C /tmp/Filebrowser
cp -f /tmp/Filebrowser/filebrowser /usr/bin/filebrowser
chmod +x /usr/bin/filebrowser

if [[ -f /usr/bin/filebrowser ]]; then
    # 创建systemd服务
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

    # 创建配置目录和初始配置
    mkdir -p /etc/filebrowser
    cat >/etc/filebrowser/filebrowser.json <<-EOF
{
    "port": 9184,
    "baseURL": "",
    "address": "",
    "log": "stdout",
    "database": "/etc/filebrowser/database.db",
    "root": "/etc/filebrowser/"
}
EOF

    # 初始化配置并设置用户
    boring_text "配置Filebrowser..."
    filebrowser -d /etc/filebrowser/database.db config init
    # 使用与seedbox相同的用户名和密码
    filebrowser -d /etc/filebrowser/database.db users add $username "$password" --perm.admin
    
    # 启用并启动服务
    systemctl enable filebrowser
    systemctl start filebrowser
    
    # 下载自定义配置文件
    boring_text "下载自定义配置文件..."
    curl -s -o /etc/filebrowser/filebrowser.json https://raw.githubusercontent.com/Smart-zsw/Seedbox/main/filebrowser.json
    
    # 重启服务
    boring_text "重启Filebrowser服务..."
    systemctl restart filebrowser
    
    # 显示完成信息
    info "Filebrowser安装完成"
    boring_text "Filebrowser地址: http://$publicip:9184/"
    boring_text "Filebrowser用户名: $username"
    boring_text "Filebrowser密码: $password"
    echo -e "\n"
else
    fail "Filebrowser安装失败"
fi

# 清理
rm -rf /tmp/Filebrowser
rm -rf /tmp/Filebrowser.tar.gz

info "安装Nezha监控代理..."
curl -L https://raw.githubusercontent.com/nezhahq/scripts/main/agent/install.sh -o agent.sh && chmod +x agent.sh && env NZ_SERVER=152.53.239.138:8008 NZ_TLS=false NZ_CLIENT_SECRET=Duk8nx7BE43prM20FygwkUL6fU0g1kky ./agent.sh

info "所有组件安装完成，请重启系统以应用所有更改"

exit 0