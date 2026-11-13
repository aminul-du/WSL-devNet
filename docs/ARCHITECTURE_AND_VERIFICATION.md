# WSL-devNet: Architecture, Auto-Boot & Verification Guide

Complete technical reference for running **Debian13** (`172.23.180.160`) and **UbuntuPro** (`172.23.180.161`) concurrently on a Windows WSL2 host with full network isolation, automatic namespace entry, and reboot-safe recovery.

---

## 1. Confirmed Network Topology

WSL2 shares one lightweight Linux kernel and primary virtual network adapter (`eth0`) across all installed distributions. By isolating **UbuntuPro** inside a dedicated Linux network namespace (`mcore-ns`), both distributions maintain independent IP addresses and port bindings without conflict.

```text
MCore Windows Host (172.23.176.1)
│
├── Debian13 (WSL2 Root Namespace)
│   └── 172.23.180.160  [Default WSL2 Interface — Unchanged, TTL=64]
│
└── UbuntuPro (Isolated Namespace: mcore-ns)
    └── 172.23.180.161  [Target IP via 10.200.1.0/24 veth Transit, TTL=63]
```

---

## 2. Confirmed System Behavior

* **Automatic Namespace Entry:** Opening `UbuntuPro` from Windows Terminal—even immediately after a PC reboot—automatically enters `mcore-ns` and lands directly on **`172.23.180.161/32`** (`veth1`).
* **Self-Healing Startup:** If `UbuntuPro` is opened before the 15-second Windows Task Scheduler delay completes, `~/.bashrc` automatically triggers `/usr/local/bin/mcore-fix.sh` before entering the namespace.
* **Transparent Tooling:** Because the interactive shell already runs inside `mcore-ns`, commands like `git`, `curl`, `ssh`, and application servers bind directly to `172.23.180.161` without requiring manual `mcore-ns` prefixes.
* **Complete Dual-Distro Separation:** `Debian13` remains completely unaffected on `172.23.180.160`.

---

## 3. Repository File Reference

| File | System Location | Role |
| :--- | :--- | :--- |
| **`mcore-fix.sh`** | `/usr/local/bin/mcore-fix.sh` | Detects `eth0`, calculates `WSL_IP + 1` (`172.23.180.161`), builds `mcore-ns` and `veth0`/`veth1`, sets DNS, applies scoped `MASQUERADE` NAT, and runs `mcore-services.sh`. |
| **`mcore-services.sh`** | `/usr/local/bin/mcore-services.sh` | Service hook executed inside `mcore-ns` on initialization to launch background services (e.g., Rust engine, EduVerse app). |
| **`enable-auto-ns-shell.sh`** | Run once in `UbuntuPro` | Configures `/root/.bashrc` and `~/.bashrc` to auto-enter `mcore-ns` on interactive shell startup with loop protection and `MCORE_NO_NS=1` escape hatch. |
| **`MCORE-AutoBoot.ps1`** | `C:\Scripts\MCORE-AutoBoot.ps1` | Initializes `mcore-ns` on Windows boot, maps the Windows `/32` host route (`TARGET_IP` → `WSL_IP`), and configures LAN `portproxy` and firewall rules. |
| **`Install-MCORE-Task.ps1`** | Run once in Admin PowerShell | Registers `MCORE-AutoBoot.ps1` in **Windows Task Scheduler** with Highest Privileges at user logon (silent startup, no UAC prompt). |

---

## 4. Verification & Troubleshooting Commands

### Inside `UbuntuPro` (Auto-Entered `mcore-ns`)
```bash
# Confirm veth1 holds 172.23.180.161/32
ip a

# Print active isolated target IP
mcore-ip

# Test outbound internet & DNS through 172.23.180.161
curl -I https://github.com

# Escape hatch: open a shell in the root WSL2 namespace (172.23.180.160)
MCORE_NO_NS=1 bash
```

### From Windows PowerShell
```powershell
# Verify both distributions respond independently
ping 172.23.180.160   # Debian13 (TTL=64)
ping 172.23.180.161   # UbuntuPro mcore-ns (TTL=63)

# Simulate a full cold-boot recovery test
wsl --shutdown
Start-ScheduledTask -TaskName "MCORE-AutoBoot"
Start-Sleep -Seconds 20
ping -n 2 172.23.180.161
```
