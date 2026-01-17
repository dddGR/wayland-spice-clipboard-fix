#!/bin/bash
set -e

echo -e "\nInstalling Wayland SPICE clipboard fix..."

if [ "$XDG_SESSION_TYPE" != "wayland" ]; then
    echo "Warning: Not running on Wayland session"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi


if command -v dnf >/dev/null 2>&1; then
    INSTALLER="dnf install -y"
elif command -v apt >/dev/null 2>&1; then
    INSTALLER="apt install -y"
elif command -v pacman >/dev/null 2>&1; then
    INSTALLER="pacman -S --noconfirm"
else
    exit 1
fi

echo -e "\nInstalling dependencies..."
sudo $INSTALLER wl-clipboard xclip spice-vdagent


echo -e "\nInstalling bridge script..."
sudo cp scripts/wayland-spice-clipboard /usr/local/bin/
sudo chmod +x /usr/local/bin/wayland-spice-clipboard

echo -e "\nSetting up service..."
mkdir -p ~/.config/systemd/user
cp systemd/wayland-spice-clipboard.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable wayland-spice-clipboard.service
systemctl --user start wayland-spice-clipboard.service

echo -e "\nSetting up spice agent..."
# ./scripts/setup-spice-autostart.sh # run manually if having issues

sudo systemctl enable spice-vdagentd
sudo systemctl start spice-vdagentd

echo -e "\nInstallation complete!"
echo "Check status: systemctl --user status wayland-spice-clipboard.service"
echo "Monitor logs: journalctl --user -u wayland-spice-clipboard.service -f"

echo -e "\nRecommend rebooting the system"
read -p "Do you want to restart? (Y/n) " -n 1 -r

if [[ $REPLY =~ ^[Nn]$ ]]; then
    exit 0
fi

sudo reboot now
