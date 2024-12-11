#!/bin/bash

set -euo pipefail

# Function to configure DNS
configure_dns() {
    echo "++++++CONFIGURING DNS++++++"

    # Retrieve IP address
    ip=$(ip addr show ens33 | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    
    # Prompt for username and domain
    read -p "Enter the username: " user
    user=${user,,} # Convert to lowercase

    if id "$user" &>/dev/null; then
        echo "Error: User '$user' already exists."
        exit 1
    fi

    useradd "$user" && echo "User '$user' created successfully."

    read -p "Enter the domain name: " domain
    domain=${domain,,} # Convert to lowercase

    if grep -q "\"$domain\"" /etc/named.conf; then
        echo "Error: Domain '$domain' is already configured on the server."
        userdel -r "$user"
        exit 1
    fi

    read -p "Enter the email (e.g., admin@example.com): " email

    # Add DNS zone configuration
    cat <<EOF >> /etc/named.conf
zone "$domain" IN {
    type master;
    file "for.$domain";
};
EOF

    # Create zone file
    cat <<EOF > "/var/named/for.$domain"
\$TTL 1D
@    IN SOA master.spider.com. $email. (
        0       ; serial
        1D      ; refresh
        1H      ; retry
        1W      ; expire
        3H )    ; minimum
@    IN NS    master.spider.com.
$domain. IN A    $ip
www     IN A    $ip
EOF

    # Set permissions
    chgrp named /var/named/for.$domain

    # Restart named service
    echo -n "Restarting the named service: "
    systemctl restart named
    echo "DONE"

    # Validate DNS configuration
    echo "Checking A record for $domain: "
    host -t a "$domain"
    echo "DNS configuration for $domain completed."
}

# Function to configure Apache
configure_apache() {
    echo "++++++CONFIGURING APACHE++++++"

    # Create public_html directory
    mkdir -p "/home/$user/public_html"

    # Add sample HTML page
    echo "<h1>Sample webpage for $domain</h1>" > "/home/$user/public_html/index.html"

    # Set permissions
    chmod 711 "/home/$user"
    chmod 755 "/home/$user/public_html"
    chmod 644 "/home/$user/public_html/index.html"
    chown "$user:$user" "/home/$user/public_html" -R

    # Create Apache virtual host configuration
    cat <<EOF > "/etc/httpd/sites-available/${domain}.conf"
<VirtualHost *:80>
    DocumentRoot /home/$user/public_html
    ServerName $domain
    ServerAlias www.$domain
    ErrorLog /var/log/httpd/${domain}_error_log
    CustomLog /var/log/httpd/${domain}_access_log combined
</VirtualHost>
EOF

    # Enable site
    ln -sf "/etc/httpd/sites-available/${domain}.conf" "/etc/httpd/sites-enabled/${domain}.conf"

    # Restart Apache service
    echo -n "Restarting the httpd service: "
    systemctl restart httpd
    echo "DONE"

    # Open site in Firefox
    echo "Opening $domain in Firefox..."
    firefox "http://$domain" &
}

# Main script
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root."
    exit 1
fi

configure_dns
configure_apache

echo "Configuration completed successfully."
