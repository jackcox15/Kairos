# Kairos: Deployment Automation for Reticulum Mesh Networks

---

## What Is Kairos?

Kairos is a **toolkit for deploying Reticulum based mesh networks**. It provides automated scripts, hardware configurations, and documentation to help communities build their own resilient communication infrastructure.

Think of it as:
- **Deployment automation** for the Reticulum Network Stack
- **Plug-and-play configuration** for LoRa hardware
- **Reference architectures** proven in real deployments
- **Infrastructure as code** that communities can own and operate

It's built for mutual aid groups, organizers, journalists, and communities who need communication systems they control.

---

## Why Does This Matter?

**The Problem:**

Centralized communication infrastructure fails exactly when you need it most:
- Internet shutdowns during protests or disasters
- Platform censorship and arbitrary bans
- Surveillance of organizing activity
- Emergency services collapse under load
- Dependency on corporate infrastructure

**The Solution:**

This project makes it practical to deploy your own mesh networks using proven open source protocols. Communities can communicate on infrastructure they own and operate.

---

## How It Works

Kairos automates deployment of networks with three layers:

### Layer 1: Global Backbone (Optional)
Connect your local mesh to others worldwide using VPS servers you control. Encrypted WireGuard tunnels provide global reach when internet is available.

### Layer 2: Local Radio Mesh
LoRa devices create city wide networks (5-15km range) that work without internet. Radio waves carry encrypted messages between nodes, creating resilient local infrastructure.

### Layer 3: Direct Device to Device
Even if everything else fails, any two devices can communicate directly through radio or local network discovery.

**The Key Feature:** These layers work together, but each layer remains functional if others fail. Internet outage? Radio mesh continues. No VPS? Local discovery works. This is resilient by design. More transport interfaces = more resiliance in your network.

---

## What You Get

Kairos provides the automation that makes Reticulum accessible:

**Deployment Scripts:**
- One command installation for Debian, Ubuntu, Arch
- Automated service configuration and startup
- VPS backbone setup with your own servers
- Hardware detection and configuration

**Hardware Support:**
- RNode auto detection and flashing
- Custom PHY parameter configuration
- Raspberry Pi gateway deploy scripts 
- LCD status displays with real time feedback

**Documentation:**
- Architecture explanations
- Hardware selection guides
- Operational security practices
- Troubleshooting workflows

**Management Tools:**
- Interactive service control
- Network diagnostics
- Status monitoring
- System health checks

---

## The Technology Stack

Kairos doesn't invent new protocols. It automates deployment of proven tools:

**Core Protocol:**
- **Reticulum Network Stack** - Encrypted mesh routing protocol by MarkQvist
- End-to-end encryption by default
- Works over any transport medium
- Designed for intermittent connectivity

**Hardware Layer:**
- **RNode Firmware** - Open LoRa radio firmware by MarkQvist
- 433/868/915 MHz operation (region dependent)
- 5-40km range depending on terrain, line of sight, and antennas
- Low power consumption for solar/battery operation

**Application Layer:**
- **MeshChat** - Web based messaging interface by Liam Cottle
- **Nomadnet** - Terminal services and bulletin boards by MarkQvist
- **LXMF** - Lightweight asynchronous messaging by MarkQvist

---

## Our Approach: Infrastructure as Mutual Aid

Kairos represents a specific philosophy about technology and community:

### Not a Service
No subscriptions, no terms of service, no company. These are tools you deploy on hardware you control.

### Not a Network to Join
Kairos doesn't operate a network. It helps you deploy your own. Your infrastructure, your rules, your community.

### Deployment Automation
Complex tasks automated so non-experts can deploy reliable infrastructure. But everything is documented and auditable.

### Core Principles

**Sovereignty:** Communities own and operate their infrastructure  
**Resilience:** Graceful degradation through redundant layers  
**Privacy:** End-to-end encryption, minimal metadata exposure  
**Accessibility:** Reticulum made deployable by non-experts  
**Mutual Aid:** Knowledge and tools shared freely, not sold

---

## Use Cases

### Community Organizing
Secure communications for coordinating actions and maintaining operations when facing surveillance or platform censorship.

