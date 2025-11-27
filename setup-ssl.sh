#!/bin/bash

# SSL/Let's Encrypt Setup Script for Ubuntu
# Run with: sudo bash setup-ssl.sh
# Developed By Egemen KEYDAL

echo "================================"
echo "SSL/Let's Encrypt Installation Started"
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

# Install required packages
echo "Installing required packages..."
apt-get install -y software-properties-common

# Check if Certbot is already installed
if command -v certbot &> /dev/null; then
    echo "Certbot is already installed"
    certbot --version
    read -p "Do you want to reinstall? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping installation"
        exit 0
    fi
fi

# Install Certbot with error handling
echo "Installing Certbot..."
if ! apt-get install -y certbot; then
    handle_error "Certbot installation failed"
    apt-get install -f -y
    apt-get install -y certbot
fi

# Detect web server and install appropriate plugin
WEB_SERVER=""
if systemctl is-active --quiet nginx; then
    echo "Nginx detected, installing Nginx plugin..."
    WEB_SERVER="nginx"
    if ! apt-get install -y python3-certbot-nginx; then
        handle_error "Nginx plugin installation failed"
        apt-get install -f -y
        apt-get install -y python3-certbot-nginx
    fi
elif systemctl is-active --quiet apache2; then
    echo "Apache detected, installing Apache plugin..."
    WEB_SERVER="apache"
    if ! apt-get install -y python3-certbot-apache; then
        handle_error "Apache plugin installation failed"
        apt-get install -f -y
        apt-get install -y python3-certbot-apache
    fi
else
    echo "No web server detected (Nginx or Apache)"
    echo "Installing standalone Certbot only..."
    WEB_SERVER="standalone"
fi

# Set up automatic renewal
echo "Setting up automatic SSL renewal..."
if ! systemctl is-active --quiet certbot.timer; then
    systemctl enable certbot.timer
    systemctl start certbot.timer
fi

# Test renewal process
echo "Testing renewal process..."
if ! certbot renew --dry-run 2>/dev/null; then
    echo "Note: Dry-run renewal test skipped (no certificates installed yet)"
fi

# Configure firewall for HTTPS
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo "Configuring firewall for HTTPS..."
        ufw allow 443/tcp || echo "Failed to add firewall rule"
        if [ "$WEB_SERVER" = "nginx" ]; then
            ufw allow 'Nginx Full' 2>/dev/null || true
        elif [ "$WEB_SERVER" = "apache" ]; then
            ufw allow 'Apache Full' 2>/dev/null || true
        fi
    fi
fi

# Display status
echo ""
echo "================================"
echo "SSL/Let's Encrypt Installation Complete!"
echo "================================"
echo "Certbot version:"
certbot --version
echo ""
echo "Web server detected: $WEB_SERVER"
echo ""

if [ "$WEB_SERVER" = "nginx" ]; then
    echo "To obtain an SSL certificate for Nginx, run:"
    echo "  certbot --nginx -d yourdomain.com -d www.yourdomain.com"
    echo ""
    echo "Or use standalone mode (requires stopping Nginx temporarily):"
    echo "  systemctl stop nginx"
    echo "  certbot certonly --standalone -d yourdomain.com"
    echo "  systemctl start nginx"
elif [ "$WEB_SERVER" = "apache" ]; then
    echo "To obtain an SSL certificate for Apache, run:"
    echo "  certbot --apache -d yourdomain.com -d www.yourdomain.com"
    echo ""
    echo "Or use standalone mode (requires stopping Apache temporarily):"
    echo "  systemctl stop apache2"
    echo "  certbot certonly --standalone -d yourdomain.com"
    echo "  systemctl start apache2"
else
    echo "To obtain an SSL certificate in standalone mode, run:"
    echo "  certbot certonly --standalone -d yourdomain.com"
fi

echo ""
echo "Automatic renewal is enabled via systemd timer"
echo "Timer status:"
systemctl status certbot.timer --no-pager | head -5
echo ""
echo "Useful commands:"
echo "  certbot certificates              # List all certificates"
echo "  certbot renew                     # Manually renew certificates"
echo "  certbot renew --dry-run           # Test renewal process"
echo "  certbot delete --cert-name domain # Delete a certificate"
echo "  systemctl status certbot.timer    # Check renewal timer status"
echo ""
echo "Certificate files location: /etc/letsencrypt/live/"
echo ""
echo "IMPORTANT NOTES:"
echo "1. Make sure your domain points to this server's IP address"
echo "2. Ports 80 and 443 must be accessible from the internet"
echo "3. Certificates will auto-renew every 60 days"
echo "4. Email notifications will alert you of renewal issues"
