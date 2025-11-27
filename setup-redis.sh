#!/bin/bash

# Redis Setup Script for Ubuntu
# Run with: sudo bash setup-redis.sh
# Developed By Egemen KEYDAL

echo "================================"
echo "Redis Installation Started"
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

# Check if Redis is already installed
if systemctl is-active --quiet redis-server; then
    echo "Redis is already installed and running"
    read -p "Do you want to reinstall? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl stop redis-server
        apt-get remove -y redis-server
        apt-get autoremove -y
        rm -rf /var/lib/redis
    else
        echo "Skipping installation"
        exit 0
    fi
fi

# Install Redis with error handling
echo "Installing Redis..."
if ! apt-get install -y redis-server; then
    handle_error "Redis installation failed"
    apt-get install -f -y
    apt-get install -y redis-server
fi

# Backup original configuration
if [ -f /etc/redis/redis.conf ]; then
    cp /etc/redis/redis.conf /etc/redis/redis.conf.backup
fi

# Configure Redis to use systemd
echo "Configuring Redis..."
if grep -q "^supervised" /etc/redis/redis.conf; then
    sed -i 's/^supervised.*/supervised systemd/' /etc/redis/redis.conf
else
    echo "supervised systemd" >> /etc/redis/redis.conf
fi

# Set memory policy (prevent OOM)
if grep -q "^maxmemory-policy" /etc/redis/redis.conf; then
    sed -i 's/^maxmemory-policy.*/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
else
    echo "maxmemory-policy allkeys-lru" >> /etc/redis/redis.conf
fi

# Check port 6379 availability
if netstat -tuln | grep -q ':6379 '; then
    echo "WARNING: Port 6379 is already in use"
    lsof -i :6379 || ss -tlnp | grep :6379
    read -p "Kill the process using port 6379? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        fuser -k 6379/tcp 2>/dev/null || true
    fi
fi

# Restart Redis with new configuration
echo "Starting and enabling Redis service..."
if ! systemctl restart redis-server; then
    handle_error "Failed to start Redis"
    echo "Checking Redis logs..."
    tail -n 20 /var/log/redis/redis-server.log
    # Try to fix common issues
    chown redis:redis /var/lib/redis
    chmod 750 /var/lib/redis
    systemctl restart redis-server
fi

systemctl enable redis-server

# Wait for Redis to start
sleep 2

# Verify installation
if ! systemctl is-active --quiet redis-server; then
    echo "ERROR: Redis is not running after installation"
    systemctl status redis-server --no-pager
    exit 1
fi

# Test Redis connection
echo "Testing Redis connection..."
if ! redis-cli ping > /dev/null 2>&1; then
    handle_error "Redis connection test failed"
    systemctl restart redis-server
    sleep 2
    redis-cli ping
fi

# Set up basic security (bind to localhost only by default)
if ! grep -q "^bind 127.0.0.1" /etc/redis/redis.conf; then
    echo "Securing Redis (binding to localhost)..."
    sed -i 's/^# bind 127.0.0.1/bind 127.0.0.1/' /etc/redis/redis.conf
    systemctl restart redis-server
fi

# Display status
echo ""
echo "================================"
echo "Redis Installation Complete!"
echo "================================"
echo "Status:"
systemctl status redis-server --no-pager | head -10
echo ""
echo "Redis version:"
redis-server --version
echo ""
echo "Configuration file: /etc/redis/redis.conf"
echo "Log file: /var/log/redis/redis-server.log"
echo "Data directory: /var/lib/redis"
echo "Default port: 6379"
echo ""
echo "Connection test:"
redis-cli ping
echo ""
echo "Useful commands:"
echo "  redis-cli                         # Connect to Redis CLI"
echo "  redis-cli ping                    # Test connection"
echo "  redis-cli info                    # Get server info"
echo "  systemctl status redis-server     # Check status"
echo "  systemctl restart redis-server    # Restart Redis"
echo "  tail -f /var/log/redis/redis-server.log  # View logs"
echo ""
echo "Security Note: Redis is bound to localhost (127.0.0.1) by default"
echo "Edit /etc/redis/redis.conf to change network settings"
