---
layout: default
title: Architecture
permalink: /architecture/
---

# KAIROS Architecture

**Technical deep dive into resilient mesh networking infrastructure.**

---

## Overview

KAIROS implements a three-tier network architecture designed for graceful degradation across multiple failure modes. Understanding this architecture is essential for deployment, troubleshooting, and extending the system.

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
- Virtual Private Servers in different jurisdictions
- WireGuard VPN for encrypted tunnels
- Reticulum listening on VPN interfaces
- Redundant routing for failover

**Characteristics:**
- High bandwidth (1-10 Gbps depending on VPS tier)
- Low latency (< 100ms for most routes)
- Global reach (anywhere with internet)
- **Not required** - system works without it

**Why VPS Instead of Home Internet:**
- **Static IPs** - No dynamic DNS issues
- **Sovereignty** - Can move between providers easily  
- **Uptime** - Better than residential connections
- **Disposable** - Seized? Deploy new server elsewhere
- **Cheap** - $5-20/month for most use cases

### Tier 2: Local Mesh Nodes (Regional Connectivity)

**Purpose:** Bridge internet backbone with local LoRa radio networks.

```
VPS Backbone
     ↓
[Home Server/Laptop]
     ├─ eth0: Internet connection
     ├─ wg0: VPN to backbone
     ├─ usb0: RNode LoRa radio
     └─ wlan0: (optional WiFi AP for clients)
```

**Components:**
- x86 computer, Raspberry Pi, or similar
- LoRa RNode connected via USB
- Reticulum configured for multi-interface
- Optional WiFi access point for clients

**Characteristics:**
- Multi-interface operation (VPN + LoRa simultaneously)
- Automatic load balancing across interfaces
- Bridge between high-speed internet and local radio
- Community access point

### Tier 3: LoRa Radio Network (Local Connectivity)

**Purpose:** Provide local mesh communications independent of internet.

```
[Node A] ←――――LoRa Radio――――→ [Node B]
    ↓                              ↓
[Node C] ←――――LoRa Radio――――→ [Node D]
```

**Components:**
- RNode LoRa radios (Heltec v3, T-Beam, etc.)
- 915 MHz ISM band (US) or 868 MHz (Europe)
- Long-range radio (1-20+ miles depending on conditions)
- Low power consumption (solar + battery viable)

**Characteristics:**
- Works without infrastructure
- True peer-to-peer communications  
- Line-of-sight dependent (better with height)
- Bandwidth limited (~5-10 kbps effective)

---

## Reticulum: The Secret Sauce

### Why Reticulum is Unique

Most mesh protocols are tied to specific hardware or network layers. Reticulum treats **any transport as equal**.

**Other Protocols:**
- Meshtastic: LoRa only
- BATMAN-adv: WiFi/Ethernet only  
- Tor: TCP/IP only

**Reticulum:**
- LoRa, TCP/IP, I2P, Serial, UDP, Sneakernet - all the same
- Automatic multi-interface routing
- Cryptographic identity independent of transport

### Multi-Interface Intelligence

This is what makes KAIROS work:

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

Via VPN: 192.168.100.50
Via LoRa: Direct radio
Via I2P: b32.i2p address
Via Sneakernet: USB drive

All the same identity. All end-to-end encrypted.
```

---

## Network Topology

### Star-with-Mesh Hybrid

KAIROS uses a hybrid topology:

```
        [VPS Backbone]
       /      |      \
      /       |       \
  [Hub1]   [Hub2]   [Hub3]
   /  \      |  \     /  \
  /    \     |   \   /    \
[A]    [B]  [C]  [D] [E]  [F]

Where:
- VPS = Fast backbone (optional)
- Hubs = Home nodes with LoRa
- A-F = Client devices or relay nodes
```

**Characteristics:**
- **Hierarchical** for efficiency when backbone available
- **Peer-to-peer** when backbone unavailable
- **Automatic** - Reticulum handles routing

### Graceful Degradation Example

**Normal Operation:**
```
Alice (Detroit) ←→ VPS Backbone ←→ Bob (Boston)
                ↑                    ↑
             LoRa Mesh            LoRa Mesh
```
Fast, global connectivity.

**Internet Disrupted:**
```
Alice (Detroit)     XXXX     Bob (Boston)
        ↓                         ↓
    Local LoRa               Local LoRa
    Mesh Only                Mesh Only
