#!/usr/bin/bash

############################
### Colors
############################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

#############################
### Variables
#############################

# Port Configuration:
### RETICULUM_PORT (4242): TCP port Reticulum listens on for VPS backbone 
### OR whichever port you have specified. you may need to update ~/.reticulum/config 

### MESHCHAT_PORT (8000): Local web UI port for MeshChat on each node
#   This is always localhost only, not exposed to network

### WireGuard (51820): VPN tunnel port, configured separately in WireGuard config
### Change if needed 

RETICULUM_PORT=4242  # TCP port for Reticulum on VPS backbone
MESHCHAT_PORT=8000   # MeshChat web UI (localhost only, not used in config)
MESHCHAT_REPO="${MESHCHAT_REPO:-https://github.com/liamcottle/reticulum-meshchat}"
MESHCHAT_BRANCH="${MESHCHAT_BRANCH:-master}"
INSTALL_DIR="/opt/reticulum-meshchat"
INSTALL_LOG="/tmp/rns_install_$(date +%Y%m%d_%H%M%S).log"

# OS detection variable
OS_TYPE=""

# Get user who ran sudo, avoids installing everything in root
if [ -n "$SUDO_USER" ]; then
    TARGET_USER="$SUDO_USER"
    USER_HOME=$(eval echo ~"$SUDO_USER")
else
    TARGET_USER="$USER"
    USER_HOME="$HOME"
fi

# WireGuard config (replaced by key_baker.sh if using VPS backbone)
WG_PRIVATE_KEY="__REPLACE_PRIVATE_KEY__"
WG_PUBLIC_KEY="__REPLACE_PUBLIC_KEY__"
WG_CLIENT_IP="__REPLACE_CLIENT_IP__"
WG_SERVER_PUBLIC_KEY="__REPLACE_SERVER_PUBLIC_KEY__"
WG_ENDPOINT="__REPLACE_ENDPOINT__"
WG_INTERNAL_IP="__REPLACE_INTERNAL_IP__"

# Track if user wants VPS backbone
VPS_BACKBONE=""

# Track installation state for cleanup
INSTALLATION_STARTED=false
PACKAGES_INSTALLED=false
MESHCHAT_CLONED=false
SERVICES_CREATED=false

# Debian/Ubuntu packages
DEBIAN_PACKAGES=(
    "python3" 
    "python3-pip" 
    "python3-setuptools" 
    "python3-wheel"
    "python3-dev"
    "python3-venv"
    "git" 
    "curl" 
    "nodejs" 
    "npm"
    "wget" 
    "build-essential" 
    "libffi-dev" 
    "libssl-dev" 
)

# Arch Linux packages
ARCH_PACKAGES=(
    "python"
    "python-pip"
    "python-setuptools"
    "python-wheel"
    "git"
    "curl"
    "nodejs"
    "npm"
    "wget"
    "base-devel"
    "libffi"
    "openssl"
)

# Optional packages for VPS backbone
DEBIAN_VPS_PACKAGES=(
    "wireguard"
    "resolvconf"
)

ARCH_VPS_PACKAGES=(
    "wireguard-tools"
    "openresolv"
)

# Optional packages for desktop shortcuts
DEBIAN_DESKTOP_PACKAGES=(
    "firefox"
    "gnome-terminal"
)

ARCH_DESKTOP_PACKAGES=(
    "firefox"
    "gnome-terminal"
)

# Python packages (same for both)
PYTHON_PACKAGES=(
    "rns"
    "nomadnet"
    "lxmf"
    "aiohttp"
    "peewee"
    "websockets"
    "pyserial"
    "cx_freeze"
)

# Binary paths
RNS_BIN=""
NOMADNET_BIN=""
PYTHON_BIN=""

#############################
# Functions
#############################

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$INSTALL_LOG"
}

cleanup_on_failure() {
    echo -e "${RED}Installation failed, cleaning up...${NC}"
    log_message "ERROR: Installation failed, running cleanup"
    
    if [ "$SERVICES_CREATED" = true ]; then
        systemctl stop reticulum meshchat 2>/dev/null || true
        systemctl disable reticulum meshchat 2>/dev/null || true
        rm -f /etc/systemd/system/reticulum.service
        rm -f /etc/systemd/system/meshchat.service
        systemctl daemon-reload
        log_message "Cleaned up systemd services"
    fi
    
    if [ "$MESHCHAT_CLONED" = true ] && [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}MeshChat directory left at $INSTALL_DIR for inspection${NC}"
        log_message "Left MeshChat directory for inspection"
    fi
    
    echo -e "${YELLOW}Installation log saved to: $INSTALL_LOG${NC}"
    echo -e "${YELLOW}Review the log for details about the failure${NC}"
    
    exit 1
}

detect_os() {
    if [ -f /etc/arch-release ]; then
        echo -e "${BLUE}Detected: Arch Linux${NC}"
        OS_TYPE="arch"
        log_message "Detected OS: Arch Linux"
    elif [ -f /etc/debian_version ]; then
        echo -e "${BLUE}Detected: Debian/Ubuntu${NC}"
        OS_TYPE="debian"
        log_message "Detected OS: Debian/Ubuntu"
    else
        echo -e "${RED}Unsupported OS. This script supports Debian/Ubuntu and Arch Linux${NC}"
        log_message "ERROR: Unsupported OS detected"
        exit 1
    fi
}

