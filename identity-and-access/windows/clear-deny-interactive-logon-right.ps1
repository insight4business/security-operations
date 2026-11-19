# Problem solved : A baseline denies local accounts interactive logon and I must regain access for troubleshooting.
# What it does    : Exports security policy with secedit, clears SeDenyInteractiveLogonRight and re-applies it.
# Requires        : Local administrator
# Effect          : destructive (review and test before use)
# Known issues    : Removes a security restriction; troubleshooting/break-glass use only; Intune may re-apply the policy.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

# $user = "Remote desktop user"
# $account = New-Object System.Security.Principal.NTAccount($user)
# $sid = $account.Translate([System.Security.Principal.SecurityIdentifier])

$tmp = [System.IO.Path]::GetTempFileName()
secedit.exe /export /cfg $tmp
$securityPolicies = Get-Content -Path $tmp

for ($i=0;$i -lt $securityPolicies.Count;$i++) {
    if ($securityPolicies[$i] -match "SeDenyInteractiveLogonRight") {
        # Clear values from the deny interactive logon
        # $securityPolicies[$i] = "SeDenyInteractiveLogonRight = *S-1-5-113"
        $securityPolicies[$i] = "SeDenyInteractiveLogonRight = *S-1-0-0"
        # $securityPolicies[$i] += ",*$($sid.Value)"
    }
}

$securityPolicies | Out-File $tmp
secedit.exe /configure /db secedit.sdb /cfg $tmp /areas USER_RIGHTS

Remove-Item -Path $tmp