#!/bin/bash

# Domotz Ubuntu 24.04 Setup Script
# Author: yourname (update as needed)

# Download and run Domotz installer
wget https://raw.githubusercontent.com/hsavior/UbuntuServer_DomotzImageScript/refs/heads/main/Domotz_Ubuntu24.04.sh
chmod +x Domotz_Ubuntu24.04.sh
sudo ./Domotz_Ubuntu24.04.sh

# Configure static IP on enp2s0 (update IP as needed)
cat <<EOF | sudo tee /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      dhcp4: true
    enp2s0:
      dhcp4: no
      addresses:
        - 192.168.1.50/24
EOF

# Apply network changes
sudo netplan apply

# Show IP info for verification
ip a

# Verify and configure Domotz Agent connections
sudo snap connections domotzpro-agent-publicstore

sudo snap connect domotzpro-agent-publicstore:firewall-control
sudo snap connect domotzpro-agent-publicstore:network-observe
sudo snap connect domotzpro-agent-publicstore:raw-usb
sudo snap connect domotzpro-agent-publicstore:shutdown
sudo snap connect domotzpro-agent-publicstore:system-observe

# Enable tun module for VPN support
sudo sh -c 'echo tun >> /etc/modules'
sudo modprobe tun

# Restart Domotz Agent
sudo snap restart domotzpro-agent-publicstore

echo "✅ Setup complete. Domotz and network config should now be active."
