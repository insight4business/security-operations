# Problem solved : We cannot tell who has access to which mailboxes.
# What it does    : Reports Full Access, Send As and Send on Behalf permissions per mailbox with trustee details from Entra ID.
# Requires        : ExchangeOnlineManagement module; Exchange Administrator; AzureAD module (retired)
# Effect          : read-only
# Known issues    : Uses the retired AzureAD module; output step not visible in sanitised copy.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module ExchangeOnlineManagement
# Install-Module AzureAD
Import-Module ExchangeOnlineManagement
Import-Module AzureAD

# Change it to your own administrator account
# $connectAs = "ENTRE_AQUI_COM_SEU_EMAIL@example.com"

Connect-ExchangeOnline #-UserPrincipalName $connectAs
Connect-AzureAD #-AccountId $connectAs

## MAIN
$mailboxes = Get-EXOMailbox

$permissionList = @()
# foreach ($mailbox in ($mailboxes | Where-Object {$_.RecipientTypeDetails -eq 'SharedMailbox'})) {
foreach ($mailbox in $mailboxes) {
    Write-Progress -Id 1 -Activity "Processing mailbox permissions" -Status "[$($mailboxes.IndexOf($mailbox) + 1) / $($mailboxes.Count)] Processing mailbox '$($mailbox.UserPrincipalName)'" -PercentComplete (($mailboxes.IndexOf($mailbox) + 1) / $mailboxes.Count * 100)

    # Get read and manage permissions
    $readPermissions = $null
    # $readPermissions = Get-EXOMailboxPermission -Identity $mailbox.Identity
    $readPermissions = Get-MailboxPermission -Identity $mailbox.Identity

    foreach ($permission in ($readPermissions | Where-Object {$_.User -ne 'NT AUTHORITY\SELF'})) {
        $user = Get-AzureADUser -ObjectId $permission.User
        
        $permissionList += [PSCustomObject]@{
            Mailbox = $mailbox.UserPrincipalName
            MailboxType = $mailbox.RecipientTypeDetails
            User = $permission.User
            UserPrincipalName = $user.UserPrincipalName
            AccessRights = $permission.AccessRights[0].ToString()
            UserIsEnabled = $user.AccountEnabled
            UserDisplayName = $user.DisplayName
            UserDepartment = $user.Department
            UserJobTitle = $user.JobTitle
        }
    }
    
    # Get send on behalf permissions
    $sendOnBehalfPermissions = $null
    $sendOnBehalfPermissions = Get-Mailbox -Identity $mailbox.Identity | Select-Object -ExpandProperty GrantSendOnBehalfTo

    foreach ($u in $sendOnBehalfPermissions) {
        try {
            $mb = Get-Mailbox -Identity $u
            $user = Get-AzureADUser -ObjectId $mb.ExternalDirectoryObjectId

            $permissionList += [PSCustomObject]@{
                Mailbox = $mailbox.UserPrincipalName
                MailboxType = $mailbox.RecipientTypeDetails
                User = $u
                UserPrincipalName = $user.UserPrincipalName
                AccessRights = "SendOnBehalf"
                UserIsEnabled = $user.AccountEnabled
                UserDisplayName = $user.DisplayName
                UserDepartment = $user.Department
                UserJobTitle = $user.JobTitle
            }
        } catch {
            $permissionList += [PSCustomObject]@{
                Mailbox = $mailbox.UserPrincipalName
                MailboxType = $mailbox.RecipientTypeDetails
                User = $u
                UserPrincipalName = $null
                AccessRights = "SendOnBehalf"
                UserIsEnabled = $false
                UserDisplayName = $null
                UserDepartment = $null
                UserJobTitle = $null
            }
        }
    }

    # Get send as permissions
    $sendAsPermissions = $null
    $sendAsPermissions = Get-RecipientPermission -Identity $mailbox.Identity

    foreach ($permission in ($sendAsPermissions | Where-Object {$_.Trustee -ne 'NT AUTHORITY\SELF'})) {
        $user = Get-AzureADUser -ObjectId $permission.Trustee
        
        $permissionList += [PSCustomObject]@{
            Mailbox = $mailbox.UserPrincipalName
            MailboxType = $mailbox.RecipientTypeDetails
            User = $permission.Trustee
            UserPrincipalName = $user.UserPrincipalName
            AccessRights = $permission.AccessRights[0].ToString()
            UserIsEnabled = $user.AccountEnabled
            UserDisplayName = $user.DisplayName
            UserDepartment = $user.Department
            UserJobTitle = $user.JobTitle
        }
    }
}
Write-Progress -Id 1 -Activity "Processing mailbox permissions" -Completed

# $permissionList | Format-Table

$permissionList | Export-Excel
