#!/bin/bash

# Apache Setup Script for Ubuntu
# Run with: sudo bash setup-apache.sh
# Developed By Egemen KEYDAL

echo "================================"
echo "Apache Installation Started"
echo "================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run as root (use sudo)"
    exit 1
fi

# Error handling function
handle_error() {
    echo "ERROR: $1"
    echo "Attempting to fix..."
}

# Update package list with error handling
echo "Updating package list..."
if ! apt-get update; then
    handle_error "apt-get update failed"
    dpkg --configure -a
    apt-get install -f -y
    apt-get update
fi

# Check if Apache is already installed
if systemctl is-active --quiet apache2; then
    echo "Apache is already installed and running"
    read -p "Do you want to reinstall? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl stop apache2
        apt-get remove -y apache2 apache2-utils
        apt-get autoremove -y
    else
        echo "Skipping installation"
        exit 0
    fi
fi

# Check if Nginx is running on port 80
if systemctl is-active --quiet nginx; then
    echo "WARNING: Nginx is running and may conflict with Apache"
    read -p "Stop Nginx? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl stop nginx
        systemctl disable nginx
    else
        echo "You may need to configure Apache to use a different port"
    fi
fi

# Check port 80 availability
if netstat -tuln | grep -q ':80 '; then
    echo "WARNING: Port 80 is already in use"
    echo "Checking which service is using port 80..."
    lsof -i :80 || ss -tlnp | grep :80
    read -p "Stop the conflicting service? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        fuser -k 80/tcp 2>/dev/null || true
        sleep 2
    fi
fi

# Install Apache with error handling
echo "Installing Apache..."
if ! apt-get install -y apache2; then
    handle_error "Apache installation failed"
    apt-get install -f -y
    apt-get install -y apache2
fi

# Install useful Apache modules
echo "Installing common Apache modules..."
apt-get install -y apache2-utils libapache2-mod-security2 libapache2-mod-evasive

# Enable useful modules
echo "Enabling Apache modules..."
a2enmod rewrite
a2enmod ssl
a2enmod headers
a2enmod expires
a2enmod security2

# Start and enable Apache
echo "Starting and enabling Apache service..."
if ! systemctl start apache2; then
    handle_error "Failed to start Apache"
    echo "Checking Apache error logs..."
    tail -n 20 /var/log/apache2/error.log
    # Test configuration
    apache2ctl configtest
    # Try to fix configuration issues
    systemctl restart apache2
fi

systemctl enable apache2

# Configure firewall (if UFW is active)
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo "Configuring firewall..."
        ufw allow 'Apache Full' || ufw allow 80/tcp
    fi
fi

# Verify installation
if ! systemctl is-active --quiet apache2; then
    echo "ERROR: Apache is not running after installation"
    echo "Checking configuration..."
    apache2ctl configtest
    systemctl status apache2 --no-pager
    exit 1
fi

# Set proper permissions
echo "Setting proper permissions..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Create a test page
echo "Creating test page..."
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Apache Installed Successfully</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; background: #f4f4f4; }
        .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); max-width: 600px; margin: 0 auto; }
        h1 { color: #d30202; }
        .info { text-align: left; margin-top: 20px; padding: 15px; background: #f9f9f9; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Apache is working!</h1>
        <p>If you see this page, Apache has been successfully installed and configured.</p>
        <div class="info">
            <strong>Document Root:</strong> /var/www/html<br>
            <strong>Configuration:</strong> /etc/apache2/apache2.conf<br>
            <strong>Sites Available:</strong> /etc/apache2/sites-available/
        </div>
    </div>
</body>
</html>
EOF

# Create a PHP info page for testing
cat > /var/www/html/info.php << 'EOF'
<?php
phpinfo();
?>
EOF

# Secure the server
echo "Applying security configurations..."
# Hide Apache version
if ! grep -q "^ServerTokens" /etc/apache2/conf-available/security.conf; then
    echo "ServerTokens Prod" >> /etc/apache2/conf-available/security.conf
else
    sed -i 's/^ServerTokens.*/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
fi

if ! grep -q "^ServerSignature" /etc/apache2/conf-available/security.conf; then
    echo "ServerSignature Off" >> /etc/apache2/conf-available/security.conf
else
    sed -i 's/^ServerSignature.*/ServerSignature Off/' /etc/apache2/conf-available/security.conf
fi

systemctl restart apache2

# Display status
echo ""
echo "================================"
echo "Apache Installation Complete!"
echo "================================"
echo "Status:"
systemctl status apache2 --no-pager | head -10
echo ""
echo "Apache version:"
apache2 -v
echo ""
echo "Configuration file: /etc/apache2/apache2.conf"
echo "Sites available: /etc/apache2/sites-available/"
echo "Sites enabled: /etc/apache2/sites-enabled/"
echo "Document root: /var/www/html"
echo "Error log: /var/log/apache2/error.log"
echo "Access log: /var/log/apache2/access.log"
echo ""
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Access your server at: http://${SERVER_IP}"
echo "PHP info page: http://${SERVER_IP}/info.php (requires PHP)"
echo ""
echo "Enabled modules:"
apache2ctl -M | grep -E "rewrite|ssl|headers|expires|security"
echo ""
echo "Useful commands:"
echo "  systemctl status apache2          # Check status"
echo "  systemctl restart apache2         # Restart Apache"
echo "  apache2ctl configtest             # Test configuration"
echo "  apache2ctl -M                     # List enabled modules"
echo "  a2enmod <module>                  # Enable module"
echo "  a2dismod <module>                 # Disable module"
echo "  a2ensite <site>                   # Enable site"
echo "  a2dissite <site>                  # Disable site"
echo "  tail -f /var/log/apache2/error.log  # View error logs"
