# Problem solved : I need to know who really has access to Azure through groups.
# What it does    : Combines Entra groups, members and Azure role assignments into a report.
# Requires        : Az, Microsoft.Graph; Reader + Directory read
# Effect          : read-only
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module Microsoft.Graph
# Install-Module Az
# Import-Module Microsoft.Graph
# Import-Module Az

$subscriptionId = "ENTRE_AQUI_COM_SEU_ID"

# Log in first with Connect-AzAccount if not using Cloud Shell
Connect-AzAccount -Subscription $subscriptionId
Connect-MgGraph

## MAIN
#
$propertiesToReturn = [PSCustomObject]@{
    Groups = @( "Id", "DisplayName", "Description", "CreatedDateTime", "DeletedDateTime", "SecurityEnabled", "MailEnabled", "GroupTypes", "Visibility" )
    Users = @( "Id", "DisplayName", "UserPrincipalName", "AccountEnabled", "JobTitle", "Department", "CompanyName", "Country", "UserType", "CreatedDateTime", "DeletedDateTime")
    Devices = @( "Id", "DisplayName", "DeviceId", "AccountEnabled", "IsCompliant", "IsManaged", "ProfileType", "TrustType", "AdditionalProperties")
    ServicePrincipals = @( "Id", "AppId", "DisplayName", "AccountEnabled", "ServicePrincipalType", "AdditionalProperties")
    RoleDefinition = @("Id", "Name", "Description", "IsCustom")
    RoleAssignment = @("RoleAssignmentName", "Scope", "RoleDefinitionId", "RoleDefinitionName", "ObjectId", "ObjectType")
}


##
# USERS
$users = Get-MgUser -All -Property $propertiesToReturn.Users | Sort-Object DisplayName | Select-Object $propertiesToReturn.Users
$users | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "MemberType" -Value "User" }
foreach ($u in $users) {
    Write-Progress -Id 1 -Activity "Processing users..." -Status "[$($users.IndexOf($u) + 1) / $($users.Count)] Processing user $($u.DisplayName)" -PercentComplete (($users.IndexOf($u) + 1) / $users.Count * 100)
    
    # Get user manager
    try { $managerId = (Get-MgUserManager -UserId $u.Id -ErrorAction SilentlyContinue).Id }
    catch { $managerId = $null }
    
    if ($null -ne $managerId) {
        $manager = $users | Where-Object { $_.Id -eq $managerId } | Select-Object Id, DisplayName, UserPrincipalName
        $u | Add-Member -MemberType NoteProperty -Name "ManagerId" -Value $manager.Id
        $u | Add-Member -MemberType NoteProperty -Name "ManagerDisplayName" -Value $manager.DisplayName
        $u | Add-Member -MemberType NoteProperty -Name "ManagerUPN" -Value $manager.UserPrincipalName
    } else {
        $u | Add-Member -MemberType NoteProperty -Name "ManagerId" -Value $null
        $u | Add-Member -MemberType NoteProperty -Name "ManagerDisplayName" -Value $null
        $u | Add-Member -MemberType NoteProperty -Name "ManagerUPN" -Value $null
    }
}
Write-Progress -Id 1 -Activity "Processing users..." -Completed

# DEVICES
$devices = Get-MgDevice -All -Property $propertiesToReturn.Devices | Sort-Object DisplayName | Select-Object $propertiesToReturn.Devices
$devices | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "MemberType" -Value "Device" }

# SERVICE PRINCIPALS
$servicePrincipals = Get-MgServicePrincipal -All -Property $propertiesToReturn.ServicePrincipals | Sort-Object DisplayName | Select-Object $propertiesToReturn.ServicePrincipals
$servicePrincipals | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "MemberType" -Value "ServicePrincipal" }

# ROLES
$roles = Get-AzRoleDefinition | Sort-Object Name | Select-Object $propertiesToReturn.RoleDefinition
$roleAssignments = Get-AzRoleAssignment | Sort-Object RoleDefinitionName | Select-Object $propertiesToReturn.RoleAssignment

