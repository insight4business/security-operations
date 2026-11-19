# Problem solved : I need to add an Entra ID user to the local Administrators group via Intune/RMM.
# What it does    : Converts the Object ID to a SID and calls Add-LocalGroupMember on the Administrators group.
# Requires        : Local administrator
# Effect          : changes-state (review and test before use)
# Known issues    : Default param is empty; group name derived with Trim('BUILTIN\') (character trim, locale fragile).
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

## Parameters
param (
  [String]$accountObjectId=''
)

## Main
# Get profile list
$profileList = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | Where-Object {$_.Name -like "*\S-1-12-1-*"}

# Local admin group
$group = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
$groupname = $group.Translate([System.Security.Principal.NTAccount])
$groupname = $groupname.tostring().trim("BUILTIN\")

# Check if user is already a member of the local admin group
$localGroup = net localgroup $groupname

$bytes = [Guid]::Parse($accountObjectId).ToByteArray()
$array = New-Object 'UInt32[]' 4

[Buffer]::BlockCopy($bytes, 0, $array, 0, 16)
$accountSid = "S-1-12-1-$array".Replace(' ', '-')

Add-LocalGroupMember -Group $groupName -Member $accountSid
if ($?) {
    Write-Output "Added user '$accountObjectId' to local admin group!"
} else {
    Write-Output "Failed to add user '$accountObjectId' to local admin group!"
    exit 1
}
