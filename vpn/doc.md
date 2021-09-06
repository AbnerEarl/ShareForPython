

openvpn --daemon --cd /etc/openvpn --config client.ovpn --log-append /var/log/openvpn.log
openvpn --daemon --cd /etc/openvpn --config client.ovpn --log-append /var/log/openvpn.log --askpass auth.info


参数解释：

--daemon：openvpn以daemon方式启动。
--cd dir：配置文件的目录，openvpn初始化前，先切换到此目录。
--config file：客户端配置文件的路径。
--log-append file：日志文件路径，如果文件不存在会自动创建。
--askpass auth.info: 通过密码访问，后面是存储密码的文件

最后可以将上述命令加到/etc/rc.local里开机启动。