$rolesReport = [System.Collections.Generic.List[Object]]::new() # Create output file
foreach ($role in $roles) {
    $assignments = $roleAssignments | Where-Object { $_.RoleDefinitionId -eq $role.Id }

    if ($assignments) {
        foreach ($assignment in $assignments) {
            # Fix Scope
            $scope = $null
            $scope = $assignment.Scope.Split('/') | Where-Object { $_ -ne "" }

            $scopeObject = [PSCustomObject]@{
                ManagementGroup = $null
                Subscription = $null
                ResourceGroup = $null
                ResourceType = $null
                Resource = $null
            }

            foreach ($s in $scope) {
                if (($scope.IndexOf($s) % 2) -eq 0) {
                    switch ($s) {
                        "providers" { $scopeObject.ResourceType = $scope[($scope.IndexOf($s) +1)] }
                        "resourceGroups" { $scopeObject.ResourceGroup = $scope[($scope.IndexOf($s) +1)] }
                        "subscriptions" { $scopeObject.Subscription = $scope[($scope.IndexOf($s) +1)] }
                        "managementGroups" { $scopeObject.ManagementGroup = $scope[($scope.IndexOf($s) +1)] }
                        Default { $scopeObject.Resource = $scope[($scope.IndexOf($s)-1) .. ($scope.Length -1)] -join '/' }
                    }
                }
            }

            if ($null -ne $scopeObject.ResourceType -and $null -ne $scopeObject.Resource) {
                $scopeObject.Resource = ($scopeObject.Resource).Replace("$($scopeObject.ResourceType)/", "")
            }

            # Add to report
            $rolesReport.Add([PSCustomObject]@{
                RoleDefinitionId = $role.Id
                RoleDefinitionName = $role.Name
                RoleDefinitionDescription = $role.Description
                RoleDefinitionIsCustom = $role.IsCustom
                RoleAssignmentName = $assignment.RoleAssignmentName
                ScopeManagementGroup = $scopeObject.ManagementGroup
                ScopeSubscription = $scopeObject.Subscription
                ScopeResourceGroup = $scopeObject.ResourceGroup
                ScopeResourceType = $scopeObject.ResourceType
                ScopeResource = $scopeObject.Resource
                ScopeResourceId = $assignment.Scope
                ObjectId = $assignment.ObjectId
                ObjectType = $assignment.ObjectType
            })
        }
    }
}

##
# GROUPS
$groups = Get-MgGroup -All -Count groupCount -Property $propertiesToReturn.Groups -Sort DisplayName
# Filter wanted groups
$groups = $groups | Where-Object {$_.SecurityEnabled -eq $true} | Select-Object $propertiesToReturn.Groups

$groupMembersReport = [System.Collections.Generic.List[Object]]::new() # Create output file
foreach ($g in $groups) {
    Write-Progress -Id 1 -Activity "Processing groups..." -Status "[$($groups.IndexOf($g) + 1) / $($groups.Count)] Processing group $($g.DisplayName)" -PercentComplete (($groups.IndexOf($g) + 1) / $groups.Count * 100)

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
            
            # User
            $owner = $users | Where-Object { $_.Id -eq $o.Id }
            if ($null -eq $owner) {
                # Group
                $owner = $groups | Where-Object { $_.Id -eq $o.Id }
                if ($null -eq $owner) {
                    # Device
                    $owner = $devices | Where-Object { $_.Id -eq $o.Id }
                    if ($null -eq $owner) {
                        # Service Principal
                        $owner = $servicePrincipals | Where-Object { $_.Id -eq $o.Id }
                        if ($null -eq $owner) {
                            # Unidentifed
                            $owner = [PSCustomObject]@{
                                Id = $o.Id
                                DisplayName = $null
                                UserPrincipalName = $null
                                JobTitle = $null
                                Department = $null
                                Company = $null
                                UserType = $null
                                MemberType = "Unknown"
                            }
                        }
                    }
                }
            }

            $groupMembersReport.Add([PSCustomObject]@{
                GroupId = $g.Id
                GroupName = $g.DisplayName
                GroupDescription = $g.Description
                GroupCreatedDateTime = $g.CreatedDateTime
                GroupDeletedDateTime = $g.DeletedDateTime
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
                MemberPermission = "GroupOwner"
            })
        }
    }

    # Members
    $members = Get-MgGroupMember -GroupId $g.Id -All | Select-Object Id, DisplayName, UserPrincipalName, JobTitle, Department, Company, UserType

    if ($members) {
        foreach ($m in $members) {
            $member = $null

            # User
            $member = $users | Where-Object { $_.Id -eq $m.Id }
            if ($null -eq $member) {                
                # Group
                $member = $groups | Where-Object { $_.Id -eq $m.Id }
                if ($null -eq $member) {
                    # Device
                    $member = $devices | Where-Object { $_.Id -eq $m.Id }
                    if ($null -eq $member) {
                        # Service Principal
                        $member = $servicePrincipals | Where-Object { $_.Id -eq $m.Id }
                        if ($null -eq $member) {
                            # Unidentified
                            $member = [PSCustomObject]@{
                                Id = $m.Id
                                DisplayName = $null
                                UserPrincipalName = $null
                                JobTitle = $null
                                Department = $null
                                Company = $null
                                UserType = $null
                                MemberType = "Unknown"
                            }
                        }
                    }
                }
            } 
                
            $groupMembersReport.Add([PSCustomObject]@{
                GroupId = $g.Id
                GroupName = $g.DisplayName
                GroupDescription = $g.Description
                GroupCreatedDateTime = $g.CreatedDateTime
                GroupDeletedDateTime = $g.DeletedDateTime
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
                MemberManager = $member.ManagerUPN
                MemberCompany = $member.CompanyName
                # MemberUserType = $member.UserType
                MemberPermission = "GroupMember"
            })
        }
    }
}
Write-Progress -Id 1 -Activity "Processing groups..." -Completed


