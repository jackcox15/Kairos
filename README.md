# What is KAIROS?

KAIROS is a deployment automation toolkit for Reticulum based mesh networks. It provides scripts, configurations, and documentation to help communities deploy their own resilient communications infrastructure with minimal technical expertise required.

### The Problem

Reticulum is a powerful cryptographic mesh networking protocol, but deploying it requires:
- Understanding complex networking concepts
- Manual configuration of LoRa radios
- VPS setup and hardening
- Reticulum parameter tuning
- Integration of multiple components

**For non-technical users or time limited organizers, this is a barrier.**

### The Solution

Kairos provides:
- **One command deployment scripts** - Automated VPS backbone and node setup
- **Hardware auto config** - Plug and play RNode detection and flashing with your own PHY settings
- **Reference architectures** - Proven patterns you can replicate to seed local communitiies 
- **Comprehensive documentation** - Guides that teach concepts, not just commands
- **Operational security guidance** - OPSEC practices built into deployment

---

## Hardware Requirements

**Minimum setup (single node):**
- Computer: Raspberry Pi 3+, 4, 5, Zero, or x86 (1GB RAM minimum)
- LoRa Radio: Heltec v3, LILYGO T-Beam, or compatible RNode device
- USB cable: Data cable (not charge only)
- Power supply: For continuous operation

**Recommended for community deployment:**
- Multiple nodes: Mix of Pi and x86 for different roles
- External antennas: Improved range for fixed installations
- Battery backup: UPS or solar for resilience
- VPS servers: Optional global connectivity (3+ in different regions)

**Supported hardware:**
- **Computers:** Raspberry Pi (Zero, 3, 4, 5), x86 desktops/laptops, mini-PCs
- **LoRa devices:** Heltec v3, LILYGO T-Beam, LoRa32, compatible ESP32+SX127x/SX126x
- **Displays:** Pimoroni ST7789, 3.5" TFT for status monitoring

**Currently works on: Debian, Ubuntu, Raspberry Pi OS, Arch Linux**

### Deploy on PC, VM, or Server
- Pre-configured Reticulum environment
- RNode flashing tools included
- No installation required
- Leaves no trace on host

*(Prebuilt images coming soon - for now, use deployment scripts)*

### Deploy as a RaspberryPi Router/Gateway
**RNode Gateway:** Pi + LoRa + WiFi AP
- Plug and play community access point with AP
- Web interface for non-technical users accessible on personal devices
- LCD status display to monitor Reticulum Pi Node

**RNode Box:** Pi Zero + LoRa + solar
- Field deployable repeater/relay
- Battery + solar power
- Weatherproof enclosure capable
- Hardware monitoring optional

---

## Example Deployment

**NodeZero HUB** (reference implementation coming soon):

- **Operator:** enigma
- **Scale:** Multi-city (Detroit/Boston/Cleveland)
- **Infrastructure:** 3 VPS (Japan, Europe, US)
- **Nodes:** 10 active (mix of Pi, VM, PC, and LoRa)
- **Use case:** Kairos Playground for testing with friends

This is **one example**. Your deployment will be different based on:
- Community size and geography
- Threat model and security needs
- Budget and technical capacity
- Specific use cases

**KAIROS provides the tools. You design your network.**

---

## Technology Stack

**Core components:**
- [Reticulum Network Stack](https://github.com/markqvist/Reticulum) - Mesh routing protocol (Mark Qvist)
- [RNode](https://github.com/markqvist/RNode_Firmware) - LoRa radio firmware (Mark Qvist)
- [MeshChat](https://github.com/liamcottle/reticulum-meshchat) - Web messaging UI (Liam Cottle)
- [Nomadnet](https://github.com/markqvist/NomadNet) - Mesh services platform (Mark Qvist)
- WireGuard - VPN backbone connectivity

**KAIROS is deployment automation** - scripts and documentation that make these components deployable by non-experts.

---

## Documentation

**Comprehensive guides at:** [https://jackcox15.github.io/Kairos/](https://jackcox15.github.io/Kairos/)

## Philosophy: Infrastructure as Mutual Aid

KAIROS represents a different approach to technology:

### Not a Product
No app stores, no subscriptions, no platforms.

### Not a Service  
No company, no terms of service, no data collection.

### A Toolkit
**Open source tools for communities to build their own infrastructure.**

### Core Principles

**Sovereignty:** Communities own and operate their infrastructure  
**Resilience:** Multiple redundant paths, graceful degradation  
**Privacy:** End-to-end encryption, minimal metadata  
**Accessibility:** Complex tech made usable  
**Mutual Aid:** Knowledge shared freely, not sold

**Build infrastructure that outlasts its creators.**

---

## Use Cases

### Mutual Aid Networks
Deploy mesh for coordinating disaster response, resource distribution, and community care without dependency on infrastructure that fails during crises.

### Community Organizing
Secure communications for organizing actions, coordinating logistics, maintaining operations under surveillance or in hostile environments.

### Independent Press
Infrastructure to protect sources and maintain communications when corporate platforms face censorship or compromise.

### Disaster Preparedness
Backup communications when cellular/internet fails. Pre-deployed, tested, ready when needed.

### Privacy-Focused Communities  
Communications outside surveillance capitalism while maintaining usability for non-technical members.

---

## Credits

KAIROS stands on the shoulders of:

**Mark Qvist ([@markqvist](https://github.com/markqvist))** - Creator of Reticulum, RNode, Nomadnet, LXMF. This project would not exist without Mark's foundational work on the protocol and ecosystem.

**Liam Cottle ([@liamcottle](https://github.com/liamcottle))** - Creator of MeshChat web interface, providing an accessible UI for Reticulum messaging.

**KAIROS is integration work** - taking excellent FOSS tools and making them deployable by communities who need resilient communications.

---

**Build infrastructure that lasts. Share knowledge freely. Own your communications.**
