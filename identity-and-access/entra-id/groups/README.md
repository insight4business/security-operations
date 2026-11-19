# Entra Groups

Scripts for the **entra-groups** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `find-users-in-multiple-groups.ps1` | Users belong to two groups that should be mutually exclusive (e.g. policy vs exception). | Lists users that are members of all groups in a given list. | AzureAD | read-only | Hard-coded client groups (ENTRE_AQUI_COM_SEU_RECURSO*); deprecated AzureAD module (retired); port to Microsoft.Graph |
| `list-disabled-users-in-groups.ps1` | Disabled or departed users remain members of access groups. | Exports group memberships where the member account is disabled, with owners. | Microsoft.Graph, ImportExcel; Group.Read.All, User.Read.All | read-only |  |
