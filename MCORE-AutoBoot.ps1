Start-Sleep -Seconds 15

# 1. Build the isolated namespace inside UbuntuPro
wsl -d UbuntuPro -u root /usr/local/bin/mcore-fix.sh | Out-Null

# 2. Detect current WSL IP and subnet dynamically, then fix return route and NAT
wsl -d UbuntuPro -u root -- bash -c '
  WSL_SUBNET=$(ip -o -f inet addr show eth0 | awk "{print \$4}")
  ip netns exec mcore-ns ip route replace $WSL_SUBNET via 10.200.1.1 dev veth1
  iptables -t nat -F POSTROUTING
  iptables -t nat -A POSTROUTING -s 10.200.1.0/24 -o eth0 -j MASQUERADE
  iptables -t nat -A POSTROUTING -s 172.23.180.161 ! -d $WSL_SUBNET -o eth0 -j MASQUERADE
' | Out-Null

# 3. Map Windows host route to the dynamic WSL IP
$WSL_IP = (wsl -d UbuntuPro -- hostname -I 2>$null).Trim().Split(" ")[0]

if ($WSL_IP) {
    route delete 172.23.180.161 2>$null | Out-Null
    route add 172.23.180.161 mask 255.255.255.255 $WSL_IP -p | Out-Null
}
