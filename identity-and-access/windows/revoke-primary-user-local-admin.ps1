# Problem solved : Remove local admin from device owners to enforce least privilege.
# What it does    : Identifies the primary user and removes them from local Administrators.
# Requires        : Local administrator (SYSTEM)
# Effect          : changes-state (review and test before use)
# Known issues    : Unused onboarding Object ID placeholder; membership test compares names to net localgroup output (may skip removal).
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

## Parameters
$onboardingAccountObjectId = "ENTRE_AQUI_COM_SEU_ID" # service.intune@


## Main
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
        break
    } catch {}
}

# Add Primary User to local admin group
if ($primaryUser) {
    Write-Host "Removing user '$($primaryUser.UserId)' from local admin group..."

    # Local admin group
    $group = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $groupname = $group.Translate([System.Security.Principal.NTAccount])
    $groupname = $groupname.tostring().trim("BUILTIN\")

    $primaryUserSid = $primaryUser.NgcKeyName.Split('/')[0]

    # Check if user is already a member of the local admin group
    $localGroup = net localgroup $groupname

    if ($username -in $localgroup) {
        Remove-LocalGroupMember -Group $groupName -Member $primaryUserSid

        if ($?) {
            Write-Output "Removed user '$username' from local admin group!"
            exit 0
        } else {
            Write-Output "Failed to remove user '$username' from local admin group!"
            exit 1
        }
    }
}