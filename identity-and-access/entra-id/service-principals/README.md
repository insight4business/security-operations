# Entra Service Principals

Scripts for the **entra-service-principals** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `grant-app-role-to-managed-identity.ps1` | Managed identities need API app roles granted. | Assigns an app role (e.g. Exchange.ManageAsApp) to a service principal via Graph. | Microsoft.Graph; AppRoleAssignment.ReadWrite.All | changes-state | Live call, placeholders for role/resource IDs |
| `grant-entra-role-to-managed-identity.ps1` | Automation identities need Entra roles granted in a controlled way. | Assigns an Entra directory role (e.g. Exchange Administrator) to a managed identity. | Microsoft.Graph; RoleManagement.ReadWrite.Directory | changes-state | Assignment line commented; ID placeholder; privileged operation, require approval |
| `grant-exchange-manage-as-app-to-managed-identity.ps1` | Runbooks cannot manage Exchange Online unattended. | Grants Exchange.ManageAsApp app role and Exchange Administrator role to a managed identity. | Az.Accounts, Microsoft.Graph; AppRoleAssignment.ReadWrite.All, RoleManagement.ReadWrite.Directory | changes-state | Uses deprecated Select-MgProfile beta; mutation lines commented; IDs placeholders |
| `grant-graph-api-permissions-to-managed-identity.ps1` | Managed identities need Graph permissions that the portal cannot assign. | Assigns listed Microsoft Graph app roles to a managed identity. | AzureAD; Global/Privileged Role Admin | changes-state | deprecated AzureAD module (retired); port to Microsoft.Graph; live call (not commented); permissions list incl. PIM read scopes |
| `list-service-principals-and-owners.ps1` | Enterprise apps/service principals have no known owner or credentials expiry. | Exports service principals with owners and credential info. | Microsoft.Graph.Applications; Application.Read.All | read-only | Unused $subscriptionId placeholder |
