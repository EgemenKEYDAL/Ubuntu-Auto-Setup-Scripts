#!/bin/bash

# MySQL Setup Script for Ubuntu
# Run with: sudo bash setup-mysql.sh
# Developed By Egemen KEYDAL

echo "================================"
echo "MySQL Installation Started"
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

# Check if MySQL is already installed
if systemctl is-active --quiet mysql; then
    echo "MySQL is already installed and running"
    mysql --version
    read -p "Do you want to reinstall? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl stop mysql
        apt-get remove -y mysql-server mysql-client mysql-common
        apt-get autoremove -y
        rm -rf /var/lib/mysql
        rm -rf /etc/mysql
    else
        echo "Skipping installation"
        exit 0
    fi
fi

# Check if MariaDB is installed (conflict)
if systemctl is-active --quiet mariadb; then
    echo "WARNING: MariaDB is installed and may conflict with MySQL"
    read -p "Remove MariaDB and continue with MySQL installation? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl stop mariadb
        apt-get remove -y mariadb-server mariadb-client
        apt-get autoremove -y
    else
        echo "Installation cancelled"
        exit 1
    fi
fi

# Install MySQL with error handling
echo "Installing MySQL server..."
export DEBIAN_FRONTEND=noninteractive
if ! apt-get install -y mysql-server mysql-client; then
    handle_error "MySQL installation failed"
    apt-get install -f -y
    apt-get install -y mysql-server mysql-client
fi

# Start and enable MySQL
echo "Starting and enabling MySQL service..."
if ! systemctl start mysql; then
    handle_error "Failed to start MySQL"
    echo "Checking MySQL error logs..."
    tail -n 20 /var/log/mysql/error.log
    # Try to fix common issues
    chown -R mysql:mysql /var/lib/mysql
    chmod 750 /var/lib/mysql
    systemctl restart mysql
fi

systemctl enable mysql

# Wait for MySQL to start
sleep 3

# Verify installation
if ! systemctl is-active --quiet mysql; then
    echo "ERROR: MySQL is not running after installation"
    systemctl status mysql --no-pager
    exit 1
fi

# Secure MySQL installation
echo ""
echo "Securing MySQL installation..."
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)

# Create temporary SQL file for secure installation
TEMP_SQL=$(mktemp)
cat > "$TEMP_SQL" << EOF
-- Update root password
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
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
if mysql < "$TEMP_SQL" 2>/dev/null; then
    echo "MySQL secured successfully"

    # Save credentials to file
    CRED_FILE="/root/.mysql_credentials"
    cat > "$CRED_FILE" << EOF
MySQL Root Credentials
======================
Username: root
Password: ${MYSQL_ROOT_PASSWORD}
Host: localhost

Connection command:
mysql -u root -p

IMPORTANT: Keep this file secure and delete it after saving the password elsewhere!
EOF
    chmod 600 "$CRED_FILE"

    echo ""
    echo "Root password has been set and saved to: $CRED_FILE"
    echo "IMPORTANT: Save this password securely and delete the file!"
else
    echo "Note: Manual security configuration may be needed"
    echo "Run: mysql_secure_installation"
fi

rm -f "$TEMP_SQL"

# Configure MySQL for better performance and security
echo "Configuring MySQL..."
MYSQL_CNF="/etc/mysql/mysql.conf.d/mysqld.cnf"

if [ -f "$MYSQL_CNF" ]; then
    # Backup original config
    cp "$MYSQL_CNF" "${MYSQL_CNF}.backup"

    # Set bind-address to localhost for security
    if grep -q "^bind-address" "$MYSQL_CNF"; then
        sed -i 's/^bind-address.*/bind-address = 127.0.0.1/' "$MYSQL_CNF"
    else
        echo "bind-address = 127.0.0.1" >> "$MYSQL_CNF"
    fi

    # Restart to apply changes
    systemctl restart mysql
fi

# Create MySQL client config for root
cat > /root/.my.cnf << EOF
[client]
user=root
password=${MYSQL_ROOT_PASSWORD}
EOF
chmod 600 /root/.my.cnf

# Test connection
echo ""
echo "Testing MySQL connection..."
if mysql -e "SELECT VERSION();" > /dev/null 2>&1; then
    echo "Connection test successful!"
else
    echo "WARNING: Could not connect to MySQL"
fi

# Configure firewall (MySQL should not be exposed by default)
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo "MySQL is configured to accept local connections only (secure default)"
        echo "To allow remote connections, run: ufw allow 3306/tcp"
    fi
fi

# Display status
echo ""
echo "================================"
echo "MySQL Installation Complete!"
echo "================================"
echo "Status:"
systemctl status mysql --no-pager | head -10
echo ""
echo "MySQL version:"
mysql --version
echo ""
echo "Configuration file: /etc/mysql/mysql.conf.d/mysqld.cnf"
echo "Data directory: /var/lib/mysql"
echo "Error log: /var/log/mysql/error.log"
echo "Socket: /var/run/mysqld/mysqld.sock"
echo ""
echo "Root credentials saved to: /root/.mysql_credentials"
echo "MySQL client config: /root/.my.cnf (allows root login without password)"
echo ""
echo "Database info:"
mysql -e "SELECT VERSION();" 2>/dev/null || echo "Run 'mysql -u root -p' to connect"
echo ""
echo "Useful commands:"
echo "  mysql -u root -p                  # Connect to MySQL"
echo "  systemctl status mysql            # Check status"
echo "  systemctl restart mysql           # Restart MySQL"
echo "  mysql -e 'SHOW DATABASES;'        # List databases"
echo "  mysqladmin -u root -p status      # Show server status"
echo "  tail -f /var/log/mysql/error.log  # View error logs"
echo ""
echo "Create new database and user:"
echo "  mysql -u root -p"
echo "  CREATE DATABASE mydb;"
echo "  CREATE USER 'myuser'@'localhost' IDENTIFIED BY 'password';"
echo "  GRANT ALL PRIVILEGES ON mydb.* TO 'myuser'@'localhost';"
echo "  FLUSH PRIVILEGES;"
echo ""
echo "Security Note: MySQL is bound to localhost (127.0.0.1) by default"
echo "This prevents remote connections. Edit $MYSQL_CNF to change."
