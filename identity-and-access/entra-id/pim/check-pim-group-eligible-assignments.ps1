# Problem solved : Nobody knows who is eligible for privileged access via PIM groups.
# What it does    : Lists PIM groups and their eligible assignments with user info to Excel.
# Requires        : Microsoft.Graph, ImportExcel; PrivilegedEligibilitySchedule.Read.AzureADGroup, Directory.Read.All
# Effect          : read-only
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module Microsoft.Graph
# Install-Module ImportExcel
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Identity.Governance
Import-Module ImportExcel


##
Connect-MgGraph #-Scopes "RoleManagement.ReadWrite.Directory", "Directory.Read.All"


##
$propertiesToReturn = [PSCustomObject]@{
    Users = @( "CreatedDateTime", "DeletedDateTime", "Id", "UserPrincipalName", "DisplayName", "AccountEnabled", "JobTitle", "Department", "CompanyName", "Country", "UserType" )
    Groups = @( "Id", "DisplayName", "Description", "CreatedDateTime", "DeletedDateTime", "SecurityEnabled", "MailEnabled", "GroupTypes", "Visibility" )
}


##
$users = Get-MgUser -All -Property $propertiesToReturn.Users | Sort-Object DisplayName | Select-Object $propertiesToReturn.User

$groups = Get-MgGroup -All -Property $propertiesToReturn.Groups | Sort-Object DisplayName | Select-Object $propertiesToReturn.Groups

$uri = "https://graph.microsoft.com/beta/privilegedAccess/aadGroups/resources"
$pimGroups = (Invoke-MgGraphRequest -Uri $uri -Method Get).value


## Exceptions for groups
$pimGroups = $pimGroups | Where-Object {$_.DisplayName -notlike "ENTRE_AQUI_COM_SEU_GRUPO*"}


##
$report = [System.Collections.Generic.List[Object]]::new()
foreach ($group in $pimGroups) {
    $pimEligibleMembers, $groupInformation = $null
    $pimEligibleMembers = [array](Get-MgIdentityGovernancePrivilegedAccessGroupEligibilitySchedule -Filter "groupId eq '$($group.id)'")

    if ($pimEligibleMembers) {
        Write-Host "Group '$($group.displayName)' has $($pimEligibleMembers.Count) eligible members" -ForegroundColor Green

        $groupInformation = $groups | Where-Object { $_.Id -eq $group.id }

        foreach ($member in $pimEligibleMembers) {    
            $user = $null
            $user = $users | Where-Object { $_.Id -eq $member.PrincipalId }

            Write-Host "User '$($user.UserPrincipalName)' is eligible for group '$($group.displayName)'" -ForegroundColor Yellow

            $report.Add([PSCustomObject]@{
                GroupId = $group.id
                GroupDisplayName = $group.displayName
                GroupDescription = $group.description
                MemberType = "Eligible"
                MemberId = $user.Id
                MemberUserPrincipalName = $user.UserPrincipalName
                MemberDisplayName = $user.DisplayName
                MemberAccountEnabled = $user.AccountEnabled
                MemberJobTitle = $user.JobTitle
                MemberDepartment = $user.Department
                MemberCompanyName = $user.CompanyName
            })
        }
    }
}

$report | Export-Excel
