#!/bin/bash

# PHP Setup Script for Ubuntu
# Run with: sudo bash setup-php.sh
# Developed By Egemen KEYDAL

echo "================================"
echo "PHP Installation Started"
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

# Install prerequisites
echo "Installing prerequisites..."
apt-get install -y software-properties-common ca-certificates apt-transport-https

# Check if PHP is already installed
if command -v php &> /dev/null; then
    echo "PHP is already installed: $(php -v | head -n 1)"
    read -p "Do you want to reinstall/add another version? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping installation"
        exit 0
    fi
fi

# Choose PHP version
echo ""
echo "Choose PHP version to install:"
echo "1) PHP 8.3 (Latest)"
echo "2) PHP 8.2 (Stable)"
echo "3) PHP 8.1"
echo "4) PHP 7.4 (Legacy)"
echo "5) Multiple versions (8.1, 8.2, 8.3)"
read -p "Enter choice [1-5]: " -n 1 -r PHP_CHOICE
echo ""

case $PHP_CHOICE in
    1)
        PHP_VERSIONS=("8.3")
        ;;
    2)
        PHP_VERSIONS=("8.2")
        ;;
    3)
        PHP_VERSIONS=("8.1")
        ;;
    4)
        PHP_VERSIONS=("7.4")
        ;;
    5)
        PHP_VERSIONS=("8.1" "8.2" "8.3")
        ;;
    *)
        echo "Invalid choice, defaulting to PHP 8.2"
        PHP_VERSIONS=("8.2")
        ;;
esac

# Add Ondřej Surý's PPA for PHP
echo "Adding PHP repository..."
if ! add-apt-repository -y ppa:ondrej/php; then
    handle_error "Failed to add PHP repository"
    # Try manual method
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
fi

if ! apt-get update; then
    handle_error "apt-get update failed after adding repository"
    apt-get update --fix-missing
fi

# Detect web server
WEB_SERVER="none"
if systemctl is-active --quiet apache2; then
    WEB_SERVER="apache"
    echo "Apache detected"
elif systemctl is-active --quiet nginx; then
    WEB_SERVER="nginx"
    echo "Nginx detected"
fi

# Install PHP versions
for PHP_VERSION in "${PHP_VERSIONS[@]}"; do
    echo ""
    echo "Installing PHP ${PHP_VERSION}..."

    # Core PHP package
    if ! apt-get install -y php${PHP_VERSION}; then
        handle_error "PHP ${PHP_VERSION} installation failed"
        apt-get install -f -y
        apt-get install -y php${PHP_VERSION}
    fi

    # Install CLI
    apt-get install -y php${PHP_VERSION}-cli

    # Install web server module
    if [ "$WEB_SERVER" = "apache" ]; then
        echo "Installing Apache module for PHP ${PHP_VERSION}..."
        apt-get install -y libapache2-mod-php${PHP_VERSION}
    elif [ "$WEB_SERVER" = "nginx" ]; then
        echo "Installing PHP-FPM for Nginx (PHP ${PHP_VERSION})..."
        apt-get install -y php${PHP_VERSION}-fpm
    else
        echo "No web server detected, installing PHP-FPM..."
        apt-get install -y php${PHP_VERSION}-fpm
    fi

    # Install common PHP extensions
    echo "Installing common PHP extensions for ${PHP_VERSION}..."
    EXTENSIONS=(
        "mysql"
        "curl"
        "gd"
        "mbstring"
        "xml"
        "zip"
        "bcmath"
        "json"
        "intl"
        "soap"
        "xmlrpc"
        "opcache"
        "readline"
    )

    for ext in "${EXTENSIONS[@]}"; do
        apt-get install -y php${PHP_VERSION}-${ext} 2>/dev/null || echo "Extension ${ext} not available for PHP ${PHP_VERSION}"
    done

    # Enable PHP-FPM if installed
    if systemctl list-unit-files | grep -q "php${PHP_VERSION}-fpm"; then
        systemctl enable php${PHP_VERSION}-fpm
        systemctl start php${PHP_VERSION}-fpm
    fi
done

# Set default PHP version (first in array)
DEFAULT_PHP="${PHP_VERSIONS[0]}"
echo ""
echo "Setting PHP ${DEFAULT_PHP} as default..."
update-alternatives --set php /usr/bin/php${DEFAULT_PHP}

# If Apache is installed, enable the module
if [ "$WEB_SERVER" = "apache" ]; then
    echo "Configuring Apache for PHP ${DEFAULT_PHP}..."

    # Disable other PHP modules
    a2dismod php* 2>/dev/null || true

    # Enable selected PHP module
    a2enmod php${DEFAULT_PHP}

    # Restart Apache
    if ! systemctl restart apache2; then
        handle_error "Failed to restart Apache"
        apache2ctl configtest
        systemctl restart apache2
    fi
fi

# If Nginx is installed, configure it
if [ "$WEB_SERVER" = "nginx" ]; then
    echo "Configuring Nginx for PHP-FPM..."

    # Create PHP-FPM configuration for Nginx
    NGINX_PHP_CONF="/etc/nginx/snippets/php-fpm.conf"
    cat > "$NGINX_PHP_CONF" << EOF
# PHP-FPM Configuration
location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/var/run/php/php${DEFAULT_PHP}-fpm.sock;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include fastcgi_params;
}
EOF

    echo "PHP-FPM configuration created at: $NGINX_PHP_CONF"
    echo "Include it in your site config with: include snippets/php-fpm.conf;"

    # Restart Nginx
    if ! systemctl restart nginx; then
        handle_error "Failed to restart Nginx"
        nginx -t
        systemctl restart nginx
    fi
fi

