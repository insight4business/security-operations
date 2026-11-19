# Problem solved : Teams need standard access on resource groups.
# What it does    : Assigns a set of roles to a set of groups across listed resource groups.
# Requires        : Az.Resources; User Access Administrator
# Effect          : changes-state (review and test before use)
# Known issues    : IDs are placeholders
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

$WarningPreference = 'SilentlyContinue'

# Connect-AzAccount

# PARAMETERS
# Role Definition IDs
$assignRoles = @(
    "ENTRE_AQUI_COM_SEU_ID"
)
# Group object IDs
$assignGroups = @(
    "ENTRE_AQUI_COM_SEU_ID",
    "ENTRE_AQUI_COM_SEU_ID",
    "ENTRE_AQUI_COM_SEU_ID"
)
# Resource Group names
$assignResourceGroups = @(
    "SystemStorage",
    "Sentinel"
)

$subscriptionId = "ENTRE_AQUI_COM_SEU_ID"

$context = Set-AzContext -Subscription $subscriptionId

# Used to check if the group is assigned or not after verifying the resource group
$isRoleAssigned = @()
foreach ($rg in $assignResourceGroups) {
    foreach ($role in $assignRoles) {
        foreach ($group in $assignGroups) {
            $isRoleAssigned += [PSCustomObject]@{
                ResourceGroup = $rg
                RoleID = $role
                ObjectID   = $group
                IsAssigned = $false
            }    
        }
    }
}

foreach ($rg in $assignResourceGroups) {
    # Get resource group to assign Roles to and the Roles already assigned    
    $resourceGroup = Get-AzResourceGroup -Name $rg
    $resourceGroupRoles = Get-AzRoleAssignment -Scope $resourceGroup.ResourceId

    # For each role to assign
    foreach ($role in $assignRoles) {
        $roleDefinition = Get-AzRoleDefinition -Id $role
        foreach ($assignedRole in $resourceGroupRoles) {
            # If the same role is assigned in the resource group
            if ($assignedRole.RoleDefinitionId -eq $role) {
                foreach ($group in $assignGroups) {
                    if ($assignedRole.ObjectId -eq $group) {
                        $isRoleAssigned | Where-Object { ($_.ResourceGroup -eq $rg) -and ($_.RoleID -eq $role) -and ($_.ObjectID -eq $group) } | ForEach-Object { $_.IsAssigned = $true }

                        $groupInformation = Get-AzADGroup -ObjectId $group
                        Write-Host("Role '$($roleDefinition.Name)' ($($role)) already assigned to group '$($groupInformation.DisplayName)' ($($group)) for resource group '$($rg)'")
                    }
                }
            }
        }
    }
}

Write-Host "Current role assigment status in the specified resource groups:"
Write-Host $isRoleAssigned

# Log
$isRoleAssigned | Export-CSV -NoTypeInformation "C:\Temp\CurrentRoleAssignmentStatus.csv"

foreach ($roleToAssign in $isRoleAssigned) {
    $roleDefinition = Get-AzRoleDefinition -Id $roleToAssign.RoleID
    $groupInformation = Get-AzADGroup -ObjectId $roleToAssign.ObjectID
    if ($roleToAssign.IsAssigned -eq $false) {
        Write-Host("Assigning role '$($roleDefinition.Name)' ($($roleToAssign.RoleID)) to group '$($groupInformation.DisplayName)' ($($roleToAssign.ObjectID)) for resource group '$($roleToAssign.ResourceGroup)'")
        # New-AzRoleAssignment -Scope "/subscriptions/$($subscriptionId)/resourceGroups/$($roleToAssign.ResourceGroup)" -ObjectId $roleToAssign.ObjectID -RoleDefinitionId $roleToAssign.RoleID 

    }
}
