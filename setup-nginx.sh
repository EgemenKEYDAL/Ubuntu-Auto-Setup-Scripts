#!/bin/bash

# Nginx Setup Script for Ubuntu
# Run with: sudo bash setup-nginx.sh
# Developed By Egemen KEYDAL

echo "================================"
echo "Nginx Installation Started"
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
    # Fix broken packages
    dpkg --configure -a
    apt-get install -f -y
    apt-get update
fi

# Check if Nginx is already installed
if systemctl is-active --quiet nginx; then
    echo "Nginx is already installed and running"
    read -p "Do you want to reinstall? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl stop nginx
        apt-get remove -y nginx nginx-common
        apt-get autoremove -y
    else
        echo "Skipping installation"
        exit 0
    fi
fi

# Install Nginx with error handling
echo "Installing Nginx..."
if ! apt-get install -y nginx; then
    handle_error "Nginx installation failed"
    apt-get install -f -y
    apt-get install -y nginx
fi

# Check port 80 availability
if netstat -tuln | grep -q ':80 '; then
    echo "WARNING: Port 80 is already in use"
    echo "Checking which service is using port 80..."
    lsof -i :80 || ss -tlnp | grep :80
    read -p "Stop the conflicting service? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Try to stop Apache if it's running
        systemctl stop apache2 2>/dev/null || true
    fi
fi

# Start and enable Nginx with error handling
echo "Starting and enabling Nginx service..."
if ! systemctl start nginx; then
    handle_error "Failed to start Nginx"
    # Check logs
    echo "Checking Nginx error logs..."
    tail -n 20 /var/log/nginx/error.log
    # Test configuration
    nginx -t
    # Try to fix configuration issues
    systemctl restart nginx
fi

systemctl enable nginx

# Configure firewall (if UFW is active)
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo "Configuring firewall..."
        ufw allow 'Nginx Full' || ufw allow 80/tcp
    fi
fi

# Verify installation
if ! systemctl is-active --quiet nginx; then
    echo "ERROR: Nginx is not running after installation"
    echo "Checking configuration..."
    nginx -t
    systemctl status nginx --no-pager
    exit 1
fi

# Create a test page
echo "Creating test page..."
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Nginx Installed Successfully</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; }
        h1 { color: #009639; }
    </style>
</head>
<body>
    <h1>Nginx is working!</h1>
    <p>If you see this page, Nginx has been successfully installed and configured.</p>
</body>
</html>
EOF

# Display status
echo ""
echo "================================"
echo "Nginx Installation Complete!"
echo "================================"
echo "Status:"
systemctl status nginx --no-pager | head -10
echo ""
echo "Nginx version:"
nginx -v
echo ""
echo "Configuration file: /etc/nginx/nginx.conf"
echo "Default site: /etc/nginx/sites-available/default"
echo "Web root: /var/www/html"
echo ""
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Access your server at: http://${SERVER_IP}"
echo ""
echo "Useful commands:"
echo "  systemctl status nginx    # Check status"
echo "  systemctl restart nginx   # Restart Nginx"
echo "  nginx -t                  # Test configuration"
echo "  tail -f /var/log/nginx/error.log  # View error logs"
