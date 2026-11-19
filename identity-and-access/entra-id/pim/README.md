# Entra Pim

Scripts for the **entra-pim** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `check-pim-group-eligible-assignments.ps1` | Nobody knows who is eligible for privileged access via PIM groups. | Lists PIM groups and their eligible assignments with user info to Excel. | Microsoft.Graph, ImportExcel; PrivilegedEligibilitySchedule.Read.AzureADGroup, Directory.Read.All | read-only |  |


# Privileged access (PIM)

Use when designing or reviewing just-in-time privileged access.

| File | Use |
|---|---|
| pim-configuration-template.md | Just-in-time privileged access settings |