```
Regional connectivity only.

**Full Infrastructure Loss:**
```
Alice ←――LoRa Radio――→ Bob
```
Direct device-to-device if within range.

**The network never "fails" - it degrades gracefully.**

---

## Why LoRa Specifically?

### What is LoRa?

**LoRa (Long Range):** Radio modulation technique for long-distance, low-power communications.

**Characteristics:**
- **Range:** 1-20+ miles depending on terrain/antennas
- **Power:** Milliwatts (solar + battery viable)  
- **Bandwidth:** Low (5-10 kbps effective for messaging)
- **License-free:** ISM bands (915 MHz US, 868 MHz EU)

**Not to be confused with:**
- **LoRaWAN:** Centralized protocol for IoT (not what we use)
- **Meshtastic:** Pre-built LoRa mesh (different protocol)

### Why LoRa vs. WiFi Mesh?

| LoRa | WiFi Mesh |
|------|-----------|
| 1-20+ miles | 100-300 feet |
| Milliwatts | Watts |
| License-free | License-free |
| 5-10 kbps | 100+ Mbps |
| Simple antennas | Complex mesh routing |
| Works mobile | Requires fixed nodes |

**For resilient mesh:** Long range + low power > high bandwidth

### RNode: LoRa for Reticulum

**RNode** is firmware that turns LoRa hardware into a Reticulum network interface.

**Supported Hardware:**
- Heltec LoRa v3 (recommended - integrated OLED)
- LILYGO T-Beam (GPS + LoRa)
- LILYGO LoRa32
- Generic ESP32 + SX127x/SX126x LoRa modules

**What RNode Does:**
```
LoRa Radio Hardware
        ↓
   RNode Firmware  
        ↓
  Serial Interface (USB)
        ↓
Reticulum Network Stack
```

**Configuration Parameters:**
- Frequency: 915 MHz (US) or 868 MHz (EU)
- Bandwidth: 125-500 kHz
- Spreading Factor: 7-12 (range vs. speed tradeoff)
- Coding Rate: 4/5 - 4/8 (error correction)

KAIROS automates all of this configuration.

---

## VPN Backbone Details

### Why WireGuard?

**WireGuard advantages:**
- Modern cryptography (ChaCha20, Poly1305, Curve25519)
- Minimal attack surface (~4,000 lines of code)
- Excellent performance
- Easy to configure
- Built into Linux kernel

**vs. OpenVPN:**
- OpenVPN: 400,000+ lines of code, complex config, slower
- WireGuard: 4,000 lines of code, simple config, faster

**vs. IPSec:**
- IPSec: Complex, enterprise-focused, difficult to configure correctly
- WireGuard: Simple, secure by default, easy to audit

### Backbone Architecture

**Multiple VPS Strategy:**

```
VPS-JP (Japan)
VPS-EU (Europe)  
VPS-US (United States)

Each running:
├─ WireGuard VPN server
├─ Reticulum listening on VPN interface
├─ Automatic peering with other VPS
└─ User node connections
```

**Why Multiple Jurisdictions:**
- **Legal resilience:** Harder to seize all servers simultaneously
- **Geographic distribution:** Better latency globally
- **Redundancy:** Lose one region, others continue

**Why NOT Tor/I2P for Backbone:**
- Tor/I2P: High latency, bandwidth limitations, complexity
- WireGuard VPN: Direct connectivity, full bandwidth, simple

*Tor/I2P are supported as Reticulum transports if you want them for specific threat models.*

### VPS Selection Criteria

**When choosing VPS providers:**

✅ **Do prioritize:**
- Payment methods (crypto, privacy-focused)
- Jurisdiction (outside Five Eyes if possible)
- Reputation for not cooperating with dragnet surveillance
- Technical specs (bandwidth, CPU, storage)

❌ **Don't assume:**
- Any VPS is immune to legal demands
- Offshore automatically means safe
- Privacy policies are legally binding

**Treat VPS as disposable.** The whole point is you can move.

---

## Security Architecture

### Threat Model

**What KAIROS defends against:**
- ✅ Network surveillance (encrypted end-to-end)
- ✅ Traffic analysis to some degree (onion routing possible)
- ✅ Single point of failure (distributed architecture)
- ✅ Platform censorship (no central platform)
- ✅ ISP blocking (LoRa works without ISP)

**What KAIROS does NOT fully defend against:**
- ❌ Targeted attacks on specific nodes (physical security required)
- ❌ Rubber-hose cryptanalysis (device encryption separate concern)
- ❌ Radio direction finding (LoRa transmissions are detectable)
- ❌ Compromised endpoints (malware, keyloggers, etc.)

**Security model:**
- **Transport encryption:** WireGuard for VPN
- **End-to-end encryption:** Reticulum's built-in crypto
- **Forward secrecy:** Session keys rotated
- **Authentication:** Cryptographic identity verification

### Network Isolation

**Critical principle:** Keep networks separate.

```
BAD - Don't do this:
[Dev Network] ←→ [Production Network]
  (Anyone)          (Trusted only)

