#!/bin/sh


username=$(date +%s%N | md5sum | head -c 10)
password=$(uuidgen |sed 's/-//g')
export vpn_client_password=$password
export vpn_client_username=$username
current_path=$(pwd)
cd /etc/openvpn/server/easy-rsa/
expect x_autho.exp ${username} ${password}
echo ${password} > auth.info
echo ${username} > user.info
cd $current_path
mkdir /tmp/$username/
cp /etc/openvpn/server/easy-rsa/ta.key /tmp/$username/
cp /etc/openvpn/server/easy-rsa/pki/private/$username.key /tmp/$username/
cp /etc/openvpn/server/easy-rsa/pki/issued/$username.crt /tmp/$username/
cp /etc/openvpn/server/easy-rsa/pki/ca.crt /tmp/$username/
cp /etc/openvpn/server/easy-rsa/auth.info /tmp/$username/
cp /etc/openvpn/server/easy-rsa/user.info /tmp/$username/
tar -zcvf $current_path/$username.tar.gz -C /tmp $username/