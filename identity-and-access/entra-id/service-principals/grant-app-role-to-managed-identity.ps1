# Problem solved : Managed identities need API app roles granted.
# What it does    : Assigns an app role (e.g. Exchange.ManageAsApp) to a service principal via Graph.
# Requires        : Microsoft.Graph; AppRoleAssignment.ReadWrite.All
# Effect          : changes-state (review and test before use)
# Known issues    : Live call, placeholders for role/resource IDs
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

Connect-MgGraph

$sp = Get-MgServicePrincipal -Filter "DisplayName eq 'ENTRE_AQUI_COM_SEU_RECURSO'"

$resource = (Get-MgServicePrincipal -Filter "AppId eq 'ENTRE_AQUI_COM_SEU_ID'") # Exchange online

$roleId = "ENTRE_AQUI_COM_SEU_ID" # Exchange.ManageAsApp

$params = @{
    ServicePrincipalId = $sp.Id # managed identity object id
    PrincipalId = $sp.Id # managed identity object id
    ResourceId =  $resource.Id # application Id
    AppRoleId = $roleId
}
New-MgServicePrincipalAppRoleAssignedTo @params