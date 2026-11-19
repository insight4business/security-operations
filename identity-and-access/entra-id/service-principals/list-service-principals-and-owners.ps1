# Problem solved : Enterprise apps/service principals have no known owner or credentials expiry.
# What it does    : Exports service principals with owners and credential info.
# Requires        : Microsoft.Graph.Applications; Application.Read.All
# Effect          : read-only
# Known issues    : Unused $subscriptionId placeholder
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

$subscriptionId = "ENTRE_AQUI_COM_SEU_ID"

Connect-MgGraph

## MAIN
$propertiesToReturn = @(
    "Id", 
    "AccountEnabled",
    "AdditionalProperties",
    "AppDisplayName",
    "AppDescription",
    "AppOwnerOrganizationId",
    "AppId",
    "Description",
    "DisplayName",
    "PreferredSingleSignOnMode",
    "SignInAudience"
)

$servicePrincipals = Get-MgServicePrincipal -All -Property $propertiesToReturn
$servicePrincipals = $servicePrincipals | Sort-Object DisplayName

Write-Host "Total service principals: $($servicePrincipals.Count)"

# Treat fields
foreach ($sp in $servicePrincipals) {
    Write-Progress -Id 1 -Activity "Processing service principals" -Status "[$($servicePrincipals.IndexOf($sp) + 1) / $($servicePrincipals.Count)] Processing service principal $($sp.DisplayName)" -PercentComplete (($servicePrincipals.IndexOf($sp) + 1) / $servicePrincipals.Count * 100)

    $owners = [array](Get-MgServicePrincipalOwner -ServicePrincipalId $sp.Id -All)

    $ownerList = @()
    foreach ($o in $owners) {
        $ownerList += $o.Id
    }
    $sp | Add-Member -MemberType NoteProperty -Name "Owners" -Value ($ownerList -join ',') -Force

    if ($null -ne $sp.AdditionalProperties['createdDateTime']) {
        $sp | Add-Member -MemberType NoteProperty -Name "CreatedDateTime" -Value $sp.AdditionalProperties['createdDateTime'] -Force
    } else {
        $sp | Add-Member -MemberType NoteProperty -Name "CreatedDateTime" -Value '' -Force
    }
}
Write-Progress -Id 1 -Activity "Processing service principals" -Completed

$propertiesToReturn += ("CreatedDateTime", "Owners")
$propertiesToReturn = $propertiesToReturn | Where-Object {$_ -notin ("AdditionalProperties")}

# Export Groups
$servicePrincipals | Select-Object $propertiesToReturn | Export-Excel