GOOD - Proper isolation:
[Dev Network]    [Production Network]
    ↓                    ↓
Different VPS      Different VPS
Different keys     Different keys
Different nodes    Different nodes
```

**Why this matters:**
- Dev network might have untrusted users
- Mesh networks reveal topology to all participants
- Cross-contamination risks identity exposure

**KAIROS handles this through:**
- Separate configuration files
- Different VPS endpoints for dev vs. production
- Clear documentation on isolation practices

---

## Performance Characteristics

### Bandwidth Expectations

**VPN Backbone:**
- Latency: 20-100ms depending on geography
- Throughput: Limited by VPS bandwidth (usually 100 Mbps+)
- **Use case:** File transfers, real-time chat, voice

**LoRa Mesh:**
- Latency: 500ms - 5s depending on path
- Throughput: 5-10 kbps effective for messages
- **Use case:** Text messages, small data packets, position reports

**Hybrid (VPN + LoRa):**
- Reticulum automatically routes based on message size
- Small messages may go via LoRa (faster to route)
- Large files prefer VPN (higher bandwidth)

### Scaling Considerations

**How many nodes can KAIROS support?**

**VPS backbone:** Thousands (limited by VPS bandwidth/CPU)  
**Local LoRa mesh:** 10-50 per area (limited by airtime, not nodes)

**Bottleneck is usually LoRa airtime:**
- ISM band regulations limit transmission time
- More nodes = more sharing of bandwidth
- Proper spreading factor selection critical

**This is why:**
- Text messages scale well (small packets)
- File transfers should use VPN when available
- LoRa is for resilience, not primary bandwidth

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

## Component Selection

### For VPS Backbone

**Minimum specs:**
- 1 CPU core
- 1 GB RAM  
- 10 GB storage
- 1 TB bandwidth/month

**Recommended providers:**
*(KAIROS is provider-agnostic - use what works for you)*
- Privacy-focused: Njalla, 1984 Hosting
- General: DigitalOcean, Vultr, Hetzner
- Crypto payment: Many accept Bitcoin/Monero

### For Local Nodes

**Budget option:** Raspberry Pi Zero W + LoRa
- $15 Pi + $25 LoRa module
- Low power, portable
- Good for relays/repeaters

**Recommended:** Raspberry Pi 4/5 + Heltec v3
- Better performance
- Integrated display
- Good for community hubs

**High-performance:** x86 mini-PC + LoRa
- Full Linux desktop capability
- Can host additional services
- Good for power users

### For LoRa Hardware

**Recommended: Heltec LoRa v3**
- Integrated OLED display
- ESP32-S3 (better than v2)
- Built-in antenna + U.FL connector for external
- Well-supported by RNode firmware

**Alternative: LILYGO T-Beam**
- GPS included (useful for position reporting)
- Larger, more field-deployable form factor
- Good battery management

**DIY option:** ESP32 + SX127x module
- Cheapest option (~$10 total)
- Requires soldering/assembly
- More flexible but more work

---

## Maintenance and Monitoring

### What Needs Monitoring

**VPS health:**
- CPU/RAM usage
- Bandwidth consumption  
- Disk space
- WireGuard tunnel status

**Local node health:**
- Reticulum interface status
- LoRa radio connectivity
- Message throughput
- Network reachability

**LoRa network:**
- RSSI (signal strength)
- SNR (signal-to-noise ratio)
- Packet loss rates
- Neighboring nodes

### Logging Strategy

**What to log:**
- ✅ Network events (interfaces up/down)
- ✅ Performance metrics
- ✅ Error conditions
- ✅ System resource usage

**What NOT to log:**
- ❌ Message contents
- ❌ User identities  
- ❌ Traffic patterns that reveal behavior
- ❌ Metadata that could be subpoenaed

**Principle:** Log technical operation, not user activity.

---

## Future Architecture Considerations

**Potential Additions:**

### Satellite Connectivity
- Starlink, satellite phones as backup transport
- Reticulum works over any IP - satellite is just another interface
- Expensive but useful for remote areas

### Store-and-Forward Nodes
- Automated message queuing when nodes offline
- Delivery when connectivity restored
- Already possible with Reticulum, needs UI work

### Mesh Routing Improvements
- Better path selection algorithms
- Quality-of-service for different message types
- Bandwidth management for LoRa networks

### Integration with Other Networks
- I2P/Tor for additional privacy layers
- Yggdrasil for IPv6 mesh routing
- Ham radio modes (APRS, Winlink) for emergency comms

**None of these require fundamental architecture changes** - that's the beauty of Reticulum's transport agnosticism.

---

## Learning Resources

**To deeply understand this architecture:**

1. **Study Reticulum source code**
   - Start with packet.py and transport.py
   - Understand routing algorithm
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
