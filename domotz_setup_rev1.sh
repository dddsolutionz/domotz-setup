#!/bin/bash
# Confirmation message
echo "------------------------------------------------------------"
echo "This script will perform the following actions:"
echo "1. Update System and install key packages"
echo "2. Load the 'tun' module if not already loaded"
echo "3. Install Domotz Pro agent via Snap Store"
echo "4. Grant permissions to Domotz Pro agent"
echo "5. Allow port 3000 in UFW"
echo "6. Configure netplan for DHCP on attached NICs"
echo "7. Resolve VPN on Demand issue with DNS"
echo "8. Disable cloud-init's network configuration"
echo "9. Enable and start SSH service"
echo "10. Enable UFW"
echo "------------------------------------------------------------"
echo "Disclaimer:"
echo
echo "1. Purpose: This script is designed for a fresh installation of Ubuntu Server 24.04."
echo "2. By proceeding, you confirm that:"
echo "   - The script will modify system configurations and install necessary packages."
echo "   - It may update system files and settings as per its instructions."
echo "   - Using this script on an already configured system may lead to unexpected behavior."
echo "3. Responsibility: You are responsible for any consequences resulting from running this script."
echo
read -p "Type 'yes' to proceed: " confirmation1
if [ "$confirmation1" != "yes" ]; then
    echo "Confirmation not received. Exiting script."
    exit 1
fi
echo "------------------------------------------------------------"

echo "Please confirm again to proceed."
read -p "Type 'yes' to proceed: " confirmation2
if [ "$confirmation2" != "yes" ]; then
    echo "Confirmation not received. Exiting script."
    exit 1
fi
# Set non-interactive mode for package configuration and disables NEEDRESTART MESSAGES
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
# Function to display step messages
step_message() {
    echo "------------------------------------------------------------"
    echo "Step $1: $2"
    echo "------------------------------------------------------------"
}
# Function to display real-time feedback
progress_message() {
    echo "   [+] $1"
}
# Step 1
step_message 1 "Updating System and installing key packages"
progress_message "Updating package lists..."
sudo apt update
progress_message "Upgrading packages..."
sudo apt upgrade -y
progress_message "Installing necessary packages..."
sudo apt install -y net-tools openvswitch-switch
# Step 2
step_message 2 "Loading tun module if not already loaded"
progress_message "Loading 'tun' module..."
sudo modprobe tun
sudo grep -qxF "tun" /etc/modules || sudo sh -c 'echo "tun" >> /etc/modules'
# Step 3
step_message 3 "Installing Domotz Pro agent via Snap Store"
progress_message "Installing Domotz Pro agent..."
sudo snap install domotzpro-agent-publicstore
# Step 4
step_message 4 "Granting permissions to Domotz Pro agent"
permissions=("firewall-control" "network-observe" "raw-usb" "shutdown" "system-observe")
for permission in "${permissions[@]}"; do
    progress_message "Connecting Domotz Pro agent: $permission..."
    sudo snap connect "domotzpro-agent-publicstore:$permission"
done
# Step 5
step_message 5 "Allowing port 3000 in UFW"
progress_message "Creating firewall rule"
sudo ufw allow 3000
# Step 6
step_message 6 "Configuring netplan for DHCP on attached NICs"
progress_message "Editing netplan configuration file..."
sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      dhcp4: true
    enp2s0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
EOL
sudo chmod 600 /etc/netplan/50-cloud-init.yaml
sudo netplan apply
# Step 7
step_message 7 "Resolving VPN on Demand issue with DNS"
progress_message "Swaping resolv.conf file link..."
sudo unlink /etc/resolv.conf
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
# Step 8
step_message 9 "Disabling cloud-init's network configuration"
progress_message "Creating /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
echo "network: {config: disabled}" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
# Step 9
step_message 9 "Enabling SSH Service"
progress_message "Installing and starting OpenSSH server..."
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh --no-pager
# Step 10
step_message 10 "Enabling UFW Firewall"
progress_message "Enabling UFW..."
sudo ufw enable
sudo ufw status verbose
echo "------------------------------------------------------------"
echo "   [+] Setup completed successfully!"
echo "------------------------------------------------------------"