### Mutual Aid Networks
Deploy mesh infrastructure for disaster response, resource coordination, and community care without dependency on systems that fail during crises.

### Independent Media
Infrastructure to protect sources and maintain communications outside corporate platforms vulnerable to pressure and compromise.

### Disaster Preparedness
Pre-deployed backup communications tested and ready before infrastructure fails. Works when cellular and internet don't.

### Privacy Communities
Communication systems outside surveillance capitalism while remaining accessible to non-technical members.

---

## Getting Started

### Prerequisites

**Knowledge:**
- Basic Linux command line
- Understanding of IP networking
- Willingness to read documentation

**Hardware (minimum):**
- Computer (Raspberry Pi, old laptop, mini PC)
- Internet for initial setup
- Optional: LoRa hardware for radio mesh

**For VPS backbone:**
- VPS server ($3-$10/month)
- Domain name (optional)
- WireGuard configuration knowledge

### Deployment Paths

**Path 1: Local Mesh (Start Here / add VPS if you want)**
```bash
git clone https://github.com/jackcox15/Kairos
cd Kairos/rns_PC
sudo ./deploy_rns.sh
```
Deploys standalone Reticulum node with local network discovery. No VPS required.

**Path 2: Add LoRa Hardware**
```bash
sudo detect-rnodes.sh
```
Auto-detects and configures RNode devices. Extends range to 5-15km.

**Path 3: Raspberry Pi Gateway**
See [Raspberry Pi Deployment](rns_RaspberryPi/) for gateway nodes with WiFi AP and LCD displays.

---

## Technical Details

### What Kairos Actually Does

**Automated Installation:**
- Detects OS (Debian/Ubuntu/Arch)
- Installs Reticulum and dependencies
- Configures systemd services
- Sets up MeshChat web interface
- Enables auto-start on boot

**Hardware Configuration:**
- Scans for RNode devices
- Flashes firmware if needed
- Configures radio parameters
- Updates Reticulum interface config
- Sets proper permissions

**VPS Integration:**
- Embeds WireGuard credentials via key_baker script
- Configures TCP interfaces
- Enables auto-reconnect
- Handles graceful degradation

**Service Management:**
- Interactive control menu
- Status monitoring
- Log viewing
- Network diagnostics
- Quick fixes for common issues

### Security Model

**What Is Protected:**
- Message content (Curve25519 end-to-end encryption)
- Identity information (cryptographic, not tied to real identity)
- Routing announcements (digitally signed)

**What Isn't Protected:**
- Packet headers (required for routing)
- Destination hashes (public identifiers, like IP addresses)
- Traffic metadata (timing, sizes)

**Threat Model:**
- Resistant to passive network monitoring
- Resistant to active MITM attacks
- Limited resistance to traffic analysis
- No resistance to physical device compromise

**Operational Security:**
- VPS operators see routing metadata, not content
- Full disk encryption recommended
- Identity backup is critical
- Physical security is user responsibility

---

## Who This Is For

Kairos is designed for communities and individuals who:

**Need resilient communications:**
- Mutual aid organizers coordinating disaster response
- Community groups facing platform censorship
- Journalists protecting their communications
- Privacy advocates building alternative infrastructure

**Have technical capacity:**
- Comfortable with command line basics
- Can follow detailed documentation
- Willing to learn networking concepts
- Able to troubleshoot with guidance

**Or have access to someone who does:**
- Community tech person deploys for group
- Hackerspaces as deployment hubs
- Tech collectives supporting organizing groups

**Not for:**
- People expecting plug-and-play consumer products
- Those unwilling to read documentation
- Use cases requiring anonymity (use Tor/I2P)
- High-stakes security without proper training

---

## Limitations and Honest Assessment

**This isn't magic:**

**Technical complexity remains:**
- Requires Linux knowledge
- VPS setup needs server experience
- Radio configuration has learning curve
- Troubleshooting needs debugging skills

**Physical infrastructure required:**
- Hardware costs money
- Radios need line-of-sight for best range
- Power and connectivity for 24/7 nodes
- Maintenance and monitoring needed

**Security trade-offs:**
- No formal security audit exists
- Metadata can leak information
- Physical security is critical
- Operational security requires discipline

