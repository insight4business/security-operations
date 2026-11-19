# Problem solved : Disabled accounts still hold Full Access, Send As and Send on Behalf on shared mailboxes.
# What it does    : Finds disabled trustees across shared mailboxes and removes the permissions; removal calls are commented out; designed for managed identity.
# Requires        : ExchangeOnlineManagement module; Exchange Administrator; Microsoft.Graph; managed identity
# Effect          : destructive (review and test before use)
# Known issues    : Removal lines commented out (dry run). Log path C:\Temp\Logs may be referenced.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module ExchangeOnlineManagement
# Install-Module Azure
# Import-Module ExchangeOnlineManagement
# Import-Module AzureAD

# Change it to your own administrator account
# $connectAs = "ENTRE_AQUI_COM_SEU_EMAIL@example.com"

# Connect-ExchangeOnline -UserPrincipalName $connectAs
# Connect-AzAccount
# Connect-MgGraph

Connect-ExchangeOnline -ManagedIdentity -Organization 'ENTRE_AQUI_COM_SEU_TENANT.onmicrosoft.com' | Out-Null

# Connect to Microsoft Graph within Azure Automation (Microsoft Graph PowerShell v1)
Connect-AzAccount -Identity | Out-Null
$token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Connect-MgGraph -AccessToken $token.Token | Out-Null

## MAIN
$mailboxes = Get-EXOMailbox
$users = Get-MgUser -All -Property ID, UserPrincipalName, AccountEnabled, DisplayName, Department, JobTitle

$permissionList = @()

$mailboxesToCheck = $mailboxes | Where-Object {$_.RecipientTypeDetails -eq 'SharedMailbox'}

foreach ($mailbox in $mailboxesToCheck) {
    Write-Progress -Id 1 -Activity "Processing mailboxes..." -Status "[$($mailboxesToCheck.IndexOf($mailbox) + 1)/$($mailboxesToCheck.Count)] Processing mailbox '$($mailbox.UserPrincipalName)'" -PercentComplete (($mailboxesToCheck.IndexOf($mailbox) + 1) / $mailboxesToCheck.Count * 100)

    # Get read and manage permissions
    $readPermissions = $null
    $readPermissions = Get-MailboxPermission -Identity $mailbox.Identity

    foreach ($permission in ($readPermissions | Where-Object {$_.User -ne 'NT AUTHORITY\SELF'})) {
        $user = $users | Where-Object {$_.UserPrincipalName -eq $permission.User}
        
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
            $user = $users | Where-Object {$_.Id -eq $mb.ExternalDirectoryObjectId}

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
        $user = $users | Where-Object {$_.UserPrincipalName -eq $permission.Trustee}
        
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
Write-Progress -Id 1 -Activity "Processing mailboxes..." -Completed

# $permissionList | Where-Object {$_.UserIsEnabled -eq $false} | Format-Table

# Remove permissions
$permissionList = ($permissionList | Where-Object {$_.UserIsEnabled -eq $false})

foreach ($permission in ($permissionList | Where-Object {$_.UserIsEnabled -eq $false})) {
    if ($permission.UserIsEnabled -eq $false) {
        Write-Output "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Removing '$($permission.AccessRights)' permission from '$($permission.UserPrincipalName)' on mailbox '$($permission.Mailbox)'"

        switch ($permission.AccessRights) {
            "FullAccess" {
                # Remove-MailboxPermission -Identity $permission.Mailbox -User $permission.User -AccessRights $permission.AccessRights -Confirm:$false
            }
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
}