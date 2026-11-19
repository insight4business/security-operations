# Problem solved : I need an audit of who holds which role across subscriptions.
# What it does    : Lists assignments per role with optional group member expansion.
# Requires        : Az, Microsoft.Graph; Reader
# Effect          : read-only
# Known issues    : Subscription comments with org names
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module Microsoft.Graph
# Install-Module Az
# Import-Module Microsoft.Graph
# Import-Module Az


##
$subscriptions = @(
    "ENTRE_AQUI_COM_SEU_ID" # ENTRE_AQUI_COM_SEU_CLIENTE Corp
    ,"ENTRE_AQUI_COM_SEU_ID" # Azure DevTest
    ,"ENTRE_AQUI_COM_SEU_ID" # Azure CyberSec Labs
    ,"ENTRE_AQUI_COM_SEU_ID" # ChatGPT
)

# Set to $true to get full report, including all members inside the groups
$fullReport = $false


## Graph
## Auth
# Log in first with Connect-AzAccount if not using Cloud Shell
Connect-AzAccount -Subscription $subscriptions[0]
# Login to MgGraph
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


## Azure
if ($fullReport) {
    $groupMembersReport = [System.Collections.Generic.List[Object]]::new() # Create output file
}
$outputReport = [System.Collections.Generic.List[Object]]::new() # Create output file

