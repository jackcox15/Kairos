#!/usr/bin/bash

############################
### Colors :)
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
### RETICULUM_PORT (4242): TCP port Reticulum listens on for VPS backbone.
#  This is the port your VPS Reticulum server should be listening on
#  Standard Reticulum default, but can be changed if needed for your use case
### MESHCHAT_PORT (8000): Local web UI port for MeshChat on each node
#   This is always localhost only, not exposed to network
### WireGuard (51820): VPN tunnel port, configured separately in WireGuard config

RETICULUM_PORT=4242  # TCP port for Reticulum on VPS backbone
MESHCHAT_PORT=8000   # MeshChat web UI (localhost only, not used in config)
REPO=https://github.com/liamcottle/reticulum-meshchat
INSTALL_DIR="/opt/reticulum-meshchat"

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

# Track if user wants VPS backbone (internal variable name kept for compatibility)
KAIROS_ACCESS=""

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
DEBIAN_KAIROS_PACKAGES=(
    "wireguard"
    "resolvconf"
)

ARCH_KAIROS_PACKAGES=(
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

detect_os() {
    if [ -f /etc/arch-release ]; then
        echo -e "${BLUE}Detected: Arch Linux${NC}"
        OS_TYPE="arch"
    elif [ -f /etc/debian_version ]; then
        echo -e "${BLUE}Detected: Debian/Ubuntu${NC}"
        OS_TYPE="debian"
    else
        echo -e "${RED}Unsupported OS. This script supports Debian/Ubuntu and Arch Linux${NC}"
        exit 1
    fi
}

detect_binary_paths() {
    echo -e "${BLUE}Detecting binary paths...${NC}"
    
    PYTHON_BIN=$(which python3 2>/dev/null || which python 2>/dev/null) || {
        echo -e "${RED}Python not found in PATH${NC}"
        exit 1
    }
    
    echo -e "${GREEN}Python: $PYTHON_BIN${NC}"
}

check_package_installed() {
    local package="$1"
    
    if [ "$OS_TYPE" = "debian" ]; then
        dpkg -l "$package" &>/dev/null
    else
        pacman -Qi "$package" &>/dev/null
    fi
}

install_system_packages() {
    local packages=("$@")
    local to_install=()
    
    echo -e "${BLUE}Checking system packages...${NC}"
    
    for package in "${packages[@]}"; do
        if check_package_installed "$package"; then
            echo -e "${GREEN}✓ $package${NC}"
        else
            echo -e "${YELLOW}  $package (will install)${NC}"
            to_install+=("$package")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        echo -e "${PURPLE}Installing ${#to_install[@]} packages...${NC}"
        
        if [ "$OS_TYPE" = "debian" ]; then
            # Debian/Ubuntu installation
            apt-get update || {
                echo -e "${RED}Failed to update package list${NC}"
                exit 1
            }
            
            apt-get install -y "${to_install[@]}" || {
                echo -e "${RED}Failed to install system packages${NC}"
                exit 1
            }
        else
            # Arch Linux installation
            pacman -Sy --noconfirm || {
                echo -e "${RED}Failed to update package database${NC}"
                exit 1
            }
            
            pacman -S --noconfirm "${to_install[@]}" || {
                echo -e "${RED}Failed to install system packages${NC}"
                exit 1
            }
        fi
        
        echo -e "${GREEN}System packages installed${NC}"
    else
        echo -e "${GREEN}All packages already installed${NC}"
    fi
}

bootstrap_pip() {
    echo -e "${BLUE}Checking pip...${NC}"
    
    # Check if pip works
    if $PYTHON_BIN -m pip --version &>/dev/null; then
        echo -e "${GREEN}Pip is working${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Bootstrapping pip...${NC}"
    
    if [ "$OS_TYPE" = "debian" ]; then
        # Try package reinstall
        apt-get install -y --reinstall python3-pip python3-setuptools python3-wheel || true
        
        if $PYTHON_BIN -m pip --version &>/dev/null; then
            echo -e "${GREEN}Pip fixed${NC}"
            return 0
        fi
        
        # Download get-pip.py
        echo -e "${YELLOW}Downloading pip installer...${NC}"
        curl -fsSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py || {
            echo -e "${RED}Failed to download pip installer${NC}"
            exit 1
        }
        
        $PYTHON_BIN /tmp/get-pip.py --break-system-packages --force-reinstall || {
            echo -e "${RED}Failed to install pip${NC}"
            exit 1
        }
        
        rm -f /tmp/get-pip.py
    else
        # Arch: reinstall python-pip
        pacman -S --noconfirm python-pip || {
            echo -e "${RED}Failed to install pip${NC}"
            exit 1
        }
    fi
    
    if ! $PYTHON_BIN -m pip --version &>/dev/null; then
        echo -e "${RED}Pip still not working${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Pip installed${NC}"
}

ask_kairos_access() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}        VPS Backbone Setup${NC}"     
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}You can optionally connect this node to your VPS backbone.${NC}"
    echo -e "${YELLOW}This requires WireGuard credentials from your VPS deployment.${NC}"
    echo ""
    echo -e "${BLUE}Do you have VPN credentials for your backbone? (y/n)${NC}"
    read -r KAIROS_ACCESS
    echo ""
    
    if [[ "$KAIROS_ACCESS" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}VPS backbone mode enabled${NC}"
    else
        echo -e "${CYAN}Local mesh only mode${NC}"
    fi
}

