#!/usr/bin/env python3

import subprocess
import os
import time
import re
import glob

class RNodeBox:
    
    def __init__(self):
        self.reticulum_dir = "/root/.reticulum"
        
    def run_command(self, cmd, log_errors=False):
        try:
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if log_errors and result.returncode != 0:
                print(f"Command failed: {cmd}")
                print(f"Exit code: {result.returncode}")
                if result.stderr:
                    print(f"Error: {result.stderr.strip()}")
            
            return result.stdout.strip()
            
        except subprocess.TimeoutExpired:
            if log_errors:
                print(f"Timeout: {cmd}")
            return ""
            
        except Exception as e:
            if log_errors:
                print(f"Exception: {e}")
            return ""
    
    # SERVICE MANAGEMENT
    
    def get_service_status(self, service_name):
        result = self.run_command(f"systemctl is-active {service_name}")
        if result == "active":
            return True
        result = self.run_command(f'systemctl status {service_name} | grep "Active:" | awk "{{print $2}}"')
        return result == "active"
    
    def get_all_services(self):
        services = {
            'rnsd': self.get_service_status('rnsd'),
            'meshchat': self.get_service_status('meshchat'),
            'nomadnet': self.get_service_status('nomadnet')
        }
        return services
    
    def start_service(self, service_name):
        self.run_command(f"sudo systemctl start {service_name}")
        time.sleep(1)
        return self.get_service_status(service_name)
    
    def stop_service(self, service_name):
        self.run_command(f"sudo systemctl stop {service_name}")
        time.sleep(1)
        return not self.get_service_status(service_name)
    
    def restart_service(self, service_name):
        self.run_command(f"sudo systemctl restart {service_name}")
        time.sleep(2)
        return self.get_service_status(service_name)
    
    # RETICULUM INFORMATION
    
    def get_reticulum_identity(self):
        result = self.run_command("rnpath -t")
        if not result:
            return "Identity not found"
        lines = result.split('\n')
        for line in lines:
            match = re.search(r'<([0-9a-f]{32})>\s+is\s+0\s+hops\s+away\s+via\s+<\1>', line)
            if match:
                return match.group(1)
        match = re.search(r'<([0-9a-f]{32})>', result)
        if match:
            return match.group(1)
        return "Identity not found"
    
    def get_announced_destinations(self):
        result = self.run_command("rnpath -t")
        if not result:
            return []
        destinations = []
        for line in result.split('\n'):
            match = re.search(r'<([0-9a-f]{32})>\s+is\s+(\d+)\s+hops\s+away', line)
            if match:
                destinations.append({
                    'hash': match.group(1),
                    'hops': int(match.group(2))
                })
        return destinations
    
    def get_mesh_node_count(self):
        destinations = self.get_announced_destinations()
        return len(destinations)
    
    def get_path_table(self):
        result = self.run_command("rnpath -t")
        if not result:
            return []
        paths = []
        for line in result.split('\n'):
            match = re.search(r'<([0-9a-f]{32})>\s+is\s+(\d+)\s+hops\s+away\s+via\s+<([0-9a-f]{32})>\s+on\s+(\S+)', line)
            if match:
                paths.append({
                    'destination': match.group(1),
                    'hops': int(match.group(2)),
                    'via': match.group(3),
                    'interface': match.group(4)
                })
        return paths
    
    def get_reticulum_interfaces(self):
        config_path = f"{self.reticulum_dir}/config"
        
        if not os.path.exists(config_path):
            return []
        
        interfaces = []
        result = self.run_command(f"grep -E '\\[\\[.*\\]\\]' {config_path}")
        
        for line in result.split('\n'):
            if line.strip():
                iface_name = line.replace('[[', '').replace(']]', '').strip()
                interfaces.append(iface_name)
        
        return interfaces
    
    # NETWORK INTERFACES
    
    def get_active_interfaces(self):
        result = self.run_command("ip link show | grep '^[0-9]' | awk '{print $2}' | sed 's/:$//'")
        if not result:
            return []
        interfaces = []
        for iface in result.split('\n'):
            if iface and iface != 'lo':
                interfaces.append(iface)
        return interfaces
    
    def get_interface_stats(self, interface):
        rx_bytes = self.run_command(f"cat /sys/class/net/{interface}/statistics/rx_bytes 2>/dev/null")
        tx_bytes = self.run_command(f"cat /sys/class/net/{interface}/statistics/tx_bytes 2>/dev/null")
        rx_packets = self.run_command(f"cat /sys/class/net/{interface}/statistics/rx_packets 2>/dev/null")
        tx_packets = self.run_command(f"cat /sys/class/net/{interface}/statistics/tx_packets 2>/dev/null")
        
        return {
            'rx_bytes': int(rx_bytes) if rx_bytes else 0,
            'tx_bytes': int(tx_bytes) if tx_bytes else 0,
            'rx_packets': int(rx_packets) if rx_packets else 0,
            'tx_packets': int(tx_packets) if tx_packets else 0
        }
    
    def get_all_interface_stats(self):
        interfaces = self.get_active_interfaces()
        stats = {}
        for iface in interfaces:
            stats[iface] = self.get_interface_stats(iface)
        return stats
    
    def is_interface_up(self, interface):
        result = self.run_command(f"ip link show {interface}")
        return 'state UP' in result
    
    # ACCESS POINT
    
    def get_ap_clients_count(self):
        result = self.run_command("iw dev | grep Interface | awk '{print $2}'")
        if not result:
            return 0
        interfaces = result.split('\n')
        total_clients = 0
        for iface in interfaces:
            if iface:
                stations = self.run_command(f"iw dev {iface} station dump | grep Station | wc -l")
                if stations:
                    try:
                        total_clients += int(stations)
                    except:
                        pass
        return total_clients
    
    def get_ap_info(self):
        ssid = self.run_command("grep '^ssid=' /etc/hostapd/hostapd.conf 2>/dev/null | cut -d'=' -f2")
        password = self.run_command("grep '^wpa_passphrase=' /etc/hostapd/hostapd.conf 2>/dev/null | cut -d'=' -f2")
        ip = self.run_command("ip addr show | grep 'inet 10.0.0.1' | awk '{print $2}' | cut -d'/' -f1")
        
        return {
            'ssid': ssid if ssid else 'Not configured',
            'password': password if password else 'Not configured',
            'ip': ip if ip else 'Not configured'
        }
    
    def get_meshchat_url(self):
        ap_info = self.get_ap_info()
        if ap_info['ip'] != 'Not configured':
            return f"http://{ap_info['ip']}:8000"
        return "Not configured"
    
    # VPN STATUS
    
    def is_vpn_active(self):
        wg_check = self.run_command("ip link show wg0 2>/dev/null")
        tun_check = self.run_command("ip link show tun0 2>/dev/null")
        
        return bool(wg_check or tun_check)
    
    def get_vpn_info(self):
        if not self.is_vpn_active():
            return None
        
        wg_peers = self.run_command("wg show wg0 peers 2>/dev/null")
        if wg_peers:
            peer_count = len(wg_peers.split('\n'))
            endpoint = self.run_command("wg show wg0 endpoints 2>/dev/null | head -n 1 | awk '{print $2}'")
            return {
                'type': 'WireGuard',
                'interface': 'wg0',
                'peers': peer_count,
                'endpoint': endpoint if endpoint else 'N/A'
            }
        
        tun_ip = self.run_command("ip addr show tun0 2>/dev/null | grep 'inet ' | awk '{print $2}'")
        if tun_ip:
            return {
                'type': 'OpenVPN',
                'interface': 'tun0',
                'ip': tun_ip
            }
        
        return None
    
    # LORA DEVICES
    
    def get_lora_devices(self):
        devices = glob.glob('/dev/ttyUSB*') + glob.glob('/dev/ttyACM*')
        return devices
    
    def get_lora_device_info(self, device_path):
        result = self.run_command(f"rnodeconf {device_path} --info 2>/dev/null")
        
        if result and 'Device' in result:
            info_lines = result.split('\n')
            device_info = {}
            for line in info_lines:
                if ':' in line:
                    key, value = line.split(':', 1)
                    device_info[key.strip()] = value.strip()
            
            return {
                'path': device_path,
                'type': 'RNode',
                'configured': True,
                'info': device_info
            }
        
        return {
            'path': device_path,
            'type': 'Serial Device',
            'configured': False,
            'info': {}
        }
    
    def get_all_lora_info(self):
        devices = self.get_lora_devices()
        lora_info = []
        
        for device in devices:
            info = self.get_lora_device_info(device)
            lora_info.append(info)
        
        return lora_info
    
    # SYSTEM HEALTH
    
    def get_cpu_temp(self):
        temp = self.run_command("cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null")
        if temp:
            try:
                return float(temp) / 1000.0
            except:
                return 0.0
        return 0.0
    
    def get_cpu_usage(self):
        result = self.run_command("top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1")
        if result:
            try:
                return float(result)
            except:
                return 0.0
        return 0.0
    
    def get_memory_usage(self):
        mem = self.run_command("free -m | grep Mem:")
        parts = mem.split()
        if len(parts) >= 3:
            try:
                total = int(parts[1])
                used = int(parts[2])
                percent = int((used / total) * 100)
                return {
                    'total': total,
                    'used': used,
                    'percent': percent
                }
            except:
                pass
        return {'total': 0, 'used': 0, 'percent': 0}
    
    def get_disk_usage(self):
        df = self.run_command("df -h / | tail -n 1")
        parts = df.split()
        if len(parts) >= 5:
            return {
                'total': parts[1],
                'used': parts[2],
                'available': parts[3],
                'percent': parts[4].replace('%', '')
            }
        return {'total': '0', 'used': '0', 'available': '0', 'percent': '0'}
    
    def get_uptime(self):
        uptime = self.run_command("uptime -p")
        return uptime.replace("up ", "")
    
    # TRAFFIC STATS
    
    def get_total_traffic(self):
        interfaces = self.get_active_interfaces()
        rx_total = 0
        tx_total = 0
        for iface in interfaces:
            stats = self.get_interface_stats(iface)
            rx_total += stats['rx_bytes']
            tx_total += stats['tx_bytes']
        return {'rx_total': rx_total, 'tx_total': tx_total}
    
    def format_bytes(self, bytes_val):
        for unit in ['B', 'KB', 'MB', 'GB']:
            if bytes_val < 1024.0:
                return f"{bytes_val:.1f}{unit}"
            bytes_val /= 1024.0
        return f"{bytes_val:.1f}TB"


