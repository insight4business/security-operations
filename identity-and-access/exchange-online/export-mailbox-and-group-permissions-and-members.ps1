# Problem solved : We cannot tell who has access to non-user mailboxes or who is in distribution groups.
# What it does    : Exports non-user mailbox permissions and distribution group owners/members into one Excel report.
# Requires        : ExchangeOnlineManagement module; Exchange Administrator; ImportExcel
# Effect          : read-only
# Known issues    : Stray $subscriptionId placeholder.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Import-Module ExchangeOnlineManagement

$subscriptionId = "ENTRE_AQUI_COM_SEU_ID"

# Connect-ExchangeOnline -ManagedIdentity -Organization 'ENTRE_AQUI_COM_SEU_TENANT.onmicrosoft.com' | Out-Null
Connect-ExchangeOnline -Organization 'ENTRE_AQUI_COM_SEU_TENANT.onmicrosoft.com' | Out-Null

## MAIN
## Mailboxes
$propertiesToReturn = @(
    "Guid",
    "Id",
    "UserPrincipalName",
    "DisplayName",
    "EmailAddresses",
    "RecipientType",
    "RecipientTypeDetails",
    "Identity",
    "ExternalDirectoryObjectId",
    "DistinguishedName"
)

$mailboxes = Get-EXOMailbox -ResultSize unlimited -IncludeInactiveMailbox -Properties $propertiesToReturn
$mailboxes = $mailboxes += (Get-ExoMailbox -ResultSize unlimited -SoftDeletedMailbox)

Write-Host "Total mailboxes: $($mailboxes.Count)"

# Filter wanted mailboxes
$mailboxes = $mailboxes | Where-Object {$_.RecipientTypeDetails -ne "UserMailbox"}

# Get permissions for each mailbox
$permissionList = @()
foreach ($m in $mailboxes) {
    Write-Progress -Id 1 -Activity "Processing mailboxes" -Status "[$($mailboxes.IndexOf($m) + 1) / $($mailboxes.Count)] Getting members for '$($m.DisplayName)'" -PercentComplete (($mailboxes.IndexOf($m) + 1) / $mailboxes.Count * 100)

    $permissions = @()
    # $permissions = [array]((Get-EXOMailboxPermission -Identity $m.Guid -ResultSize unlimited) | Where-Object {$_.User -ne 'NT AUTHORITY\SELF'} | Select-Object Identity, User, AccessRights, IsInherited, Deny, InheritanceType)
    $permissions = [array]((Get-MailboxPermission -Identity $m.Guid -ResultSize unlimited) | Where-Object {$_.User -ne 'NT AUTHORITY\SELF'} | Select-Object Identity, User, UserSid, AccessRights, IsInherited, Deny, InheritanceType)
    
    if ($permissions.Count -gt 0) {
        foreach ($p in $permissions) {
            $permissionList += [PSCustomObject]@{
                Guid = $m.Guid
                Type = "Mailbox"
                Permission_Identity = $p.Identity
                Permission_User = $p.User
                Permission_AccessRights = $p.AccessRights -join ','
                Permission_IsInherited = $p.IsInherited
                Permission_Deny = $p.Deny.IsPresent
                Permission_InheritanceType = $p.InheritanceType
                UniqueId = "$($m.Guid)+$($p.UserSid)+$($p.AccessRights -join '')"
            }
        }
    }
}
Write-Progress -Id 1 -Activity "Processing mailboxes" -Completed

$propertiesToReturn = @(
    "Guid",
    "Type",
    "Permission_Identity",
    "Permission_User",
    "Permission_AccessRights",
    "Permission_IsInherited",
    "Permission_Deny",
    "Permission_InheritanceType"
    "UniqueId"
)

# Export Groups
$permissionList = $permissionList | Select-Object $propertiesToReturn