detect_binary_paths() {
    echo -e "${BLUE}Detecting binary paths...${NC}"
    
    PYTHON_BIN=$(which python3 2>/dev/null || which python 2>/dev/null) || {
        echo -e "${RED}Python not found in PATH${NC}"
        log_message "ERROR: Python not found"
        exit 1
    }
    
    echo -e "${GREEN}Python: $PYTHON_BIN${NC}"
    log_message "Python binary: $PYTHON_BIN"
}

check_package_installed() {
    local package="$1"
    
    if [ "$OS_TYPE" = "debian" ]; then
        dpkg -l "$package" &>/dev/null
    else
        pacman -Qi "$package" &>/dev/null
    fi
}

check_disk_space() {
    local required_mb=2048
    local available_mb=$(df /opt | awk 'NR==2 {print int($4/1024)}')
    
    if [ "$available_mb" -lt "$required_mb" ]; then
        echo -e "${RED}Insufficient disk space${NC}"
        echo -e "${YELLOW}Required: ${required_mb}MB, Available: ${available_mb}MB${NC}"
        log_message "ERROR: Insufficient disk space: ${available_mb}MB available, ${required_mb}MB required"
        exit 1
    fi
    
    log_message "Disk space check passed: ${available_mb}MB available"
}

install_system_packages() {
    local packages=("$@")
    local to_install=()
    
    echo -e "${BLUE}Checking system packages...${NC}"
    log_message "Checking system packages"
    
    for package in "${packages[@]}"; do
        if check_package_installed "$package"; then
            echo -e "${GREEN}Installed: $package${NC}"
        else
            echo -e "${YELLOW}Will install: $package${NC}"
            to_install+=("$package")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        echo -e "${PURPLE}Installing ${#to_install[@]} packages...${NC}"
        log_message "Installing packages: ${to_install[*]}"
        
        if [ "$OS_TYPE" = "debian" ]; then
            apt-get update >> "$INSTALL_LOG" 2>&1 || {
                echo -e "${RED}Failed to update package list${NC}"
                log_message "ERROR: apt-get update failed"
                cleanup_on_failure
            }
            
            apt-get install -y "${to_install[@]}" >> "$INSTALL_LOG" 2>&1 || {
                echo -e "${RED}Failed to install system packages${NC}"
                echo -e "${YELLOW}Check log: $INSTALL_LOG${NC}"
                log_message "ERROR: apt-get install failed"
                cleanup_on_failure
            }
        else
            pacman -Sy --noconfirm >> "$INSTALL_LOG" 2>&1 || {
                echo -e "${RED}Failed to update package database${NC}"
                log_message "ERROR: pacman -Sy failed"
                cleanup_on_failure
            }
            
            pacman -S --noconfirm "${to_install[@]}" >> "$INSTALL_LOG" 2>&1 || {
                echo -e "${RED}Failed to install system packages${NC}"
                echo -e "${YELLOW}Check log: $INSTALL_LOG${NC}"
                log_message "ERROR: pacman -S failed"
                cleanup_on_failure
            }
        fi
        
        echo -e "${GREEN}System packages installed${NC}"
        log_message "System packages installed successfully"
        PACKAGES_INSTALLED=true
    else
        echo -e "${GREEN}All packages already installed${NC}"
        log_message "All system packages already installed"
    fi
}

bootstrap_pip() {
    echo -e "${BLUE}Checking pip...${NC}"
    log_message "Checking pip installation"
    
    if $PYTHON_BIN -m pip --version &>/dev/null; then
        echo -e "${GREEN}Pip is working${NC}"
        log_message "Pip is working"
        return 0
    fi
    
    echo -e "${YELLOW}Bootstrapping pip...${NC}"
    log_message "Bootstrapping pip"
    
    if [ "$OS_TYPE" = "debian" ]; then
        apt-get install -y --reinstall python3-pip python3-setuptools python3-wheel >> "$INSTALL_LOG" 2>&1 || true
        
        if $PYTHON_BIN -m pip --version &>/dev/null; then
            echo -e "${GREEN}Pip fixed${NC}"
            log_message "Pip fixed via package reinstall"
            return 0
        fi
        
        echo -e "${YELLOW}Downloading pip installer...${NC}"
        log_message "Downloading get-pip.py"
        curl -fsSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py >> "$INSTALL_LOG" 2>&1 || {
            echo -e "${RED}Failed to download pip installer${NC}"
            log_message "ERROR: Failed to download get-pip.py"
            cleanup_on_failure
        }
        
        $PYTHON_BIN /tmp/get-pip.py --break-system-packages --force-reinstall >> "$INSTALL_LOG" 2>&1 || {
            echo -e "${RED}Failed to install pip${NC}"
            log_message "ERROR: get-pip.py failed"
            cleanup_on_failure
        }
        
        rm -f /tmp/get-pip.py
    else
        pacman -S --noconfirm python-pip >> "$INSTALL_LOG" 2>&1 || {
            echo -e "${RED}Failed to install pip${NC}"
            log_message "ERROR: Failed to install pip on Arch"
            cleanup_on_failure
        }
    fi
    
    if ! $PYTHON_BIN -m pip --version &>/dev/null; then
        echo -e "${RED}Pip still not working${NC}"
        log_message "ERROR: Pip installation failed"
        cleanup_on_failure
    fi
    
    echo -e "${GREEN}Pip installed${NC}"
    log_message "Pip installed successfully"
}