if __name__ == "__main__":
    box = RNodeBox()
    
    print("RNode Box Core Testing")
    print("=" * 50)
    
    print("\n[SERVICE STATUS]")
    services = box.get_all_services()
    for service, status in services.items():
        print(f"  {service}: {'Running' if status else 'Stopped'}")
    
    print("\n[RETICULUM INFO]")
    print(f"  Identity: {box.get_reticulum_identity()}")
    print(f"  Mesh Nodes: {box.get_mesh_node_count()}")
    rns_interfaces = box.get_reticulum_interfaces()
    if rns_interfaces:
        print(f"  Configured Interfaces: {', '.join(rns_interfaces)}")
    
    print("\n[NETWORK INTERFACES]")
    for iface in box.get_active_interfaces():
        stats = box.get_interface_stats(iface)
        print(f"  {iface}: RX {box.format_bytes(stats['rx_bytes'])} / TX {box.format_bytes(stats['tx_bytes'])}")
    
    print("\n[ACCESS POINT]")
    ap_info = box.get_ap_info()
    print(f"  SSID: {ap_info['ssid']}")
    print(f"  IP: {ap_info['ip']}")
    print(f"  Clients: {box.get_ap_clients_count()}")
    print(f"  MeshChat: {box.get_meshchat_url()}")
    
    print("\n[VPN STATUS]")
    if box.is_vpn_active():
        vpn_info = box.get_vpn_info()
        if vpn_info:
            print(f"  Type: {vpn_info['type']}")
            print(f"  Interface: {vpn_info['interface']}")
            if 'peers' in vpn_info:
                print(f"  Peers: {vpn_info['peers']}")
            if 'endpoint' in vpn_info:
                print(f"  Endpoint: {vpn_info['endpoint']}")
    else:
        print("  VPN: Not Active")
    
    print("\n[LORA DEVICES]")
    lora_devices = box.get_all_lora_info()
    if lora_devices:
        for device in lora_devices:
            print(f"  {device['path']}: {device['type']}")
            if device['configured']:
                print(f"    Configured as RNode")
    else:
        print("  No LoRa devices detected")
    
    print("\n[SYSTEM HEALTH]")
    print(f"  CPU Temp: {box.get_cpu_temp():.1f}C")
    print(f"  CPU Usage: {box.get_cpu_usage():.1f}%")
    mem = box.get_memory_usage()
    print(f"  Memory: {mem['used']}MB / {mem['total']}MB ({mem['percent']}%)")
    disk = box.get_disk_usage()
    print(f"  Disk: {disk['used']} / {disk['total']} ({disk['percent']}%)")
    print(f"  Uptime: {box.get_uptime()}")
    
    print("\n" + "=" * 50)
