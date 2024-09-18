#!/bin/bash

# 自动添加定时任务的函数
setup_cron_job() {
  # 检查是否已经有相关的cron任务
  crontab -l | grep -q "/root/ddns.sh"
  if [ $? -ne 0 ]; then
    # 如果没有找到相关任务，则添加定时任务
    (crontab -l; echo "*/2 * * * * /root/ddns.sh >> /root/ddns.log 2>&1") | crontab -
    (crontab -l; echo "0 0 * * * > /root/ddns.log") | crontab -
    echo "定时任务已添加"
  else
    echo "定时任务已经存在"
  fi
}

# 调用自动添加定时任务的函数
setup_cron_job

# Cloudflare 设置
API_KEY="123"
ZONE_ID="123"
RECORD_NAME="二级域名"
RECORD_TYPE="A" # 或者 AAAA，如果你在使用IPv6

# 获取当前的公网IP
IP=$(curl -s http://ipv4.icanhazip.com)

# 打印检测到的公网IP地址
echo "Detected IP: $IP"

# 动态获取 RECORD_ID
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME&type=$RECORD_TYPE" \
     -H "X-Auth-Email: behappymy9by@gmail.com" \
     -H "X-Auth-Key: $API_KEY" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')

# 检查是否成功获取到 RECORD_ID
if [[ -z "$RECORD_ID" || "$RECORD_ID" == "null" ]]; then
  echo "获取 RECORD_ID 失败，请检查域名和类型是否正确"
  exit 1
fi

# 更新Cloudflare DNS记录
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
     -H "X-Auth-Email: behappymy9by@gmail.com" \
     -H "X-Auth-Key: $API_KEY" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"$RECORD_TYPE\",\"name\":\"$RECORD_NAME\",\"content\":\"$IP\", \"ttl\": 60, \"proxied\": false}")

# 检查是否成功
if [[ $(echo $RESPONSE | jq '.success') == "true" ]]; then
  echo "DNS 更新成功: $RECORD_NAME -> $IP"
else
  echo "DNS 更新失败"
  echo $RESPONSE | jq '.errors'
fi
