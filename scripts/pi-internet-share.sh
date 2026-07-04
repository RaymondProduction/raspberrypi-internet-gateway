#!/bin/bash
set -e

WAN_IF="wlan0"
LOCAL_IF="eth0"

echo "Internet interface: $WAN_IF"
echo "Local interface:   $LOCAL_IF"

sysctl -w net.ipv4.ip_forward=1

iptables -t nat -D POSTROUTING -o "$WAN_IF" -j MASQUERADE 2>/dev/null || true
iptables -D FORWARD -i "$LOCAL_IF" -o "$WAN_IF" -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -i "$WAN_IF" -o "$LOCAL_IF" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true

iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE
iptables -A FORWARD -i "$LOCAL_IF" -o "$WAN_IF" -j ACCEPT
iptables -A FORWARD -i "$WAN_IF" -o "$LOCAL_IF" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

echo "Internet sharing enabled."
