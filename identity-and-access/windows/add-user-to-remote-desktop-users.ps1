# Problem solved : A cloud user needs RDP access to a device.
# What it does    : Converts the Object ID to a SID and adds it to Remote Desktop Users.
# Requires        : Local administrator
# Effect          : changes-state (review and test before use)
# Known issues    : Default param is a placeholder (ENTRE_AQUI_COM_SEU_ID); grants remote access.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

## Parameters
param (
  [String]$accountObjectId='ENTRE_AQUI_COM_SEU_ID'
)

## Main
# Get profile list
$profileList = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | Where-Object {$_.Name -like "*\S-1-12-1-*"}

# Remote Desktop Users group
$group = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-555") # Remote Desktop Users
$groupname = $group.Translate([System.Security.Principal.NTAccount])
$groupname = $groupname.tostring().trim("BUILTIN\")

# Check if user is already a member of the Remote Desktop Users group
$localGroup = net localgroup $groupname

$bytes = [Guid]::Parse($accountObjectId).ToByteArray()
$array = New-Object 'UInt32[]' 4

[Buffer]::BlockCopy($bytes, 0, $array, 0, 16)
$accountSid = "S-1-12-1-$array".Replace(' ', '-')

Add-LocalGroupMember -Group $groupName -Member $accountSid
if ($?) {
    Write-Output "Added user '$accountObjectId' to Remote Desktop Users group!"
} else {
    Write-Output "Failed to add user '$accountObjectId' to Remote Desktop Users group!"
    exit 1
}
