#!/bin/sh
if [ -e ezserver.enterprise_bit64.tar ]; then
rm -f ezserver.enterprise_bit64.tar
fi
read  -p "Please enter installation password? " dpass
if test -z $dpass; then
exit 0
fi
standard_url='http://www.ezhometech.com/download_enterprise_'$dpass'/ezserver.enterprise_bit64.tar'
wget -O ezserver.enterprise_bit64.tar $standard_url
if [ -s ezserver.enterprise_bit64.tar ]; then
	echo "ezserver standard version downloaded..."
	if [ -e ezserver_enterprise ]; then
		backupfilename="ezserver_enterprise$(date +%Y%m%d_%s)"
		read  -p "Backup current ezserver_enterprise folder(?(y/n) " yn
		if [ "$yn" != "Y" ] && [ "$yn" != "y" ]; then
			rm -rf ezserver_enterprise
			echo "Remove ezserver_enterprise folder"
		else
			mv ezserver_enterprise $backupfilename
			echo "Backup ezserver_enterprise folder to "$backupfilename		
		fi
	fi
	tar xfvz ezserver.enterprise_bit64.tar
	rm ezserver.enterprise_bit64.tar
else
	echo "Password Error..."
	exit 0
fi
cd ezserver_enterprise
chmod 777 *.*
chmod 777 *
echo 2062780 > /proc/sys/kernel/threads-max
if ! cat /etc/sysctl.conf | grep -v grep | grep -c 1677721600 > /dev/null; then 
echo 'net.core.wmem_max= 1677721600' >> /etc/sysctl.conf
echo 'net.core.rmem_max= 1677721600' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem= 1024000 8738000 1677721600' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem= 1024000 8738000 1677721600' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_window_scaling = 1' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_timestamps = 1' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_sack = 1' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_no_metrics_save = 1' >> /etc/sysctl.conf
echo 'net.core.netdev_max_backlog = 5000' >> /etc/sysctl.conf
echo 'net.ipv4.route.flush=1' >> /etc/sysctl.conf
echo 'fs.file-max=65536' >> /etc/sysctl.conf
sysctl -p
fi
ezgetconfig_image="./ezgetconfig"
#
# 1. Type network interface
#
network_interface_str="network_interface"
network_interface_value=$("$ezgetconfig_image"  $network_interface_str)
rm -rf serial_number.txt
echo "1. Please input network interface name:"
ifconfig -a -s|cut -d' ' -f1|tail -n +2
while [ 1 ]
do
	read  -p "--> " ni
	if test -z $ni; then
		echo "1. Please input network interface name:"
		ifconfig -a -s|cut -d' ' -f1|tail -n +2
	else
		break
	fi
done
sedcmd='s/'$network_interface_value'/'$ni'/g'
sed -i $sedcmd ezserver_config.txt
echo "Set iface to "$ni
#
# 2. Type Panel Port
#
http_base_port_str="http_base_port"
http_base_port=$("$ezgetconfig_image"  $http_base_port_str)
RANDOM=$$
http_base_random_port=$((($RANDOM % 100)+$http_base_port))
#if iptables -L | grep -c "tcp dpt:"$http_base_random_port > /dev/null; then
#iptables -D INPUT -p tcp --dport $http_base_random_port -j ACCEPT
#fi
read  -p "2. Please type new panel port no. ("$http_base_random_port"): " new_http_base_port
if test -z $new_http_base_port; then
new_http_base_port=$http_base_random_port
fi
http_base_port_keyword_with_value="http_base_port="$http_base_port
new_http_base_port_keyword_with_value="http_base_port="$new_http_base_port
sedcmd='s/'$http_base_port_keyword_with_value'/'$new_http_base_port_keyword_with_value'/g'
sed -i $sedcmd ezserver_config.txt
echo "Set Panel Port No. to "$new_http_base_port
#iptables -I INPUT -p tcp --dport $new_http_base_port -j ACCEPT
#
# 3. Type HTTP Video Streaming Port
#
http_port_str="http_port"
http_port=$("$ezgetconfig_image"  $http_port_str)
RANDOM=$$
http_random_port=$((($RANDOM % 100)+$http_port))
#if iptables -L | grep -c "tcp dpt:"$http_random_port > /dev/null; then
#iptables -D INPUT -p tcp --dport $http_random_port -j ACCEPT
#fi
read  -p "3. Please type new http streaming port no. for players ("$http_random_port"): " new_http_port
if test -z $new_http_port; then
new_http_port=$http_random_port
fi

http_port_keyword_with_value="httpport="$http_port
new_http_port_keyword_with_value="httpport="$new_http_port
sedcmd='s/'$http_port_keyword_with_value'/'$new_http_port_keyword_with_value'/g'
sed -i $sedcmd ezserver_config.txt
echo "Set Streaming HTTP Port No. to "$new_http_port
#iptables -I INPUT -p tcp --dport $new_http_port -j ACCEPT
#
# 4. Setup Auto Start
#
ezserver_folder="$PWD"
read  -p "4. Do you want to setup auto_start mode?(y/n) " yn
if test -z $yn; then
yn="y"
fi
if [ "$yn" != "Y" ] && [ "$yn" != "y" ]; then
echo "auto_start mode is disabled..."
sed -i '/checkmo.sh/d' /etc/crontab
else
sed -i '/checkmo.sh/d' /etc/crontab
sed -i '$a\'"*/1 * * * * root ""$ezserver_folder""/checkmo.sh" /etc/crontab
if ! cat /etc/rc.local | grep -v grep | grep -c monitor.sh > /dev/null; then
sed -i '/monitor.sh/d' /etc/rc.local
sed -i '1a\'".""$ezserver_folder""/monitor.sh" /etc/rc.local
fi
echo "auto_start mode is enabled..."
fi
sed -i '2d' checkmo.sh
sed -i '1a\''export EZSERVER_DIR="'"$ezserver_folder"'"' checkmo.sh
sed -i '3d' monitor.sh
sed -i '2a\''export EZSERVER_DIR="'"$ezserver_folder"'"' monitor.sh
#
if ! which killall; then
echo "killall command not found, please install it"
exit 0
fi
killall -9 ezserver
nohup ./ezserver &
yn=no
while [ "$yn" != "yes" ]
do 
sleep 1
if [ -e serial_number.txt ]; then
killall -9 ezserver
rm -rf nohup.out
yn=yes
fi
done

# download testing links
rm -f channel_definition.xml
testing_url='http://www.ezhometech.com/download/channel_definition.xml'
wget -O channel_definition.xml $testing_url


echo "5. Setup successfully..."
echo "6. Send serial_number.txt to sales@ezhometech.com for license activation..."
echo " "
