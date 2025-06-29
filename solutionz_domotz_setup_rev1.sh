#!/bin/bash
# Confirmation message
echo "------------------------------------------------------------"
echo "This script will perform the following actions:"
echo "1. Update System and install key packages"
echo "2. Load the 'tun' module if not already loaded"
echo "3. Install Domotz Pro agent via Snap Store"
echo "4. Grant permissions to Domotz Pro agent"
echo "5. Enabling UFW Firewall"
echo "6. Allow port 3000 in UFW"
echo "7. Configure netplan for DHCP on attached NICs"
echo "8. Resolve VPN on Demand issue with DNS"
echo "9. Disable cloud-init's network configuration"
echo "10. Enable and start SSH service, install package lists..."
echo "11. Automatically append kernel parameters to GRUB config"
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
step_message 5 "Enabling UFW Firewall"
progress_message "Installing and enabling UFW..."
# Install UFW if not already installed
if ! dpkg -s ufw >/dev/null 2>&1; then
    sudo apt-get install -y ufw
    echo "UFW installed successfully."
else
    echo "UFW is already installed."
fi
# Enable UFW without interactive prompt
sudo ufw --force enable
# Show verbose status
sudo ufw status verbose
# Step 6
step_message 6 "Allowing port 3000 in UFW"
progress_message "Creating firewall rule"
sudo ufw allow 3000
# Step 7
step_message 7 "Configuring netplan for DHCP on attached NICs"
progress_message "Editing netplan configuration file..."
sudo tee /etc/netplan/00-installer-config.yaml > /dev/null <<EOL
network:
    version: 2
    ethernets:
        all-en:
            match:
                name: "en*"
            dhcp4: true
            dhcp6: false
            accept-ra: false
        all-eth:
            match:
                name: "eth*"
            dhcp4: true
            dhcp6: false
            accept-ra: false
EOL
sudo chmod 600 /etc/netplan/00-installer-config.yaml
sudo rm -f /etc/netplan/50-cloud-init.yaml
sudo rm -f /etc/netplan/50-cloud-init.yaml.save
sudo netplan apply
# Step 8
step_message 8 "Resolving VPN on Demand issue with DNS"
progress_message "Swaping resolv.conf file link..."
sudo unlink /etc/resolv.conf
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
ls -l /etc/resolv.conf
# Step 9
step_message 9 "Disabling cloud-init's network configuration"
progress_message "Creating /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
echo "network: {config: disabled}" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
# Step 10
step_message 10 "Enabling SSH Service, install package lists..."
progress_message "Installing and starting OpenSSH server..."
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh --no-pager
echo "Installing nano..."
sudo apt install -y nano
echo "Installing iputils-ping..."
sudo apt install -y iputils-ping
echo "All requested packages are installed."
# Step 11
step_message 11 "Automatically append kernel parameters to GRUB config"
progress_message "Safely modify GRUB to disable predictable network interface names"
GRUB_FILE="/etc/default/grub"
PARAMS="net.ifnames=0 biosdevname=0"
echo "Modifying GRUB configuration..."
# Backup GRUB config
sudo cp "$GRUB_FILE" "${GRUB_FILE}.bak"
# Check if GRUB_CMDLINE_LINUX exists
if grep -q "^GRUB_CMDLINE_LINUX=" "$GRUB_FILE"; then
    # Append only if parameters are not already present
    if ! grep -q "$PARAMS" "$GRUB_FILE"; then
        sudo sed -i "/^GRUB_CMDLINE_LINUX=/ s/\"\(.*\)\"/\"\1 $PARAMS\"/" "$GRUB_FILE"
        echo "Added kernel parameters to GRUB_CMDLINE_LINUX."
    else
        echo "Kernel parameters already set in GRUB config."
    fi
else
    # Add the line if it doesn't exist
    echo "GRUB_CMDLINE_LINUX=\"$PARAMS\"" | sudo tee -a "$GRUB_FILE"
    echo "Created GRUB_CMDLINE_LINUX entry with kernel parameters."
fi
# Apply changes
sudo update-grub
echo "GRUB updated. Rebooting system now..."
sudo reboot
echo "------------------------------------------------------------"
echo "   [+] Setup completed successfully!"
echo "------------------------------------------------------------"
