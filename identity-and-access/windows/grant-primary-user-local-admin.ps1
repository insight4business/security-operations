# Problem solved : The device owner needs admin rights without handing out a shared account.
# What it does    : Identifies the primary user from the registry and adds them to local Administrators, then removes the onboarding account.
# Requires        : Local administrator (SYSTEM)
# Effect          : changes-state (review and test before use)
# Known issues    : Placeholder ENTRE_AQUI_COM_SEU_ID for onboarding account removal; privilege escalation by design - tie to an approval.
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
    # Local admin group
    $group = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $groupname = $group.Translate([System.Security.Principal.NTAccount])
    $groupname = $groupname.tostring().trim("BUILTIN\")

    $primaryUserSid = $primaryUser.NgcKeyName.Split('/')[0]

    # Check if user is already a member of the local admin group
    $localGroup = net localgroup $groupname

    if ($username -notin $localgroup) {
        Add-LocalGroupMember -Group $groupName -Member $primaryUserSid
        # if ($?) {
        #     Write-Output "Added user '$username' to local admin group!"

        #     # Remove service.intune@ from local admin group
        #     $bytes = [Guid]::Parse($onboardingAccountObjectId).ToByteArray()
        #     $array = New-Object 'UInt32[]' 4
        
        #     [Buffer]::BlockCopy($bytes, 0, $array, 0, 16)
        #     $onboardingAccountSid = "S-1-12-1-$array".Replace(' ', '-')

        #     Remove-LocalGroupMember -Group $groupName -Member $onboardingAccountSid
        #     if ($?) {
        #         Write-Output "Removed service.intune@ from local admin group!"
        #         exit 0
        #     } else {
        #         Write-Output "Failed to remove service.intune@ from local admin group!"
        #         exit 1
        #     }
        # } else {
        #     Write-Output "Failed to add user '$username' to local admin group!"
        #     exit 1
        # }
    }
}
