#!/bin/bash

# NodeJS Setup Script for Ubuntu
# Run with: sudo bash setup-nodejs.sh
# Developed By Egemen KEYDAL

echo "================================"
echo "NodeJS Installation Started"
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
apt-get install -y curl wget gnupg2 ca-certificates lsb-release apt-transport-https

# Check if Node.js is already installed
if command -v node &> /dev/null; then
    echo "Node.js is already installed"
    node --version
    npm --version
    read -p "Do you want to reinstall? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping installation"
        exit 0
    fi
fi

# Choose Node.js version
echo ""
echo "Choose Node.js version to install:"
echo "1) LTS (Long Term Support - Recommended)"
echo "2) Current (Latest features)"
echo "3) Node.js 18.x LTS"
echo "4) Node.js 20.x LTS"
echo "5) Node.js 21.x (Current)"
read -p "Enter choice [1-5]: " -n 1 -r NODE_CHOICE
echo ""

case $NODE_CHOICE in
    1)
        NODE_VERSION="lts"
        NODE_MAJOR=20
        ;;
    2)
        NODE_VERSION="current"
        NODE_MAJOR=21
        ;;
    3)
        NODE_VERSION="18.x"
        NODE_MAJOR=18
        ;;
    4)
        NODE_VERSION="20.x"
        NODE_MAJOR=20
        ;;
    5)
        NODE_VERSION="21.x"
        NODE_MAJOR=21
        ;;
    *)
        echo "Invalid choice, defaulting to LTS"
        NODE_VERSION="lts"
        NODE_MAJOR=20
        ;;
esac

# Add NodeSource repository
echo "Adding NodeSource repository for Node.js ${NODE_MAJOR}.x..."
if ! curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash -; then
    handle_error "Failed to add NodeSource repository"
    # Try alternative method
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg
    echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    apt-get update
fi

# Install Node.js
echo "Installing Node.js..."
if ! apt-get install -y nodejs; then
    handle_error "Node.js installation failed"
    apt-get install -f -y
    apt-get install -y nodejs
fi

# Verify Node.js installation
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js installation failed"
    exit 1
fi

# Verify npm installation
if ! command -v npm &> /dev/null; then
    echo "npm not found, installing separately..."
    apt-get install -y npm
fi

# Install build essentials for native modules
echo "Installing build tools for native Node modules..."
apt-get install -y build-essential

# Update npm to latest version
echo "Updating npm to latest version..."
if ! npm install -g npm@latest; then
    handle_error "npm update failed"
    # Try clearing npm cache
    npm cache clean --force
    npm install -g npm@latest
fi

# Install useful global packages
echo ""
read -p "Install useful global packages (yarn, pm2, nodemon)? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing global packages..."

    # Install Yarn
    if ! npm install -g yarn; then
        echo "Warning: Yarn installation failed"
    else
        echo "Yarn installed: $(yarn --version)"
    fi

    # Install PM2
    if ! npm install -g pm2; then
        echo "Warning: PM2 installation failed"
    else
        echo "PM2 installed: $(pm2 --version)"
        # Setup PM2 startup script
        env PATH=$PATH:/usr/bin pm2 startup systemd -u root --hp /root
    fi

    # Install Nodemon
    if ! npm install -g nodemon; then
        echo "Warning: Nodemon installation failed"
    else
        echo "Nodemon installed: $(nodemon --version)"
    fi
fi

# Fix npm permissions for global installs
echo "Configuring npm permissions..."
mkdir -p /usr/local/lib/node_modules
chown -R root:root /usr/local/lib/node_modules
chmod -R 755 /usr/local/lib/node_modules

# Create a test project directory
TEST_DIR="/opt/nodejs-test"
if [ ! -d "$TEST_DIR" ]; then
    mkdir -p "$TEST_DIR"
    cat > "$TEST_DIR/hello.js" << 'EOF'
// Simple Node.js test script
const http = require('http');

const hostname = '127.0.0.1';
const port = 3000;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/html');
  res.end('<h1>Hello from Node.js!</h1><p>Node.js is working correctly.</p>');
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});
EOF

    cat > "$TEST_DIR/package.json" << 'EOF'
{
  "name": "nodejs-test",
  "version": "1.0.0",
  "description": "Node.js test application",
  "main": "hello.js",
  "scripts": {
    "start": "node hello.js"
  }
}
EOF
fi

# Display status
echo ""
echo "================================"
echo "NodeJS Installation Complete!"
echo "================================"
echo "Node.js version:"
node --version
echo ""
echo "npm version:"
npm --version
echo ""

# Check for installed global packages
if command -v yarn &> /dev/null; then
    echo "Yarn version:"
    yarn --version
fi

if command -v pm2 &> /dev/null; then
    echo "PM2 version:"
    pm2 --version
fi

if command -v nodemon &> /dev/null; then
    echo "Nodemon version:"
    nodemon --version
fi

echo ""
echo "Global npm packages location: $(npm root -g)"
echo "Node.js binary: $(which node)"
echo "npm binary: $(which npm)"
echo ""
echo "Test application created at: $TEST_DIR"
echo "Run test server: cd $TEST_DIR && npm start"
echo ""
echo "Useful commands:"
echo "  node --version              # Check Node.js version"
echo "  npm --version               # Check npm version"
echo "  npm install <package>       # Install package locally"
echo "  npm install -g <package>    # Install package globally"
echo "  npm list -g --depth=0       # List global packages"
echo "  npm init                    # Initialize new project"
echo "  npm start                   # Run start script"
echo "  npm test                    # Run test script"
echo ""

if command -v pm2 &> /dev/null; then
    echo "PM2 Process Manager commands:"
    echo "  pm2 start app.js            # Start application"
    echo "  pm2 list                    # List applications"
    echo "  pm2 stop <app>              # Stop application"
    echo "  pm2 restart <app>           # Restart application"
    echo "  pm2 logs                    # View logs"
    echo "  pm2 monit                   # Monitor applications"
    echo ""
fi

if command -v yarn &> /dev/null; then
    echo "Yarn Package Manager commands:"
    echo "  yarn init                   # Initialize project"
    echo "  yarn add <package>          # Add package"
    echo "  yarn remove <package>       # Remove package"
    echo "  yarn install                # Install dependencies"
    echo ""
fi

echo "Get started:"
echo "  mkdir my-app && cd my-app"
echo "  npm init -y"
echo "  npm install express"
echo "  echo 'console.log(\"Hello Node.js!\")' > index.js"
echo "  node index.js"
