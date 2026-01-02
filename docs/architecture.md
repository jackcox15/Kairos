# KAIROS Architecture

**Technical deep dive into resilient mesh networking infrastructure.**
**Using my local community network for examples**

---

## Overview

KAIROS implements a three tier network architecture designed for graceful degradation across multiple failure modes.
Understanding this architecture is essential for deployment, troubleshooting, and extending the system. 
Or you can incorporate these practices into your own local community, in your own style!

---

## The Three Tiers

### Tier 1: VPS Backbone (Global Connectivity)

**Purpose:** Provide global mesh connectivity when internet is available.

```
VPS Server (Japan) ←→ WireGuard VPN ←→ Local Nodes
VPS Server (Europe) ←→ WireGuard VPN ←→ Local Nodes  
VPS Server (US) ←→ WireGuard VPN ←→ Local Nodes
```

**Components:**
- Securely owned Virtual Private Servers in different jurisdictions
- WireGuard VPN for encrypted tunnels
- Reticulum listening on VPN interfaces
- Redundant routing for failover across multiple VPS interfaces

**Characteristics:**
- High bandwidth (1-10 Gbps depending on VPS tier, Reticulum handles routing)
- Low latency (< 100ms for most routes)
- Global reach (anywhere with internet)
- **Not required** - system works without it

**Why VPS Instead of Home Internet:**
- **Static IPs** - No dynamic DNS issues
- **Sovereignty** - Can move between providers easily  
- **Uptime** - Better than residential connections
- **Disposable** - Seized? Deploy new server elsewhere
- **Cheap** - $3-$15/month for most use cases

# How KAIROS Nodes Bridge Global and Local Networks

**Purpose:** Create redundant communication paths by combining internet backbone with local LoRa radio networks.

## Network Architecture

```
    Internet
         ↓
    [VPS Backbone]
         ↓ (WireGuard VPN tunnel)
         ↓
  ┌─────────────────────┐
  │     Your  Node      │
  │  (Laptop/Pi/PC)     │
  ├─────────────────────┤
  │ eth0 or wlan0       │ ← Gets internet from your router/WiFi
  │ wg0                 │ ← Encrypted tunnel to VPS backbone  
  │ usb0                │ ← RNode LoRa radio (local mesh)
  │ wlan1 (optional)    │ ← WiFi access point for local users
  └─────────────────────┘
         ↓
    [LoRa Radio Network]
```

## How It Works

### Step 1: Getting Online
Your device connects to the internet using either:
- **eth0**: Ethernet cable to your router
- **wlan0**: WiFi connection to your network

*(Just like any normal computer)*

### Step 2: VPS Backbone Connection
Once online, WireGuard automatically creates a secure tunnel:
- **wg0** interface appears
- Encrypted connection to VPS backbone established
- Your node joins the global mesh network

### Step 3: Local Radio Network
Simultaneously, your LoRa radio (RNode) provides:
- **usb0** or **acm0** interface for radio communication
- Long range local mesh (1-20+ mile radius)
- Works completely independently of internet

### Step 4: The Magic - Reticulum Routing
Reticulum (the mesh protocol) runs on your device and:

1. **Sees both interfaces** (wg0 and usb0) as available paths
2. **Sends packets through BOTH** simultaneously
3. **Receives from BOTH** at the same time
4. **Uses whichever arrives first** (usually wg0 is faster)

This is called **interface aggregation** or **path diversity**.

## What This Means In Practice

### Scenario 1: Normal Operation (Internet Working)
```
Message to another user
    ↓
Reticulum sends via:
    ├─ wg0 → VPS -> friend (FAST - milliseconds)
    └─ usb0 → LoRa mesh → friend's usb0 (LOCAL Only - Few seconds)
    ↓
They receive via wg0 first 
LoRa copy arrives later (ignored, already received)
```

**Result**: Fast global communication with automatic radio backup for local comms 

### Scenario 2: Internet Dies
```
Message to another user
    ↓
Reticulum tries:
    ├─ wg0 → [OFFLINE - no internet] 
    └─ usb0 → LoRa mesh → Their usb0 = received! 
    ↓
They receive via LoRa only
```

**Result**: Slower but communication still works! No manual intervention needed.

### Scenario 3: No Internet, Never Had Internet
```
Message to nearby  user
    ↓
Reticulum only has:
    └─ usb0 → LoRa mesh → Their usb0 device
    ↓
Works perfectly within radio range/Line of sight
```

**Result**: Completely independent local mesh network

## Your Node's Role: Router/Forwarder Not Translator

Think of your device as a **smart post office**, not a translator:

1. **Receives** Reticulum packets from:
   - Local LoRa radio (usb0 or acm0)
   - VPN tunnel (wg0)
   - Local WiFi clients (wlan0 - optional)
   - Any other medium you're using to build the network

2. **Routes** packets to their destination using:
   - Best available path
   - All available paths simultaneously (redundancy)
   - Intelligent failover if one path dies

3. **Forwards** packets for other nodes:
   - Acts as relay for multi-hop messages
   - Extends mesh network range
   - Helps build redundant infrastructure
   - Can store message for later retrieval 

## Key Concepts

### Interface Aggregation
Reticulum treats multiple network interfaces as **active resources**, not primary/backup.

### Graceful Degradation
As interfaces fail, Reticulum automatically adjusts:

```
Full connectivity:    wg0 ✓  usb0 ✓  (best performance)
Internet outage:      wg0 ✗  usb0 ✓  (local mesh only)
Radio failure:        wg0 ✓  usb0 ✗  (global mesh only)
Both operational:     wg0 ✓  usb0 ✓  (maximum redundancy)
```

