# Problem solved : Disabled accounts remain members/owners of Microsoft 365 groups.
# What it does    : Reads a semicolon CSV (GroupId;GroupName;GroupType;MemberUserPrincipalName) and removes each member (owner first) from Microsoft 365 groups; removal calls partly commented.
# Requires        : ExchangeOnlineManagement module; Exchange Administrator
# Effect          : destructive (review and test before use)
# Known issues    : Hard-coded CSV path with a dated Portuguese file name; the removal lines are commented out (dry-run by default).
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

foreach ($row in ($content | Where-Object {$_.GroupType -in ("Microsoft 365")})) {
    Write-Progress -Id 1 -Activity "Processing" -Status "Processing $($row.GroupName):$($row.MemberUserPrincipalName)" -PercentComplete (($content.IndexOf($row) / $content.Count) * 100)

    Write-Output "Removing '$($row.MemberUserPrincipalName)' from '$($row.GroupName)'"

    # try {
    #     # if user is owner, remove it first
    #     Remove-UnifiedGroupLinks -Identity $row.GroupId -LinkType Owners -Links $row.MemberUserPrincipalName -Confirm:$false -ErrorAction
    # } catch {
    #     # get error information
    #     $ErrorMessage = $_.Exception.Message
    
    #     if ($ErrorMessage -like "*Microsoft.Exchange.Management.Recipient.MinGroupOwnersCriteriaBreachedExcept*") {
    #         Write-Output "ERROR: User is the only owner: $($row.GroupName):$($row.MemberUserPrincipalName)" -ForegroundColor Red
    #     }
    # }
    # Remove-UnifiedGroupLinks -Identity $row.GroupId -LinkType Members -Links $row.MemberUserPrincipalName -Confirm:$false
}
Write-Progress -Id 1 -Activity "Processing" -Status "Completed" -Completed
