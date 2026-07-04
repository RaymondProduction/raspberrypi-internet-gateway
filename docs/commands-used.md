# Commands Used During Real Setup

Check NetworkManager devices:

```bash
nmcli device status
sudo nmcli con show
```

Real connection names:

```text
netplan-wlan0-MERCUSYS_1
netplan-eth0
```

Set Ethernet static IP:

```bash
sudo nmcli con mod netplan-eth0 \
  ipv4.addresses 192.168.1.1/24 \
  ipv4.method manual
```

After reboot, check Ethernet IP from laptop:

```bash
ping 192.168.1.1
ssh raymond@192.168.1.1
```

Fix SSH known host conflict:

```bash
ssh-keygen -R 192.168.1.1
ssh raymond@192.168.1.1
```

Enable IP forwarding:

```bash
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-ip-forward.conf
sudo sysctl --system
```

Create NAT service and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now pi-internet-share.service
```

Initial failure:

```text
iptables: command not found
```

Fix:

```bash
sudo apt update
sudo apt install -y iptables
sudo systemctl restart pi-internet-share.service
```

Successful status:

```text
Active: active (exited)
Internet sharing enabled.
```

Verify Pi Internet:

```bash
ping 8.8.8.8
```
