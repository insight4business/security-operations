# Problem solved : Users belong to two groups that should be mutually exclusive (e.g. policy vs exception).
# What it does    : Lists users that are members of all groups in a given list.
# Requires        : AzureAD
# Effect          : read-only
# Known issues    : Hard-coded client groups (ENTRE_AQUI_COM_SEU_RECURSO*); deprecated AzureAD module (retired); port to Microsoft.Graph
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

$groupsToCheck = @("ENTRE_AQUI_COM_SEU_RECURSO", "ENTRE_AQUI_COM_SEU_RECURSO")
# $groupsToCheck = @("ENTRE_AQUI_COM_SEU_RECURSO", "ENTRE_AQUI_COM_SEU_RECURSO")

## Main
Connect-AzureAD

$azureAdGroups = Get-AzureADGroup -All $true

$groups = @()
foreach ($group in $groupsToCheck) {
    $groupObject = $null

    $groupInfo = [array]($azureAdGroups | Where-Object {$_.DisplayName -eq $group})

    if ($groupInfo.Count -gt 0) {
        foreach ($g in $groupInfo) {
            $groupObject = [PSCustomObject]@{
                ObjectId = $g.ObjectId
                DisplayName = $g.DisplayName
                Members = (Get-AzureADGroupMember -ObjectId $g.ObjectId -All $true)
            }
        }
    }

    $groups += $groupObject
}

$users = @()
foreach ($group in $groups) {
    if ($users.Count -eq 0) {
        # If this is the first group (with members), add all members
        foreach ($member in $group.Members) {
            $users += [PSCustomObject]@{
                UserPrincipalName = $member.UserPrincipalName
                DisplayName = $member.DisplayName
                IsMemberOfAllGroups = $true
            }
        }       
    } else {
        # Check if users are also in the next group, if they are not, set IsMemberOfAllGroups to false
        foreach ($u in ($users | Where-Object {$_.IsMemberOfAllGroups -eq $true})) {
            if ($u.UserPrincipalName -notin $group.Members.UserPrincipalName) {
                $u.IsMemberOfAllGroups = $false
            }
        }
    }
}

# Only users which are member of all groups
$users | Where-Object {$_.IsMemberOfAllGroups -eq $true}