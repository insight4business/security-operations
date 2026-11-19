# Problem solved : Shared mailboxes exist with no assigned users and no forwarding (orphaned).
# What it does    : Counts permissioned users per shared mailbox and shows those with zero and no forwarding.
# Requires        : ExchangeOnlineManagement module; Exchange Administrator; AzureAD module (retired)
# Effect          : read-only
# Known issues    : Uses the retired AzureAD module; calls Get-AzureADUser on the mailbox UPN (may fail for shared mailboxes).
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
$mailboxes = Get-Mailbox -ResultSize unlimited | Select-Object DeliverToMailboxAndForward, ExchangeUserAccountControl, ForwardingAddress, ForwardingSmtpAddress, UserPrincipalName, AccountDisabled, DisplayName, HiddenFromAddressListsEnabled, PrimarySmtpAddress, RecipientTypeDetails, Id, WhenChangedUTC, WhenCreatedUTC

$permissionList = @()
foreach ($mailbox in ($mailboxes | Where-Object {$_.RecipientTypeDetails -eq 'SharedMailbox'})) {
    $permissions = Get-EXOMailboxPermission -Identity $mailbox.UserPrincipalName
    $user = Get-AzureADUser -ObjectId $mailbox.UserPrincipalName

    $permissionList += [PSCustomObject]@{
        Mailbox = $mailbox.UserPrincipalName
        # MailboxType = $mailbox.RecipientTypeDetails
        # ForwardingAddress = $mailbox.ForwardingAddress
        ForwardingSmtpAddress = $mailbox.ForwardingSmtpAddress
        DeliverToMailboxAndForward = $mailbox.DeliverToMailboxAndForward
        ExchangeUserAccountControl = $mailbox.ExchangeUserAccountControl
        # AccountDisabled = $mailbox.AccountDisabled
        JobTitle = $user.JobTitle
        Department = $user.Department
        Count = ($permissions | Where-Object {$_.User -ne 'NT AUTHORITY\SELF'}).Count
    }
}

$permissionList | Where-Object {$_.Count -eq 0 -and $_.DeliverToMailboxAndForward -eq $false} | Format-Table
