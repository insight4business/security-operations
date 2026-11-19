# Problem solved : I want to review what actions each role grants (custom role review).
# What it does    : Expands Actions/NotActions/DataActions for all roles.
# Requires        : Az.Resources
# Effect          : read-only
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

$subscriptionId = "ENTRE_AQUI_COM_SEU_ID"

## MAIN
# Log in first with Connect-AzAccount if not using Cloud Shell
Connect-AzAccount -Subscription $subscriptionId

#
$propertiesToReturn = [PSCustomObject]@{
    RoleDefinition = @("Id", "Name", "Description", "IsCustom", "Actions", "NotActions", "DataActions", "NotDataActions")
}

# ROLES
$roles = Get-AzRoleDefinition | Sort-Object Name | Select-Object $propertiesToReturn.RoleDefinition

$outputReport = [System.Collections.Generic.List[Object]]::new() # Create output file

foreach ($role in $roles) {
    foreach ($a in $role.Actions) {
        $outputReport.Add([PSCustomObject]@{
            RoleId = $role.Id
            RoleName = $role.Name
            RoleDescription = $role.Description
            IsCustom = $role.IsCustom
            ActionType = "Action"
            Action = $a
        })
    }

    foreach ($na in $role.NotActions) {
        $outputReport.Add([PSCustomObject]@{
            RoleId = $role.Id
            RoleName = $role.Name
            RoleDescription = $role.Description
            IsCustom = $role.IsCustom
            ActionType = "NotAction"
            Action = $na
        })
    }

    foreach ($da in $role.DataActions) {
        $outputReport.Add([PSCustomObject]@{
            RoleId = $role.Id
            RoleName = $role.Name
            RoleDescription = $role.Description
            IsCustom = $role.IsCustom
            ActionType = "DataAction"
            Action = $da
        })
    }

    foreach ($nda in $role.NotDataActions) {
        $outputReport.Add([PSCustomObject]@{
            RoleId = $role.Id
            RoleName = $role.Name
            RoleDescription = $role.Description
            IsCustom = $role.IsCustom
            ActionType = "NotDataAction"
            Action = $nda
        })
    }
}

$outputReport | Export-Excel
