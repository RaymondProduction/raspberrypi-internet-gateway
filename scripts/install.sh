#!/bin/bash
set -e

echo "[1/6] Installing required packages..."
apt update
apt install -y iptables avahi-daemon

echo "[2/6] Installing NAT script..."
install -m 0755 scripts/pi-internet-share.sh /usr/local/sbin/pi-internet-share.sh

echo "[3/6] Installing sysctl config..."
install -m 0644 sysctl/99-ip-forward.conf /etc/sysctl.d/99-ip-forward.conf
sysctl --system

echo "[4/6] Installing systemd service..."
install -m 0644 systemd/pi-internet-share.service /etc/systemd/system/pi-internet-share.service
systemctl daemon-reload

echo "[5/6] Enabling and starting service..."
systemctl enable --now pi-internet-share.service

echo "[6/6] Done."
systemctl status pi-internet-share.service --no-pager
