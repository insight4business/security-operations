# Entra Roles

Scripts for the **entra-roles** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `assign-entra-roles-from-csv.ps1` | Role assignments are made ad hoc without a reviewed list. | Reads CSV and assigns directory roles to principals (assignment line commented). | Microsoft.Graph.Identity.Governance; RoleManagement.ReadWrite.Directory | changes-state | New-MgRoleManagementDirectoryRoleAssignment commented; path placeholder; prefer PIM eligible assignments |