The network **never fully collapses** it just reduces in capability.

### Zero Configuration
For end users, all of this happens automatically:
- Plug in ethernet, wg0 tunnel establishes
- Plug in RNode, usb0/acm0 interface activates  
- Reticulum routes packets intelligently

**No manual failover. No service restarts. It just works.**

## Why This Architecture Matters

### Resilience
- VPS seized? Local mesh keeps working
- Internet censored? Local mesh keeps working
- LoRa down? VPN tunnel keeps working
- Power outage? Battery powered nodes keep meshing

### Privacy
- Traffic encrypted end-to-end across all interfaces
- VPS can't read message content (only routes packets)
- LoRa uses cryptographic identities
- No single point of surveillance

### Accessibility
- Uses common hardware
- Works with existing internet connection, and new
- Gracefully handles partial failures
- Non-technical users just "plug and go"

---


## Summary

Your node doesn't just "translate" between networks, it's a **redundant routing node** that:

 - Maintains multiple simultaneous connections  
 - Routes packets intelligently across all interfaces  
 - Provides automatic failover without user intervention  
 - Extends mesh network reach by relaying for others  
 - Works standalone or as part of global infrastructure  

**Components:**
- x86 Linux computer, Raspberry Pi, or similar
- LoRa RNode connected via USB
- Reticulum configured for multi interface
- Optional WiFi access point for clients 

**Characteristics:**
- Multi interface operation (VPN + LoRa simultaneously)
- Automatic load balancing across interfaces
- Bridge between high-speed internet and local radio
- Community access point

---

## Reticulum: The Secret Sauce

### Why Reticulum is Unique

Most mesh protocols are tied to specific hardware or network layers. Reticulum treats **any transport as equal**.

**Other Protocols:**
- Meshtastic: LoRa only
- Traditional Internet: TCP/IP only
- Tor: TCP/IP only

**Reticulum:**
- LoRa, TCP/IP, I2P, Serial, UDP, Sneakernet, yggsdrasil, all the same
- Automatic multi-interface routing
- Cryptographic identity independent of transport

### Agnostic Interfaces

This is what makes Kairos work:

**Traditional networking:** Primary interface + backup failover  
**Reticulum:** All interfaces active simultaneously

Example:
```
Your node has:
- wg0: VPN to backbone (10 Mbps)
- usb0: LoRa radio (10 kbps)

Reticulum behavior:
├─ Small messages: May route via either interface
├─ Large files: Prefers high-bandwidth VPN
├─ VPN fails: Automatically uses LoRa
├─ Both available: Load balances based on path quality
└─ Routes update automatically
```

**You never configure "primary" or "backup" interfaces.** Reticulum figures it out.

### Cryptographic Identity

Traditional networking: Identity = IP address  
Reticulum: Identity = cryptographic key pair

**Benefits:**
- Your identity works across any transport
- No dependency on IP addresses or DNS
- Move between networks seamlessly
- Messages encrypted end-to-end by default

**Example:**
```
Your identity: a5f4d3c2b1...

Via VPN: 10.10.100.50
Via LoRa: Direct radio
Via I2P: b32.i2p address
Via Sneakernet: USB drive

All the same identity. All E2E encrypted.
```
---
---

## Deployment Patterns

### Pattern 1: Community Hub

```
[Community Center]
     ├─ Server with LoRa
     ├─ WiFi AP for local devices
     └─ VPN to backbone

Community members connect via WiFi
Messages route through hub to mesh
```

**Use case:** Neighborhood mesh, community center, resource distribution

### Pattern 2: Distributed Mesh

```
[Home A] ←―LoRa―→ [Home B]
    ↓                 ↓
  VPN to          VPN to
 Backbone        Backbone
```

**Use case:** Residential mesh, widespread geography

### Pattern 3: Mobile Relay

```
[Backpack Node]
  ├─ Raspberry Pi
  ├─ LoRa Radio
  ├─ Battery Pack
  └─ Optional: WiFi AP

Carried to events, protests, disaster sites
```

**Use case:** Temporary deployment, mobile organizing

### Pattern 4: Fixed Repeater

```
[Hilltop/Rooftop Node]
  ├─ Raspberry Pi
  ├─ High-gain LoRa antenna
  ├─ Solar + battery
  └─ No internet required

Extends range of local mesh
```

**Use case:** Extending coverage, rural areas

---

## Future Architecture Considerations

**Potential Additions:**

### Integration with Other Networks
- I2P/Tor for additional privacy layers
- Yggdrasil for IPv6 mesh routing
- Ham radio modes (APRS, Winlink) for emergency comms

**None of these require fundamental architecture changes** - that's the beauty of Reticulum's transport agnosticism.

---

## Learning Resources

**To deeply understand this architecture:**

1. **Study Reticulum source code**
   - Start with original Reticulu repo 
   - Understand routing algorithm and .py programs
   - Map cryptographic flows

2. **Experiment with WireGuard**
   - Set up point-to-point tunnel
   - Understand routing tables
   - Test failover scenarios

3. **Learn LoRa fundamentals**
   - RF propagation basics
   - Spreading factor vs. range tradeoffs
   - Antenna theory

4. **Network protocol analysis**
   - Use `tcpdump` to watch traffic
   - Analyze Reticulum packet structures
   - Understand routing decisions

**The code is the documentation.** Read it, modify it, break it, fix it.

---

[← Back to Philosophy](/Kairos/philosophy/) | [Deployment Guide →](/Kairos/deployment/)
