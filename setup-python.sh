#!/bin/bash

# Python Setup Script for Ubuntu
# Run with: sudo bash setup-python.sh
# Developed By Egemen KEYDAL

echo "================================"
echo "Python Installation Started"
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

# Check current Python versions
echo "Checking for existing Python installations..."
if command -v python3 &> /dev/null; then
    echo "Python3 is already installed: $(python3 --version)"
fi
if command -v python &> /dev/null; then
    echo "Python is available: $(python --version)"
fi

# Choose Python version
echo ""
echo "Choose installation type:"
echo "1) Python 3 (Default system version - Recommended)"
echo "2) Python 3 + Python 2 (Legacy support)"
echo "3) Python 3.11 (Latest stable)"
echo "4) Python 3.10"
echo "5) All versions (2, 3.10, 3.11)"
read -p "Enter choice [1-5]: " -n 1 -r PYTHON_CHOICE
echo ""

case $PYTHON_CHOICE in
    2)
        INSTALL_PY2=true
        INSTALL_PY3=true
        ;;
    3)
        INSTALL_PY311=true
        ;;
    4)
        INSTALL_PY310=true
        ;;
    5)
        INSTALL_PY2=true
        INSTALL_PY310=true
        INSTALL_PY311=true
        ;;
    *)
        INSTALL_PY3=true
        ;;
esac

# Install build dependencies
echo "Installing build dependencies..."
if ! apt-get install -y software-properties-common build-essential libssl-dev libffi-dev; then
    handle_error "Failed to install dependencies"
    apt-get install -f -y
    apt-get install -y software-properties-common build-essential libssl-dev libffi-dev
fi

# Install Python 3 (default)
if [ "$INSTALL_PY3" = true ]; then
    echo "Installing Python 3..."
    if ! apt-get install -y python3 python3-pip python3-dev python3-venv; then
        handle_error "Python 3 installation failed"
        apt-get install -f -y
        apt-get install -y python3 python3-pip python3-dev python3-venv
    fi
fi

# Install Python 3.10
if [ "$INSTALL_PY310" = true ]; then
    echo "Adding deadsnakes PPA for Python 3.10..."
    add-apt-repository -y ppa:deadsnakes/ppa
    apt-get update

    echo "Installing Python 3.10..."
    if ! apt-get install -y python3.10 python3.10-venv python3.10-dev; then
        handle_error "Python 3.10 installation failed"
        apt-get install -f -y
        apt-get install -y python3.10 python3.10-venv python3.10-dev
    fi
fi

# Install Python 3.11
if [ "$INSTALL_PY311" = true ]; then
    echo "Adding deadsnakes PPA for Python 3.11..."
    add-apt-repository -y ppa:deadsnakes/ppa
    apt-get update

    echo "Installing Python 3.11..."
    if ! apt-get install -y python3.11 python3.11-venv python3.11-dev; then
        handle_error "Python 3.11 installation failed"
        apt-get install -f -y
        apt-get install -y python3.11 python3.11-venv python3.11-dev
    fi
fi

# Install Python 2 (if requested)
if [ "$INSTALL_PY2" = true ]; then
    echo "Installing Python 2..."
    if ! apt-get install -y python2 python2-dev; then
        echo "Warning: Python 2 installation failed (may not be available in newer Ubuntu versions)"
    else
        # Install pip for Python 2
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o /tmp/get-pip.py
        python2 /tmp/get-pip.py
        rm /tmp/get-pip.py
    fi
fi

# Verify Python 3 installation
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 installation failed"
    exit 1
fi

# Install/upgrade pip for Python 3
echo "Installing/upgrading pip..."
if ! python3 -m pip install --upgrade pip; then
    handle_error "pip upgrade failed"
    apt-get install -y python3-pip --reinstall
    python3 -m pip install --upgrade pip
fi

# Install essential Python packages
echo ""
read -p "Install essential Python packages (virtualenv, wheel, setuptools)? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing essential packages..."

    python3 -m pip install --upgrade virtualenv wheel setuptools

    # Install additional useful packages
    read -p "Install development tools (pylint, black, pytest, ipython)? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        python3 -m pip install pylint black pytest ipython requests
    fi
fi

# Create python symlink if it doesn't exist
if ! command -v python &> /dev/null; then
    echo "Creating python symlink..."
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1
fi

# Set up virtual environment example
VENV_DIR="/opt/python-venv-example"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating example virtual environment..."
    python3 -m venv "$VENV_DIR"

    cat > "$VENV_DIR/README.txt" << 'EOF'
