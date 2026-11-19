# Problem solved : Managed identities need Graph permissions that the portal cannot assign.
# What it does    : Assigns listed Microsoft Graph app roles to a managed identity.
# Requires        : AzureAD; Global/Privileged Role Admin
# Effect          : changes-state (review and test before use)
# Known issues    : deprecated AzureAD module (retired); port to Microsoft.Graph; live call (not commented); permissions list incl. PIM read scopes
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
Import-Module AzureAD

##
$managedIdentity = "ENTRE_AQUI_COM_SEU_ID"
$msGraph = "ENTRE_AQUI_COM_SEU_ID"
$permissions = @("Directory.Read.All", "PrivilegedAccess.Read.AzureADGroup", "PrivilegedEligibilitySchedule.Read.AzureADGroup")


## Main
$context = Connect-AzureAD


##
foreach ($permission in $permissions) {
    $graph = Get-AzureADServicePrincipal -Filter "AppId eq '$msGraph'" # Graph
    $permission = $graph.AppRoles | Where-Object Value -eq "$permission"

    New-AzureADServiceAppRoleAssignment `
        -Id $permission.Id `
        -ObjectId $managedIdentity `
        -PrincipalId $managedIdentity `
        -ResourceId $graph.ObjectId
}