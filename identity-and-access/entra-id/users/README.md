# Entra Users

Scripts for the **entra-users** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `get-users-last-signin.ps1` | Inactive accounts stay enabled and unnoticed. | Exports users with last sign-in activity to Excel. | Microsoft.Graph.Beta.Users, ImportExcel; AuditLog.Read.All, Directory.Read.All | read-only | Uses beta endpoint; requires Entra ID P1/P2 |