ask_vps_backbone() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        VPS Backbone Setup${NC}"     
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}You can optionally connect this node to your VPS backbone.${NC}"
    echo -e "${YELLOW}This requires WireGuard credentials from your VPS deployment.${NC}"
    echo ""
    echo -e "${BLUE}Do you have VPN credentials for your backbone? (y/n)${NC}"
    read -r VPS_BACKBONE
    echo ""
    
    if [[ "$VPS_BACKBONE" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}VPS backbone mode enabled${NC}"
        log_message "User selected VPS backbone mode"
    else
        echo -e "${CYAN}Local mesh only mode${NC}"
        log_message "User selected local mesh only mode"
    fi
}

validate_wg_key() {
    local key="$1"
    local key_name="$2"
    
    # WireGuard keys are 44 characters of base64 (32 bytes encoded)
    if [[ ! "$key" =~ ^[A-Za-z0-9+/]{43}=$ ]] && [[ ! "$key" =~ ^[A-Za-z0-9+/]{44}$ ]]; then
        echo -e "${RED}Invalid WireGuard key format for $key_name${NC}"
        echo -e "${YELLOW}Keys should be 44 characters of base64${NC}"
        log_message "ERROR: Invalid WireGuard key format: $key_name"
        cleanup_on_failure
    fi
}

