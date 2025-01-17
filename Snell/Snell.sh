#!/bin/bash
# 创建小写软链接
if [ ! -L "/usr/local/bin/snell.sh" ]; then
    ln -s "$(realpath "$0")" /usr/local/bin/snell.sh
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 创建了软链接 /usr/local/bin/snell.sh" >> "$LOG_FILE"
fi
# 安装unzip
apt install unzip 
# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# 日志文件路径
LOG_FILE="/var/log/snell_manager.log"

# 服务名称
SERVICE_NAME="snell.service"

# Snell 配置
SNELL_VERSION="4.1.1"
INSTALL_DIR="/usr/local/bin"
CONF_DIR="/etc/snell"
CONF_FILE="${CONF_DIR}/snell-server.conf"

# 检查是否以 root 权限运行
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}请以 root 权限运行此脚本.${RESET}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 尝试以非 root 权限运行脚本" >> "$LOG_FILE"
        exit 1
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 以 root 权限运行脚本" >> "$LOG_FILE"
}

# 安装 Snell
install_snell() {
    echo -e "${CYAN}正在安装 Snell${RESET}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始安装 Snell" >> "$LOG_FILE"

    # 检查是否已安装
    if [ -f "${INSTALL_DIR}/snell-server" ]; then
        echo -e "${YELLOW}Snell 已经安装。如需重新安装，请先卸载。${RESET}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Snell 已安装，安装过程终止" >> "$LOG_FILE"
        return
    fi

    # 下载 Snell
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        DOWNLOAD_URL="https://dl.nssurge.com/snell/snell-server-v${SNELL_VERSION}-linux-amd64.zip"
    elif [[ "$ARCH" == "aarch64" ]]; then
        DOWNLOAD_URL="https://dl.nssurge.com/snell/snell-server-v${SNELL_VERSION}-linux-aarch64.zip"
    else
        echo -e "${RED}不支持的架构: $ARCH${RESET}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 不支持的架构: $ARCH" >> "$LOG_FILE"
        return 1
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始下载 Snell: $DOWNLOAD_URL" >> "$LOG_FILE"
    wget -O snell-server.zip $DOWNLOAD_URL
    if [ $? -ne 0 ]; then
        echo -e "${RED}下载 Snell 失败${RESET}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 下载 Snell 失败" >> "$LOG_FILE"
        return 1
    fi

    # 解压并安装
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 解压并安装 Snell" >> "$LOG_FILE"
    unzip -o snell-server.zip -d ${INSTALL_DIR}
    chmod +x ${INSTALL_DIR}/snell-server
    rm snell-server.zip

    # 生成配置文件
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 生成 Snell 配置文件" >> "$LOG_FILE"
    mkdir -p ${CONF_DIR}
    if [ ! -f "${CONF_FILE}" ]; then
        RANDOM_PORT=$(shuf -i 10000-65000 -n 1)
        RANDOM_PSK=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 31)
        cat > ${CONF_FILE} << EOF
[snell-server]
dns = 1.1.1.1 8.8.8.8
listen = ::0:${RANDOM_PORT}
psk = ${RANDOM_PSK}
ipv6 = true
EOF
    fi

    # 创建 systemd 服务文件
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 创建 Snell systemd 服务文件" >> "$LOG_FILE"
    cat > /etc/systemd/system/${SERVICE_NAME} << EOF
[Unit]
Description=Snell Proxy Service
After=network.target

[Service]
Type=simple
User=root
Group=root
LimitNOFILE=32768
ExecStart=${INSTALL_DIR}/snell-server -c ${CONF_FILE}
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=snell-server