##
$outputReport = [System.Collections.Generic.List[Object]]::new() # Create output file
foreach ($group in $groups) {
    Write-Progress -Id 1 -Activity "Processing groups..." -Status "[$($groups.IndexOf($group) + 1) / $($groups.Count)] Processing group $($group.DisplayName)" -PercentComplete (($groups.IndexOf($group) + 1) / $groups.Count * 100)

    $groupRoles, $groupMembers = $null

    $groupRoles = $rolesReport | Where-Object {$_.ObjectId -eq $group.Id} #| Select-Object * -ExcludeProperty ObjectId, ObjectType

    $groupMembers = $groupMembersReport | Where-Object {$_.GroupId -eq $group.Id} #| Select-Object * -ExcludeProperty GroupId, GroupName, GroupDescription, GroupCreatedDateTime, GroupDeletedDateTime, GroupSecurityEnabled, GroupMailEnabled, GroupType, GroupMembership, GroupVisibility

    if ($groupRoles -and $groupMembers) {
        foreach ($role in $groupRoles) {
            foreach ($member in $groupMembers) {
                $outputReport += [PSCustomObject]@{
                    GroupId = $group.Id
                    GroupDisplayName = $group.DisplayName
                    GroupDescription = $group.Description
                    GroupMemberId = $member.MemberId
                    GroupMemberAccountEnabled = $member.MemberAccountEnabled
                    GroupMemberDisplayName = $member.MemberDisplayName
                    GroupMemberUserPrincipalName = $member.MemberUserPrincipalName
                    GroupMemberJobTitle = $member.MemberJobTitle
                    GroupMemberDepartment = $member.MemberDepartment
                    GroupMemberManager = $member.MemberManager
                    GroupMemberPermission = $member.MemberPermission
                    RoleDefinitionId = $role.RoleDefinitionId
                    RoleDefinitionName = $role.RoleDefinitionName
                    RoleDefinitionDescription = $role.RoleDefinitionDescription
                    RoleDefinitionIsCustom = $role.RoleDefinitionIsCustom
                    ScopeManagementGroup = $role.ScopeManagementGroup
                    ScopeSubscription = $role.ScopeSubscription
                    ScopeResourceGroup = $role.ScopeResourceGroup
                    ScopeResourceType = $role.ScopeResourceType
                    ScopeResource = $role.ScopeResource
                    ScopeResourceId = $role.ScopeResourceId
                }
            }
        }
    }
}
Write-Progress -Id 1 -Activity "Processing groups..." -Completed

$outputReport | Export-Excel
