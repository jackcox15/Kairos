#!/usr/bin/env bash
# kairos-nuke.sh - Complete Kairos cleanup script

set -e

echo "═════════════════════════════════════════"
echo "            CLEANUP SCRIPT"
echo═══════════════════════════════════════════"
echo ""
echo "This will DELETE:"
echo "  • All  services (Reticulum, MeshChat)"
echo "  • All configuration files"
echo "  • All databases and message history"
echo "  • All installed binaries"
echo "  • WireGuard VPN configs (optional)"
echo ""
read -p "Are you ABSOLUTELY sure? Type 'NUKE' to continue: " confirm

if [[ "$confirm" != "NUKE" ]]; then
    echo "Cancelled. Nothing was deleted."
    exit 0
fi

echo ""
echo "Starting cleanup..."

# ===== Stop all services =====
echo ""
echo "[1/8] Stopping services..."

# Stop user services
systemctl --user stop reticulum.service 2>/dev/null || true
systemctl --user stop rnsd.service 2>/dev/null || true
systemctl --user stop meshchat.service 2>/dev/null || true

# Stop system services
sudo systemctl stop reticulum.service 2>/dev/null || true
sudo systemctl stop rnsd.service 2>/dev/null || true
sudo systemctl stop meshchat.service 2>/dev/null || true

echo "   Services stopped"

# ===== Disable all services =====
echo ""
echo "[2/8] Disabling services..."

# Disable user services
systemctl --user disable reticulum.service 2>/dev/null || true
systemctl --user disable rnsd.service 2>/dev/null || true
systemctl --user disable meshchat.service 2>/dev/null || true

# Disable system services
sudo systemctl disable reticulum.service 2>/dev/null || true
sudo systemctl disable rnsd.service 2>/dev/null || true
sudo systemctl disable meshchat.service 2>/dev/null || true

echo "   Services disabled"

# ===== Remove service files =====
echo ""
echo "[3/8] Removing service files..."

# User service files
rm -f ~/.config/systemd/user/reticulum.service
rm -f ~/.config/systemd/user/rnsd.service
rm -f ~/.config/systemd/user/meshchat.service

# System service files
sudo rm -f /etc/systemd/system/reticulum.service
sudo rm -f /etc/systemd/system/rnsd.service
sudo rm -f /etc/systemd/system/meshchat.service

# Reload systemd
systemctl --user daemon-reload 2>/dev/null || true
sudo systemctl daemon-reload 2>/dev/null || true

echo "    Service files removed"

# ===== Remove installed binaries =====
echo ""
echo "[4/8] Removing installed binaries..."

# Remove kairosctl
sudo rm -f /usr/local/bin/kairosctl
sudo rm -f ~/.local/bin/kairosctl

# Remove other Kairos binaries if they exist
sudo rm -f /usr/local/bin/kairos-*
rm -f ~/.local/bin/kairos-*

echo "    Binaries removed"

# ===== Remove Reticulum installation =====
echo ""
echo "[5/8] Removing Reticulum..."

# Remove Reticulum config and data
rm -rf ~/.reticulum

# Uninstall Reticulum packages (if installed via pip)
pip3 uninstall -y rns 2>/dev/null || true
pip3 uninstall -y reticulum 2>/dev/null || true

echo "    Reticulum removed"

# ===== Remove MeshChat installation =====
echo ""
echo "[6/8] Removing MeshChat..."

# Remove MeshChat from /opt
sudo rm -rf /opt/reticulum-meshchat

# Remove MeshChat from home directory
rm -rf ~/reticulum-meshchat
rm -rf ~/.local/share/reticulum-meshchat
rm -rf ~/.config/reticulum-meshchat

# Uninstall MeshChat Python package if installed
pip3 uninstall -y reticulum-meshchat 2>/dev/null || true

echo "    MeshChat removed"

# ===== Remove logs and temporary files =====
echo ""
echo "[7/8] Removing logs and cache..."

# Remove Kairos logs
rm -rf ~/rns_logs
rm -rf ~/.config/kairosctl
rm -f ~/kairos-status.txt

# Remove any Kairos-related temp files
rm -f /tmp/kairos*
rm -f /tmp/meshchat*
rm -f /tmp/rns*

echo "    Logs and cache removed"

# ===== Optional: WireGuard cleanup =====
echo ""
echo "[8/8] WireGuard VPN cleanup..."
read -p "Remove WireGuard configs too? (y/N): " remove_wg

if [[ "$remove_wg" =~ ^[Yy]$ ]]; then
    # Stop WireGuard interfaces
    sudo wg-quick down wg0 2>/dev/null || true
    sudo wg-quick down wg1 2>/dev/null || true
    
    # Remove WireGuard configs (BACKUP FIRST!)
    if [[ -d /etc/wireguard ]]; then
        sudo mkdir -p ~/wireguard-backup-$(date +%Y%m%d-%H%M%S)
        sudo cp -r /etc/wireguard ~/wireguard-backup-$(date +%Y%m%d-%H%M%S)/ 2>/dev/null || true
        sudo rm -rf /etc/wireguard/*.conf
        echo "   ✓ WireGuard configs backed up and removed"
    fi
else
    echo "    WireGuard configs kept"
fi

# ===== Final cleanup =====
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  CLEANUP COMPLETE"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "The following have been removed:"
echo "   All services (stopped and disabled)"
echo "   Service files"
echo "   Installed binaries (kairosctl, etc.)"
echo "   Reticulum installation and configs"
echo "   MeshChat installation and databases"
echo "   All logs and cache files"
[[ "$remove_wg" =~ ^[Yy]$ ]] && echo "  ✓ WireGuard configs (backed up)"
echo ""
echo "System is now clean. You can reinstall Kairos fresh."
echo ""
echo "To reinstall:"
echo "  1. cd ~/Kairos"
echo "  2. git pull"
echo "  3. Run your installation script"
echo ""
