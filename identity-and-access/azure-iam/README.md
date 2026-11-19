# Azure Iam

Scripts for the **azure-iam** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `azure-iam-assign-roles-from-csv.ps1` | I must grant many role assignments consistently. | Reads CSV and assigns roles per management group/subscription scope. | Az.Resources; User Access Administrator | changes-state | New-AzRoleAssignment line is commented out (dry-run state) |
| `azure-iam-assign-roles-on-specific-resources.ps1` | Grant groups access to specific resources. | Assigns roles to objects on a list of resources. | Az.Resources | changes-state | Commented client group names (ENTRE_AQUI_COM_SEU_GRUPO*) to scrub |
| `azure-iam-assign-roles-to-groups-by-resource-group.ps1` | Teams need standard access on resource groups. | Assigns a set of roles to a set of groups across listed resource groups. | Az.Resources; User Access Administrator | changes-state | IDs are placeholders |
| `azure-iam-full-report-groups-members-roles.ps1` | I need to know who really has access to Azure through groups. | Combines Entra groups, members and Azure role assignments into a report. | Az, Microsoft.Graph; Reader + Directory read | read-only |  |
| `azure-iam-list-role-assignments-by-role-multi-subscription.ps1` | I need an audit of who holds which role across subscriptions. | Lists assignments per role with optional group member expansion. | Az, Microsoft.Graph; Reader | read-only | Subscription comments with org names |
| `azure-iam-permissions-on-web-apps.ps1` | I want to see direct permissions on App Services. | Lists role assignments scoped to each Web App, excluding inherited. | Az.Resources | read-only | Management group ID placeholder in filter |
| `azure-iam-remove-role-assignments-from-csv.ps1` | I must revoke a batch of role assignments. | Reads CSV and removes matching assignments. | Az.Resources; User Access Administrator | destructive | Check that the removal call is enabled |
| `azure-roles-list-definitions-and-permissions.ps1` | I want to review what actions each role grants (custom role review). | Expands Actions/NotActions/DataActions for all roles. | Az.Resources | read-only |  |
