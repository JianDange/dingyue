#!/bin/bash

# 下载 ddns.sh 并设置权限
wget -N https://raw.githubusercontent.com/JianDange/dingyue/main/ddns.sh && chmod +x ddns.sh

# 提示用户输入 API_KEY、ZONE_ID 和 RECORD_NAME
read -p "请输入API_KEY: " api_key
read -p "请输入ZONE_ID: " zone_id
read -p "请输入RECORD_NAME: " record_name

# 替换 ddns.sh 中的默认值为用户输入的值
sed -i "s/API_KEY=\"123\"/API_KEY=\"$api_key\"/; s/ZONE_ID=\"123\"/ZONE_ID=\"$zone_id\"/; s/RECORD_NAME=\"二级域名\"/RECORD_NAME=\"$record_name\"/" ddns.sh

# 安装 jq 工具
apt-get install -y jq

# 添加定时任务
(crontab -l 2>/dev/null; echo "*/2 * * * * /root/ddns.sh >> /root/ddns.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "0 0 * * * > /root/ddns.log") | crontab -

echo "定时任务已添加并启动。"