validate_wg_key() {
    local key="$1"
    local key_name="$2"
    if [[ ! "$key" =~ ^[A-Za-z0-9+/]{43}=$ ]]; then
        echo -e "${RED}Invalid WireGuard key format for $key_name${NC}"
        exit 1
    fi
}

setup_wireguard() {
    if [[ ! "$KAIROS_ACCESS" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Skipping WireGuard (VPS backbone not enabled)${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Setting up WireGuard VPN for backbone...${NC}"
    
    # Check if keys are configured
    if [[ "$WG_PRIVATE_KEY" == "__REPLACE_PRIVATE_KEY__" ]]; then
        echo -e "${RED}WireGuard keys not configured!${NC}"
        echo -e "${YELLOW}You need to run key_baker.sh first to bake in your VPN credentials${NC}"
        echo -e "${YELLOW}Get credentials from your VPS deployment, then run:${NC}"
        echo -e "${CYAN}  ./key_baker.sh${NC}"
        exit 1
    fi
    
    # Validate keys
    validate_wg_key "$WG_PRIVATE_KEY" "private key"
    validate_wg_key "$WG_SERVER_PUBLIC_KEY" "server public key"
    
    # Validate IP
    if [[ ! "$WG_CLIENT_IP" =~ ^10\.5\.5\.[0-9]+$ ]]; then
        echo -e "${RED}Invalid client IP: $WG_CLIENT_IP${NC}"
        exit 1
    fi
    
    mkdir -p /etc/wireguard
    
    # Different config based on OS - Arch doesn't play nice with DNS in WireGuard
    if [ "$OS_TYPE" = "arch" ]; then
        cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_CLIENT_IP/24
Table = off

[Peer]
PublicKey = $WG_SERVER_PUBLIC_KEY
Endpoint = $WG_ENDPOINT
AllowedIPs = 10.5.5.0/24
PersistentKeepalive = 25
EOF
    else
        # Debian can handle DNS in WireGuard config
        cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = $WG_CLIENT_IP/24
Table = off
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $WG_SERVER_PUBLIC_KEY
Endpoint = $WG_ENDPOINT
AllowedIPs = 10.5.5.0/24
PersistentKeepalive = 25
EOF
    fi

    chmod 600 /etc/wireguard/wg0.conf
    
    # Enable and start WireGuard
    systemctl enable wg-quick@wg0 || {
        echo -e "${RED}Failed to enable WireGuard${NC}"
        exit 1
    }
    
    systemctl start wg-quick@wg0 || {
        echo -e "${RED}Failed to start WireGuard${NC}"
        echo -e "${YELLOW}This might be a DNS conflict - checking...${NC}"
        
        # Show helpful error message
        systemctl status wg-quick@wg0 --no-pager -l
        
        # Don't exit - let user decide
        echo -e "${YELLOW}WireGuard failed to start, but continuing installation...${NC}"
        echo -e "${YELLOW}You may need to fix DNS issues manually${NC}"
        echo -e "${CYAN}Try: sudo resolvconf -u${NC}"
        return 1
    }
    
    # Test connection
    echo -e "${BLUE}Testing VPN connection...${NC}"
    sleep 3
    
    if timeout 10 ping -c 3 -W 2 "$WG_INTERNAL_IP" &>/dev/null; then
        echo -e "${GREEN}✓ VPS backbone connection established${NC}"
    else
        echo -e "${YELLOW}⚠ Cannot reach VPS server (may still work)${NC}"
    fi
}

install_python_packages() {
    local packages=("$@")
    
    echo -e "${BLUE}Installing Python packages...${NC}"
    
    for package in "${packages[@]}"; do
        echo -e "${PURPLE}Installing: $package${NC}"
        
        local success=false
        
        if [ "$OS_TYPE" = "arch" ]; then
            if python -m pip install --break-system-packages --upgrade "$package" &>/dev/null; then
                success=true
            elif sudo -u "$TARGET_USER" env HOME="$USER_HOME" python -m pip install --user --upgrade "$package" &>/dev/null; then
                success=true
            fi
        else
            if sudo -u "$TARGET_USER" python3 -m pip install --user --break-system-packages --upgrade "$package" &>/dev/null; then
                success=true
            fi
        fi
        
        if [ "$success" = true ]; then
            echo -e "${GREEN}✓ $package${NC}"
        else
            local base_package=$(echo "$package" | cut -d'>' -f1 | cut -d'<' -f1 | cut -d'=' -f1)
            echo -e "${YELLOW}Retrying with base package: $base_package${NC}"
            
            if [ "$OS_TYPE" = "arch" ]; then
                if python -m pip install --break-system-packages --upgrade "$base_package" &>/dev/null; then
                    success=true
                elif sudo -u "$TARGET_USER" env HOME="$USER_HOME" python -m pip install --user --upgrade "$base_package" &>/dev/null; then
                    success=true
                fi
            else
                if sudo -u "$TARGET_USER" python3 -m pip install --user --break-system-packages --upgrade "$base_package" &>/dev/null; then
                    success=true
                fi
            fi
            
            if [ "$success" = true ]; then
                echo -e "${GREEN}✓ $base_package${NC}"
            else
                echo -e "${YELLOW}⚠ $package (may already be installed)${NC}"
            fi
        fi
    done
    
    echo -e "${GREEN}Python packages installation complete${NC}"
    
    # Create executable wrappers for Arch (pip doesn't install scripts with --break-system-packages)
    if [ "$OS_TYPE" = "arch" ]; then
        echo -e "${BLUE}Creating RNS executable wrappers...${NC}"
        
        # rnsd
        cat > /usr/local/bin/rnsd << 'EOF'
#!/usr/bin/env python
import sys
from RNS.Utilities import rnsd
if __name__ == '__main__':
    sys.exit(rnsd.main())
EOF
        chmod +x /usr/local/bin/rnsd
        
        # rnstatus  
        cat > /usr/local/bin/rnstatus << 'EOF'
#!/usr/bin/env python
import sys
from RNS.Utilities import rnstatus
if __name__ == '__main__':
    sys.exit(rnstatus.main())
EOF
        chmod +x /usr/local/bin/rnstatus
        
        # rnpath
        cat > /usr/local/bin/rnpath << 'EOF'
#!/usr/bin/env python
import sys
from RNS.Utilities import rnpath
if __name__ == '__main__':
    sys.exit(rnpath.main())
EOF
        chmod +x /usr/local/bin/rnpath
        
        # rnprobe
        cat > /usr/local/bin/rnprobe << 'EOF'
#!/usr/bin/env python
import sys
from RNS.Utilities import rnprobe
if __name__ == '__main__':
    sys.exit(rnprobe.main())
EOF
        chmod +x /usr/local/bin/rnprobe
        
        # rncp
        cat > /usr/local/bin/rncp << 'EOF'
#!/usr/bin/env python
import sys
from RNS.Utilities import rncp
if __name__ == '__main__':
    sys.exit(rncp.main())
EOF
        chmod +x /usr/local/bin/rncp
        
        # rnodeconf
        cat > /usr/local/bin/rnodeconf << 'EOF'
#!/usr/bin/env python
import sys
from RNS.Utilities import rnodeconf
if __name__ == '__main__':
    sys.exit(rnodeconf.main())
EOF
        chmod +x /usr/local/bin/rnodeconf
        
        # nomadnet
        cat > /usr/local/bin/nomadnet << 'EOF'
#!/usr/bin/env python
import sys
from nomadnet.nomadnet import main
if __name__ == '__main__':
    sys.exit(main())
EOF
        chmod +x /usr/local/bin/nomadnet
        
        echo -e "${GREEN}RNS wrappers created in /usr/local/bin${NC}"
    fi
    
    # Detect binary paths
    echo -e "${BLUE}Detecting Reticulum binaries...${NC}"
    
    RNS_BIN=$(which rnsd 2>/dev/null || echo "/usr/local/bin/rnsd")
    NOMADNET_BIN=$(which nomadnet 2>/dev/null || echo "/usr/local/bin/nomadnet")
    
    # Verify binaries exist
    if [ ! -f "$RNS_BIN" ]; then
        echo -e "${RED}ERROR: rnsd binary not found at $RNS_BIN${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}RNS: $RNS_BIN${NC}"
    echo -e "${GREEN}Nomadnet: $NOMADNET_BIN${NC}"
}

clone_and_build_repo() {
    echo -e "${BLUE}Installing MeshChat web interface...${NC}"
    
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}Removing old installation${NC}"
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone repo
    local retry=0
    while [ $retry -lt 3 ]; do
        if git clone "$REPO" "$INSTALL_DIR" 2>/dev/null; then
            break
        fi
        retry=$((retry + 1))
        if [ $retry -lt 3 ]; then
            echo -e "${YELLOW}Clone failed, retry $retry/3...${NC}"
            sleep 3
        else
            echo -e "${RED}Failed to clone repository${NC}"
            exit 1
        fi
    done
    
    cd "$INSTALL_DIR" || {
        echo -e "${RED}Failed to enter repository directory${NC}"
        exit 1
    }
    
    mkdir -p public
    
    echo -e "${PURPLE}Installing Node.js dependencies...${NC}"
    npm install --omit=dev || {
        echo -e "${RED}Failed to install Node dependencies${NC}"
        exit 1
    }
    
    echo -e "${PURPLE}Building frontend...${NC}"
    npm run build-frontend || {
        echo -e "${RED}Failed to build frontend${NC}"
        exit 1
    }
    
    chown -R "$TARGET_USER:$TARGET_USER" "$INSTALL_DIR"
    
    echo -e "${GREEN}MeshChat installed${NC}"
}

configure_reticulum() {
    echo -e "${BLUE}Configuring Reticulum...${NC}"
    
    local config_dir="$USER_HOME/.reticulum"
    local config_file="$config_dir/config"
    
    mkdir -p "$config_dir"
    
    if [[ "$KAIROS_ACCESS" =~ ^[Yy]$ ]]; then
        # VPS backbone mode: VPS + local mesh
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

  # RNode support (commented out - enable if you have LoRa hardware!!!)
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
    else
        # Local only mode
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

  # RNode support (commented out - enable if you have LoRa hardware!!!)
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
    fi
    
    chown -R "$TARGET_USER:$TARGET_USER" "$config_dir"
}

create_rnode_detector() {
    echo -e "${BLUE}Creating RNode detection script...${NC}"
    
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
            systemctl --user restart reticulum 2>/dev/null || true
            break
        fi
    fi
done

echo "Scan complete"
EOF
    
    chmod +x /usr/local/bin/detect-rnodes.sh
    echo -e "${GREEN}RNode detector: /usr/local/bin/detect-rnodes.sh${NC}"
}

create_serial_udev_rules() {
    echo -e "${BLUE}Creating udev rules for serial devices...${NC}"
    
    cat > /etc/udev/rules.d/99-serial-permissions.rules << 'EOF'
# Serial device permissions for LoRa radios
KERNEL=="ttyUSB[0-9]*", MODE="0666", GROUP="dialout"
KERNEL=="ttyACM[0-9]*", MODE="0666", GROUP="dialout"
SUBSYSTEM=="usb", MODE="0666", GROUP="plugdev"
EOF

    udevadm control --reload-rules 2>/dev/null || true
    udevadm trigger 2>/dev/null || true

    # Add user to dialout group for serial device access
    usermod -a -G dialout "$TARGET_USER" 2>/dev/null || true
    
    # On Arch, also add to uucp group (common for serial devices)
    if [ "$OS_TYPE" = "arch" ]; then
        usermod -a -G uucp "$TARGET_USER" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}Udev rules created${NC}"
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
    
    # Reticulum service - no --config flag needed (rnsd uses ~/.reticulum/config by default)
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

    # MeshChat service
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
    
    echo -e "${GREEN}Services created${NC}"
}

start_services() {
    echo -e "${BLUE}Starting services...${NC}"
    
    systemctl enable reticulum.service || {
        echo -e "${RED}Failed to enable Reticulum${NC}"
        exit 1
    }
    
    systemctl enable meshchat.service || {
        echo -e "${RED}Failed to enable MeshChat${NC}"
        exit 1
    }
    
    systemctl start reticulum.service || {
        echo -e "${RED}Failed to start Reticulum${NC}"
        journalctl -u reticulum.service --no-pager -n 20
        exit 1
    }
    
    if ! wait_for_service "reticulum.service"; then
        echo -e "${RED}Reticulum failed to start${NC}"
        journalctl -u reticulum.service --no-pager -n 20
        exit 1
    fi
    
    systemctl start meshchat.service || {
        echo -e "${RED}Failed to start MeshChat${NC}"
        journalctl -u meshchat.service --no-pager -n 20
        exit 1
    }
    
    if ! wait_for_service "meshchat.service"; then
        echo -e "${RED}MeshChat failed to start${NC}"
        journalctl -u meshchat.service --no-pager -n 20
        exit 1
    fi
    
    echo -e "${GREEN}Services started${NC}"
}

check_service_status() {
    echo -e "${BLUE}Service status:${NC}"
    
    local services=("reticulum" "meshchat")
    if [[ "$KAIROS_ACCESS" =~ ^[Yy]$ ]]; then
        services+=("wg-quick@wg0")
    fi
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service.service" || systemctl is-active --quiet "$service"; then
            echo -e "${GREEN}✓ $service${NC}"
        else
            echo -e "${RED}✗ $service${NC}"
        fi
    done
}

create_desktop_shortcuts() {
    # Check if desktop environment exists
    if [ ! -d "$USER_HOME/Desktop" ] && [ -z "$DISPLAY" ]; then
        echo -e "${CYAN}No desktop environment detected - skipping shortcuts${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Creating desktop shortcuts...${NC}"
    
    mkdir -p "$USER_HOME/Desktop"
    
    # MeshChat shortcut
    cat > "$USER_HOME/Desktop/meshchat.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Reticulum MeshChat
Exec=firefox http://localhost:8000
Icon=network-workgroup
Terminal=false
EOF

    # Nomadnet shortcut
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
}

install_kairosctl() {
    echo -e "${BLUE}Installing management tool...${NC}"
    
    curl -fsSL https://raw.githubusercontent.com/jackcox15/Kairos/main/rns_PC/kairosctl.sh -o /usr/local/bin/kairosctl || {
        echo -e "${RED}Failed to download kairosctl${NC}"
        return 1
    }
    
    chmod +x /usr/local/bin/kairosctl
    
    echo -e "${GREEN}kairosctl installed${NC}"
    echo -e "${BLUE}  Run 'kairosctl' to manage your mesh node${NC}"
}

