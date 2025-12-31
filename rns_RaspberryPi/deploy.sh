#!/bin/bash

#git repos necessary for deployment
LCD_REPO="https://github.com/goodtft/LCD-show.git"
RNS_REPO="https://github.com/markqvist/Reticulum.git"
MESHCHAT_REPO="https://github.com/liamcottle/reticulum-meshchat.git"

#apt dependencies
APT_DEPS=(
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
    "iw"
    "wireless-tools"
    "dnsmasq"
    "hostapd"

)

#python dependencies for GUI/TUI/CLI
PYTHON_DEPS=(
    "rns"
    "lxmf"
    "nomadnet"
    "kivy"
    "aiohttp"
    "peewee"
    "websockets"
    "pyserial"
    "cx_freeze"
)

echo "Rnode Router Deployment!" 

#checking for root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo!"
    exit 1
fi

#installing dependencies here....
echo ""
echo "Installing dependencies now..."
apt update
apt install -y "${APT_DEPS[@]}"
sleep 2

#installing geeekpi LCD driver for rpi here
#If you wish to use a different display by GeekPi
#this library has all the necessary drivers for you 
echo ""
echo "Getting GeeekPi 3.5 LCD driver library"
echo "You can adjust the script here to fit your specific model!"
if [ ! -d "LCD-show" ]; then
    git clone "$LCD_REPO"
    chmod -R 755 LCD-show/
fi
sleep 1
echo "Warning! the LCD driver tries to force a reboot"
#System will force a reboot... 
read -p "Install LCD driver now? This will force a reboot! (y/n) " -n 1 -r 
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd LCD-show/
    ./LCD35-show
    #system reboot happens from driver install
fi

#return
cd "$(dirname "$0")"


# in case these are running prior to setting up
echo ""
echo "stopping conflicting services..."
systemctl stop hostapd 2>/dev/null || true
systemctl stop dnsmasq 2>/dev/null || true
systemctl disable hostapd 2>/dev/null || true
systemctl disable dnsmasq 2>/dev/null || true

# run system check python program
echo ""
echo "Running a system check"
python3 scripts/system_check.py

if [ $? -eq 0 ]; then 
    echo ""
    echo "Good to go!"
else
    echo ""
    echo "System check failed"
    exit 1
fi

#install python gui/tui tools
echo ""
echo "Install Python packages for interfaces...."
for package in "${PYTHON_DEPS[@]}"; do 
    echo "installing $package..."
    pip3 install "$package" --break-system-packages
done 

#reticulum install 
echo ""
echo "installing reticulum..."

pip3 install rns --break-system-packages

#verify 
if command -v rnsd &> /dev/null; then
    echo "Installed!"
    rnsd --version
else
    echo "reticulum install failed!"
    exit 1
fi


#install LXMF
echo ""
echo "Installing LXMF..."
pip3 install lxmf --break-system-packages

#install nomadnet
pip3 install nomadnet --break-system-packages 

#install meshchat
echo "installing meshchat now"

if [ ! -d "/opt/meshchat" ]; then
    git clone "$MESHCHAT_REPO" /opt/meshchat
    cd /opt/meshchat
    npm install
    npm run build-frontend
    cd ~
else
    echo "meshchat already installed! updating..."
    cd /opt/meshchat
    git pull
    npm install
    npm run build-frontend
    cd ~
fi

#run meshchat once to create database
echo "initializing meshchat database..."
cd /opt/meshchat
timeout 10 python3 meshchat.py &
MESHCHAT_PID=$!
sleep 5
kill $MESHCHAT_PID 2>/dev/null || true
cd ~

#reticulum configuration 
echo "Creating reticulum config directory..."
mkdir -p /root/.reticulum
mkdir -p /home/$SUDO_USER/.reticulum 2>/dev/null || true

echo "generating an ID..."
if [ ! -f "/root/.reticulum/identity" ]; then
    rnsd --daemon
    sleep 3
    pkill rnsd
    echo "ID generated!"
else
    echo "ID already exists skipping..."
fi

#create reticulum config
echo ""
echo "Creating Reticulum configuration..."
cat > /root/.reticulum/config << 'EOF'
[reticulum]
enable_transport = yes
share_instance = yes

[logging]
loglevel = 4

[interfaces]
  [[Default Interface]]
    type = AutoInterface
    enabled = yes
EOF
echo "Reticulum configured!"

