#!/bin/bash
set -e

echo " Starting kernel downgrade to GA version 6.8.0"

# Show current kernel
echo "Current kernel version:"
uname -r

# Confirm Ubuntu version
echo "Checking Ubuntu version..."
lsb_release -a

# Update package list
echo "Updating package list..."
sudo apt update

# Install GA kernel
echo "Installing linux-image-generic (GA kernel)..."
sudo apt install -y linux-image-generic

# Remove HWE kernel 6.14.0-32
echo "Removing HWE kernel 6.14.0-32..."
sudo apt remove --autoremove -y \
  linux-generic-hwe-24.04 \
  linux-image-6.14.0-32-generic \
  linux-headers-6.14.0-32-generic \
  linux-modules-6.14.0-32-generic

# Update GRUB
echo "Updating GRUB..."
sudo update-grub

# Prompt for reboot
echo " Kernel downgrade complete."
echo " Reboot is required to apply changes."
read -p "Do you want to reboot now? (y/n): " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
  touch /tmp/kernel_upgrade_complete
  echo "Rebooting now..."
  sudo reboot
else
  echo "Reboot skipped. Please reboot manually before continuing."
  exit 1
fi