validate_ip() {
    local ip="$1"
    local ip_name="$2"
    
    # Validate RFC1918 private IP (10.x.x.x range)
    if [[ ! "$ip" =~ ^10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
        echo -e "${RED}Invalid IP for $ip_name: $ip${NC}"
        echo -e "${YELLOW}Must be in 10.x.x.x range${NC}"
        log_message "ERROR: Invalid IP: $ip_name = $ip"
        cleanup_on_failure
    fi
}


setup_wireguard() {
    if [[ ! "$VPS_BACKBONE" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Skipping WireGuard (VPS backbone not enabled)${NC}"
        log_message "Skipping WireGuard setup"
        return 0
    fi
    
    echo -e "${BLUE}Setting up WireGuard VPN for backbone...${NC}"
    log_message "Setting up WireGuard"
    
    if [[ "$WG_PRIVATE_KEY" == "__REPLACE_PRIVATE_KEY__" ]]; then
        echo -e "${RED}WireGuard keys not configured${NC}"
        echo -e "${YELLOW}You need to run key_baker.sh first to bake in your VPN credentials${NC}"
        echo -e "${YELLOW}Get credentials from your VPS deployment, then run:${NC}"
        echo -e "${CYAN}  ./key_baker.sh${NC}"
        log_message "ERROR: WireGuard keys not configured"
        cleanup_on_failure
    fi
    
    validate_wg_key "$WG_PRIVATE_KEY" "private key"
    validate_wg_key "$WG_SERVER_PUBLIC_KEY" "server public key"
    validate_ip "$WG_CLIENT_IP" "client IP"
    validate_ip "$WG_INTERNAL_IP" "server internal IP"
    
    # Extract VPN subnet from client IP automatically
    # Example: 10.5.5.10 -> 10.5.5.0/24
    local vpn_subnet=$(echo "$WG_CLIENT_IP" | cut -d'.' -f1-3).0/24
    
    echo -e "${BLUE}VPN subnet detected: $vpn_subnet${NC}"
    log_message "VPN subnet: $vpn_subnet"
    
    # Verify this won't conflict with existing network
    echo -e "${YELLOW}Checking for network conflicts...${NC}"
    
    # Get current IP addresses on all interfaces
    local existing_ips=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+' | grep -v '127.0.0.1')
    local vpn_network_prefix=$(echo "$vpn_subnet" | cut -d'.' -f1-3)
    
    # Check if any existing IP is in the same subnet as VPN
    local conflict=false
    while IFS= read -r existing_ip; do
        local existing_prefix=$(echo "$existing_ip" | cut -d'.' -f1-3)
        if [ "$existing_prefix" = "$vpn_network_prefix" ]; then
            conflict=true
            echo -e "${RED}WARNING: Network conflict detected${NC}"
            echo -e "${YELLOW}Your current network uses: $existing_ip${NC}"
            echo -e "${YELLOW}VPN wants to use subnet: $vpn_subnet${NC}"
            echo ""
            echo -e "${RED}This configuration will break your network connection${NC}"
            echo -e "${YELLOW}Please reconfigure your VPS to use a different subnet${NC}"
            echo -e "${CYAN}Suggested: Use 10.8.0.0/24 or 10.9.0.0/24 instead${NC}"
            log_message "ERROR: Network conflict - existing IP $existing_ip conflicts with VPN subnet $vpn_subnet"
            cleanup_on_failure
        fi
    done <<< "$existing_ips"
    
    if [ "$conflict" = false ]; then
        echo -e "${GREEN}No network conflicts detected${NC}"
        log_message "No network conflicts detected"
    fi
    
    mkdir -p /etc/wireguard
    
    if [ "$OS_TYPE" = "arch" ]; then
        cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_CLIENT_IP/24
Table = off

[Peer]
PublicKey = $WG_SERVER_PUBLIC_KEY
Endpoint = $WG_ENDPOINT
AllowedIPs = $vpn_subnet
PersistentKeepalive = 25
EOF
    else
        cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_CLIENT_IP/24
Table = off
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $WG_SERVER_PUBLIC_KEY
Endpoint = $WG_ENDPOINT
AllowedIPs = $vpn_subnet
PersistentKeepalive = 25
EOF
    fi

    chmod 600 /etc/wireguard/wg0.conf
    log_message "WireGuard config created with AllowedIPs=$vpn_subnet"
    
    echo -e "${GREEN}WireGuard configured${NC}"
    echo -e "${CYAN}  VPN subnet: $vpn_subnet${NC}"
    echo -e "${CYAN}  Client IP: $WG_CLIENT_IP${NC}"
    echo -e "${CYAN}  Server IP: $WG_INTERNAL_IP${NC}"
    
    systemctl enable wg-quick@wg0 >> "$INSTALL_LOG" 2>&1 || {
        echo -e "${RED}Failed to enable WireGuard${NC}"
        log_message "ERROR: Failed to enable WireGuard"
        cleanup_on_failure
    }
    
    if ! systemctl start wg-quick@wg0 >> "$INSTALL_LOG" 2>&1; then
        echo -e "${RED}Failed to start WireGuard${NC}"
        echo -e "${YELLOW}This might be a DNS conflict - checking...${NC}"
        systemctl status wg-quick@wg0 --no-pager -l
        echo -e "${YELLOW}WireGuard failed to start, but continuing installation...${NC}"
        echo -e "${YELLOW}You may need to fix DNS issues manually${NC}"
        echo -e "${CYAN}Try: sudo resolvconf -u${NC}"
        log_message "WARNING: WireGuard failed to start"
        return 1
    fi
    
    echo -e "${BLUE}Testing VPN connection...${NC}"
    sleep 3
    
    if timeout 10 ping -c 3 -W 2 "$WG_INTERNAL_IP" &>/dev/null; then
        echo -e "${GREEN}VPS backbone connection established${NC}"
        log_message "VPN connection successful"
    else
        echo -e "${YELLOW}Cannot reach VPS server (may still work)${NC}"
        log_message "WARNING: Cannot ping VPS server"
    fi
}

install_python_packages() {
    local packages=("$@")
    local failed_packages=()
    
    echo -e "${BLUE}Installing Python packages...${NC}"
    log_message "Installing Python packages"
    
    for package in "${packages[@]}"; do
        echo -e "${PURPLE}Installing: $package${NC}"
        log_message "Installing Python package: $package"
        
        local success=false
        local install_output=""
        
        if [ "$OS_TYPE" = "arch" ]; then
            if install_output=$(python -m pip install --break-system-packages --upgrade "$package" 2>&1); then
                success=true
                echo -e "${GREEN}Installed: $package (system-wide)${NC}"
                log_message "SUCCESS: $package (system-wide)"
            elif install_output=$(sudo -u "$TARGET_USER" env HOME="$USER_HOME" python -m pip install --user --upgrade "$package" 2>&1); then
                success=true
                echo -e "${GREEN}Installed: $package (user)${NC}"
                log_message "SUCCESS: $package (user)"
            fi
        else
            if install_output=$(sudo -u "$TARGET_USER" python3 -m pip install --user --break-system-packages --upgrade "$package" 2>&1); then
                success=true
                echo -e "${GREEN}Installed: $package${NC}"
                log_message "SUCCESS: $package"
            fi
        fi
        
        if [ "$success" = false ]; then
            local base_package=$(echo "$package" | cut -d'>' -f1 | cut -d'<' -f1 | cut -d'=' -f1)
            echo -e "${YELLOW}Retrying with base package: $base_package${NC}"
            log_message "Retrying with base package: $base_package"
            
            if [ "$OS_TYPE" = "arch" ]; then
                if install_output=$(python -m pip install --break-system-packages --upgrade "$base_package" 2>&1); then
                    success=true
                    echo -e "${GREEN}Installed: $base_package (system-wide)${NC}"
                    log_message "SUCCESS: $base_package (system-wide)"
                elif install_output=$(sudo -u "$TARGET_USER" env HOME="$USER_HOME" python -m pip install --user --upgrade "$base_package" 2>&1); then
                    success=true
                    echo -e "${GREEN}Installed: $base_package (user)${NC}"
                    log_message "SUCCESS: $base_package (user)"
                fi
            else
                if install_output=$(sudo -u "$TARGET_USER" python3 -m pip install --user --break-system-packages --upgrade "$base_package" 2>&1); then
                    success=true
                    echo -e "${GREEN}Installed: $base_package${NC}"
                    log_message "SUCCESS: $base_package"
                fi
            fi
            
            if [ "$success" = false ]; then
                echo -e "${RED}Failed: $package${NC}"
                echo "$install_output" | tail -n 5
                log_message "ERROR: Failed to install $package"
                echo "$install_output" >> "$INSTALL_LOG"
                failed_packages+=("$package")
            fi
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        echo -e "${RED}Failed to install packages: ${failed_packages[*]}${NC}"
        echo -e "${YELLOW}Check log: $INSTALL_LOG${NC}"
        log_message "ERROR: Failed packages: ${failed_packages[*]}"
        cleanup_on_failure
    fi
    
    echo -e "${GREEN}Python packages installation complete${NC}"
    log_message "Python packages installed successfully"
    
    if [ "$OS_TYPE" = "arch" ]; then
        echo -e "${BLUE}Creating RNS executable wrappers...${NC}"
        log_message "Creating Arch wrappers"
        
        cat > /usr/local/bin/rnsd << 'EOF'
#!/usr/bin/env python
import sys
from RNS.Utilities import rnsd
if __name__ == '__main__':
    sys.exit(rnsd.main())
EOF
        chmod +x /usr/local/bin/rnsd
        
        cat > /usr/local/bin/rnstatus << 'EOF'
#!/usr/bin/env python
import sys
from RNS.Utilities import rnstatus
if __name__ == '__main__':
    sys.exit(rnstatus.main())
EOF
        chmod +x /usr/local/bin/rnstatus
        
        cat > /usr/local/bin/rnpath << 'EOF'
#!/usr/bin/env python
import sys
from RNS.Utilities import rnpath
if __name__ == '__main__':
    sys.exit(rnpath.main())
EOF
        chmod +x /usr/local/bin/rnpath
        
        cat > /usr/local/bin/rnprobe << 'EOF'
#!/usr/bin/env python
import sys
from RNS.Utilities import rnprobe
if __name__ == '__main__':
    sys.exit(rnprobe.main())
EOF
        chmod +x /usr/local/bin/rnprobe
        
        cat > /usr/local/bin/rncp << 'EOF'
#!/usr/bin/env python
import sys
from RNS.Utilities import rncp
if __name__ == '__main__':
    sys.exit(rncp.main())
EOF
        chmod +x /usr/local/bin/rncp
        
        cat > /usr/local/bin/rnodeconf << 'EOF'
#!/usr/bin/env python
import sys
from RNS.Utilities import rnodeconf
if __name__ == '__main__':
    sys.exit(rnodeconf.main())
EOF
        chmod +x /usr/local/bin/rnodeconf
        
        cat > /usr/local/bin/nomadnet << 'EOF'
#!/usr/bin/env python
import sys
from nomadnet.nomadnet import main
if __name__ == '__main__':
    sys.exit(main())
EOF
        chmod +x /usr/local/bin/nomadnet
        
        echo -e "${GREEN}RNS wrappers created in /usr/local/bin${NC}"
        log_message "Arch wrappers created"
    fi
    
    echo -e "${BLUE}Detecting Reticulum binaries...${NC}"
    
    RNS_BIN=$(which rnsd 2>/dev/null || echo "/usr/local/bin/rnsd")
    NOMADNET_BIN=$(which nomadnet 2>/dev/null || echo "/usr/local/bin/nomadnet")
    
    if [ ! -f "$RNS_BIN" ]; then
        echo -e "${RED}ERROR: rnsd binary not found at $RNS_BIN${NC}"
        log_message "ERROR: rnsd binary not found"
        cleanup_on_failure
    fi
    
    echo -e "${GREEN}RNS: $RNS_BIN${NC}"
    echo -e "${GREEN}Nomadnet: $NOMADNET_BIN${NC}"
    log_message "Binaries located: RNS=$RNS_BIN, Nomadnet=$NOMADNET_BIN"
}

clone_and_build_repo() {
    echo -e "${BLUE}Installing MeshChat web interface...${NC}"
    log_message "Cloning MeshChat repository"
    
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}Removing old installation${NC}"
        rm -rf "$INSTALL_DIR"
        log_message "Removed old MeshChat installation"
    fi
    
    local retry=0
    while [ $retry -lt 3 ]; do
        if git clone --branch "$MESHCHAT_BRANCH" "$MESHCHAT_REPO" "$INSTALL_DIR" >> "$INSTALL_LOG" 2>&1; then
            MESHCHAT_CLONED=true
            log_message "MeshChat cloned successfully"
            break
        fi
        retry=$((retry + 1))
        if [ $retry -lt 3 ]; then
            echo -e "${YELLOW}Clone failed, retry $retry/3...${NC}"
            log_message "Clone retry $retry/3"
            sleep 3
        else
            echo -e "${RED}Failed to clone repository${NC}"
            echo -e "${YELLOW}Check log: $INSTALL_LOG${NC}"
            log_message "ERROR: Failed to clone MeshChat after 3 attempts"
            cleanup_on_failure
        fi
    done
    
    cd "$INSTALL_DIR" || {
        echo -e "${RED}Failed to enter repository directory${NC}"
        log_message "ERROR: Cannot cd to $INSTALL_DIR"
        cleanup_on_failure
    }
    
    mkdir -p public
    
    echo -e "${PURPLE}Installing Node.js dependencies (this may take 2-3 minutes)...${NC}"
    log_message "Installing Node.js dependencies"
    
    if ! npm install --omit=dev >> "$INSTALL_LOG" 2>&1; then
        echo -e "${RED}Failed to install Node dependencies${NC}"
        echo -e "${YELLOW}Common causes:${NC}"
        echo "  - Node.js version incompatibility (needs v16+)"
        echo "  - npm cache corruption"
        echo "  - Insufficient disk space"
        echo -e "${CYAN}Build log: $INSTALL_LOG${NC}"
        echo -e "${CYAN}Try: npm cache clean --force${NC}"
        log_message "ERROR: npm install failed"
        cleanup_on_failure
    fi
    
    echo -e "${PURPLE}Building frontend (this may take 2-3 minutes)...${NC}"
    log_message "Building MeshChat frontend"
    
    if ! npm run build-frontend >> "$INSTALL_LOG" 2>&1; then
        echo -e "${RED}Failed to build frontend${NC}"
        echo -e "${YELLOW}Common causes:${NC}"
        echo "  - Node.js version incompatibility"
        echo "  - Build dependencies missing"
        echo "  - Insufficient memory"
        echo -e "${CYAN}Build log: $INSTALL_LOG${NC}"
        log_message "ERROR: npm run build-frontend failed"
        cleanup_on_failure
    fi
    
    chown -R "$TARGET_USER:$TARGET_USER" "$INSTALL_DIR"
    
    echo -e "${GREEN}MeshChat installed${NC}"
    log_message "MeshChat installation complete"
}

configure_reticulum() {
    echo -e "${BLUE}Configuring Reticulum...${NC}"
    log_message "Configuring Reticulum"
    
    local config_dir="$USER_HOME/.reticulum"
    local config_file="$config_dir/config"
    
    mkdir -p "$config_dir"
    
    if [[ "$VPS_BACKBONE" =~ ^[Yy]$ ]]; then
        cat > "$config_file" << EOF
[reticulum]
enable_transport = yes
share_instance = yes
shared_instance_port = 37428

[logging]
loglevel = 3

[interfaces]

  # VPS Backbone Connection (via WireGuard)
  [[VPS Backbone]]
    type = TCPClientInterface
    interface_enabled = yes
    target_host = $WG_INTERNAL_IP
    target_port = $RETICULUM_PORT

  # Local mesh discovery
  [[Local Interface]]
    type = AutoInterface
    interface_enabled = yes

  # RNode support (commented out - enable if you have LoRa hardware)
  # [[RNode Interface]]
  #   type = RNodeInterface
  #   interface_enabled = no
  #   port = /dev/ttyUSB0
  #   frequency = 867200000
  #   bandwidth = 125000
  #   txpower = 7
  #   spreadingfactor = 8
  #   codingrate = 5

EOF
        echo -e "${GREEN}Config: VPS backbone + local mesh${NC}"
        log_message "Reticulum configured for VPS backbone mode"
    else
        cat > "$config_file" << EOF
[reticulum]
enable_transport = yes
share_instance = yes
shared_instance_port = 37428

[logging]
loglevel = 3

[interfaces]

  # Local mesh discovery
  [[Local Interface]]
    type = AutoInterface
    interface_enabled = yes

  # RNode support (commented out - enable if you have LoRa hardware)
  # [[RNode Interface]]
  #   type = RNodeInterface
  #   interface_enabled = no
  #   port = /dev/ttyUSB0
  #   frequency = 867200000
  #   bandwidth = 125000
  #   txpower = 7
  #   spreadingfactor = 8
  #   codingrate = 5

EOF
        echo -e "${GREEN}Config: Local mesh only${NC}"
        log_message "Reticulum configured for local mesh only"
    fi
    
    chown -R "$TARGET_USER:$TARGET_USER" "$config_dir"
}

create_rnode_detector() {
    echo -e "${BLUE}Creating RNode detection script...${NC}"
    log_message "Creating RNode detector"
    
    cat > /usr/local/bin/detect-rnodes.sh << 'EOF'
#!/bin/bash
# Auto-detect and configure RNode devices

echo "Scanning for RNode devices..."

for device in /dev/ttyUSB* /dev/ttyACM*; do
    if [ -e "$device" ]; then
        echo "Found device: $device"
        if timeout 5 rnodeconf -i "$device" 2>/dev/null; then
            echo "Confirmed RNode at $device"
            
            # Update config
            sed -i "s|port = /dev/ttyUSB0|port = $device|g" ~/.reticulum/config
            sed -i 's|interface_enabled = no|interface_enabled = yes|g' ~/.reticulum/config
            
            echo "RNode configured"
            systemctl --user restart reticulum 2>/dev/null || sudo systemctl restart reticulum
            break
        fi
    fi
done

echo "Scan complete"
EOF
    
    chmod +x /usr/local/bin/detect-rnodes.sh
    echo -e "${GREEN}RNode detector: /usr/local/bin/detect-rnodes.sh${NC}"
    log_message "RNode detector created"
}

create_serial_udev_rules() {
    echo -e "${BLUE}Creating udev rules for serial devices...${NC}"
    log_message "Creating udev rules"
    
    cat > /etc/udev/rules.d/99-serial-permissions.rules << 'EOF'
# Serial device permissions for LoRa radios
KERNEL=="ttyUSB[0-9]*", MODE="0666", GROUP="dialout"
KERNEL=="ttyACM[0-9]*", MODE="0666", GROUP="dialout"
SUBSYSTEM=="usb", MODE="0666", GROUP="plugdev"
EOF

    udevadm control --reload-rules 2>/dev/null || true
    udevadm trigger 2>/dev/null || true

    usermod -a -G dialout "$TARGET_USER" 2>/dev/null || true
    
    if [ "$OS_TYPE" = "arch" ]; then
        usermod -a -G uucp "$TARGET_USER" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}Udev rules created${NC}"
    log_message "Udev rules created and user added to groups"
}

wait_for_service() {
    local service="$1"
    local max_wait=30
    
    for i in $(seq 1 $max_wait); do
        if systemctl is-active --quiet "$service"; then
            return 0
        fi
        sleep 1
    done
    
    return 1
}

create_systemd_services() {
    echo -e "${BLUE}Creating systemd services...${NC}"
    log_message "Creating systemd services"
    
    cat > /etc/systemd/system/reticulum.service << EOF
[Unit]
Description=Reticulum Network Stack
After=network.target
Wants=network.target

[Service]
Type=simple
User=$TARGET_USER
WorkingDirectory=$USER_HOME
ExecStart=$RNS_BIN
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
Environment="PATH=$USER_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/meshchat.service << EOF
[Unit]
Description=Reticulum MeshChat
After=reticulum.service
Requires=reticulum.service

[Service]
Type=simple
User=$TARGET_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$PYTHON_BIN meshchat.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment="PATH=$USER_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    SERVICES_CREATED=true
    
    echo -e "${GREEN}Services created${NC}"
    log_message "Systemd services created"
}

start_services() {
    echo -e "${BLUE}Starting services...${NC}"
    log_message "Starting services"
    
    systemctl enable reticulum.service || {
        echo -e "${RED}Failed to enable Reticulum${NC}"
        log_message "ERROR: Failed to enable reticulum.service"
        cleanup_on_failure
    }
    
    systemctl enable meshchat.service || {
        echo -e "${RED}Failed to enable MeshChat${NC}"
        log_message "ERROR: Failed to enable meshchat.service"
        cleanup_on_failure
    }
    
    systemctl start reticulum.service || {
        echo -e "${RED}Failed to start Reticulum${NC}"
        journalctl -u reticulum.service --no-pager -n 20
        log_message "ERROR: Failed to start reticulum.service"
        cleanup_on_failure
    }
    
    if ! wait_for_service "reticulum.service"; then
        echo -e "${RED}Reticulum failed to start${NC}"
        journalctl -u reticulum.service --no-pager -n 20
        log_message "ERROR: Reticulum service did not become active"
        cleanup_on_failure
    fi
    
    systemctl start meshchat.service || {
        echo -e "${RED}Failed to start MeshChat${NC}"
        journalctl -u meshchat.service --no-pager -n 20
        log_message "ERROR: Failed to start meshchat.service"
        cleanup_on_failure
    }
    
    if ! wait_for_service "meshchat.service"; then
        echo -e "${RED}MeshChat failed to start${NC}"
        journalctl -u meshchat.service --no-pager -n 20
        log_message "ERROR: MeshChat service did not become active"
        cleanup_on_failure
    fi
    
    echo -e "${GREEN}Services started${NC}"
    log_message "Services started successfully"
}

check_service_status() {
    echo -e "${BLUE}Service status:${NC}"
    log_message "Checking service status"
    
    local services=("reticulum" "meshchat")
    if [[ "$VPS_BACKBONE" =~ ^[Yy]$ ]]; then
        services+=("wg-quick@wg0")
    fi
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service.service" || systemctl is-active --quiet "$service"; then
            echo -e "${GREEN}Active: $service${NC}"
            log_message "Service active: $service"
        else
            echo -e "${RED}Inactive: $service${NC}"
            log_message "Service inactive: $service"
        fi
    done
}

create_desktop_shortcuts() {
    if [ ! -d "$USER_HOME/Desktop" ] && [ -z "$DISPLAY" ]; then
        echo -e "${CYAN}No desktop environment detected - skipping shortcuts${NC}"
        log_message "No desktop environment, skipping shortcuts"
        return 0
    fi
    
    echo -e "${BLUE}Creating desktop shortcuts...${NC}"
    log_message "Creating desktop shortcuts"
    
    mkdir -p "$USER_HOME/Desktop"
    
    cat > "$USER_HOME/Desktop/meshchat.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Reticulum MeshChat
Exec=firefox http://localhost:8000
Icon=network-workgroup
Terminal=false
EOF

    cat > "$USER_HOME/Desktop/nomadnet.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Nomad Network
Exec=gnome-terminal -- nomadnet
Icon=terminal
Terminal=false
EOF

    chmod +x "$USER_HOME/Desktop"/*.desktop
    chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/Desktop"
    
    echo -e "${GREEN}Desktop shortcuts created${NC}"
    log_message "Desktop shortcuts created"
}

print_completion() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}     Installation Complete${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    if [[ "$VPS_BACKBONE" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Mode: VPS Backbone + Local Mesh${NC}"
        echo -e "${BLUE}   Connected to your VPS backbone via VPN${NC}"
        echo -e "${BLUE}   Local mesh discovery enabled${NC}"
    else
        echo -e "${CYAN}Mode: Local Mesh Only${NC}"
        echo -e "${BLUE}   Local mesh discovery enabled${NC}"
        echo -e "${BLUE}   To add VPS backbone later, get credentials and re-run${NC}"
    fi
    
    echo ""
    echo -e "${PURPLE}Access:${NC}"
    echo -e "${BLUE}  MeshChat: http://localhost:8000${NC}"
    echo -e "${BLUE}  Nomadnet: nomadnet${NC}"
    echo -e "${BLUE}  Status: rnstatus${NC}"
    
    echo ""
    echo -e "${PURPLE}Service Management:${NC}"
    echo -e "${BLUE}  Status: sudo systemctl status reticulum meshchat${NC}"
    echo -e "${BLUE}  Logs: sudo journalctl -u reticulum -f${NC}"
    echo -e "${BLUE}  Restart: sudo systemctl restart reticulum${NC}"
    
    echo ""
    echo -e "${PURPLE}Configuration:${NC}"
    echo -e "${BLUE}  Reticulum: ~/.reticulum/config${NC}"
    echo -e "${BLUE}  RNode detection: /usr/local/bin/detect-rnodes.sh${NC}"
    echo -e "${BLUE}  Installation log: $INSTALL_LOG${NC}"
    
    if [ "$OS_TYPE" = "arch" ]; then
        echo ""
        echo -e "${YELLOW}Note: On Arch, you may need to log out and back in for group${NC}"
        echo -e "${YELLOW}      changes (dialout/uucp) to take effect.${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}Happy meshing${NC}"
    echo ""
    
    log_message "Installation completed successfully"
}

#############################
### Main Script
#############################

echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}   Reticulum Network Installer${NC}"
echo -e "${PURPLE}========================================${NC}"
echo ""

log_message "Installation started"
INSTALLATION_STARTED=true

trap cleanup_on_failure ERR

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run with sudo${NC}"
    log_message "ERROR: Not run as root"
    exit 1
fi

echo -e "${PURPLE}[1/16] Detecting OS...${NC}"
detect_os

echo -e "${PURPLE}[2/16] Checking disk space...${NC}"
check_disk_space

ask_vps_backbone

if [ "$OS_TYPE" = "debian" ]; then
    FINAL_PACKAGES=("${DEBIAN_PACKAGES[@]}")
    if [[ "$VPS_BACKBONE" =~ ^[Yy]$ ]]; then
        FINAL_PACKAGES+=("${DEBIAN_VPS_PACKAGES[@]}")
    fi
    if [ -n "$DISPLAY" ] || [ -d "$USER_HOME/Desktop" ]; then
        FINAL_PACKAGES+=("${DEBIAN_DESKTOP_PACKAGES[@]}")
    fi
else
    FINAL_PACKAGES=("${ARCH_PACKAGES[@]}")
    if [[ "$VPS_BACKBONE" =~ ^[Yy]$ ]]; then
        FINAL_PACKAGES+=("${ARCH_VPS_PACKAGES[@]}")
    fi
    if [ -n "$DISPLAY" ] || [ -d "$USER_HOME/Desktop" ]; then
        FINAL_PACKAGES+=("${ARCH_DESKTOP_PACKAGES[@]}")
    fi
fi

echo -e "${PURPLE}[3/16] Detecting binaries...${NC}"
detect_binary_paths

echo -e "${PURPLE}[4/16] Installing system packages...${NC}"
install_system_packages "${FINAL_PACKAGES[@]}"

echo -e "${PURPLE}[5/16] Checking pip...${NC}"
bootstrap_pip

echo -e "${PURPLE}[6/16] Installing Python packages...${NC}"
install_python_packages "${PYTHON_PACKAGES[@]}"

echo -e "${PURPLE}[7/16] Installing MeshChat...${NC}"
clone_and_build_repo

echo -e "${PURPLE}[8/16] Configuring Reticulum...${NC}"
configure_reticulum

echo -e "${PURPLE}[9/16] Creating utility scripts...${NC}"
create_rnode_detector
create_serial_udev_rules

echo -e "${PURPLE}[10/16] Creating services...${NC}"
create_systemd_services

echo -e "${PURPLE}[11/16] Creating shortcuts...${NC}"
create_desktop_shortcuts

echo -e "${PURPLE}[12/16] Starting services...${NC}"
start_services

echo -e "${PURPLE}[13/16] Network setup...${NC}"
setup_wireguard

echo -e "${PURPLE}[14/16] Checking status...${NC}"
check_service_status

print_completion

exit 0