print_completion() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}     Installation Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    
    if [[ "$KAIROS_ACCESS" =~ ^[Yy]$ ]]; then
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
    echo -e "${PURPLE}Config:${NC}"
    echo -e "${BLUE}  Reticulum: ~/.reticulum/config${NC}"
    echo -e "${BLUE}  RNode detection: /usr/local/bin/detect-rnodes.sh${NC}"
    echo -e "${BLUE}  Run: 'kairosctl' in the console to manage Reticulum!${NC}"
    
    if [ "$OS_TYPE" = "arch" ]; then
        echo ""
        echo -e "${YELLOW}Note: On Arch, you may need to log out and back in for group${NC}"
        echo -e "${YELLOW}      changes (dialout/uucp) to take effect.${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}Happy meshing! <3 ${NC}"
    echo ""
}

#############################
### Main Script
#############################

echo -e "${PURPLE}════════════════════════════════════════${NC}"
echo -e "${PURPLE}   Reticulum Network Installer${NC}"
echo -e "${PURPLE}════════════════════════════════════════${NC}"
echo ""

# Root check
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

# Detect OS
echo -e "${PURPLE}[1/15] Detecting OS...${NC}"
detect_os

# Ask about VPS backbone
ask_kairos_access

# Build package list based on OS and user choice
if [ "$OS_TYPE" = "debian" ]; then
    FINAL_PACKAGES=("${DEBIAN_PACKAGES[@]}")
    if [[ "$KAIROS_ACCESS" =~ ^[Yy]$ ]]; then
        FINAL_PACKAGES+=("${DEBIAN_KAIROS_PACKAGES[@]}")
    fi
    if [ -n "$DISPLAY" ] || [ -d "$USER_HOME/Desktop" ]; then
        FINAL_PACKAGES+=("${DEBIAN_DESKTOP_PACKAGES[@]}")
    fi
