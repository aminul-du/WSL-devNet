# WSL-devNet

Dynamic dual-distro **WSL2 network isolation and static/offset IP routing** for running multiple Linux distributions with distinct, dedicated IP addresses reachable directly from a Windows host.

---

## Network Architecture

WSL2 shares a single lightweight Linux kernel and virtual network adapter (`eth0`) across all installed distributions. This setup isolates **UbuntuPro** inside a dedicated Linux network namespace (`mcore-ns`) and automatically assigns it `WSL_IP + 1` (e.g., `172.23.180.161` while **Debian13** remains untouched on `172.23.180.160`).

```text
MCore Windows Host
│
├── Debian13 (WSL2 Root Namespace)
│   └── WSL_IP (e.g. 172.23.180.160)      [Default WSL2 Interface - Unchanged]
│
└── UbuntuPro (Isolated Namespace: mcore-ns)
    └── WSL_IP + 1 (e.g. 172.23.180.161)  [Isolated Target IP via 10.200.1.0/24 Transit]
```

---

## Repository Files

| File | Target Location | Purpose |
| :--- | :--- | :--- |
| **`mcore-fix.sh`** | `/usr/local/bin/mcore-fix.sh` | Dynamically detects `eth0`, calculates `WSL_IP + 1`, builds `mcore-ns` with a `/32` host IP, configures DNS, and applies scoped `MASQUERADE` NAT rules. |
| **`MCORE-AutoBoot.ps1`** | `C:\Scripts\MCORE-AutoBoot.ps1` | Triggers `mcore-fix.sh` at boot and maps the Windows `/32` route (`TARGET_IP` → `WSL_IP`). |
| **`Install-MCORE-Task.ps1`** | Run once in Admin PowerShell | Registers `MCORE-AutoBoot.ps1` in **Windows Task Scheduler** with Highest Privileges for silent background execution (no UAC prompt). |

---

## Daily Usage & Verification

### Inside `UbuntuPro`
```bash
# Enter an interactive shell inside the isolated namespace
mcore

# Check the active isolated IP
mcore-ip

# Run a single command inside mcore-ns
mcore-ns git push origin main
```

### From Windows PowerShell
```powershell
ping 172.23.180.160   # Debian13 (TTL=64)
ping 172.23.180.161   # UbuntuPro mcore-ns (TTL=63)
```
