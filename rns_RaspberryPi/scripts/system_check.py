#!/usr/bin/env python3

import subprocess
import sys



def run_command(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip()

def check_python():
    print("\n ====== Python Version ======")
    version = sys.version_info
    print(f"Python {version.major}.{version.minor}")
    
    if version.major >= 3 and version.minor >= 7:
        print("Ok!")
        return True
    else:
        print("Need Python 3.7+ !!!")
        return False
    
def check_interface():
    print("\n========= Network Interfaces ==========")
    output = run_command("ip link show")
    
    interface = []
    for line in output.split('\n'):
        if 'eth0' in line:
            interface.append('eth0')
        if 'wlan0' in line:
            interface.append('wlan0')
        if 'wlan1' in line:
            interface.append('wlan1')
            
    for iface in interface:
        print(f"Found: {iface}")
    
    return len(interface) > 0

if __name__ == "__main__":
    print("Rnode Router - System Check 1.0!")
    
    results = []
    results.append(check_python())
    results.append(check_interface())
    
    print ("\n" + "="*40)
    if all(results):
        print("All good!")
        sys.exit(0)
    else:
        print("Checks failed.")
        sys.exit(1)
