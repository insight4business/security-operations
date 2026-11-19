# Problem solved : Disabled accounts remain members of mail distribution lists.
# What it does    : Reads a semicolon CSV and removes members from GroupType 'Mail' groups; Remove-DistributionGroupMember is commented out so it only logs.
# Requires        : ExchangeOnlineManagement module; Exchange Administrator
# Effect          : destructive (review and test before use)
# Known issues    : Same CSV format as the unified-group script; hard-coded dated CSV path.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module ExchangeOnlineManagement
# Import-Module ExchangeOnlineManagement

$ErrorActionPreference = 'Stop'

#
$path = "~\Temp\20240624 - usuarios desabilitados em grupos.csv"

# CSV Type:
# GroupId;GroupName;GroupType;MemberUserPrincipalName

#
Connect-ExchangeOnline

## MAIN
$content = Get-Content $path | ConvertFrom-Csv -Delimiter ";"

foreach ($row in $content) {
    Write-Progress -Id 1 -Activity "Processing" -Status "Processing $($row.GroupName):$($row.MemberUserPrincipalName)" -PercentComplete (($content.IndexOf($row) / $content.Count) * 100)

    if ($row.GroupType -in ("Mail")) {
        Write-Output "Removing '$($row.MemberUserPrincipalName)' from '$($row.GroupName)'"
        # Remove-DistributionGroupMember -Identity $row.GroupId -Member $row.MemberUserPrincipalName -Confirm:$false
    }
}
Write-Progress -Id 1 -Activity "Processing" -Status "Completed" -Completed
