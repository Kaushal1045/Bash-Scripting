#!/bin/bash
echo "++++++CONFIGURE DNS++++++++++++++++++++++++++++++++"
ip=$(ifconfig ens33 | grep "inet"| grep -v "inet6" | awk '{print $2}')
read -p "Enter the user name: " user
user=${user,,}
id ${user:-root} &> /dev/null && (echo "User ${user:-root} exists.";exit 1)|| useradd ${user};echo "User ${user} created successfully"

read -p "Enter the domain name: " domain
domain=${domain,,}
if grep "\"$domain\"" /etc/named.conf &> /dev/null;then
	echo "$domain already configured on server"
	userdel -r $user
	exit 1
else
	read -p "Enter the Email: " email
	echo -e "zone \"$domain\" IN {\n\ttype master;\n\tfile \"for.$domain\";\n};" >> /etc/named.conf
	echo -e "\$TTL 1D
@	IN SOA master.spider.com. $email. (
					0	; serial
					1D	; refresh
					1H	; retry
					1W	; expire
					3H )	; minimum
@	IN	NS	master.spider.com.
$domain.	IN	A	$ip
www		IN	A	$ip" > /var/named/for.$domain
	chgrp named /var/named/for.$domain
	echo -n "Starting the service \"named\" : "
	systemctl restart named
	echo "DONE"
	echo "Looking for A record for $domain: "
	host -t a $domain
fi
echo "+++++++++++++++++++++++++++++++++++++++++++++++"	
echo "++++++CONFIGURE APACHE++++++++++++++++++++++++++++++++"	
mkdir /home/$user/public_html
echo "<h1>Sample webpage for $domain</h1>" > /home/$user/public_html/index.html
chmod 711 /home/$user
chmod 755 /home/$user/public_html
chmod 644 /home/$user/public_html/index.html
chown $user:$user /home/$user/public_html -R
echo "<VirtualHost *:80>
	DocumentRoot	/home/$user/public_html
	ServerName	$domain
	ServerAlias	www.$domain
	ErrorLog	/var/log/httpd/${domain}_error_log
	CustomLog	/var/log/httpd/${domain}_access_log combined
</VirtualHost>" > /etc/httpd/sites-available/${domain}.conf
ln -s /etc/httpd/sites-available/${domain}.conf /etc/httpd/sites-enabled/${domain}.conf
echo -n "Starting the service \"httpd\" : "
systemctl restart httpd
echo "DONE"
firefox http://$domain
