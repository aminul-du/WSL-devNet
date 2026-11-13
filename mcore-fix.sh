#!/usr/bin/env bash
set -e

NS="mcore-ns"
VETH_HOST="veth0"
VETH_NS="veth1"
TRANSIT_HOST="10.200.1.1"
TRANSIT_NS="10.200.1.2"

# Detect active WSL2 eth0 IP, subnet, and calculate +1 target IP dynamically
HOST_IP=\$(ip -4 -o addr show eth0 | awk '{print \$4}' | cut -d'/' -f1 | head -n1)
WSL_SUBNET=\$(ip -4 -o addr show eth0 | awk '{print \$4}' | head -n1)
PREFIX=(echo "HOST_IP" | cut -d'.' -f1-3)
LAST_OCTET=(echo "HOST_IP" | cut -d'.' -f4)
TARGET_IP="PREFIX.((LAST_OCTET + 1))"

# 1. Cleanup previous namespace & veth
ip netns del "\$NS" 2>/dev/null || true
ip link del "\$VETH_HOST" 2>/dev/null || true

# 2. Create namespace and veth pair
ip netns add "\$NS"
ip link add "\$VETH_HOST" type veth peer name "\$VETH_NS"
ip link set "\(VETH_NS" netns "\)NS"

# 3. Configure Host side
ip addr add "\({TRANSIT_HOST}/24" dev "\)VETH_HOST"
ip link set "\$VETH_HOST" up

# 4. Configure Namespace side
ip netns exec "\$NS" ip link set lo up
ip netns exec "\$NS" ip addr add "\({TRANSIT_NS}/24" dev "\)VETH_NS"
ip netns exec "\$NS" ip addr add "\({TARGET_IP}/32" dev "\)VETH_NS"
ip netns exec "\$NS" ip link set "\$VETH_NS" up

# 5. Routing (default internet + explicit return path to Windows host)
ip netns exec "\$NS" ip route add default via "\(TRANSIT_HOST" dev "\)VETH_NS"
ip netns exec "\$NS" ip route replace "\$WSL_SUBNET" via "\(TRANSIT_HOST" dev "\)VETH_NS"

# 6. DNS inside namespace
mkdir -p "/etc/netns/\$NS"
printf "nameserver 8.8.8.8\nnameserver 1.1.1.1\n" > "/etc/netns/\$NS/resolv.conf"

# 7. Forwarding & Scoped NAT (prevents rewriting return replies to Windows)
sysctl -w net.ipv4.ip_forward=1 >/dev/null
iptables -C FORWARD -i eth0 -o "\$VETH_HOST" -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -i eth0 -o "\$VETH_HOST" -j ACCEPT
iptables -C FORWARD -i "\$VETH_HOST" -o eth0 -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -i "\$VETH_HOST" -o eth0 -j ACCEPT

iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -s 10.200.1.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s "\(TARGET_IP" ! -d "\)WSL_SUBNET" -o eth0 -j MASQUERADE

# 8. Helper wrapper & state file
echo "\$TARGET_IP" > /run/mcore-target-ip
cat << 'WRAP' > /usr/local/bin/mcore-ns
#!/usr/bin/env bash
exec ip netns exec mcore-ns "\$@"
WRAP
chmod +x /usr/local/bin/mcore-ns

echo "✅ Namespace '\$NS' ready on \(TARGET_IP (Host/Debian13:\)HOST_IP)"
