# Problem solved : Automation identities need Entra roles granted in a controlled way.
# What it does    : Assigns an Entra directory role (e.g. Exchange Administrator) to a managed identity.
# Requires        : Microsoft.Graph; RoleManagement.ReadWrite.Directory
# Effect          : changes-state (review and test before use)
# Known issues    : Assignment line commented; ID placeholder; privileged operation, require approval
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

### Assign permission to service principal
# $MIAppID = 'ENTRE_AQUI_COM_SEU_ID'
$MIAppID = 'ENTRE_AQUI_COM_SEU_ID'

Connect-MgGraph

$roleId = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Exchange Administrator'").id
# New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $MIAppID -RoleDefinitionId $roleId -DirectoryScopeId "/"