#set up auto login for raspberrypi 
echo ""
echo "Setting up auto-login..."
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
EOF

#setting up systemd services
echo ""
echo "Setting up systemd services..."

#create rnsd service
cat > /etc/systemd/system/rnsd.service << 'EOF'
[Unit]
Description=Reticulum Network Stack Daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/rnsd --service
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

#create meshchat service
cat > /etc/systemd/system/meshchat.service << 'EOF'
[Unit]
Description=Reticulum MeshChat
After=network.target rnsd.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/meshchat
ExecStart=/usr/bin/python3 meshchat.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

#create nomadnet service
cat > /etc/systemd/system/nomadnet.service << 'EOF'
[Unit]
Description=Nomadnet BBS
After=network.target rnsd.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/nomadnet --daemon
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable rnsd
systemctl enable meshchat
systemctl enable nomadnet

echo "services installed!"

#setup wifi access point
echo ""
echo "Setting up WiFi Access Point..."
echo "Detecting wireless adapters..."

#get list of wireless interfaces
WIFI_INTERFACES=$(iw dev | grep Interface | awk '{print $2}')

if [ -z "$WIFI_INTERFACES" ]; then
    echo "No WiFi adapters found!"
    echo "You can configure this manually later"
    read -p "Continue without Access Point? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    SKIP_AP=true
else
    echo "Found wireless adapters:"
    echo ""
    
    #create array from interfaces
    IFS=$'\n' read -rd '' -a WIFI_ARRAY <<< "$WIFI_INTERFACES"
    
    #display numbered list
    for i in "${!WIFI_ARRAY[@]}"; do
        IFACE="${WIFI_ARRAY[$i]}"
        echo "  [$i] $IFACE"
        
        #show if interface is USB or built-in
        if udevadm info /sys/class/net/$IFACE 2>/dev/null | grep -q "usb"; then
            echo "      (USB WiFi adapter)"
        else
            echo "      (Built-in WiFi)"
        fi
    done
    
    echo ""
    echo "Which adapter should be the Access Point?"
    read -p "Enter number (or 's' to skip): " AP_CHOICE
    
    if [[ "$AP_CHOICE" =~ ^[0-9]+$ ]] && [ "$AP_CHOICE" -lt "${#WIFI_ARRAY[@]}" ]; then
        AP_INTERFACE="${WIFI_ARRAY[$AP_CHOICE]}"
        echo "Selected: $AP_INTERFACE"
        
        #ask for AP settings
        echo ""
        read -p "WiFi network name (default: RNode_Box): " AP_SSID
        AP_SSID=${AP_SSID:-RNode_Box}
        
        read -p "WiFi password (default: reticulum): " AP_PASSWORD
        AP_PASSWORD=${AP_PASSWORD:-reticulum}
        
        #configure hostapd
        echo ""
        echo "Configuring Access Point..."
        sed "s/INTERFACE_NAME/$AP_INTERFACE/g" config/hostapd.conf.template > /etc/hostapd/hostapd.conf
        sed -i "s/RNode_Box/$AP_SSID/g" /etc/hostapd/hostapd.conf
        sed -i "s/PASSWORD_HERE/$AP_PASSWORD/g" /etc/hostapd/hostapd.conf
        
        #set static IP for AP interface
        echo ""
        echo "Setting static IP for Access Point..."
        ip addr flush dev $AP_INTERFACE
        ip addr add 10.0.0.1/24 dev $AP_INTERFACE

        #make persistent
        cat >> /etc/dhcpcd.conf << IPEOF

# RnodeBox Access Point
interface $AP_INTERFACE
static ip_address=10.0.0.1/24
nohook wpa_supplicant
IPEOF
        
        #configure dnsmasq
        cat > /etc/dnsmasq.conf << EOF
interface=$AP_INTERFACE
dhcp-range=10.0.0.10,10.0.0.100,24h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
EOF
        
        #enable and start services
        systemctl unmask hostapd
        systemctl enable hostapd
        systemctl enable dnsmasq
        systemctl start hostapd
        systemctl start dnsmasq
        
        echo "Access Point configured!"
        echo "SSID: $AP_SSID"
        echo "Password: $AP_PASSWORD"
        echo "IP: 10.0.0.1"
        
    else
        echo "Skipping Access Point setup"
        SKIP_AP=true
    fi
fi


echo ""
echo "setup complete!!"
echo "recommended to reboot!"

