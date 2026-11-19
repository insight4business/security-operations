# Problem solved : I see an S-1-12-1-* SID on a device and need the Entra ID user it belongs to.
# What it does    : Converts an S-1-12-1-* SID back into the Object ID (GUID) of the Entra ID account.
# Requires        : None (pure conversion)
# Effect          : read-only
# Origin          : written from the documented SID format for Entra ID accounts

<#
.SYNOPSIS
Converts an S-1-12-1-* SID into the Entra ID Object ID.

.PARAMETER Sid
A SID that starts with S-1-12-1- and has four numeric parts after it.

.EXAMPLE
.\convert-entra-sid-to-object-id.ps1 -Sid S-1-12-1-0-0-0-0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^S-1-12-1-\d+-\d+-\d+-\d+$')]
    [string]$Sid
)

$numbers = $Sid.Substring('S-1-12-1-'.Length).Split('-') | ForEach-Object { [uint32]$_ }
$bytes = New-Object byte[] 16
for ($i = 0; $i -lt 4; $i++) {
    [BitConverter]::GetBytes($numbers[$i]).CopyTo($bytes, $i * 4)
}
([guid]::new($bytes)).Guid