foreach ($subscriptionId in $subscriptions) {
    Write-Host "Processing subscription '$subscriptionId'" -ForegroundColor Yellow
    Set-AzContext -Subscription $subscriptionId

    # ROLES
    $roles = Get-AzRoleDefinition | Sort-Object Name | Select-Object $propertiesToReturn.RoleDefinition
    $roleAssignments = Get-AzRoleAssignment | Sort-Object RoleDefinitionName | Select-Object $propertiesToReturn.RoleAssignment

    $rolesReport = [System.Collections.Generic.List[Object]]::new() # Create output file
    foreach ($role in $roles) {
        Write-Progress -Id 1 -Activity "Processing roles..." -Status "[$($roles.IndexOf($role) + 1) / $($roles.Count)] Processing role '$($role.Name)'" -PercentComplete (($roles.IndexOf($role) + 1) / $roles.Count * 100)

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
                    FullScope = $assignment.Scope
                    ObjectId = $assignment.ObjectId
                    ObjectType = $assignment.ObjectType
                })
            }
        }
    }
    Write-Progress -Id 1 -Activity "Processing roles..." -Completed

    ##
    # GROUPS
    $groups = Get-MgGroup -All -Count groupCount -Property $propertiesToReturn.Groups -Sort DisplayName
    # Filter wanted groups
    $groups = $groups | Where-Object {$_.SecurityEnabled -eq $true} | Select-Object $propertiesToReturn.Groups

    ##
    function Get-GroupMemberNested($GroupObject, $MemberList, $ADUsers, $ADDevices, $ADServicePrincipals, $ADGroups) {
        $members = Get-MgGroupMember -GroupId $GroupObject.Id
        
        foreach ($member in $members) {
            $current = $null

            if ($member.AdditionalProperties['@odata.type'] -eq "#microsoft.graph.group") {	
                # If member is a group then recursively look at group membership
                # $group = Get-MgGroup -GroupId $member.id
                $group = $ADGroups | Where-Object { $_.Id -eq $member.id }
                $MemberList = Get-GroupMemberNested -GroupObject $group -MemberList $MemberList -ADUsers $ADUsers -ADDevices $ADDevices -ADServicePrincipals $ADServicePrincipals -ADGroups $ADGroups

            } elseif ($member.AdditionalProperties['@odata.type'] -eq "#microsoft.graph.user") {
                $current = $ADUsers | Where-Object { $_.Id -eq $member.id }

                $MemberList += [PSCustomObject]@{
                    GroupId = $GroupObject.Id
                    GroupName = $GroupObject.DisplayName
                    GroupDescription = $GroupObject.Description
                    GroupCreatedDateTime = $GroupObject.CreatedDateTime
                    GroupDeletedDateTime = $GroupObject.DeletedDateTime
                    GroupSecurityEnabled = $GroupObject.SecurityEnabled
                    GroupMailEnabled = $GroupObject.MailEnabled
                    GroupType = $GroupObject.GroupType
                    GroupMembership = $GroupObject.GroupMembership
                    GroupVisibility = $GroupObject.Visibility
                    MemberId = $current.Id
                    MemberType = "User"
                    MemberDisplayName = $current.DisplayName
                    MemberUserPrincipalName = $current.UserPrincipalName
                    MemberJobTitle = $current.JobTitle
                    MemberDepartment = $current.Department
                    MemberCompany = $current.CompanyName
                    MemberPermission = "GroupMember"
                }

            } elseif ($member.AdditionalProperties['@odata.type'] -eq "#microsoft.graph.device") {
                $MemberList += [PSCustomObject]@{
                    GroupId = $GroupObject.Id
                    GroupName = $GroupObject.DisplayName
                    GroupDescription = $GroupObject.Description
                    GroupCreatedDateTime = $GroupObject.CreatedDateTime
                    GroupDeletedDateTime = $GroupObject.DeletedDateTime
                    GroupSecurityEnabled = $GroupObject.SecurityEnabled
                    GroupMailEnabled = $GroupObject.MailEnabled
                    GroupType = $GroupObject.GroupType
                    GroupMembership = $GroupObject.GroupMembership
                    GroupVisibility = $GroupObject.Visibility
                    MemberId = $current.Id
                    MemberType = "Device"
                    MemberDisplayName = $current.DisplayName
                    MemberPermission = "GroupMember"
                }

            }
        }

        return $MemberList
    }


    # Get group members recursively if full report is requested
    if ($fullReport) {
        foreach ($g in $groups) {
            Write-Progress -Id 1 -Activity "Processing groups..." -Status "[$($groups.IndexOf($g) + 1) / $($groups.Count)] Processing group $($g.DisplayName)" -PercentComplete (($groups.IndexOf($g) + 1) / $groups.Count * 100)
        
            $groupMembersReport = Get-GroupMemberNested -GroupObject $g -MemberList $groupMembersReport -ADUsers $users -ADDevices $devices -ADServicePrincipals $servicePrincipals -ADGroups $groups
        }
        Write-Progress -Id 1 -Activity "Processing groups..." -Completed
    }
    

    foreach ($role in ($rolesReport | Where-Object { $_.ObjectType -notin ("Device", "ServicePrincipal", "Unknown")})) {
        Write-Progress -Id 1 -Activity "Processing roles..." -Status "[$($rolesReport.IndexOf($role) + 1) / $($rolesReport.Count)] Processing role '$($role.RoleDefinitionName)'" -PercentComplete (($rolesReport.IndexOf($role) + 1) / $rolesReport.Count * 100)
        $obj = $role

        switch ($role.ObjectType) {
            "User" {
                $user = $users | Where-Object { $_.Id -eq $role.ObjectId }

                $obj = $role

                $obj | Add-Member -MemberType NoteProperty -Force -Name "TargetId" -Value $user.Id
                $obj | Add-Member -MemberType NoteProperty -Force -Name "TargetDisplayName" -Value $user.DisplayName
                $obj | Add-Member -MemberType NoteProperty -Force -Name "TargetUserPrincipalName" -Value $user.UserPrincipalName
                $obj | Add-Member -MemberType NoteProperty -Force -Name "AssignmentType" -Value "Direct"

                $obj = $obj | Select-Object * -ExcludeProperty ObjectId, ObjectType
                $outputReport.Add($obj)
            }
            "Group" {
                if ($fullReport) {
                    $groupMembership = $groupMembersReport | Where-Object { $_.GroupId -eq $role.ObjectId }

                    foreach ($m in $groupMembership) {
                        $user = $users | Where-Object { $_.Id -eq $m.MemberId }
        
                        $obj = $role
        
                        $obj | Add-Member -MemberType NoteProperty -Force -Name "TargetId" -Value $user.Id
                        $obj | Add-Member -MemberType NoteProperty -Force -Name "TargetDisplayName" -Value $user.DisplayName
                        $obj | Add-Member -MemberType NoteProperty -Force -Name "TargetUserPrincipalName" -Value $user.UserPrincipalName
                        $obj | Add-Member -MemberType NoteProperty -Force -Name "AssignmentType" -Value "Group"   
                        
                        $obj = $obj | Select-Object * -ExcludeProperty ObjectId, ObjectType
                        $outputReport.Add($obj)
                    }
                } else {
                    $group = $groups | Where-Object { $_.Id -eq $role.ObjectId }

                    $obj = $role
                    
                    $obj | Add-Member -MemberType NoteProperty -Force -Name "TargetId" -Value $group.Id
                    $obj | Add-Member -MemberType NoteProperty -Force -Name "TargetDisplayName" -Value $group.DisplayName
                    $obj | Add-Member -MemberType NoteProperty -Force -Name "AssignmentType" -Value "Group"

                    $obj = $obj | Select-Object * -ExcludeProperty ObjectId, ObjectType
                    $outputReport.Add($obj)
                }
            }
            Default { continue }
        }
    }
    Write-Progress -Id 1 -Activity "Processing roles..." -Completed
}


$outputReport | Export-Excel

