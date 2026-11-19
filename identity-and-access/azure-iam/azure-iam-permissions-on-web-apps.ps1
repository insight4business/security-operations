# Problem solved : I want to see direct permissions on App Services.
# What it does    : Lists role assignments scoped to each Web App, excluding inherited.
# Requires        : Az.Resources
# Effect          : read-only
# Known issues    : Management group ID placeholder in filter
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

#
$subscriptionId = "ENTRE_AQUI_COM_SEU_ID"

# az login --subscription $subscriptionId
Connect-AzAccount -Subscription $subscriptionId | Out-Null

## MAIN
$functions = Get-AzResource -ResourceType "Microsoft.Web/sites"

$outputReport = [System.Collections.Generic.List[Object]]::new() # Create output file
foreach ($function in $functions) {
    $iam = Get-AzRoleAssignment -Scope $function.ResourceId
    $iamToCheck = $iam | Where-Object { $_.Scope -ne '/providers/Microsoft.Management/managementGroups/ENTRE_AQUI_COM_SEU_ID' -and $_.Scope -ne '/subscriptions/ENTRE_AQUI_COM_SEU_ID' }
    foreach ($assignment in $iamToCheck) {
        $outputReport.Add($assignment)   
    }
}

$outputReport | Export-Excel