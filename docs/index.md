---
layout: default
title: Home
permalink: /
---

# KAIROS: Infrastructure as Mutual Aid

**Resilient communications that work when everything else fails.**

Kairos provides the deployment automation, hardware integration,
and operational frameworks to make advanced mesh networking accessible
to mutual aid groups, community organizers, and activists who need secure 
communications independent of corporate infrastructure.

---

## The goal:

### Community owned infrastructure
This is entirely built to resist modern internet and strive 
for a soverign community for any given sceneario. 

### Not a Service/Product
Not meant to make a profit, be exploitable, etc. 
only meant to outlast modern surveillance capitalism.  
No centralized servers that can be seized or shut down.

### Infrastructure
**Community owned. Community operated. Community sustained.**

Built on mature Free and Open Source Software components,
configured for resilience, deployed through mutual aid principles.

---

## How It Works

KAIROS combines three infrastructure layers:

### 1. VPS Backbone (Optional - not required to join KairosNet)
Redundant virtual private servers providing global connectivity when internet is available.  
*You control the servers. You hold the keys. You own the infrastructure.*

### 2. Local Mesh Nodes
Your hardware (laptop, Raspberry Pi, mini-PC, LoRa device) running Reticulum Network Stack/RNode.  
Bridges internet connectivity with local LoRa radio mesh networks.

### 3. LoRa Radio Network
Long-range, low-power radio communications (1-20+ mile range).  
**Works without internet. Works without infrastructure. Works peer-to-peer securely.**

---

## Graceful Degradation

The system is designed to fail gracefully across multiple modes:

```
GLOBAL CONNECTIVITY
├─ Internet + VPS backbone through KairosNet (Or host your own VPS!)
├─ Full mesh across all nodes worldwide
└─ Encrypted, censorship resistant messaging

    ↓ Internet disrupted	

REGIONAL CONNECTIVITY  
├─ Local mesh networks hosted by you
├─ LoRa radio/Reticulum Hosts bridge communities
└─ City wide or neighborhood coverage

    ↓ Infrastructure seized

LOCAL-ONLY MESH
├─ Device-to-device radio communications via RNodes/Local Reticulum Hosts
├─ No central coordination required, total offline messaging locally
└─ Truly peer-to-peer resilience, fully encrypted based on Radio configuration 

    ↓ All infrastructure destroyed(totally hypothetical) 

PHYSICAL PROXIMITY
├─ Direct LoRa device-to-device
├─ Messages passed person-to-person
└─ Digital sneakernet if needed
```

**The network degrades, but never fully collapses.**

---

## Core Principles

### Sovereignty
Communities own and operate their own infrastructure. 
No dependency on corporate platforms, government services,
or external providers beyond commodity VPS hostingthat can be changed at any time.

### Resilience  
Multiple redundant paths ensure communications survive partial failures.
VPS backbone provides convenience; local mesh ensures survival.

### Privacy
End-to-end encryption by default. Cryptographic identity not tied to legal names,
phone numbers, or government IDs.

### Accessibility
Complex technology hidden behind automation and plug-and-play hardware. 
Overall goal is to allow Non-technical users to operate nodes without
understanding the underlying protocols. 

### Mutual Aid
Not sold as a product or provided as a service. 
Built collaboratively, shared freely, maintained communally. 
Technology as a tool, not a commodity.

---

## Who This Serves

### Mutual Aid Networks
Coordinate disaster response, resource distribution,
and community care without depending on systems that may fail precisely when needed most.

### Community Organizers
Communicate securely for organizing actions, coordinating logistics, 
and maintaining operations in hostile environments or under surveillance.

### Independent Press  
Protect sources and maintain communications channels when
corporate platforms are censored or compromised.

### Privacy-Focused Individuals
Communicate outside surveillance capitalism infrastructure 
while maintaining ease of use and reliability.

---

## What KAIROS Provides

### Automated Deployment
- Live USB systems that boot on any x86 hardware
- Pre-configured Raspberry Pi images
- One command server installation scripts
- No manual configuration required

### Hardware Integration
- Automated LoRa radio (RNode) firmware flashing
- Plug-and-play device detection and configuration  
- LCD status displays for headless operation
- Solar + battery power support for field deployment

### User Interface
- MeshChat web UI for familiar messaging experience
- Nomadnet for mesh services and bulletin boards
- Status monitoring and network visualization
- No command line required for basic operation

### Infrastructure Blueprints
- VPS backbone setup with WireGuard VPN for KairosNet
- Multi-tier network architecture 
- Redundancy and failover configurations
- Operational security practices

---

## Technology Foundation

KAIROS is **systems integration work** built on mature FOSS components:

- **[Reticulum Network Stack](https://github.com/markqvist/Reticulum)** - Cryptographic mesh routing protocol (Mark Qvist)
- **[MeshChat](https://github.com/liamcottle/reticulum-meshchat)** - Web-based messaging interface (Liam Cottle)  
- **[Nomadnet](https://github.com/markqvist/NomadNet)** - Mesh services platform (Mark Qvist)
- **RNode** - LoRa radio interfaces (MarkQvist)
- **WireGuard** - VPN backbone connectivity

---

## Getting Started

Ready to build resilient infrastructure for your community?

- **[Read the Philosophy](/Kairos/philosophy)** - Understand the principles behind infrastructure as mutual aid
- **[Explore the Architecture](/Kairos/architecture)** - Deep dive into how the system actually works
- **[Deploy a Node](/Kairos/deployment)** - Technical guide to getting started
- **[Security Considerations](/Kairos/security)** - Operational security and threat modeling
- **[Contribute](/Kairos/contributing)** - Join the effort to build community infrastructure

---

## A Note on Community

KAIROS operates through **trusted networks**, not mass marketing.

We grow organically through personal connections and mutual aid relationships. 
If you're involved in community organizing, mutual aid work, or building 
resilient infrastructure and these principles resonate with you, we'd like to connect!

This is intentionally not mass-market technology. It's infrastructure for communities who need it,
whenever theyy need it. 

---

*"From untruth to truth, from darkness to light, from death to immortality."*