Python Virtual Environment Example
===================================

To activate this virtual environment:
  source /opt/python-venv-example/bin/activate

To deactivate:
  deactivate

To install packages in this environment:
  source /opt/python-venv-example/bin/activate
  pip install <package-name>

To create your own virtual environment:
  python3 -m venv /path/to/your/venv
  source /path/to/your/venv/bin/activate
EOF
fi

# Create a test Python script
TEST_DIR="/opt/python-test"
mkdir -p "$TEST_DIR"
cat > "$TEST_DIR/hello.py" << 'EOF'
#!/usr/bin/env python3
"""
Simple Python test script
Run with: python3 hello.py
"""

import sys
import platform

def main():
    print("=" * 50)
    print("Hello from Python!")
    print("=" * 50)
    print(f"Python version: {sys.version}")
    print(f"Python executable: {sys.executable}")
    print(f"Platform: {platform.platform()}")
    print(f"Architecture: {platform.machine()}")
    print("=" * 50)
    print("\nPython is working correctly!")

if __name__ == "__main__":
    main()
EOF

chmod +x "$TEST_DIR/hello.py"

# Create a simple HTTP server example
cat > "$TEST_DIR/webserver.py" << 'EOF'
#!/usr/bin/env python3
"""
Simple HTTP server example
Run with: python3 webserver.py
Access at: http://localhost:8000
"""

from http.server import HTTPServer, SimpleHTTPRequestHandler
import sys

class MyHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            html = """
            <!DOCTYPE html>
            <html>
            <head><title>Python HTTP Server</title></head>
            <body style="font-family: Arial; text-align: center; padding: 50px;">
                <h1>Python HTTP Server is Running!</h1>
                <p>Python version: {}</p>
            </body>
            </html>
            """.format(sys.version)
            self.wfile.write(html.encode())
        else:
            super().do_GET()

def run(port=8000):
    server_address = ('', port)
    httpd = HTTPServer(server_address, MyHandler)
    print(f"Server running at http://localhost:{port}/")
    print("Press Ctrl+C to stop")
    httpd.serve_forever()

if __name__ == '__main__':
    run()
EOF

chmod +x "$TEST_DIR/webserver.py"

# Display status
echo ""
echo "================================"
echo "Python Installation Complete!"
echo "================================"

# Show installed versions
if command -v python3 &> /dev/null; then
    echo "Python 3: $(python3 --version)"
    echo "  Location: $(which python3)"
fi

if command -v python3.10 &> /dev/null; then
    echo "Python 3.10: $(python3.10 --version)"
fi

if command -v python3.11 &> /dev/null; then
    echo "Python 3.11: $(python3.11 --version)"
fi

if command -v python2 &> /dev/null; then
    echo "Python 2: $(python2 --version)"
fi

if command -v python &> /dev/null; then
    echo "Default python: $(python --version)"
fi

echo ""
echo "pip version:"
python3 -m pip --version

echo ""
echo "Installed packages:"
python3 -m pip list | head -10

echo ""
echo "Virtual environment example: $VENV_DIR"
echo "Test scripts location: $TEST_DIR"
echo ""
echo "Run test script:"
echo "  python3 $TEST_DIR/hello.py"
echo ""
echo "Run test web server:"
echo "  python3 $TEST_DIR/webserver.py"
echo ""
echo "Useful commands:"
echo "  python3 --version           # Check Python version"
echo "  pip3 --version              # Check pip version"
echo "  pip3 install <package>      # Install package"
echo "  pip3 list                   # List installed packages"
echo "  pip3 freeze > requirements.txt  # Save dependencies"
echo "  pip3 install -r requirements.txt  # Install from file"
echo ""
echo "Virtual Environment commands:"
echo "  python3 -m venv myenv       # Create virtual environment"
echo "  source myenv/bin/activate   # Activate environment"
echo "  deactivate                  # Deactivate environment"
echo ""
echo "Python REPL:"
echo "  python3                     # Start interactive Python"
echo "  ipython                     # Start IPython (if installed)"
echo ""
echo "Alternative Python versions:"
echo "  update-alternatives --config python3  # Switch default python3"
echo ""
echo "Get started:"
echo "  mkdir my-project && cd my-project"
echo "  python3 -m venv venv"
echo "  source venv/bin/activate"
echo "  pip install requests"
echo "  echo 'print(\"Hello World!\")' > hello.py"
echo "  python hello.py"
