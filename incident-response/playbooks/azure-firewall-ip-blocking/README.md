# Azure Firewall Ip Blocking

Scripts for the **azure-nsg-firewall** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `azure-firewall-block-ips-runbook.ps1` | A Sentinel incident needs immediate IP containment. | Runbook adds IP addresses to the blocked IP Group via managed identity. | Az.Network; Network Contributor | changes-state | Hard-coded org resource IDs as parameter defaults |
| `azure-firewall-ip-group-get-and-set.ps1` | I need to read/modify the blocked IP Group. | Reads an IP Group and (commented) adds an address. | Az.Network | changes-state | Core logic is commented; org resource ID |
| `azure-firewall-ip-group-unblock-ips.ps1` | A legitimate IP was blocked and I need to release it. | Automation runbook that removes IPs from the blocked IP Group using managed identity. | Az.Network; Network Contributor | changes-state | Hard-coded org resource IDs/names as parameter defaults |
| `azure-firewall-read-blocked-ips-runbook.ps1` | What is currently blocked? | Reads IP Group addresses. | Az.Network | read-only | Hard-coded org resource IDs |
