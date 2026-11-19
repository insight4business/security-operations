# Problem solved : I must grant many role assignments consistently.
# What it does    : Reads CSV and assigns roles per management group/subscription scope.
# Requires        : Az.Resources; User Access Administrator
# Effect          : changes-state (review and test before use)
# Known issues    : New-AzRoleAssignment line is commented out (dry-run state)
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module Az
Import-Module Az.Accounts
Import-Module Az.Resources


##
$path = "ENTRE_AQUI_COM_SEU_CAMINHO"


## Auth
Connect-AzAccount #-Subscription $subscriptionId | Out-Null


## MAIN
$csv = Import-Csv -Path $path -Delimiter ";"

# Assign
foreach ($row in $csv) {
    $currentContext = Get-AzContext

    # Get current row management group or subscription
    $scope, $splitScope = $null
    $splitScope = $row.FulLScope -split "/"

    # If subscription
    if ($splitScope.Contains("subscriptions")) {
        $scope = $splitScope[$splitScope.IndexOf("subscriptions") + 1]
        
        # If not the current subscription, switch
        if ($currentContext.SubscriptionId -ne $scope) {
            Set-AzContext -Subscription $scope
        }
    } elseif ($splitScope.Contains("managementGroups")) {
        $scope = $splitScope[$splitScope.IndexOf("managementGroups") + 1]
    }

    # New-AzRoleAssignment -ObjectId $row.AssignToId -RoleDefinitionId $row.RoleDefinitionId -Scope $row.FullScope

    if ($?) {
        Write-Host "Assigned role '$($row.RoleDefinitionName)' to '$($row.AssignToId)' in '$($row.FullScope)'" -ForegroundColor Green
    }
}
