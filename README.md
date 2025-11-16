# What is Kairos?
Kairos is a reproducible deployment system for Reticulum based mesh networks. Its purpose is to make resilient, censorship resistant communication practical and accessible for mutual aid groups, community organizers, independent press, and privacy focused individuals.
Kairos provides the toolkits, configuration, and workflows needed to deploy and maintain mesh communication nodes on laptops, Raspberry Pis, or LoRa devices with minimal setup and no centralized authority. It turns complex networking into a "plug-and-operate" system, enabling communities to build and maintain their own communication infrastructure even in degraded, surveilled, or disconnected environments. These tools give users the power to quickly spin up their own local Reticulum mesh 
networks and seed resiliant community infrastructure.

Kairos combines internet based infrastructure (utilizing securely owned virtual private servers + WireGuard) with local LoRa radio networks to create communications that work with or without internet connectivity.
The system is designed for graceful degradation: as infrastructure fails, the network automatically falls back from:
#### GLOBAL → REGIONAL → LOCAL ONLY

## What Problem Does This Solve?
Reticulum is a powerful cryptographic network protocol, but deploying it at scale for non-tech savvy people can be difficult. 
Kairos strives to simplify the setup of LoRa radios, Reticulum deployments, and organically build local resilient communication networks with minimum effort
- Automated Deployment - Live USB systems that come preconfigured with helper tools
- Hardware Integration – Plug and play RNode devices with automated firmware flashing, and PHY settings, and reticulum config updates
- User Interface - MeshChat web UI instead of command line only, RaspberryPi Python programs, and custom management programs
- Infrastructure Setup - VPS backbone with WireGuard VPN for global connectivity **if you join KairosNet**
- Operational Security – Built in OPSEC practices for adversarial environments

Three Layers:
1. VPS Backbone - Redundant servers for global connectivity through the Kairos VPN network
2. Home Nodes - Your computer + RNode bridging internet and RF mesh
3. LoRa Network - Local radio mesh (1-20+ mile range, works without internet)
   
Graceful Degradation:
- Internet works → Global mesh via VPS + local LoRa
- Internet fails → Local LoRa mesh only
- Infrastructure seized → Device-to-device via LoRa 

# Quick Start
#### Every node requires:
- Computer (x86 mini PC, old desktop server, or Raspberry Pi) 
- LoRa RNode (Heltec v3, LILYGO T-Beam, LoRa32, etc.) 
- USB cable to connect them, ensure data cables, not just charge.

## Deployment Options
Option 1: Live USB (Recommended for technical users)
- Bootable Ubuntu system with automated setup and preconfigured tools 
- Works on any x86 computer without permanent installation 
- Scripts to automate LoRa Config, and easily manage the system

Option 2: RNode Box (Raspberry Pi relay/repeater)
- Pre-built Pi Zero system with Pimornai ST7789 display 
- Solar + battery power for field deployment 
- LoRa device connected to USB hub, or via MicroUSB cable 
      
Option 3: RNode Gateway
- Raspberry Pi with WiFi AP and web interface 
- Plug and play for non-technical users 
- 3.5" LCD with real-time status monitoring 
 
# Technology Stack
#### Core:
- Reticulum Network Stack - Mesh routing protocol 
- RNode - LoRa radio interfaces 
- WireGuard - VPN backbone connectivity 
#### Applications:
- MeshChat - Web messaging UI 
- Nomadnet - Mesh services platform 
- LXMF - Lightweight message format

# Philosophy: Infrastructure as Mutual Aid
Kairos represents a different approach to technology infrastructure:
- Not a Product: No app stores, no subscriptions, no platforms
- Not a Service: No company, no terms of service, no data collection
- Not a Startup: No investors, no exit strategy, no growth metrics
#### Instead: **Community owned infrastructure built through mutual aid principles.**
#### Target Audience: Trusted network of vetted individuals distributed through small cells of aligned individuals. This is intentionally not mass-market, it's infrastructure for communities who need it.

# Alternative Transports
While the main Kairos Network uses WireGuard for sovereignty reasons, 
the Reticulum mesh layer works over any IP transport. You could adapt 
these scripts to use Tailscale, ZeroTier, I2P, yggsdrasil, or even direct internet 
connections if that fits your community's needs better.

# Community & Contribution
#### Getting Involved
Kairos operates through trust networks rather than public channels. We carefully vet new participants:
- Personal connections and trusted referrals preferred 
- Mutual aid groups and community organizations prioritized 
- Contributions should align with project values 

Contributing Code
We welcome contributions that:
- Improve deployment automation 
- Enhance user experience for non-technical users 
- Add monitoring and diagnostic capabilities 
- Improve documentation 
See CONTRIBUTING.md for guidelines.

# Credits
Kairos is built on the incredible work of:
- Mark Qvist (@markqvist) - Creator of Reticulum, RNode, Nomadnet, and LXMF. This project would not exist without the foundational work Mark has done on the protocol and ecosystem.
Checkout the Reticulum Github: https://github.com/markqvist/Reticulum

- Liam Cottle (@liamcottle) - Creator of MeshChat web interface, providing an accessible UI for Reticulum messaging.
Checkout the Reticulum-Meshchat Github: (https://github.com/liamcottle/reticulum-meshchat)
  
**Kairos is integration and deployment work. Taking these excellent open source tools and making them accessible to non-technical users who need resilient communications.**

#### Note on OPSEC: While code is open source, operational details (node locations, user identities, deployment strategies) remain confidential. Please respect the security needs of communities using this infrastructure.

## Contact
#### For Technical Questions About Reticulum:
- See the Reticulum community forums (https://github.com/markqvist/Reticulum/discussions)
#### For KAIROS Deployment:
- This project operates through trusted networks. If you're involved with mutual aid or community organizing and share our values, reach out through existing community channels, or on Github.

