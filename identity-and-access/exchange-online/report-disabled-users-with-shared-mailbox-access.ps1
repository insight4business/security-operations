# Problem solved : Disabled accounts still hold permissions on shared mailboxes.
# What it does    : Lists permissions on shared mailboxes and flags whether each trustee account is enabled.
# Requires        : ExchangeOnlineManagement module; Exchange Administrator; AzureAD module (retired)
# Effect          : read-only
# Known issues    : Uses the retired AzureAD module; rewrite with Microsoft Graph.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module ExchangeOnlineManagement
# Install-Module Azure
Import-Module ExchangeOnlineManagement
Import-Module AzureAD

# Change it to your own administrator account
$connectAs = "ENTRE_AQUI_COM_SEU_EMAIL@example.com"

Connect-ExchangeOnline -UserPrincipalName $connectAs
Connect-AzureAD -AccountId $connectAs

## MAIN
$mailboxes = Get-EXOMailbox

$permissionList = @()
foreach ($mailbox in ($mailboxes | Where-Object {$_.RecipientTypeDetails -eq 'SharedMailbox'})) {
    $permissions = Get-EXOMailboxPermission -Identity $mailbox.Identity

    foreach ($permission in ($permissions | Where-Object {$_.User -ne 'NT AUTHORITY\SELF'})) {
        $user = Get-AzureADUser -ObjectId $permission.User
        
        $permissionList += [PSCustomObject]@{
            Mailbox = $mailbox.UserPrincipalName
            MailboxType = $mailbox.RecipientTypeDetails
            User = $permission.User
            AccessRights = $permission.AccessRights
            UserIsEnabled = $user.AccountEnabled
        }
    }
}

$permissionList | Where-Object {$_.UserIsEnabled -eq $false} | Format-Table
