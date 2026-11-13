Start-Sleep -Seconds 15

# 1. Build isolated namespace inside UbuntuPro (auto-assigns WSL_IP + 1)
wsl -d UbuntuPro -u root /usr/local/bin/mcore-fix.sh | Out-Null

# 2. Retrieve dynamic WSL Host IP and Namespace Target IP
$WSL_IP = (wsl -d UbuntuPro -- hostname -I 2>$null).Trim().Split(" ")
$TARGET_IP = (wsl -d UbuntuPro -- cat /run/mcore-target-ip 2>$null).Trim()

# 3. Map Windows /32 host route cleanly
if ($WSL_IP -and $TARGET_IP) {
    route delete $TARGET_IP 2>$null | Out-Null
    route add $TARGET_IP mask 255.255.255.255 $WSL_IP -p | Out-Null
}

# 4. Forward external LAN ports to UbuntuPro mcore-ns ($TARGET_IP)
$PortsToExpose = @(3000, 3001, 3002)
if ($TARGET_IP) {
    foreach ($Port in $PortsToExpose) {
        netsh interface portproxy delete v4tov4 listenport=$Port listenaddress=0.0.0.0 2>$null | Out-Null
        netsh interface portproxy add v4tov4 listenport=$Port listenaddress=0.0.0.0 connectport=$Port connectaddress=$TARGET_IP | Out-Null

        if (-not (Get-NetFirewallRule -DisplayName "MCORE-LAN-$Port" -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName "MCORE-LAN-$Port" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
        }
    }
}
