# Raspberry Pi Internet Gateway

This repository contains a minimal Raspberry Pi Internet sharing setup based on a real field configuration.

The Raspberry Pi receives Internet access over Wi-Fi and shares it to a local Ethernet network. In this setup the Raspberry Pi works like a small router.

## Real Tested Environment

- Device: Raspberry Pi 4
- Hostname during setup: `pi4`
- SSH user: `raymond`
- OS: Debian GNU/Linux / Raspberry Pi OS, 64-bit
- Kernel from login banner: `6.18.34+rpt-rpi-v8`
- Architecture: `aarch64`
- Wi-Fi connection: `netplan-wlan0-MERCUSYS_1`
- Ethernet connection: `netplan-eth0`
- Internet interface: `wlan0`
- Local / camera interface: `eth0`
- Raspberry Pi Ethernet IP: `192.168.1.1/24`
- NAT service: `pi-internet-share.service`

## Network Topology

```text
Internet / Wi-Fi router
        │
        │ Wi-Fi
        ▼
+----------------------------+
| Raspberry Pi 4             |
|                            |
| wlan0 = Internet uplink    |
| eth0  = 192.168.1.1/24     |
+----------------------------+
        │
        │ Ethernet
        ▼
+----------------------------+
| Computer / Embedded device |
| 192.168.1.x                |
| Gateway: 192.168.1.1       |
+----------------------------+
```

## What This Setup Does

The Raspberry Pi forwards packets between `eth0` and `wlan0`.

Devices connected to `eth0` use the Raspberry Pi as their gateway. The Raspberry Pi then performs NAT masquerading through `wlan0`.

In practice:

- The Raspberry Pi itself has Internet through Wi-Fi.
- The camera or other device is connected to the Raspberry Pi Ethernet port.
- The camera has an IP like `192.168.1.10`.
- The camera gateway is `192.168.1.1`.
- The Raspberry Pi rewrites outgoing packets so they can reach the Internet through Wi-Fi.

## Files

```text
raspberrypi-internet-gateway/
├── README.md
├── scripts/
│   ├── pi-internet-share.sh
│   └── install.sh
├── systemd/
│   └── pi-internet-share.service
├── sysctl/
│   └── 99-ip-forward.conf
└── docs/
    ├── troubleshooting.md
    └── commands-used.md
```

## Configure Static Ethernet IP

On the Raspberry Pi, Ethernet is configured as `192.168.1.1/24`.

The connection name in this real setup was:

```text
netplan-eth0
```

Command:

```bash
sudo nmcli con mod netplan-eth0 \
  ipv4.addresses 192.168.1.1/24 \
  ipv4.method manual
```

Reconnect the interface:

```bash
sudo nmcli con down netplan-eth0
sudo nmcli con up netplan-eth0
```

Or reboot:

```bash
sudo reboot
```

After reboot, check from another Linux machine:

```bash
ping 192.168.1.1
ssh raymond@192.168.1.1
```

## SSH Known Hosts Note

If `192.168.1.1` was previously used by another device, SSH may show:

```text
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
```

Fix it on the client machine:

```bash
ssh-keygen -R 192.168.1.1
ssh raymond@192.168.1.1
```

This happens because SSH remembers the old host key for that IP address.

## Install Dependencies

The NAT script uses `iptables`.

On the tested Raspberry Pi, the first service start failed because `iptables` was missing:

```text
/usr/local/sbin/pi-internet-share.sh: line 16: iptables: command not found
```

Install it:

```bash
sudo apt update
sudo apt install -y iptables
```

## Enable IP Forwarding

Permanent setting:

```bash
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-ip-forward.conf
sudo sysctl --system
```

Check:

```bash
cat /proc/sys/net/ipv4/ip_forward
```

Expected:

```text
1
```

## Install Files Manually

Copy NAT script:

```bash
sudo cp scripts/pi-internet-share.sh /usr/local/sbin/pi-internet-share.sh
sudo chmod +x /usr/local/sbin/pi-internet-share.sh
```

Copy sysctl config:

```bash
sudo cp sysctl/99-ip-forward.conf /etc/sysctl.d/99-ip-forward.conf
sudo sysctl --system
```

Copy systemd service:

```bash
sudo cp systemd/pi-internet-share.service /etc/systemd/system/pi-internet-share.service
sudo systemctl daemon-reload
sudo systemctl enable --now pi-internet-share.service
```

Check service:

```bash
systemctl status pi-internet-share.service
```

Expected successful state:

```text
Active: active (exited)
```

This is normal because the service is `Type=oneshot`. It runs the script, applies firewall rules, and exits successfully.

