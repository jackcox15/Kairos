# KAIROS Network Architecture

## Overview
KAIROS also provides optional VPS infrastructure to bridge isolated local meshes.

## How the VPS Backbone Works
- Redundant servers spread across Japan
- WireGuard VPN for transport
- Reticulum TCP interface over VPN
- No logging, no data retention

## Local Mesh vs. KAIROS Mode

### Local Mesh Only
- Your nodes talk to each other via LoRa
- No internet dependency, unless you build your network!
- Range: 1-20+ miles

### KAIROS Network Mode  
- Local mesh + VPN to global backbone
- Can reach other KAIROS users anywhere
- Graceful degradation if VPN fails
- Requires trust in VPS operator

## Decision Framework
Use Local Only if:
- Building isolated community network
- Don't trust external infrastructure
- Don't need global reach

Join KAIROS if:
- Want to reach other nodes globally, through the KairosNet
- Need redundant backbone
- Want access to shared resources (wiki, etc.)
