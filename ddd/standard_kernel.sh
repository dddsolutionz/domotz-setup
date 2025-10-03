### Script: `downgrade_kernel_6_8.sh`

```bash
#!/bin/bash

# Check current kernel version
echo "Current kernel version:"
uname -r

# Confirm Ubuntu version
echo "Checking Ubuntu version..."
lsb_release -a

# Update package list
echo "Updating package list..."
sudo apt update

# Install GA kernel (6.8.x)
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

# Prompt before reboot
echo "Kernel downgrade complete."
echo "Reboot is required to apply changes."
read -p "Do you want to reboot now? (y/n): " confirm
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
  sudo reboot
else
  echo "Reboot skipped. Please reboot manually when ready."
fi
```

---
