#!/bin/bash

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
        exit 1
    fi
}

# 安装 Snell
install_snell() {
    echo -e "${CYAN}正在安装 Snell${RESET}"

    # 检查是否已安装
    if [ -f "${INSTALL_DIR}/snell-server" ]; then
        echo -e "${YELLOW}Snell 已经安装。如需重新安装，请先卸载。${RESET}"
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
        return 1
    fi

    wget -O snell-server.zip $DOWNLOAD_URL
    if [ $? -ne 0 ]; then
        echo -e "${RED}下载 Snell 失败${RESET}"
        return 1
    fi

    # 解压并安装
    unzip -o snell-server.zip -d ${INSTALL_DIR}
    chmod +x ${INSTALL_DIR}/snell-server
    rm snell-server.zip

    # 生成配置文件
    mkdir -p ${CONF_DIR}
    if [ ! -f "${CONF_FILE}" ]; then
        RANDOM_PORT=$(shuf -i 10000-65000 -n 1)
        RANDOM_PSK=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 31)
        cat > ${CONF_FILE} << EOF
[snell-server]
listen = ::0:${RANDOM_PORT}
psk = ${RANDOM_PSK}
ipv6 = true
EOF
    fi

    # 创建 systemd 服务文件
    cat > ${SYSTEMD_SERVICE_FILE} << EOF
[Unit]
Description=Snell Proxy Service
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
LimitNOFILE=32768
ExecStart=${INSTALL_DIR}/snell-server -c ${CONF_FILE}
AmbientCapabilities=CAP_NET_BIND_SERVICE
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=snell-server

[Install]
WantedBy=multi-user.target
EOF

    # 启动服务
    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME}
    systemctl start ${SERVICE_NAME}

    echo -e "${GREEN}Snell 安装完成${RESET}"
    echo "配置文件位置: ${CONF_FILE}"
    echo "请查看配置文件以获取端口和 PSK 信息"
}

# 卸载 Snell
uninstall_snell() {
    echo -e "${CYAN}正在卸载 Snell${RESET}"

    # 停止并禁用服务
    systemctl stop ${SERVICE_NAME}
    systemctl disable ${SERVICE_NAME}

    # 删除文件
    rm -f ${INSTALL_DIR}/snell-server
    rm -f /etc/systemd/system/${SERVICE_NAME}
    
    # 可选：删除配置文件
    read -p "是否删除配置文件? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ${CONF_DIR}
    fi

    systemctl daemon-reload

    echo -e "${GREEN}Snell 卸载完成${RESET}"
}

# 启动 Snell
start_snell() {
    echo -e "${CYAN}正在启动 Snell${RESET}"
    systemctl start ${SERVICE_NAME}
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Snell 启动成功${RESET}"
    else
        echo -e "${RED}Snell 启动失败${RESET}"
    fi
}

# 停止 Snell
stop_snell() {
    echo -e "${CYAN}正在停止 Snell${RESET}"
    systemctl stop ${SERVICE_NAME}
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Snell 停止成功${RESET}"
    else
        echo -e "${RED}Snell 停止失败${RESET}"
    fi
}

# 更新 Snell
update_snell() {
    echo -e "${CYAN}正在更新 Snell${RESET}"
    
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        DOWNLOAD_URL="https://dl.nssurge.com/snell/snell-server-v${SNELL_VERSION}-linux-amd64.zip"
    elif [[ "$ARCH" == "aarch64" ]]; then
        DOWNLOAD_URL="https://dl.nssurge.com/snell/snell-server-v${SNELL_VERSION}-linux-aarch64.zip"
    else
        echo -e "${RED}不支持的架构: $ARCH${RESET}"
        return 1
    fi
    
    if wget -O snell-server.zip $DOWNLOAD_URL; then
        systemctl stop ${SERVICE_NAME}
        mv ${INSTALL_DIR}/snell-server ${INSTALL_DIR}/snell-server.old
        unzip -o snell-server.zip -d ${INSTALL_DIR}
        chmod +x ${INSTALL_DIR}/snell-server
        rm snell-server.zip
        systemctl start ${SERVICE_NAME}
        echo -e "${GREEN}Snell 已更新完成${RESET}"
    else
        echo -e "${RED}下载失败，请检查网络连接${RESET}"
        return 1
    fi
}

# 显示菜单
show_menu() {
    echo -e "${GREEN}=== Snell 管理工具 ===${RESET}"
    echo "1. 安装 Snell"
    echo "2. 卸载 Snell"
    echo "3. 启动 Snell"
    echo "4. 停止 Snell"
    echo "5. 更新 Snell"
    echo "6. 查看 Snell 状态"
    echo "0. 退出"
    echo -e "${GREEN}======================${RESET}"
}

# 主函数
main() {
    check_root

    while true; do
        show_menu
        read -p "请输入选项: " choice
        case $choice in
            1) install_snell ;;
            2) uninstall_snell ;;
            3) start_snell ;;
            4) stop_snell ;;
            5) update_snell ;;
            6) systemctl status ${SERVICE_NAME} ;;
            0) echo "退出"; exit 0 ;;
            *) echo -e "${RED}无效的选项${RESET}" ;;
        esac
        echo
        read -p "按 Enter 键继续..."
    done
}

# 运行主函数
main
