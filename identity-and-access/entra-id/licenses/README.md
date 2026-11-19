# Entra Licenses

Scripts for the **entra-licenses** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `get-disabled-users-with-licenses.ps1` | Leavers' accounts are disabled but keep paid licenses and a live footprint. | Lists disabled users with every license they still hold, to Excel. | Microsoft.Graph.Users, ImportExcel; User.Read.All | read-only |  |
