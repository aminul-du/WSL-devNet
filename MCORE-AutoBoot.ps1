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