## Automatic Install

From the repository directory:

```bash
sudo ./scripts/install.sh
```

## Verify NAT Rules

```bash
sudo iptables -t nat -L -n -v
sudo iptables -L FORWARD -n -v
```

You should see a `MASQUERADE` rule for `wlan0` and forwarding rules between `eth0` and `wlan0`.

## Verify Internet on Raspberry Pi

```bash
ping 8.8.8.8
```

The tested setup showed successful pings with around 22-27 ms latency.

## Configure the Downstream Device

Example for camera or embedded device:

```text
IP address : 192.168.1.10
Netmask    : 255.255.255.0
Gateway    : 192.168.1.1
DNS        : 1.1.1.1
```

Test from the device:

```bash
ping 192.168.1.1
ping 8.8.8.8
ping google.com
```

If `ping 8.8.8.8` works but `ping google.com` does not, the problem is DNS.

## mDNS / `.local`

The actual hostname during the setup was:

```text
pi4
```

So the mDNS name should usually be:

```text
pi4.local
```

To check current hostname:

```bash
hostname
hostnamectl
echo "$(hostname).local"
```

To set another hostname, for example `raymond`:

```bash
sudo hostnamectl set-hostname raymond
```

Install and enable Avahi:

```bash
sudo apt install -y avahi-daemon
sudo systemctl enable --now avahi-daemon
```

Then the Raspberry Pi should be reachable as:

```text
raymond.local
```

or, if hostname stays `pi4`:

```text
pi4.local
```

## Important Nuances

### Do not set the same IP on Wi-Fi and Ethernet

In this setup, Wi-Fi belongs to the upstream network, for example:

```text
192.168.0.0/24
```

Ethernet is a separate local network:

```text
192.168.1.0/24
```

This separation is important. If both sides use the same subnet, routing becomes ambiguous.

### `192.168.1.1` is used as the Raspberry Pi local gateway

Many routers also use `192.168.1.1`. This is fine only if the Raspberry Pi Ethernet network is separate from the upstream Wi-Fi network.

In the tested setup, the Raspberry Pi was accessed first through Wi-Fi at:

```text
192.168.0.206
```

Then Ethernet was configured as:

```text
192.168.1.1
```

### systemd service is `active (exited)`

This is expected.

The service is not a long-running daemon. It applies kernel and firewall settings and exits. `RemainAfterExit=yes` keeps systemd status as active.

### Rules are applied at boot

The service is enabled with:

```bash
sudo systemctl enable --now pi-internet-share.service
```

At boot, it waits for `network-online.target` and then applies NAT rules.

## Security Note

This setup is intended for a trusted local Ethernet segment. Any device connected to the Raspberry Pi Ethernet side can use it as a gateway if its network settings point to `192.168.1.1`.

For field use this is usually acceptable, but for untrusted networks firewall restrictions should be added.

## Quick Recovery Commands

Restart NAT:

```bash
sudo systemctl restart pi-internet-share.service
```

View logs:

```bash
journalctl -xeu pi-internet-share.service
```

Run script directly:

```bash
sudo /usr/local/sbin/pi-internet-share.sh
```

Check interfaces:

```bash
nmcli device status
ip addr
ip route
```

# Enable VNC on Raspberry Pi and Connect from Linux

## 1. Enable VNC on Raspberry Pi

Open Raspberry Pi configuration:

```bash
sudo raspi-config
```

Go to:

```text
Interface Options
└── VNC
    └── Yes
```

Exit `raspi-config`.

Verify that the VNC server is running:

```bash
sudo systemctl status wayvnc
```

On older Raspberry Pi OS versions:

```bash
sudo systemctl status vncserver-x11-serviced
```

If needed, reboot:

```bash
sudo reboot
```

---

## 2. Find the Raspberry Pi IP Address

```bash
hostname -I
```

Example:

```text
192.168.1.1
```

If mDNS is configured, the Raspberry Pi may also be reachable as:

```text
raspberrypi.local
```

or:

```text
pi4.local
```

---

## 3. Install TigerVNC Viewer on Linux

Ubuntu/Debian:

```bash
sudo apt update
sudo apt install tigervnc-viewer
```

---

## 4. Connect to Raspberry Pi

Using the IP address:

```bash
vncviewer 192.168.1.1
```

Using mDNS:

```bash
vncviewer raspberrypi.local
```

or:

```bash
vncviewer pi4.local
```

You can also start the graphical application:

```bash
vncviewer
```

and enter:

```text
192.168.1.1
```

or:

```text
raspberrypi.local
```

---

## 5. Login

Enter the Raspberry Pi username and password when prompted.

---