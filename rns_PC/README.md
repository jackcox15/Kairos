# Kairos Deployment Scripts
## Automated installer for Reticulum mesh networking infrastructure

**The goal of Kairos is to make decentralized mesh communication easy to deploy and accessible to anyone.**

This installer helps you quickly set up:
- Local Reticulum mesh networks for you or your community
- Optional VPS backbone for global connectivity, if hosting one
- All necessary software and services configured automatically

---

## What This Installs

The deployment script automatically configures:

- **Reticulum Network Stack** - Core mesh routing protocol
- **Nomadnet** - Mesh services and bulletin boards
- **MeshChat** - Web-based messaging interface (http://localhost:8000)
- **LXMF** - Lightweight message format
- **RNode support** - Automatic detection and configuration for LoRa radios
- **Systemd services** - Auto-start on boot
- **Helper scripts** - For hardware deployment and diagnostics

---

## Deployment Modes

### Mode 1: Local Mesh Only (Recommended to start)
Deploy a standalone mesh network:
- Works entirely on local LoRa radio
- No internet required for operation
- Perfect for learning, testing, or isolated communities
- No external dependencies

### Mode 2: VPS Backbone (Optional)
Add global connectivity to your local mesh with Wireguard Tunnels:
- Connect your local mesh to your VPS infrastructure 
- Requires WireGuard VPN credentials (you deploy your own VPS)
- Enables communication across cities/regions when internet available
- Local mesh continues working if VPN/internet fails

**You choose which mode fits your deployment.**

---

## Requirements

**Supported Systems:**
- Debian 11+
- Ubuntu 20.04+
- Arch Linux

**Hardware:**
- Computer with 1GB+ RAM
- Internet access for initial setup
- (Optional) RNode LoRa device for local mesh

**For VPS Backbone Mode:**
- WireGuard credentials from your VPS deployment
- Utilize the key_baker script to replace the deploy_rns wireguard variables with
  your own VPN

---

## Quick Start: Local Mesh

**Deploy a standalone local mesh node:**

```bash
# Clone repository
git clone https://github.com/jackcox15/Kairos
cd Kairos/rns_PC

# Make script executable
chmod +x deploy_rns.sh

# Run installer
sudo ./deploy_rns.sh
```

**What you get:**
- Reticulum configured for AutoInterface (local discovery)
- MeshChat web UI at http://localhost:8000
- Nomadnet CLI available
- RNode support ready (plug in LoRa device)
- Services auto start on boot

---

## VPS Backbone Setup:

**If you've deployed your own VPS/VPN infrastructure and want to connect this node:**

### Step 1: Generate Configured Installer

The `key_baker.sh` script creates a customized installer with your VPN credentials embedded:

```bash
# Make scripts executable
chmod +x key_baker.sh deploy_rns.sh

# Run key baker
./key_baker.sh
```

**You'll be prompted for:**
- **Client name** 
- **WireGuard private key**
- **WireGuard public key**
- **Client IP**
- **Server public key** 
- **Endpoint** 
- **Internal VPS IP** 

**Output:** Creates `configured_scripts/deploy_rns_<CLIENT>.sh`

### Step 2: Deploy on Target System

**Option A: Deploy on current machine**
```bash
cd configured_scripts
sudo ./deploy_rns_<CLIENT>.sh
```

**When prompted:**
- "Do you have VPN credentials?" → Choose **Yes**
- The script will configure VPN + local mesh

---

## After Installation

### What's Running

**Services:**
```bash
# Check status
sudo systemctl status reticulum
sudo systemctl status meshchat

# View logs
sudo journalctl -u reticulum -f
sudo journalctl -u meshchat -f

# Restart if needed
sudo systemctl restart reticulum
sudo systemctl restart meshchat
```

**Interfaces:**
- **MeshChat:** http://localhost:8000 (web messaging)
- **Nomadnet:** Run `nomadnet` in terminal (mesh services, TUI version)

**Configuration:**
- Reticulum config: `~/.reticulum/config`
- Identity: `~/.reticulum/identity`
- Logs: `journalctl -u reticulum`

### Detect RNode Devices

**Plug in your LoRa RNode, then:**
```bash
detect-rnodes.sh
```

**Expected output:**
```
Found RNode at /dev/ttyUSB0
```

**Configure the RNode:**
```bash
# See RNode setup guide for configuration
# Location: /docs/rnode-setup.md
```

### Management Tool: rnsctl

**Launch interactive menu:**
```bash
rnsctl
```

**Menu options:**
- View System Status
- Manage Services (start/stop/restart)
- View Network Activity
- View Messages
- Open Chat Interface
- VPN Status (if configured)
- System Health Check
- Quick Fixes
- Troubleshooting Guide

**Quick status check:**
```bash
rnsctl status
```
---


**Build your infrastructure. Own your communications.**
