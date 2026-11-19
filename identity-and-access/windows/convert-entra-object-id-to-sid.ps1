# Problem solved : I have an Entra ID user Object ID and need the matching local SID to grant rights on a device.
# What it does    : Converts an Object ID (GUID) into the S-1-12-1-* SID by reading the GUID as four 32-bit integers.
# Requires        : None (pure conversion)
# Effect          : read-only
# Origin          : written from the documented SID format for Entra ID accounts

<#
.SYNOPSIS
Converts an Entra ID Object ID into the S-1-12-1-* SID used on Windows devices.

.PARAMETER ObjectId
The Object ID (GUID) of the Entra ID user or group.

.EXAMPLE
.\convert-entra-object-id-to-sid.ps1 -ObjectId 00000000-0000-0000-0000-000000000000
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [guid]$ObjectId
)

$bytes = $ObjectId.ToByteArray()
$parts = for ($i = 0; $i -lt 16; $i += 4) { [BitConverter]::ToUInt32($bytes, $i) }
"S-1-12-1-" + ($parts -join '-')