# Install Composer
echo ""
read -p "Install Composer (PHP package manager)? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing Composer..."

    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        echo "ERROR: Invalid Composer installer checksum"
        rm composer-setup.php
    else
        php composer-setup.php --install-dir=/usr/local/bin --filename=composer
        rm composer-setup.php
        echo "Composer installed successfully"
    fi
fi

# Optimize PHP configuration
echo ""
read -p "Optimize PHP configuration for production? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for PHP_VERSION in "${PHP_VERSIONS[@]}"; do
        PHP_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"
        CLI_INI="/etc/php/${PHP_VERSION}/cli/php.ini"

        if [ -f "$PHP_INI" ]; then
            echo "Optimizing PHP ${PHP_VERSION} FPM configuration..."
            cp "$PHP_INI" "${PHP_INI}.backup"

            sed -i 's/^upload_max_filesize.*/upload_max_filesize = 64M/' "$PHP_INI"
            sed -i 's/^post_max_size.*/post_max_size = 64M/' "$PHP_INI"
            sed -i 's/^memory_limit.*/memory_limit = 256M/' "$PHP_INI"
            sed -i 's/^max_execution_time.*/max_execution_time = 300/' "$PHP_INI"
            sed -i 's/^;opcache.enable=.*/opcache.enable=1/' "$PHP_INI"
            sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=128/' "$PHP_INI"

            systemctl restart php${PHP_VERSION}-fpm 2>/dev/null || true
        fi
    done

    [ "$WEB_SERVER" = "apache" ] && systemctl restart apache2
    [ "$WEB_SERVER" = "nginx" ] && systemctl restart nginx
fi

# Create test PHP files
TEST_DIR="/var/www/html"
if [ -d "$TEST_DIR" ]; then
    echo "Creating PHP test files..."

    cat > "$TEST_DIR/info.php" << 'EOF'
<?php
phpinfo();
?>
EOF

    cat > "$TEST_DIR/test.php" << 'EOF'
<?php
echo "<html><head><title>PHP Test</title></head><body>";
echo "<h1>PHP is working!</h1>";
echo "<p><strong>PHP Version:</strong> " . phpversion() . "</p>";
echo "<p><strong>Server Software:</strong> " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
echo "<p><strong>Document Root:</strong> " . $_SERVER['DOCUMENT_ROOT'] . "</p>";

echo "<h2>Loaded Extensions:</h2><ul>";
$extensions = get_loaded_extensions();
sort($extensions);
foreach($extensions as $ext) {
    echo "<li>$ext</li>";
}
echo "</ul>";

echo "<p><a href='info.php'>View Full PHP Info</a></p>";
echo "</body></html>";
?>
EOF

    chmod 644 "$TEST_DIR/info.php" "$TEST_DIR/test.php"
fi

# Display status
echo ""
echo "================================"
echo "PHP Installation Complete!"
echo "================================"

for PHP_VERSION in "${PHP_VERSIONS[@]}"; do
    if command -v php${PHP_VERSION} &> /dev/null; then
        echo "PHP ${PHP_VERSION}: $(php${PHP_VERSION} -v | head -n 1)"
    fi
done

echo ""
echo "Default PHP version:"
php -v | head -n 1

echo ""
echo "Active PHP CLI: $(which php)"

if [ "$WEB_SERVER" = "apache" ]; then
    echo "Web server: Apache with mod_php${DEFAULT_PHP}"
    echo "Apache modules:"
    apache2ctl -M | grep php
elif [ "$WEB_SERVER" = "nginx" ]; then
    echo "Web server: Nginx with PHP-FPM"
    echo "PHP-FPM services:"
    systemctl list-units --type=service | grep php.*fpm
fi

if command -v composer &> /dev/null; then
    echo ""
    echo "Composer version:"
    composer --version
fi

echo ""
echo "Configuration files:"
for PHP_VERSION in "${PHP_VERSIONS[@]}"; do
    echo "  PHP ${PHP_VERSION} FPM: /etc/php/${PHP_VERSION}/fpm/php.ini"
    echo "  PHP ${PHP_VERSION} CLI: /etc/php/${PHP_VERSION}/cli/php.ini"
done

echo ""
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Test PHP:"
echo "  http://${SERVER_IP}/test.php"
echo "  http://${SERVER_IP}/info.php"

echo ""
echo "Useful commands:"
echo "  php -v                      # Check PHP version"
echo "  php -m                      # List loaded modules"
echo "  php -i                      # PHP configuration info"
echo "  php -r 'phpinfo();'         # Quick PHP info"
echo ""
echo "Switch PHP versions:"
echo "  update-alternatives --config php"
echo ""

if [ "$WEB_SERVER" = "apache" ]; then
    echo "Apache PHP module commands:"
    echo "  a2dismod php8.2 && a2enmod php8.3  # Switch PHP version"
    echo "  systemctl restart apache2           # Restart Apache"
fi

if [ "$WEB_SERVER" = "nginx" ]; then
    echo "PHP-FPM commands:"
    echo "  systemctl status php${DEFAULT_PHP}-fpm"
    echo "  systemctl restart php${DEFAULT_PHP}-fpm"
    echo "  tail -f /var/log/php${DEFAULT_PHP}-fpm.log"
fi

if command -v composer &> /dev/null; then
    echo ""
    echo "Composer commands:"
    echo "  composer init               # Initialize project"
    echo "  composer require <package>  # Install package"
    echo "  composer install            # Install dependencies"
    echo "  composer update             # Update dependencies"
fi

echo ""
echo "Get started:"
echo "  cd /var/www/html"
echo "  echo '<?php echo \"Hello PHP!\"; ?>' > hello.php"
echo "  curl http://localhost/hello.php"
