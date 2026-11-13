# WSL-devNet

Dual-distro **WSL2 network isolation and static IP routing** for running multiple Linux distributions with distinct, dedicated IP addresses reachable directly from a Windows host.

---

## Network Architecture

WSL2 shares a single lightweight Linux kernel and virtual network adapter (`eth0`) across all installed distributions. This setup isolates **UbuntuPro** inside a dedicated Linux network namespace (`mcore-ns`) with its own virtual Ethernet pair (`veth`), transit subnet, and NAT rules, leaving **Debian13** untouched on the primary WSL2 IP.

```text
MCore Windows Host (172.23.176.1)
│
├── Debian13 (WSL2 Root Namespace)
│   └── 172.23.180.160  [Default WSL2 Interface - Unchanged]
│
└── UbuntuPro (Isolated Namespace: mcore-ns)
    └── 172.23.180.161  [Target IP via 10.200.1.0/24 veth Transit]
```

---

## Repository Files

| File | Target Location | Purpose |
| :--- | :--- | :--- |
| **`mcore-fix.sh`** | `/usr/local/bin/mcore-fix.sh` | Creates the `mcore-ns` network namespace, configures the `veth` pair (`10.200.1.1` ↔ `10.200.1.2`), assigns `172.23.180.161`, sets up DNS, and enables outbound NAT. |
| **`MCORE-AutoBoot.ps1`** | `C:\Scripts\MCORE-AutoBoot.ps1` | Initializes `mcore-ns` at boot, dynamically detects the WSL2 subnet, fixes return routing and `MASQUERADE` exclusions, and maps the Windows `/32` host route (`172.23.180.161` → dynamic WSL IP). |
| **`Install-MCORE-Task.ps1`** | Run once in Admin PowerShell | Registers `MCORE-AutoBoot.ps1` in **Windows Task Scheduler** with Highest Privileges at user logon for silent background execution without UAC prompts. |

---

## Key Routing & NAT Mechanics

1. **Dynamic Subnet Return Path:** Replaces the on-link WSL subnet route inside `mcore-ns` with an explicit gateway route via `10.200.1.1` (`veth1`) so return packets reach the Windows host cleanly instead of failing ARP.
2. **Scoped NAT (`MASQUERADE` Exclusion):** Excludes the local WSL subnet (`! -d $WSL_SUBNET`) from `POSTROUTING` `MASQUERADE` so Windows receives reply packets directly from `172.23.180.161` rather than having the source IP rewritten to `172.23.180.160`.
3. **Windows Host `/32` Route:** Maps `172.23.180.161/32` to the active WSL2 `eth0` IP on Windows so host applications connect directly to `UbuntuPro`.

---

## Daily Usage & Cold-Boot Verification

### Run Commands Inside `UbuntuPro` (`172.23.180.161`)
```bash
# Run a single command inside the isolated namespace
mcore-ns curl -s ifconfig.me
mcore-ns git push origin main

# Enter an interactive shell inside mcore-ns
sudo ip netns exec mcore-ns su - \$USER
```

### Verify Connectivity & Cold-Boot Recovery (PowerShell)
```powershell
wsl --shutdown
Start-ScheduledTask -TaskName "MCORE-AutoBoot"
Start-Sleep -Seconds 20

ping 172.23.180.160   # Debian13 (TTL=64)
ping 172.23.180.161   # UbuntuPro mcore-ns (TTL=63)
```
