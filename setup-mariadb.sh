#!/bin/bash

# MariaDB Setup Script for Ubuntu
# Run with: sudo bash setup-mariadb.sh
# Developed By Egemen KEYDAL

echo "================================"
echo "MariaDB Installation Started"
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

# Check if MariaDB is already installed
if systemctl is-active --quiet mariadb; then
    echo "MariaDB is already installed and running"
    mariadb --version
    read -p "Do you want to reinstall? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl stop mariadb
        apt-get remove -y mariadb-server mariadb-client mariadb-common
        apt-get autoremove -y
        rm -rf /var/lib/mysql
        rm -rf /etc/mysql
    else
        echo "Skipping installation"
        exit 0
    fi
fi

# Check if MySQL is installed (conflict)
if systemctl is-active --quiet mysql; then
    echo "WARNING: MySQL is installed and may conflict with MariaDB"
    read -p "Remove MySQL and continue with MariaDB installation? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl stop mysql
        apt-get remove -y mysql-server mysql-client
        apt-get autoremove -y
    else
        echo "Installation cancelled"
        exit 1
    fi
fi

# Install MariaDB with error handling
echo "Installing MariaDB server..."
export DEBIAN_FRONTEND=noninteractive
if ! apt-get install -y mariadb-server mariadb-client; then
    handle_error "MariaDB installation failed"
    apt-get install -f -y
    apt-get install -y mariadb-server mariadb-client
fi

# Start and enable MariaDB
echo "Starting and enabling MariaDB service..."
if ! systemctl start mariadb; then
    handle_error "Failed to start MariaDB"
    echo "Checking MariaDB error logs..."
    tail -n 20 /var/log/mysql/error.log
    # Try to fix common issues
    chown -R mysql:mysql /var/lib/mysql
    chmod 750 /var/lib/mysql
    systemctl restart mariadb
fi

systemctl enable mariadb

# Wait for MariaDB to start
sleep 3

# Verify installation
if ! systemctl is-active --quiet mariadb; then
    echo "ERROR: MariaDB is not running after installation"
    systemctl status mariadb --no-pager
    exit 1
fi

# Secure MariaDB installation
echo ""
echo "Securing MariaDB installation..."
MARIADB_ROOT_PASSWORD=$(openssl rand -base64 32)

# Create temporary SQL file for secure installation
TEMP_SQL=$(mktemp)
cat > "$TEMP_SQL" << EOF
-- Update root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';
-- Disallow root login remotely
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- Reload privilege tables
FLUSH PRIVILEGES;
EOF

# Execute SQL file
if mariadb < "$TEMP_SQL" 2>/dev/null; then
    echo "MariaDB secured successfully"

    # Save credentials to file
    CRED_FILE="/root/.mariadb_credentials"
    cat > "$CRED_FILE" << EOF
MariaDB Root Credentials
========================
Username: root
Password: ${MARIADB_ROOT_PASSWORD}
Host: localhost

Connection command:
mariadb -u root -p
# or
mysql -u root -p

IMPORTANT: Keep this file secure and delete it after saving the password elsewhere!
EOF
    chmod 600 "$CRED_FILE"

    echo ""
    echo "Root password has been set and saved to: $CRED_FILE"
    echo "IMPORTANT: Save this password securely and delete the file!"
else
    echo "Note: Manual security configuration may be needed"
    echo "Run: mariadb-secure-installation"
fi

rm -f "$TEMP_SQL"

# Configure MariaDB for better performance and security
echo "Configuring MariaDB..."
MARIADB_CNF="/etc/mysql/mariadb.conf.d/50-server.cnf"

if [ -f "$MARIADB_CNF" ]; then
    # Backup original config
    cp "$MARIADB_CNF" "${MARIADB_CNF}.backup"

    # Set bind-address to localhost for security
    if grep -q "^bind-address" "$MARIADB_CNF"; then
        sed -i 's/^bind-address.*/bind-address = 127.0.0.1/' "$MARIADB_CNF"
    else
        echo "bind-address = 127.0.0.1" >> "$MARIADB_CNF"
    fi

    # Restart to apply changes
    systemctl restart mariadb
fi

# Create MariaDB client config for root
cat > /root/.my.cnf << EOF
[client]
user=root
password=${MARIADB_ROOT_PASSWORD}
EOF
chmod 600 /root/.my.cnf

# Test connection
echo ""
echo "Testing MariaDB connection..."
if mariadb -e "SELECT VERSION();" > /dev/null 2>&1; then
    echo "Connection test successful!"
else
    echo "WARNING: Could not connect to MariaDB"
fi

# Configure firewall (MariaDB should not be exposed by default)
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo "MariaDB is configured to accept local connections only (secure default)"
        echo "To allow remote connections, run: ufw allow 3306/tcp"
    fi
fi

# Display status
echo ""
echo "================================"
echo "MariaDB Installation Complete!"
echo "================================"
echo "Status:"
systemctl status mariadb --no-pager | head -10
echo ""
echo "MariaDB version:"
mariadb --version
echo ""
echo "Configuration file: /etc/mysql/mariadb.conf.d/50-server.cnf"
echo "Data directory: /var/lib/mysql"
echo "Error log: /var/log/mysql/error.log"
echo "Socket: /var/run/mysqld/mysqld.sock"
echo ""
echo "Root credentials saved to: /root/.mariadb_credentials"
echo "MariaDB client config: /root/.my.cnf (allows root login without password)"
echo ""
echo "Database info:"
mariadb -e "SELECT VERSION();" 2>/dev/null || echo "Run 'mariadb -u root -p' to connect"
echo ""
echo "Useful commands:"
echo "  mariadb -u root -p                # Connect to MariaDB"
echo "  mysql -u root -p                  # Connect using mysql command"
echo "  systemctl status mariadb          # Check status"
echo "  systemctl restart mariadb         # Restart MariaDB"
echo "  mariadb -e 'SHOW DATABASES;'      # List databases"
echo "  mariadb-admin -u root -p status   # Show server status"
echo "  tail -f /var/log/mysql/error.log  # View error logs"
echo ""
echo "Create new database and user:"
echo "  mariadb -u root -p"
echo "  CREATE DATABASE mydb;"
echo "  CREATE USER 'myuser'@'localhost' IDENTIFIED BY 'password';"
echo "  GRANT ALL PRIVILEGES ON mydb.* TO 'myuser'@'localhost';"
echo "  FLUSH PRIVILEGES;"
echo ""
echo "Security Note: MariaDB is bound to localhost (127.0.0.1) by default"
echo "This prevents remote connections. Edit $MARIADB_CNF to change."
