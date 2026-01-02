# What is Kairos?

Kairos is a deployment automation toolkit for Reticulum based mesh networks. It provides scripts, configurations, and documentation to help deploy your own resilient communications infrastructure with minimal technical expertise required.

---

## Hardware Requirements

**Minimum setup (single node):**
- Computer: Raspberry Pi 3+, 4, 5, Zero, or x86 Linux PC
- LoRa Radio: Heltec v3, LILYGO T-Beam, or compatible RNode device
- USB cable: Data cable (not charge only)
- Power supply: For continuous operation

**Supported hardware:**
- **Computers:** Raspberry Pi (Zero, 3, 4, 5), x86 desktops/laptops, mini-PCs
- **LoRa devices:** Heltec v3, LILYGO T-Beam, LoRa32, compatible ESP32+SX127x/SX126x
- **Displays:** Pimoroni ST7789, 3.5" TFT for status monitoring

**Currently works on: Debian, Ubuntu, Raspberry Pi OS, Arch Linux**
---

## Deploy as a RaspberryPi Router/Gateway
**RNode Gateway:** Pi + LoRa + WiFi AP
- Plug and play community access point with AP
- Web interface for non-technical users accessible on personal devices
- LCD status display to monitor Reticulum Pi Node

**RNode Repeater:** Pi Zero + LoRa + solar
- Field deployable repeater/relay
- Battery + solar power
- Weatherproof enclosure capable
- Hardware monitoring optional

## Deploy on a PC
- Full setup including Meshchat, Nomadnet, and Reticulum services
- RNode detection scripts, flashing assistance, custom PHY settings made easy
- Supports Wireguard VPN / VPS setups and auto bakes into the reticulum config

---

## Technology Stack

**Core components:**
- [Reticulum Network Stack](https://github.com/markqvist/Reticulum) - Mesh routing protocol (Mark Qvist)
- [RNode](https://github.com/markqvist/RNode_Firmware) - LoRa radio firmware (Mark Qvist)
- [MeshChat](https://github.com/liamcottle/reticulum-meshchat) - Web messaging UI (Liam Cottle)
- [Nomadnet](https://github.com/markqvist/NomadNet) - Mesh services platform (Mark Qvist)
- WireGuard - VPN backbone connectivity

---

## Documentation

**Comprehensive guides / explainations at:** [https://jackcox15.github.io/Kairos/](https://jackcox15.github.io/Kairos/)

## Philosophy: Infrastructure as Mutual Aid
Kairos represents a different approach to technology:

### Not a Product
No app stores, no subscriptions, no platforms.

### Not a Service  
No company, no terms of service, no data collection.

### A Toolkit
**Open source tools for communities and people to build their own infrastructure.**

---

## Use Cases

### Mutual Aid Networks
- Deploy mesh for coordinating disaster response, resource distribution, and community care without dependency on infrastructure that fails during crises.

### Community Organizing
- Secure communications for organizing actions, coordinating logistics, maintaining operations under surveillance or in hostile environments.

### Independent Press
- Infrastructure to protect sources and maintain communications when corporate platforms face censorship or compromise.

### Disaster Preparedness
- Backup communications when cellular/internet fails. Pre-deployed, tested, ready when needed.

### Privacy focused communities  
- Communications outside surveillance capitalism while maintaining usability for non-technical members.

---

## Credits

Kairos stands on the shoulders of:

**Mark Qvist ([@markqvist](https://github.com/markqvist))** - Creator of Reticulum, RNode, Nomadnet, LXMF. This project would not exist without Mark's foundational work on the protocol and ecosystem.

**Liam Cottle ([@liamcottle](https://github.com/liamcottle))** - Creator of MeshChat web interface, providing an accessible UI for Reticulum messaging.

**Kairos is integration work** - taking excellent FOSS tools and making them deployable by communities who need resilient communications.

---

**Build infrastructure that lasts. Share knowledge freely. Own your communications.**