## Distribution Groups
$propertiesToReturn = @(
    "Guid",
    "Id",
    "Description",
    "DisplayName",
    "EmailAddresses",
    "PrimarySmtpAddress",
    "Identity",
    "RecipientType",
    "RecipientTypeDetails"
    "WhenChangedUTC",
    "WhenCreatedUTC",
    "ExternalDirectoryObjectId",
    "DistinguishedName"
)

$distributionGroups = Get-DistributionGroup -ResultSize unlimited -SortBy DisplayName

Write-Host "Total distribution groups: $($distributionGroups.Count)"

# Get permissions for each Distribution Group
$membershipList = @()
foreach ($dg in $distributionGroups) {
    Write-Progress -Id 1 -Activity "Processing distribution groups" -Status "[$($distributionGroups.IndexOf($dg) + 1) / $($distributionGroups.Count)] Getting members for '$($dg.DisplayName)'" -PercentComplete (($distributionGroups.IndexOf($dg) + 1) / $distributionGroups.Count * 100)

    # Owners
    if ($dg.ManagedBy.Count -gt 0) {
        foreach ($o in $dg.ManagedBy) {
            # $mailboxInfo = Get-EXOMailbox -Identity $o
            $mailboxInfo = Get-Mailbox -Identity $o

            $membershipList += [PSCustomObject]@{
                Guid = $dg.Guid
                Type = "DistributionGroup"
                Permission_Guid = $mailboxInfo.Guid
                Permission_Id = $mailboxInfo.Id
                Permission_Identity = $mailboxInfo.Identity
                Permission_DisplayName = $mailboxInfo.DisplayName
                Permission_PrimarySmtpAddress = $mailboxInfo.PrimarySmtpAddress
                Permission_RecipientTypeDetails = $mailboxInfo.RecipientTypeDetails
                Permission_DistinguishedName = $mailboxInfo.DistinguishedName
                Permission_Permission = "Owner"
                UniqueId = "$($dg.Guid)+$($mailboxInfo.Guid)+Owner"
            }
        }
    }

    # Members
    $members = @()
    $members = [array]((Get-DistributionGroupMember -Identity $dg.Guid -ResultSize unlimited) | Select-Object Guid, Id, Identity, DisplayName, PrimarySmtpAddress, RecipientTypeDetails, DistinguishedName)
    
    if ($members.Count -gt 0) {
        foreach ($m in $members) {
            $membershipList += [PSCustomObject]@{
                Guid = $dg.Guid
                Type = "DistributionGroup"
                Permission_Guid = $m.Guid
                Permission_Id = $m.Id
                Permission_Identity = $m.Identity
                Permission_DisplayName = $m.DisplayName
                Permission_PrimarySmtpAddress = $m.PrimarySmtpAddress
                Permission_RecipientTypeDetails = $m.RecipientTypeDetails
                Permission_DistinguishedName = $m.DistinguishedName
                Permission_Permission = "Member"
                UniqueId = "$($dg.Guid)+$($m.Guid)+Member"
            }
        }
    }
}
Write-Progress -Id 1 -Activity "Processing distribution groups" -Completed

$propertiesToReturn = @(
    "Guid",
    "Type",
    "Permission_Guid",
    "Permission_Id",
    "Permission_Identity",
    "Permission_DisplayName",
    "Permission_PrimarySmtpAddress",
    "Permission_RecipientTypeDetails",
    "Permission_DistinguishedName",
    "Permission_Permission",
    "UniqueId"
)

# Export Groups
$membershipList = $membershipList | Select-Object $propertiesToReturn

#

$propertiesToReturn = @(
    "Guid",
    "Type",
    "Permission_Guid",
    "Permission_Id",
    "Permission_Identity",
    "Permission_DisplayName",
    "Permission_PrimarySmtpAddress",
    "Permission_RecipientTypeDetails",
    "Permission_DistinguishedName",
    "Permission_Permission",
    "Permission_User",
    "Permission_AccessRights",
    "Permission_IsInherited",
    "Permission_Deny",
    "Permission_InheritanceType",
    "UniqueId"
)

$fullList = ($permissionList + $membershipList) | Select-Object $propertiesToReturn
$fullList | Export-Excel