**Not a complete solution:**
- Doesn't replace organizing skills
- Technology alone doesn't create security
- Community trust still required
- Legal and political context matters

**Kairos makes deployment easier. Mesh networks require hands on work!**

---

## Contributing

Kairos grows through community contribution:

**Ways to help:**
- Document your deployment experiences
- Report bugs and edge cases
- Improve installation scripts
- Write guides for specific hardware
- Test on different operating systems
- Share operational security practices

**What we need:**
- Testing on diverse hardware
- Feedback from real deployments
- Documentation improvements
- Hardware compatibility reports
- Security review and analysis

**Not ready to contribute code?**
- Improve documentation
- Answer questions from new users
- Share deployment stories
- Test pre-release versions

---

## Frequently Asked Questions

**Is this legal?**

Yes, in most jurisdictions. LoRa operates on ISM bands (license-free). Encryption is legal in most countries. Check your local regulations for both radio transmission and encryption.

**How much does this cost?**

- Used mini PC: $0 - $100
- RNode LoRa device: $20 - $60
- VPS server: $3-10/month (optional)
- Total initial: $20-130 for basic setup

**Do I need to join a network?**

No. Kairos helps you deploy your own network. You're not joining anything. You can connect to others if you choose.

**How many people can use it?**

Reticulum scales from 2 users to thousands. Kairos deployments have run networks of 5-15 nodes. The protocol supports much larger networks.

**What's the range?**

- Local network: Same WiFi/Ethernet
- LoRa urban: 1-5km
- LoRa rural: 5-15km
- LoRa optimal: 20-40km (high elevation, good antennas)
- Global: Unlimited with VPS backbone

**Is it secure?**

Messages are end-to-end encrypted. Metadata can leak information. Physical security matters. No formal security audit exists. Use appropriate to your threat model.

**Can I use existing hardware?**

Yes. Kairos runs on Raspberry Pi, old laptops, used mini PCs, and my current main PC. Reuse what you have.

**Do I need to know Linux?**

Basic command line knowledge helps. Documentation assumes you can navigate directories, edit files, and run commands. You don't need to be an expert.

---

## Credits and Acknowledgments

Kairos is integration and automation work. The hard technical problems were solved by others:

**Core Technologies:**

**Mark Qvist** ([@markqvist](https://github.com/markqvist))
- Reticulum Network Stack (the protocol that makes this possible)
- RNode Firmware (LoRa radio firmware)
- Nomadnet (mesh services platform)
- LXMF (message format)

Without Mark's foundational work, none of this exists.

**Liam Cottle** ([@liamcottle](https://github.com/liamcottle))
- MeshChat web interface (makes Reticulum accessible to non-technical users)

**Kairos Contribution:**
- Deployment automation scripts
- Hardware auto-configuration
- System integration and packaging
- Documentation and guides
- Operational patterns from real deployments

We stand on the shoulders of giants. Kairos just makes their excellent work more deployable.

---

## Support and Community

**Getting Help:**
- [GitHub Issues](https://github.com/jackcox15/Kairos/issues) - Bug reports and feature requests
- [Discussions](https://github.com/jackcox15/Kairos/discussions) - Questions and community support
- [Reticulum Matrix](https://matrix.to/#/#reticulum:matrix.org) - General Reticulum discussion

---

## A Note on Philosophy

This project exists because communities need to communicate, especially during moments when communication becomes difficult and critical.

When platforms silence voices, when infrastructure fails during disasters, when surveillance threatens organizing, having control over communication infrastructure becomes both resistance and resilience.

Kairos doesn't solve political problems with technology. It provides tools for communities already doing the real work of mutual aid, organizing, and resistance.

The technology matters because it enables the work to be started. 

---

**Ready to deploy?** Start with the [rns_PC deployment guide](rns_PC/) or explore the [architecture documentation](docs/architecture.md).

**Want to understand the why?** Read about [infrastructure as mutual aid](docs/philosophy.md) and our [approach to community technology](docs/approach.md).

**Building for your community?** See [deployment patterns](docs/deployment-patterns.md) and [operational security guidance](docs/opsec.md).
