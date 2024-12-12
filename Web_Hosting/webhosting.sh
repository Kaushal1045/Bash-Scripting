#!/bin/bash
set -euo pipefail

# Function to configure DNS
configure_dns() {
    echo "++++++CONFIGURE DNS++++++++++++++++++++++++++++++++"
    ip=$(ifconfig ens33 | grep "inet" | grep -v "inet6" | awk '{print $2}')
    read -p "Enter the user name: " user
    user=${user,,}

    # Check if user exists
    id ${user:-root} &> /dev/null && { echo "User ${user:-root} exists."; exit 1; } || useradd ${user}; echo "User ${user} created successfully"

    read -p "Enter the domain name: " domain
    domain=${domain,,}

    # Check if the domain is already configured
    if grep -q "\"$domain\"" /etc/named.conf; then
        echo "$domain already configured on the server."
        read -p "Do you want to overwrite the existing configuration? (y/n): " choice
        case "$choice" in
            y|Y)
                echo "Removing existing configuration for $domain..."
                # Remove zone configuration from /etc/named.conf
                sed -i "/zone \"$domain\" IN {/,/};/d" /etc/named.conf
                # Remove the zone file
                rm -f "/var/named/for.$domain"
                ;;
            n|N)
                echo "Exiting without changes."
                exit 0
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    fi

    read -p "Enter the Email: " email
    echo -e "zone \"$domain\" IN {\n\ttype master;\n\tfile \"for.$domain\";\n};" >> /etc/named.conf
    echo -e "\$TTL 1D
@\tIN SOA master.spider.com. $email. (
                    0\t; serial
                    1D\t; refresh
                    1H\t; retry
                    1W\t; expire
                    3H )\t; minimum
@\tIN\tNS\tmaster.spider.com.
$domain.\tIN\tA\t$ip
www\tIN\tA\t$ip" > /var/named/for.$domain
    chgrp named /var/named/for.$domain
    echo -n "Starting the service \"named\" : "
    systemctl restart named
    echo "DONE"
    echo "Looking for A record for $domain: "
    host -t a $domain
    echo "+++++++++++++++++++++++++++++++++++++++++++++++"
}

# Function to configure Apache
configure_apache() {
    echo "++++++CONFIGURE APACHE++++++++++++++++++++++++++++++++"
    mkdir -p /home/$user/public_html
    echo "<h1>Sample webpage for $domain</h1>" > /home/$user/public_html/index.html
    chmod 711 /home/$user
    chmod 755 /home/$user/public_html
    chmod 644 /home/$user/public_html/index.html
    chown $user:$user /home/$user/public_html -R
    echo "<VirtualHost *:80>
    DocumentRoot\t/home/$user/public_html
    ServerName\t$domain
    ServerAlias\twww.$domain
    ErrorLog\t/var/log/httpd/${domain}_error_log
    CustomLog\t/var/log/httpd/${domain}_access_log combined
</VirtualHost>" > /etc/httpd/sites-available/${domain}.conf
    ln -sf /etc/httpd/sites-available/${domain}.conf /etc/httpd/sites-enabled/${domain}.conf
    echo -n "Starting the service \"httpd\" : "
    systemctl restart httpd
    echo "DONE"
    firefox http://$domain
}

# Main Script
configure_dns
configure_apache
