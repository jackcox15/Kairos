#!/bin/bash

echo "Uninstalling RNode Router..."

#check for root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo!"
    exit 1
fi

#stop all services
echo "Stopping services..."
systemctl stop rnsd 2>/dev/null || true
systemctl stop meshchat 2>/dev/null || true
systemctl stop nomadnet 2>/dev/null || true
systemctl stop hostapd 2>/dev/null || true
systemctl stop dnsmasq 2>/dev/null || true

#disable services
echo "Disabling services..."
systemctl disable rnsd 2>/dev/null || true
systemctl disable meshchat 2>/dev/null || true
systemctl disable nomadnet 2>/dev/null || true
systemctl disable hostapd 2>/dev/null || true
systemctl disable dnsmasq 2>/dev/null || true

#remove service files
echo "Removing service files..."
rm -f /etc/systemd/system/rnsd.service
rm -f /etc/systemd/system/meshchat.service
rm -f /etc/systemd/system/nomadnet.service

systemctl daemon-reload

#remove meshchat
echo "Removing MeshChat..."
rm -rf /opt/meshchat

#remove reticulum configs
echo "Removing Reticulum configs..."
rm -rf /root/.reticulum
rm -rf /home/$SUDO_USER/.reticulum 2>/dev/null || true

#remove hostapd config
echo "Removing Access Point configs..."
rm -f /etc/hostapd/hostapd.conf
rm -f /etc/dnsmasq.conf

#remove dhcpcd AP config
echo "Cleaning network configs..."
sed -i '/# RnodeBox Access Point/,+3d' /etc/dhcpcd.conf

#remove auto-login
echo "Removing auto-login..."
rm -rf /etc/systemd/system/getty@tty1.service.d/

#uninstall python packages
echo "Removing Python packages..."
pip3 uninstall -y rns lxmf nomadnet kivy aiohttp peewee websockets pyserial cx_freeze 2>/dev/null || true

echo ""
echo "Uninstall complete!"
echo "Reboot recommended"
