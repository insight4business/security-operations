# Problem solved : Former staff or wrong users can still send as certain mailboxes.
# What it does    : Collects Send As and Send on Behalf for a list of mailboxes and removes them; removal lines commented out (dry run).
# Requires        : ExchangeOnlineManagement module; Exchange Administrator; AzureAD module (retired)
# Effect          : destructive (review and test before use)
# Known issues    : Long list of placeholder e-mails; uses retired AzureAD module; hard-coded C:\Temp\Logs.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module ExchangeOnlineManagement
# Install-Module Azure
Import-Module ExchangeOnlineManagement
Import-Module AzureAD

$path = 'C:\Temp\Logs'

# Change it to your own administrator account
$connectAs = "ENTRE_AQUI_COM_SEU_EMAIL@example.com"

Connect-ExchangeOnline -UserPrincipalName $connectAs
Connect-AzureAD -AccountId $connectAs

$mailboxesToRemove = @(
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com",
    "ENTRE_AQUI_COM_SEU_EMAIL@example.com"
)

## MAIN
$mailboxes = Get-EXOMailbox

$permissionList = @()
# foreach ($mailbox in ($mailboxes | Where-Object {$_.RecipientTypeDetails -eq 'SharedMailbox'})) {
foreach ($mailbox in $mailboxes) {
    Write-Progress -Id 1 -Activity "Processing mailbox permissions" -Status "[$($mailboxes.IndexOf($mailbox) + 1) / $($mailboxes.Count)] Processing mailbox '$($mailbox.UserPrincipalName)'" -PercentComplete (($mailboxes.IndexOf($mailbox) + 1) / $mailboxes.Count * 100)

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
                UserDisplayName = $user.DisplayName
                UserDepartment = $user.Department
                UserJobTitle = $user.JobTitle
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

$permissionList = $permissionList | Where-Object {$_.Mailbox -in $mailboxesToRemove}

# Remove permission from specified mailboxes
foreach ($permission in ($permissionList | Where-Object {$_.Mailbox -in $mailboxesToRemove})) {
    Write-Output "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Removing '$($permission.AccessRights)' permission from '$($permission.UserPrincipalName)' on mailbox '$($permission.Mailbox)'"

    switch ($permission.AccessRights) {
        "SendAs" {
            # Remove-RecipientPermission -Identity $permission.Mailbox -AccessRights $permission.AccessRights -Trustee $permission.User -Confirm:$false
        }
        "SendOnBehalf" {
            # Set-Mailbox -Identity $permission.Mailbox -GrantSendOnBehalfTo @{Remove = $permission.User}
        }
        default {
            Write-Error "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] ERROR: Invalid permission type '$($permission.AccessRights)'"
        }
    }
}