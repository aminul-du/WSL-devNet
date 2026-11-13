# WSL-devNet

Dynamic dual-distro **WSL2 network isolation and static/offset IP routing** for running multiple Linux distributions with distinct, dedicated IP addresses reachable directly from a Windows host.

---

## Network Architecture

WSL2 shares a single lightweight Linux kernel and virtual network adapter (`eth0`) across all installed distributions. This setup isolates **UbuntuPro** inside a dedicated Linux network namespace (`mcore-ns`) and automatically assigns it `WSL_IP + 1` (e.g., `172.23.180.161`), leaving **Debian13** untouched on the primary WSL2 IP (`172.23.180.160`).

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

## Repository Contents

| File | Target Location | Purpose |
| :--- | :--- | :--- |
| **`mcore-fix.sh`** | `/usr/local/bin/mcore-fix.sh` | Dynamically detects `eth0`, calculates `WSL_IP + 1`, creates `mcore-ns`, configures DNS, applies scoped `MASQUERADE` NAT rules, and triggers `mcore-services.sh`. |
| **`mcore-services.sh`** | `/usr/local/bin/mcore-services.sh` | Hook executed inside `mcore-ns` to auto-start services (e.g., Rust engine, EduVerse app) on `172.23.180.161`. |
| **`enable-auto-ns-shell.sh`** | Run once inside `UbuntuPro` | Configures `~/.bashrc` and `/root/.bashrc` so opening `UbuntuPro` automatically enters `mcore-ns` (`172.23.180.161`) with self-healing if opened early after a PC reboot. |
| **`MCORE-AutoBoot.ps1`** | `C:\Scripts\MCORE-AutoBoot.ps1` | Initializes `mcore-ns` at Windows startup, maps the Windows `/32` host route (`TARGET_IP` → `WSL_IP`), and configures external LAN port forwarding. |
| **`Install-MCORE-Task.ps1`** | Run once in Admin PowerShell | Registers `MCORE-AutoBoot.ps1` in **Windows Task Scheduler** with Highest Privileges for silent background startup (no UAC prompt). |

---

## Quick Verification

### Inside `UbuntuPro`
Opening `UbuntuPro` drops you directly into `mcore-ns`:
```bash
ip a          # Shows veth1 with 172.23.180.161/32
mcore-ip      # Prints active isolated target IP
```
*(Escape hatch to root WSL2 namespace if ever needed: `MCORE_NO_NS=1 bash`)*

### From Windows PowerShell
```powershell
ping 172.23.180.160   # Debian13 (TTL=64)
ping 172.23.180.161   # UbuntuPro mcore-ns (TTL=63)
```

---

## Detailed Documentation

See **[docs/ARCHITECTURE_AND_VERIFICATION.md](docs/ARCHITECTURE_AND_VERIFICATION.md)** for the full topology diagram, confirmed system behavior, file reference table, and cold-boot verification guide.
