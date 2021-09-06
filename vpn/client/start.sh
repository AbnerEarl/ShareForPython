#!/bin/sh


enter=""

function get_token_project_container_info() {

  token_info=$(curl -i -X POST -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"'${username}'","domain":{"name":"'${domain}'"},"password":"'${password}'"}}},"scope":{"project":{"domain":{"name":"Default"},"name":"admin"}}}}' -H "Content-type:application/json" ${keystone_url}/auth/tokens | grep X-Subject-Token | awk -F : '{print $2}')
  header=$(echo \"X-Auth-Token:${token_info}\" | sed -e "s/: /:/g" | sed -e "s/${enter}//g")
  echo curl -i ${keystone_url}/projects?name=${project_name} -X GET -H "${header}" >/tmp/cmd
  project_info=$(sh /tmp/cmd)
  id_pos=$(echo $project_info | awk '{printf("%d\n",match($0, "\"id\": \""))}')
  let id_end=id_pos+40
  project_id=$(echo $project_info | cut -c ${id_pos}-${id_end} | cut -d ',' -f1 | cut -d ' ' -f2)
  echo curl -X GET -H "${header}" ${swift_uri}/AUTH_${project_id} >/tmp/cmd
  containers=$(sh /tmp/cmd)
  echo $containers
  containers=$(echo ${containers} | cut -d ' ' -f1)

}

function download_file_sync_data() {
  
  weapon_file_path="${weapon_file_path}"
  file_path="/home/auth_info.tar.gz"
#   rm -rf $file_path
  echo curl -k -X GET -H "${header}" "${swift_uri}"/AUTH_"${project_id}"/"\"${weapon_file_path}\"" \> "${file_path}" >/tmp/cmd
  download_info=$(eval "sh /tmp/cmd")
  echo "${download_info}"
  cd /home
  rm -rf auth_info
  tar -zxvf $file_path
  VPN_CLIENT_USERNAME=$(cat /home/auth_info/user.info)
  cp /home/auth_info/* /etc/openvpn/
  
}


function config_vpn_client() {

    cat > /etc/openvpn/client.ovpn <<EOF

    client
    dev tun
    proto tcp
    remote $VPN_SERVER_IP 1194
    resolv-retry infinite
    nobind
    ;user nobody
    ;group nobody
    persist-key
    persist-tun
    ca /etc/openvpn/ca.crt
    cert /etc/openvpn/${VPN_CLIENT_USERNAME}.crt
    key /etc/openvpn/${VPN_CLIENT_USERNAME}.key
    remote-cert-tls server
    tls-auth /etc/openvpn/ta.key 1
    cipher AES-256-CBC
    compress lz4-v2
    verb 3
    ;mute 20


    EOF

    chmod 600 /etc/openvpn/client.ovpn

    route del default dev tun0
    sysctl -w net.ipv4.ip_forward=1
    kill -9 $( ps -ef | grep openvpn | awk 'FNR<2 {print$2}' )
    cd /etc/openvpn/
    openvpn --daemon --cd /etc/openvpn --config client.ovpn --log-append /var/log/openvpn.log --askpass auth.info
    iptables -t filter -I FORWARD -j ACCEPT
    default_gateway=$(ip route | grep default | awk '{printf $3}')
    route add "$VPN_SERVER_IP" gw "$default_gateway"
    route add default dev tun0
    wget -qO- http://ipv4.icanhazip.com; echo


}


get_token_project_container_info
download_file_sync_data
config_vpn_client