[Install]
WantedBy=multi-user.target
EOF

    # 启动服务
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 启动 Snell 服务" >> "$LOG_FILE"
    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME}
    systemctl start ${SERVICE_NAME}

    # 获取本机IP地址
    HOST_IP=$(curl -s http://checkip.amazonaws.com)

    # 获取IP所在国家
    IP_COUNTRY=$(curl -s http://ipinfo.io/${HOST_IP}/country)

    echo -e "${GREEN}Snell 安装成功${RESET}"
    echo "${IP_COUNTRY} = snell, ${HOST_IP}, ${RANDOM_PORT}, psk = ${RANDOM_PSK}, version = 4, reuse = true, tfo = true"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Snell 安装成功: ${IP_COUNTRY}, ${HOST_IP}, ${RANDOM_PORT}, psk=${RANDOM_PSK}" >> "$LOG_FILE"
}

# 卸载 Snell
uninstall_snell() {
    echo -e "${CYAN}正在卸载 Snell${RESET}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始卸载 Snell" >> "$LOG_FILE"

    # 停止并禁用服务
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 停止并禁用 Snell 服务" >> "$LOG_FILE"
    systemctl stop ${SERVICE_NAME}
    systemctl disable ${SERVICE_NAME}

    # 删除文件
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 删除 Snell 相关文件" >> "$LOG_FILE"
    rm -f ${INSTALL_DIR}/snell-server
    rm -f /etc/systemd/system/${SERVICE_NAME}

    # 删除配置文件
    rm -rf ${CONF_DIR}

    systemctl daemon-reload

    echo -e "${GREEN}Snell 卸载完成${RESET}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Snell 卸载完成" >> "$LOG_FILE"
}

# 重启 Snell
restart_snell() {
    echo -e "${CYAN}正在重启 Snell${RESET}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始重启 Snell" >> "$LOG_FILE"
    systemctl restart ${SERVICE_NAME}
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Snell 重启成功${RESET}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Snell 重启成功" >> "$LOG_FILE"
    else
        echo -e "${RED}Snell 重启失败${RESET}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Snell 重启失败" >> "$LOG_FILE"
    fi
}

# 更新 Snell
update_snell() {
    echo -e "${CYAN}正在更新 Snell${RESET}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始更新 Snell" >> "$LOG_FILE"
    
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        DOWNLOAD_URL="https://dl.nssurge.com/snell/snell-server-v${SNELL_VERSION}-linux-amd64.zip"
    elif [[ "$ARCH" == "aarch64" ]]; then
        DOWNLOAD_URL="https://dl.nssurge.com/snell/snell-server-v${SNELL_VERSION}-linux-aarch64.zip"
    else
        echo -e "${RED}不支持的架构: $ARCH${RESET}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 更新失败：不支持的架构 $ARCH" >> "$LOG_FILE"
        return 1
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 下载新版本 Snell" >> "$LOG_FILE"
    if wget -O snell-server.zip $DOWNLOAD_URL; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 停止 Snell 服务" >> "$LOG_FILE"
        systemctl stop ${SERVICE_NAME}
        mv ${INSTALL_DIR}/snell-server ${INSTALL_DIR}/snell-server.old
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 解压并安装新版本" >> "$LOG_FILE"
        unzip -o snell-server.zip -d ${INSTALL_DIR}
        chmod +x ${INSTALL_DIR}/snell-server
        rm snell-server.zip
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 启动更新后的 Snell 服务" >> "$LOG_FILE"
        systemctl start ${SERVICE_NAME}
        echo -e "${GREEN}Snell 已更新完成${RESET}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Snell 更新成功" >> "$LOG_FILE"
    else
        echo -e "${RED}下载失败，请检查网络连接${RESET}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Snell 更新失败：下载失败" >> "$LOG_FILE"
        return 1
    fi
}

# 显示菜单
show_menu() {
    echo -e "${GREEN}=== Snell 管理工具 ===${RESET}"
    echo "1. 安装 Snell"
    echo "2. 重启 Snell"
    echo "3. 更新 Snell"
    echo "4. 查看 Snell 状态"
    echo "5. 卸载 Snell"
    echo "0. 退出"
    echo -e "${GREEN}======================${RESET}"
}

# 主函数
main() {
    check_root

    while true; do
        show_menu
        read -p "请输入选项: " choice
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 用户选择了选项: $choice" >> "$LOG_FILE"
        case $choice in
            1) install_snell ;;
            2) restart_snell ;;
            3) update_snell ;;
            4) 
               echo "$(date '+%Y-%m-%d %H:%M:%S') - 查看 Snell 状态" >> "$LOG_FILE"
               systemctl status ${SERVICE_NAME} 
               ;;
            5) uninstall_snell ;;
            0) 
               echo "退出"
               echo "$(date '+%Y-%m-%d %H:%M:%S') - 用户退出脚本" >> "$LOG_FILE"
               exit 0 
               ;;
            *) 
               echo -e "${RED}无效的选项${RESET}"
               echo "$(date '+%Y-%m-%d %H:%M:%S') - 用户输入了无效选项: $choice" >> "$LOG_FILE"
               ;;
        esac
        echo
        read -p "按 Enter 键继续..."
    done
}

# 运行主函数
main
