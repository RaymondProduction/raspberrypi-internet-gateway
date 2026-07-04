# Troubleshooting

## Service fails: `iptables: command not found`

Install iptables:

```bash
sudo apt update
sudo apt install -y iptables
```

Then restart:

```bash
sudo systemctl restart pi-internet-share.service
systemctl status pi-internet-share.service
```

## SSH warning: remote host identification has changed

If `192.168.1.1` was previously used by another device, SSH may refuse connection.

Fix on the client:

```bash
ssh-keygen -R 192.168.1.1
ssh raymond@192.168.1.1
```

## Raspberry Pi has Internet but camera does not

Check that the camera has:

```text
Gateway: 192.168.1.1
DNS:     1.1.1.1 or 8.8.8.8
```

Check NAT rules on Raspberry Pi:

```bash
sudo iptables -t nat -L -n -v
sudo iptables -L FORWARD -n -v
```

Check forwarding:

```bash
cat /proc/sys/net/ipv4/ip_forward
```

Expected:

```text
1
```

## DNS problem

If this works:

```bash
ping 8.8.8.8
```

but this does not:

```bash
ping google.com
```

then the problem is DNS. Set DNS on the camera to:

```text
1.1.1.1
8.8.8.8
```

## mDNS problem

Check current hostname:

```bash
hostname
echo "$(hostname).local"
```

Check Avahi:

```bash
systemctl status avahi-daemon
```

Install and start:

```bash
sudo apt install -y avahi-daemon
sudo systemctl enable --now avahi-daemon
```
