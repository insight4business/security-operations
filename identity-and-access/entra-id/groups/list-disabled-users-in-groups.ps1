# Problem solved : Disabled or departed users remain members of access groups.
# What it does    : Exports group memberships where the member account is disabled, with owners.
# Requires        : Microsoft.Graph, ImportExcel; Group.Read.All, User.Read.All
# Effect          : read-only
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module Microsoft.Graph
# Import-Module Microsoft.Graph

$ErrorActionPreference = "Stop"

#
Connect-MgGraph

## MAIN
$propertiesToReturn = [PSCustomObject]@{
    Users = @( "Id", "DisplayName", "UserPrincipalName", "AccountEnabled", "JobTitle", "Department", "CompanyName", "Country", "UserType", "CreatedDateTime", "DeletedDateTime")
}

# GROUPS
$groups = Get-MgGroup -All -Property $propertiesToReturn.Groups | Sort-Object DisplayName | Select-Object $propertiesToReturn.Groups
$groups | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "MemberType" -Value "Group" }

# USERS
$users = Get-MgUser -All -Property $propertiesToReturn.Users | Sort-Object DisplayName | Select-Object $propertiesToReturn.Users
$users | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "MemberType" -Value "User" }

#
$outputReport = [System.Collections.Generic.List[Object]]::new() # Create output file

foreach ($g in $groups) {
    Write-Progress -Id 1 -Activity "Processing groups..." -Status "[$($groups.IndexOf($g) + 1) / $($groups.Count)] Processing group $($g.DisplayName)" -PercentComplete (($groups.IndexOf($g) + 1) / $groups.Count * 100)

    # Skip dynamic groups
    if ($g.GroupTypes -contains "DynamicMembership") {
        continue
    }

    # Group properties
    $groupType, $groupMembership, $members, $owners = $null
    
    $groupType = switch ($g) {
        { $_.GroupTypes -contains "Unified" } { "Microsoft 365" }
        { $_.GroupTypes -notcontains "Unified" -and $_.MailEnabled -eq $true } { "Mail" }
        Default { "Security" }
    }
    
    $groupMembership = switch ($g) {
        { $_.GroupTypes -contains "DynamicMembership" } { "Dynamic" }
        Default { "Assigned" }
    }

    $g | Add-Member -MemberType NoteProperty -Name "GroupType" -Value $groupType
    $g | Add-Member -MemberType NoteProperty -Name "GroupMembership" -Value $groupMembership

    # Owners
    $owners = Get-MgGroupOwner -GroupId $g.Id -All | Select-Object Id, DisplayName, UserPrincipalName, JobTitle, Department, Company, UserType

    if ($owners) {
        foreach ($o in $owners) {
            $owner = $null
            
            $owner = $users | Where-Object { $_.Id -eq $o.Id }
            if ($null -ne $owner -and $null -eq $owner.MemberType) {
                $owner | Add-Member -MemberType NoteProperty -Name "MemberType" -Value "User"
            }

            $outputReport.Add([PSCustomObject]@{
                GroupId = $g.Id
                GroupName = $g.DisplayName
                GroupDescription = $g.Description
                # GroupCreatedDateTime = $g.CreatedDateTime
                # GroupDeletedDateTime = $g.DeletedDateTime
                GroupSecurityEnabled = $g.SecurityEnabled
                GroupMailEnabled = $g.MailEnabled
                GroupType = $g.GroupType
                GroupMembership = $g.GroupMembership
                GroupVisibility = $g.Visibility
                MemberId = $o.Id
                MemberType = $owner.MemberType
                MemberDisplayName = $owner.DisplayName
                MemberUserPrincipalName = $owner.UserPrincipalName
                MemberJobTitle = $owner.JobTitle
                MemberDepartment = $owner.Department
                MemberCompany = $owner.CompanyName
                #MemberUserType = $owner.UserType
                MemberPermission = "Owner"
            })
        }
    }

    # Members
    $members = Get-MgGroupMember -GroupId $g.Id -All | Select-Object Id, DisplayName, UserPrincipalName, JobTitle, Department, Company, UserType

    if ($members) {
        foreach ($m in $members) {
            $member = $null

            $member = $users | Where-Object { $_.Id -eq $m.Id }
            if ($null -eq $member) {
                $member = $groups | Where-Object { $_.Id -eq $m.Id }
            } 
                
            $outputReport.Add([PSCustomObject]@{
                GroupId = $g.Id
                GroupName = $g.DisplayName
                GroupDescription = $g.Description
                # GroupCreatedDateTime = $g.CreatedDateTime
                # GroupDeletedDateTime = $g.DeletedDateTime
                GroupSecurityEnabled = $g.SecurityEnabled
                GroupMailEnabled = $g.MailEnabled
                GroupType = $g.GroupType
                GroupMembership = $g.GroupMembership
                GroupVisibility = $g.Visibility
                MemberId = $m.Id
                MemberType = $member.MemberType
                MemberAccountEnabled = $member.AccountEnabled
                MemberDisplayName = $member.DisplayName
                MemberUserPrincipalName = $member.UserPrincipalName
                MemberJobTitle = $member.JobTitle
                MemberDepartment = $member.Department
                MemberCompany = $member.CompanyName
                # MemberUserType = $member.UserType
                MemberPermission = "Member"
            })
        }
    }
}
Write-Progress -Id 1 -Activity "Processing groups..." -Completed

$outputReport | Where-Object {$_.MemberAccountEnabled -eq $false} | Export-Excel
