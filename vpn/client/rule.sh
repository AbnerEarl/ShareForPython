#!/bin/sh

proxy_ip=$(ifconfig | grep -E '10.8.0.[0-9]' | awk '{print$2}')
proxy_port=$1
source_ip=$2
source_port=$3
iptables -t nat -A PREROUTING -p tcp -d "$proxy_ip" --dport "$proxy_port" -j DNAT --to "$source_ip":"$source_port"
iptables -t nat -A POSTROUTING -p tcp -d "$source_ip" --dport "$source_port" -j SNAT --to "$proxy_ip":"$proxy_port"

echo iptables -t nat -A PREROUTING -p tcp -d "$proxy_ip" --dport "$proxy_port" -j DNAT --to "$source_ip":"$source_port" >> /etc/rc.local
echo iptables -t nat -A POSTROUTING -p tcp -d "$source_ip" --dport "$source_port" -j SNAT --to "$proxy_ip":"$proxy_port" >> /etc/rc.local