else
    FINAL_PACKAGES=("${ARCH_PACKAGES[@]}")
    if [[ "$KAIROS_ACCESS" =~ ^[Yy]$ ]]; then
        FINAL_PACKAGES+=("${ARCH_KAIROS_PACKAGES[@]}")
    fi
    if [ -n "$DISPLAY" ] || [ -d "$USER_HOME/Desktop" ]; then
        FINAL_PACKAGES+=("${ARCH_DESKTOP_PACKAGES[@]}")
    fi
fi

# Detect binaries
echo -e "${PURPLE}[2/15] Detecting binaries...${NC}"
detect_binary_paths

# Install system packages
echo -e "${PURPLE}[3/15] Installing system packages...${NC}"
install_system_packages "${FINAL_PACKAGES[@]}"

# Bootstrap pip
echo -e "${PURPLE}[4/15] Checking pip...${NC}"
bootstrap_pip

# Install Python packages
echo -e "${PURPLE}[6/15] Installing Python packages...${NC}"
install_python_packages "${PYTHON_PACKAGES[@]}"

# Clone and build MeshChat
echo -e "${PURPLE}[7/15] Installing MeshChat...${NC}"
clone_and_build_repo

# Configure Reticulum
echo -e "${PURPLE}[8/15] Configuring Reticulum...${NC}"
configure_reticulum

# Create utility scripts
echo -e "${PURPLE}[9/15] Creating utility scripts...${NC}"
create_rnode_detector
create_serial_udev_rules

# Create systemd services
echo -e "${PURPLE}[10/15] Creating services...${NC}"
create_systemd_services

# Create desktop shortcuts
echo -e "${PURPLE}[11/15] Creating shortcuts...${NC}"
create_desktop_shortcuts

# Start services
echo -e "${PURPLE}[12/15] Starting services...${NC}"
start_services

# Install kairosctl
echo -e "${PURPLE}[13/15] Installing management tool...${NC}"
install_kairosctl

# Setup WireGuard (if VPS backbone enabled)
echo -e "${PURPLE}[14/15] Network setup...${NC}"
setup_wireguard

# Check status
echo -e "${PURPLE}[15/15] Checking status...${NC}"
check_service_status

# Print completion info
print_completion

exit 0
