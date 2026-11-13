# Vertex AI Identity & Parallel CLI Architecture

**Document ID:** `MCORE-VERTEX-ID-002`
**Status:** Active / Production
**Architecture:** Dual-Node Parallel Execution

## 1. Core Identity & Authentication
All local AI operations authenticate via Google Application Default Credentials (ADC) bound to the `mcoreai` user.
- **GCP Project:** `project-12884862-2ba9-4048-b03`
- **Identity Principal:** `aminulcse7@gmail.com`
- **Credential Isolation:** Credentials are locked in `~/.config/gcloud/application_default_credentials.json` with `0600` permissions.

## 2. Dual-Node Parallel CLI Execution
The MCore environment supports running multiple autonomous Vertex AI Gemini CLI agents simultaneously across isolated network namespaces.

| Node / Host OS | Network Namespace | IP Address | Purpose |
|---|---|---|---|
| **Debian 13** | Default `eth0` | `172.23.180.160` | Primary NativeBox, MCP Gateways, System Operations |
| **Ubuntu 24.04** | `mcore-ns` (Isolated) | `172.23.180.161` | Container Parity, Next.js Apps, Research Sandboxing |

### Parallel Safeties
- **Zero Port Collisions:** Each OS maintains an independent localhost loopback.
- **Shared Quota:** Both instances securely map to the same Vertex AI API quota limits.
- **Independent Workspaces:** To prevent Git lock conflicts, the Debian agent governs `/opt/MCoreNativeEngine`, while the Ubuntu agent governs `/srv/mcore/apps`.
