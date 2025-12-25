# Kairos PC Installer 
## This script installs and prepares your system for LoRa radio usage, Installs Reticulum, Nomadnet, MeshChat web interface + more!!
**The goal of Kairos is to make decentralized communication easy to deploy, prepackaged, and accessible to anyone.**
**This allows you to quickly seed local communities, run resilient communication hubs, and expand your mesh network with minimal effort.**

**Joining the Kairos network is optional! You can run a standalone local mesh, or connect to the Kairos VPS hub if you have credentials. If you do not wish to join the private Kairos network, you can simply select "No"
during the installer!**

### Installer supports two modes:
- Local mesh only (If desire is for seeding your own local community)
- Kairos network mode (VPN tunnel if you have credentials)
#### After installation you get:
- Reticulum running as a system service
- MeshChat at http://localhost:8000
- Nomadnet CLI
- Kaiosctl Whiptail TUI for system management
- Helper scripts for deploying hardware 
- **Optional:** WireGuard tunnel if you would like to join the Kairos network

# Features
### The script automatically:
- Installs all required packages (Python, pip, git, curl, Node.js, etc.)
- Installs Reticulum, Nomadnet, LXMF, and MeshChat
- Creates a Reticulum config with AutoInterface
- Adds optional Kairos TCP interface if using VPN tunnel 
- Installs udev rules for RNodes
- Creates systemd services for Reticulum and MeshChat
- Builds and installs the MeshChat web UI
- Enables and starts all services
- Optionally creates desktop shortcuts if a desktop environment exists

# Requirements
- Debian or Ubuntu
- Now supporting Arch Linux!!
- Run with sudo
- Internet access for apt, git, and npm installs
- For Kairos mode: WireGuard credentials provided by 3n19ma
### Files in this Folder
- deploy_rns.sh: main installer
- key_baker.sh: generates a version of the installer with your WireGuard keys included


# How to Run the Installer
#### Local Mesh Only (no VPN)
- `git clone https://github.com/jackcox15/Kairos`
- `cd Kairos/rns_PC`
- `chmod +x deploy_rns.sh`
- `sudo ./deploy_rns.sh`
#### When prompted, choose **no** for KAIROS credentials.

# Kairos Mode: Bake Your Keys Into the Script
#### To create an installer with your VPN keys:
- `chmod +x key_baker.sh deploy_rns.sh`
- `./key_baker.sh`

#### You will be asked for:
- Client name
- WireGuard private key
- WireGuard public key
- Client IP
- Server public key
- Endpoint
- Internal VPS IP
#### The script creates: your/directory/configured_scripts/deploy_rns_<YOURCLIENT>.sh
#### This file is ready to run on the client machine.


# Kairos Network Mode (with VPN)
#### First bake your keys:
- `./key_baker.sh`
- Copy the generated script to the client system:
- `scp /from/your/directory/deploy_rns_<CLIENT>.sh user@client:/to/your/directory`
- Or run it directly on your machine if running locally!
- `cd /your/directory/to/Kairos/configured_scripts`
- `./deploy_rns<yourclientname>`
##### Choose yes when asked if you have KAIROS credentials.

# After Installation
#### You should now have:
- MeshChat: http://localhost:8000
- Nomadnet: run nomadnet in a terminal
- Reticulum config at ~/.reticulum/config
- RNode detection script at /usr/local/bin/detect-rnodes.sh
#### Useful commands:
- `sudo systemctl status reticulum meshchat`
- `sudo systemctl restart reticulum`
- `sudo systemctl restart meshchat`
- `sudo journalctl -u reticulum -f`
- `sudo journalctl -u meshchat -f`
#### To detect a plugged-in RNode:
`detect-rnodes.sh`
**Expected output**: Your device should appear ( `/dev/ttyUSB0` or `/dev/ttyACM0`)

## TUI Management tool "kairosctl"

After installation, use `kairosctl` for easy system management!

### Quick Start

Simply run:
```bash
kairosctl
```

This launches an interactive menu where you can:

- **View System Status**
- **Manage Services** 
- **View Network Activity** 
- **View Messages** 
- **Open Chat Interface** 
- **VPN Status**
- **System Health Check**
- **Quick Fixes** 
- **Troubleshooting Guide** 

For quick status checks:
```bash
kairosctl status
```
