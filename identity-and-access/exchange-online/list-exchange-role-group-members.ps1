# Problem solved : We do not know who holds admin roles in Exchange Online.
# What it does    : Lists every Exchange role group, its roles and members and exports to Excel.
# Requires        : ExchangeOnlineManagement module; Exchange Administrator; ImportExcel
# Effect          : read-only
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module ExchangeOnlineManagement
# Install-Module ImportExcel
Import-Module ExchangeOnlineManagement
Import-Module ImportExcel


##
Connect-ExchangeOnline


##
$roles = Get-RoleGroup

$outputReport = [System.Collections.Generic.List[Object]]::new()
foreach ($r in $roles) {
    $members = Get-RoleGroupMember $r

    foreach ($member in $members) {
        $outputReport.Add([PSCustomObject]@{
            RoleGroupType = $r.RoleGroupType
            RoleGroupName = $r.Name
            RoleGroupIdentity = $r.Identity
            RoleId = $r.RoleAssignments.SamAccountName
            Member = $member.DisplayName
            MemberType = $member.RecipientType
            MemberIdentity = $member.Identity
        })
    }
}

$outputReport | Export-Excel
