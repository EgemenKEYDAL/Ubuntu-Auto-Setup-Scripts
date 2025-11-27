# Ubuntu Automated Setup Scripts

Developed By Egemen KEYDAL

English | [Türkçe](README.md)

Fully automated installation scripts for Ubuntu servers. Each script installs the respective software with error checking and automatic fixing capabilities.

## 📋 Table of Contents

- [Features](#features)
- [Available Scripts](#available-scripts)
- [Installation](#installation)
- [Usage](#usage)
- [Detailed Information](#detailed-information)
- [Security Notes](#security-notes)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

Each script includes:

- ✅ **Fully Automated**: One command installs everything
- 🔧 **Smart Error Recovery**: Automatically detects and fixes errors
- 🛡️ **Security-Focused**: Comes with secure default configurations
- 🔍 **Conflict Detection**: Detects port and service conflicts
- 📝 **Detailed Logging**: Explains and logs every step
- 🔄 **Reinstall Support**: Safely manages existing installations
- 🧪 **Test Files**: Creates sample files to test installation
- 📚 **Comprehensive Documentation**: Usage instructions after each script

## 🚀 Available Scripts

| Script | Description | Default Port |
|--------|-------------|--------------|
| **setup-nginx.sh** | Nginx web server | 80, 443 |
| **setup-apache.sh** | Apache web server | 80, 443 |
| **setup-mysql.sh** | MySQL database server | 3306 |
| **setup-mariadb.sh** | MariaDB database server | 3306 |
| **setup-redis.sh** | Redis cache server | 6379 |
| **setup-php.sh** | PHP (7.4, 8.1, 8.2, 8.3) | - |
| **setup-nodejs.sh** | Node.js runtime (18.x, 20.x, 21.x) | - |
| **setup-python.sh** | Python (2, 3.10, 3.11) | - |
| **setup-ssl.sh** | Let's Encrypt SSL/TLS certificates | 443 |

## 📦 Installation

### Prerequisites

- Ubuntu 20.04, 22.04, or 24.04
- Root access (sudo)
- Internet connection

### Make Scripts Executable

```bash
chmod +x setup-*.sh
```

## 🎯 Usage

Run each script with root privileges:

```bash
sudo bash setup-nginx.sh
```

### Example Usage Scenarios

#### 1. Web Server Setup (Nginx + PHP + MySQL)

```bash
# Step 1: Install Nginx
sudo bash setup-nginx.sh

# Step 2: Install PHP
sudo bash setup-php.sh
# Choose: 1 (PHP 8.2 - Recommended)

# Step 3: Install MySQL
sudo bash setup-mysql.sh

# Step 4: Add SSL certificate
sudo bash setup-ssl.sh
```

#### 2. Node.js Application Server

```bash
# Install Node.js
sudo bash setup-nodejs.sh
# Choose: 1 (LTS - Recommended)

# Install Nginx as reverse proxy
sudo bash setup-nginx.sh

# Add SSL
sudo bash setup-ssl.sh
```

#### 3. Full Stack Development Environment

```bash
# Install all tools
sudo bash setup-nginx.sh
sudo bash setup-apache.sh      # Will use different port
sudo bash setup-mysql.sh
sudo bash setup-redis.sh
sudo bash setup-php.sh
sudo bash setup-nodejs.sh
sudo bash setup-python.sh
```

## 📖 Detailed Information

### Nginx (setup-nginx.sh)

**What Gets Installed:**
- Nginx web server
- Default site configuration
- Test HTML page
- Firewall rules (if UFW is active)

**Important Files:**
- Configuration: `/etc/nginx/nginx.conf`
- Site configurations: `/etc/nginx/sites-available/`
- Web root: `/var/www/html`
- Logs: `/var/log/nginx/`

**Usage:**
```bash
# Restart Nginx
sudo systemctl restart nginx

# Test configuration
sudo nginx -t

# Check status
sudo systemctl status nginx
```

### Apache (setup-apache.sh)

**What Gets Installed:**
- Apache2 web server
- Common modules (rewrite, ssl, headers, expires)
- Security modules (mod_security2, mod_evasive)
- Test pages

**Important Files:**
- Configuration: `/etc/apache2/apache2.conf`
- Site configurations: `/etc/apache2/sites-available/`
- Web root: `/var/www/html`
- Logs: `/var/log/apache2/`

**Usage:**
```bash
# Enable site
sudo a2ensite mysite.conf

# Enable module
sudo a2enmod rewrite

# Test configuration
sudo apache2ctl configtest

# Restart
sudo systemctl restart apache2
```

### MySQL (setup-mysql.sh)

**What Gets Installed:**
- MySQL Server and Client
- Secure root password (automatically generated)
- Optimized configuration
- Client configuration for root

**Important Information:**
- Root password: Saved in `/root/.mysql_credentials`
- Client configuration: `/root/.my.cnf`
- Configuration: `/etc/mysql/mysql.conf.d/mysqld.cnf`
- Data directory: `/var/lib/mysql`

**Security:**
- Anonymous users removed
- Remote root access disabled
- Test database removed
- Bound to localhost (127.0.0.1)

**Usage:**
```bash
# Connect to MySQL
mysql -u root -p

# Create database
mysql -e "CREATE DATABASE myapp;"

# Create user
mysql -e "CREATE USER 'myuser'@'localhost' IDENTIFIED BY 'password';"
mysql -e "GRANT ALL PRIVILEGES ON myapp.* TO 'myuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"
```

### MariaDB (setup-mariadb.sh)

Similar to MySQL but with MariaDB-specific features. Same usage and configuration.

**Note:** MySQL and MariaDB cannot be installed simultaneously. The script automatically detects conflicts.

### Redis (setup-redis.sh)

**What Gets Installed:**
- Redis Server
- Systemd integration
- Optimized memory policy
- Security configuration

**Important Files:**
- Configuration: `/etc/redis/redis.conf`
- Log: `/var/log/redis/redis-server.log`
- Data: `/var/lib/redis`

**Usage:**
```bash
# Connect to Redis CLI
redis-cli

# Basic commands
redis-cli ping
redis-cli set mykey "Hello"
redis-cli get mykey
redis-cli info
```

### PHP (setup-php.sh)

**What Gets Installed:**
- Selected PHP version(s)
- Common extensions (mysql, curl, gd, mbstring, xml, zip, etc.)
- PHP-FPM (for Nginx) or mod_php (for Apache)
- Composer (optional)
- Test PHP files

**Supported Versions:**
- PHP 8.3 (Latest)
- PHP 8.2 (Stable)
- PHP 8.1
- PHP 7.4 (Legacy)

**Usage:**
```bash
# Check PHP version
php -v

# List installed modules
php -m

# Switch PHP version
sudo update-alternatives --config php

# Restart PHP-FPM
sudo systemctl restart php8.2-fpm
```

### Node.js (setup-nodejs.sh)

**What Gets Installed:**
- Node.js runtime
- npm package manager
- Yarn (optional)
- PM2 process manager (optional)
- nodemon (optional)
- Build tools

**Supported Versions:**
- Node.js 18.x LTS
- Node.js 20.x LTS
- Node.js 21.x (Current)

**Usage:**
```bash
# Create project
mkdir myapp && cd myapp
npm init -y

# Install package
npm install express

# Run with PM2
pm2 start app.js
pm2 save
pm2 startup
```

### Python (setup-python.sh)

**What Gets Installed:**
- Python 3.x (system default)
- pip package manager
- virtualenv
- Development tools (optional)
- Example virtual environment

**Supported Versions:**
- Python 3.11
- Python 3.10
- Python 3 (system default)
- Python 2 (legacy - optional)

**Usage:**
```bash
# Create virtual environment
python3 -m venv myenv
source myenv/bin/activate

# Install package
pip install flask

# Deactivate
deactivate
```

### SSL/Let's Encrypt (setup-ssl.sh)

**What Gets Installed:**
- Certbot
- Web server plugin (Nginx or Apache)
- Automatic renewal system
- Firewall rules

**Usage:**

For Nginx:
```bash
# Obtain SSL certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

For Apache:
```bash
# Obtain SSL certificate
sudo certbot --apache -d yourdomain.com -d www.yourdomain.com
```

Standalone (without web server):
```bash
# Stop web server
sudo systemctl stop nginx

# Obtain certificate
sudo certbot certonly --standalone -d yourdomain.com

# Start web server
sudo systemctl start nginx
```

**Management:**
```bash
# List certificates
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run

# Manual renewal
sudo certbot renew
```

## 🔒 Security Notes

### General Security

1. **Strong Passwords**: Auto-generated passwords can be found in `/root/` directory
2. **Firewall**: Scripts automatically add rules if UFW is active
3. **Updates**: Regularly run `apt-get update && apt-get upgrade`
4. **SSH**: Consider disabling root SSH access
5. **Fail2ban**: Consider installing to prevent brute-force attacks

### Database Security

- Root passwords are auto-generated and stored in secure files
- Databases are bound to localhost by default
- Remote access is disabled
- Copy password files to a secure location and delete them:

```bash
# Copy the password
cat /root/.mysql_credentials

# Save to a secure location, then delete
rm /root/.mysql_credentials
```

### Web Server Security

- Unnecessary modules are disabled
- Server signatures are hidden
- Secure default configurations
- Update regularly

### SSL/TLS Security

- Let's Encrypt certificates auto-renew
- Modern TLS protocols are used
- Configure certificates for port 443

## 🔧 Troubleshooting

### Common Issues

**Problem**: "Permission denied" error
```bash
# Solution: Run with sudo
sudo bash setup-nginx.sh
```

**Problem**: "Port already in use" error
```bash
# Solution: Check which service is using the port
sudo lsof -i :80
sudo ss -tlnp | grep :80

# Stop the service
sudo systemctl stop apache2
```

**Problem**: Package installation errors
```bash
# Solution: Fix package manager
sudo dpkg --configure -a
sudo apt-get install -f
sudo apt-get update
```

### Service Won't Start

```bash
# Check status
sudo systemctl status nginx

# Check logs
sudo journalctl -xe

# Test configuration
sudo nginx -t
sudo apache2ctl configtest
```

### Database Connection Issues

```bash
# Check if service is running
sudo systemctl status mysql

# Check logs
sudo tail -f /var/log/mysql/error.log

# Check socket file
ls -la /var/run/mysqld/mysqld.sock
```

### PHP Not Working

```bash
# Check PHP version
php -v

# Check PHP-FPM status
sudo systemctl status php8.2-fpm

# Check PHP modules (Apache)
sudo apache2ctl -M | grep php

# Check Nginx PHP configuration
sudo nginx -t
```

## 📝 Log Files

If you experience issues, check these log files:

- **Nginx**: `/var/log/nginx/error.log`
- **Apache**: `/var/log/apache2/error.log`
- **MySQL**: `/var/log/mysql/error.log`
- **MariaDB**: `/var/log/mysql/error.log`
- **Redis**: `/var/log/redis/redis-server.log`
- **PHP-FPM**: `/var/log/php8.2-fpm.log`
- **System**: `sudo journalctl -xe`

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Contribution Guidelines

- Each script should work standalone
- Add comprehensive error checking
- Comment your code
- Update README
- Test on Ubuntu 20.04, 22.04, and 24.04

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Ubuntu community
- All open-source project contributors
- Everyone who uses these scripts and provides feedback

## 🔗 Useful Links

- [Ubuntu Documentation](https://help.ubuntu.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Apache Documentation](https://httpd.apache.org/docs/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [PHP Documentation](https://www.php.net/docs.php)
- [Node.js Documentation](https://nodejs.org/docs/)
- [Python Documentation](https://docs.python.org/)
- [Let's Encrypt](https://letsencrypt.org/docs/)

---

⭐ Don't forget to star this project if you find it useful!
