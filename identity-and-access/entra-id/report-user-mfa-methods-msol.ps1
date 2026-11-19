# Problem solved : We cannot tell which users have MFA enabled and with which method.
# What it does    : Uses MSOnline to list member users with MFA state, default method, phone number and aliases, to CSV.
# Requires        : MSOnline (retired); ExchangeOnlineManagement; Global Reader
# Effect          : read-only
# Known issues    : Marked legacy; MSOnline is retired, replace with Graph authentication methods report. Hard-coded C:\Temp output; $sharedMailboxes fetched but only partly used.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

# Connect-MsolService
# Connect-ExchangeOnline

$outputPath = "C:\Temp\OfficeMFAReport.csv"

$sharedMailboxes = Get-EXOMailbox -RecipientType 'SharedMailbox'

Write-Host "Finding Azure Active Directory Accounts..."
$Users = Get-MsolUser -All | Where-Object { $_.UserType -ne "Guest" }
$Report = [System.Collections.Generic.List[Object]]::new() # Create output file
Write-Host "Processing" $Users.Count "accounts..." 
ForEach ($User in $Users) {

    $MFADefaultMethod = ($User.StrongAuthenticationMethods | Where-Object { $_.IsDefault -eq "True" }).MethodType
    $MFAPhoneNumber = $User.StrongAuthenticationUserDetails.PhoneNumber
    $PrimarySMTP = $User.ProxyAddresses | Where-Object { $_ -clike "SMTP*" } | ForEach-Object { $_ -replace "SMTP:", "" }
    $Aliases = $User.ProxyAddresses | Where-Object { $_ -clike "smtp*" } | ForEach-Object { $_ -replace "smtp:", "" }

    If ($User.StrongAuthenticationRequirements) {
        $MFAState = $User.StrongAuthenticationRequirements.State
    }
    Else {
        $MFAState = 'Disabled'
    }

    If ($MFADefaultMethod) {
        Switch ($MFADefaultMethod) {
            "OneWaySMS" { $MFADefaultMethod = "Text code authentication phone" }
            "TwoWayVoiceMobile" { $MFADefaultMethod = "Call authentication phone" }
            "TwoWayVoiceOffice" { $MFADefaultMethod = "Call office phone" }
            "PhoneAppOTP" { $MFADefaultMethod = "Authenticator app or hardware token" }
            "PhoneAppNotification" { $MFADefaultMethod = "Microsoft authenticator app" }
        }
    }
    Else {
        $MFADefaultMethod = "Not enabled"
    }
  
    $ReportLine = [PSCustomObject] @{
        UserPrincipalName = $User.UserPrincipalName
        DisplayName       = $User.DisplayName
        IsEnabled = !$($User.BlockCredential)
        IsLicensed = $User.IsLicensed
        IsSharedMailbox = if ($($User.UserPrincipalName).ToLower() -in $sharedMailboxes.UserPrincipalName) { $true } else { $false }
        MFAState          = $MFAState
        MFADefaultMethod  = $MFADefaultMethod
        MFAPhoneNumber    = $MFAPhoneNumber
        PrimarySMTP       = ($PrimarySMTP -join ',')
        Aliases           = ($Aliases -join ',')
    }
                 
    $Report.Add($ReportLine)
}

Write-Host "Report is in $outputPath"
$Report | Select-Object UserPrincipalName, DisplayName, MFAState, MFADefaultMethod, MFAPhoneNumber, PrimarySMTP, Aliases | Sort-Object UserPrincipalName | Out-GridView
$Report | Sort-Object UserPrincipalName | Export-CSV -Encoding UTF8 -NoTypeInformation $outputPath