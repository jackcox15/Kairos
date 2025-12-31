#!/usr/bin/env python3 

import subprocess
import re

def get_interfaces():
    cmd = "ip link show | grep '^[0-9]' | awk '{print $2}' | sed 's/:$//'"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    interfaces = []
    for line in result.stdout.split('\n'):
        line = line.strip()
        if line and line != 'lo': #skip in case of loopback
            interfaces.append(line)
    return interfaces

def is_interface_up(interface):
    cmd = f"ip link show {interface}"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return 'state UP' in result.stdout

def get_ip_address(interface):
    cmd = f"ip addr show {interface} | grep 'inet ' | awk '{{print $2}}' | cut -d/ -f1"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip()

def has_internet(interface):
    cmd = f"ping -c 1 -W 2 -I {interface} 8.8.8.8"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.returncode == 0

if __name__ == "__main__":
    print("Network Interfaces:")
    interfaces = get_interfaces()
    
    for iface in interfaces:
        print(f"\n{iface}:")
        print(f"  Up: {is_interface_up(iface)}")
        print(f"  IP: {get_ip_address(iface)}")
        if is_interface_up(iface):
            print(f"Internet: {has_internet(iface)}")
    
