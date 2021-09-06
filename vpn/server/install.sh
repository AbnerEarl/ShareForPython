#!/bin/sh



check_os() {
  os_type=centos
  rh_file="/etc/redhat-release"
  if grep -qs "Red Hat" "$rh_file"; then
    os_type=rhel
  fi
  if grep -qs "release 7" "$rh_file"; then
    os_ver=7
  elif grep -qs "release 8" "$rh_file"; then
    os_ver=8
    grep -qi stream "$rh_file" && os_ver=8s
    grep -qi rocky "$rh_file" && os_type=rocky
    grep -qi alma "$rh_file" && os_type=alma
  elif grep -qs "Amazon Linux release 2" /etc/system-release; then
    os_type=amzn
    os_ver=2
  else
    os_type=$(lsb_release -si 2>/dev/null)
    [ -z "$os_type" ] && [ -f /etc/os-release ] && os_type=$(. /etc/os-release && printf '%s' "$ID")
    case $os_type in
      [Uu]buntu)
        os_type=ubuntu
        ;;
      [Dd]ebian)
        os_type=debian
        ;;
      [Rr]aspbian)
        os_type=raspbian
        ;;
      *)
        exiterr "This script only supports Ubuntu, Debian, CentOS/RHEL 7/8 and Amazon Linux 2."
        ;;
    esac
    os_ver=$(sed 's/\..*//' /etc/debian_version | tr -dc 'A-Za-z0-9')
    if [ "$os_ver" = "8" ] || [ "$os_ver" = "jessiesid" ]; then
      exiterr "Debian 8 or Ubuntu < 16.04 is not supported."
    fi
    if { [ "$os_ver" = "10" ] || [ "$os_ver" = "11" ]; } && [ ! -e /dev/ppp ]; then
      exiterr "/dev/ppp is missing. Debian 11 or 10 users, see: https://git.io/vpndebian10"
    fi
  fi
}



install_vpn() {
    if [ "$os_type" = "ubuntu" ] || [ "$os_type" = "debian" ] || [ "$os_type" = "raspbian" ]; then
        apt-get install -y epel-release
        apt-get update -y
        apt-get install -y openssl lzo pam openssl-devel lzo-devel pam-devel
        apt-get install -y easy-rsa
        apt-get install -y openvpn
        apt-get -y install tcl tk expect
    else
      (
        yum install -y epel-release
        yum update -y
        yum install -y openssl lzo pam openssl-devel lzo-devel pam-devel
        yum install -y easy-rsa
        yum install -y openvpn
        yum -y install tcl tk expect
    fi



    mkdir -p /var/log/openvpn/
    mkdir -p /etc/openvpn/server/user
    chown openvpn:openvpn /var/log/openvpn
    cp -rf /usr/share/easy-rsa/3.0.8 /etc/openvpn/server/easy-rsa
    current_path=$(pwd)
    cd /etc/openvpn/server/easy-rsa
    ./easyrsa init-pki
    ./easyrsa build-ca nopass
    ./easyrsa build-server-full server nopass
    ./easyrsa gen-dh
    openvpn --genkey --secret ta.key
    ./easyrsa build-client-full client nopass
    mkdir -p /etc/openvpn/server
    cp -a pki/ca.crt /etc/openvpn/server/
    cp -a pki/private/server.key /etc/openvpn/server
    cp -a pki/issued/server.crt /etc/openvpn/server
    cp -a pki/dh.pem /etc/openvpn/server
    cp -a ta.key /etc/openvpn/server
    cp server.conf /etc/openvpn/server/
    cp openvpn-server.service /usr/lib/systemd/system/
    systemctl start openvpn-server
    systemctl enable openvpn-server
    firewall-cmd --permanent --add-masquerade
    firewall-cmd --permanent --add-service=openvpn
    firewall-cmd --permanent --add-port=1194/tcp
    firewall-cmd --permanent --direct --passthrough ipv4 -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
    firewall-cmd --reload
    sysctl -w net.ipv4.ip_forward=1
    client_info=$current_path/client_info
    mkdir -p $client_info
    cp /etc/openvpn/server/easy-rsa/ta.key $client_info/
    cp /etc/openvpn/server/easy-rsa/pki/private/client.key $client_info/
    cp /etc/openvpn/server/easy-rsa/pki/issued/client.crt $client_info/
    cp /etc/openvpn/server/easy-rsa/pki/ca.crt $client_info/
    echo "=============================================================================================================================="
    echo 'The vpn server has been installed, you can view the vpn client connection information in the "client_info" directory in the current directory. 
This is a connection certificate that does not require a password. You can also generate a vpn client connection with password verification 
by executing "sh gen_user.sh" Certificate.'
    echo "=============================================================================================================================="

}


check_os
install_vpn


