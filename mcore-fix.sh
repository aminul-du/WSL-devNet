#!/usr/bin/env bash
set -euo pipefail

echo ">>> 0. Safety Check: Verifying host namespace (eth0)..."
if ! ip link show eth0 >/dev/null 2>&1; then
    echo "❌ CRITICAL: You are inside a namespace! Type 'exit' until 'ip a' shows eth0."
    exit 1
fi

echo ">>> 1. Aggressive cleanup of previous attempts..."
pkill -9 -f "mcore-ns" || true
umount -l /var/run/netns/mcore-ns 2>/dev/null || true
ip netns del mcore-ns 2>/dev/null || true
ip link del veth0 2>/dev/null || true

echo ">>> 2. Creating namespace and veth..."
ip netns add mcore-ns
ip link add veth0 type veth peer name veth1
ip link set veth1 netns mcore-ns

echo ">>> 3. Configuring IPs and MAC..."
ip link set dev veth0 address 02:23:18:01:61:00
ip addr add 10.200.1.1/24 dev veth0
ip link set veth0 up

ip netns exec mcore-ns ip link set dev veth1 address 02:23:18:01:61:01
ip netns exec mcore-ns ip addr add 10.200.1.2/24 dev veth1
ip netns exec mcore-ns ip addr add 172.23.180.161/20 dev veth1
ip netns exec mcore-ns ip link set veth1 up
ip netns exec mcore-ns ip link set lo up

echo ">>> 4. Configuring Routing and DNS..."
ip netns exec mcore-ns ip route add default via 10.200.1.1
ip route replace 172.23.180.161/32 dev veth0

# Create DNS config for the namespace
mkdir -p /etc/netns/mcore-ns
echo "nameserver 1.1.1.1" > /etc/netns/mcore-ns/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/netns/mcore-ns/resolv.conf

echo ">>> 5. Configuring NAT..."
sysctl -w net.ipv4.ip_forward=1 >/dev/null
iptables -t nat -A POSTROUTING -s 10.200.1.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.23.180.161/32 -o eth0 -j MASQUERADE
iptables -P FORWARD ACCEPT

echo ">>> 6. Creating easy shortcut 'mcore-ns'..."
cat << 'ALIAS' > /usr/local/bin/mcore-ns
#!/bin/bash
ip netns exec mcore-ns "$@"
ALIAS
chmod +x /usr/local/bin/mcore-ns

echo ">>> 7. Testing DNS and Internet..."
if ip netns exec mcore-ns ping -c 1 8.8.8.8 >/dev/null && ip netns exec mcore-ns ping -c 1 google.com >/dev/null; then
    echo "✅ SUCCESS! Namespace is isolated, has internet, and DNS is working."
else
    echo "⚠️ WARNING: Ping failed. Check iptables."
fi
