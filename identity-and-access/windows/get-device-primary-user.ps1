# Problem solved : I need to know who the primary (Entra-joined) user of this device is.
# What it does    : Reads WorkplaceJoin AADNGC data in user hives and reports the primary user.
# Requires        : Local administrator
# Effect          : read-only
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

# Get profile list
$profileList = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | Where-Object {$_.Name -like "*\S-1-12-1-*"}

$primaryUser = $null
foreach ($profile in $profileList) {
    # Get User SID
    $sid = $profile.Name.Split('\')[-1]
    # Get SID Object
    $sidObj = [Security.Principal.SecurityIdentifier] $sid
    # Get username
    $username = $sidObj.Translate([Security.Principal.NTAccount]).Value
    
    # Convert SID to Azure AD ID
    $text = $sid.Replace('S-1-12-1-', '')
    $array = [UInt32[]]$text.Split('-')
    $bytes = New-Object 'Byte[]' 16
    [Buffer]::BlockCopy($array, 0, $bytes, 0, 16)
    [Guid] $guid = $bytes

    # Try to get workplace join info, if there is none, the user is not the primary user
    try {
        $primaryUser = (Get-ItemProperty (Get-ChildItem "REGISTRY::HKEY_USERS\$sid\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC").PSPath)
        Write-Host "User '$username' is the primary user ($($primaryUser.UserId))"
    } catch {}
}
