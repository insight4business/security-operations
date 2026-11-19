# Problem solved : A specific cloud user needs temporary local admin rights on this device.
# What it does    : Searches Entra ID profiles by name fragment, resolves the SID and adds it to the local Administrators group.
# Requires        : Local administrator
# Effect          : changes-state (review and test before use)
# Known issues    : Name fragment match may hit several profiles; privilege grant - log and time-box it.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

## Parameters
param(
    [Parameter(Mandatory)]
    [string]$searchFor
)
# $searchFor = "valter"

## Main
# Get profile list
$profileList = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | Where-Object {$_.Name -like "*\S-1-12-1-*"}

foreach ($profile in $profileList) {
    if ((Get-ItemProperty -Path $profile.PSPath | Select-Object -Property ProfileImagePath).ProfileImagePath -like "*$searchFor*") {
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

        $sidToAdd = (Get-ItemProperty -Path $profile.PSPath | Select-Object -Property PSChildName).PSChildName

        # Add User to local admin group
        # Local admin group
        $group = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
        $groupname = $group.Translate([System.Security.Principal.NTAccount])
        $groupname = $groupname.tostring().trim("BUILTIN\")

        # Check if user is already a member of the local admin group
        $localGroup = net localgroup $groupname

        if ($username -notin $localgroup) {
            Add-LocalGroupMember -Group $groupName -Member $sidToAdd
            if ($?) {
                Write-Output "Added user '$username' to local admin group!"
            } else {
                Write-Output "Failed to add user '$username' to local admin group!"
            }
        }
    }
}
