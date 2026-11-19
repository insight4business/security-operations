# Problem solved : I have an Entra ID user Object ID and need the matching local SID to grant rights on a device.
# What it does    : Function that converts an Object ID GUID into the S-1-12-1-* SID.
# Requires        : None (pure conversion)
# Effect          : read-only
# Known issues    : Placeholder ENTRE_AQUI_COM_SEU_ID must be replaced before the demo call runs; third-party author credit (Oliver Kieselbach) - keep attribution/check licence.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

function Convert-AzureAdObjectIdToSid {
    <#
    .SYNOPSIS
    Convert an Azure AD Object ID to SID
    
    .DESCRIPTION
    Converts an Azure AD Object ID to a SID.
    Author: Oliver Kieselbach (oliverkieselbach.com)
    The script is provided "AS IS" with no warranties.
    
    .PARAMETER ObjectID
    The Object ID to convert
    #>

    param([String] $ObjectId)

    $bytes = [Guid]::Parse($ObjectId).ToByteArray()
    $array = New-Object 'UInt32[]' 4

    [Buffer]::BlockCopy($bytes, 0, $array, 0, 16)
    $sid = "S-1-12-1-$array".Replace(' ', '-')

    return $sid
}

$objectId = "ENTRE_AQUI_COM_SEU_ID"
$sid = Convert-AzureAdObjectIdToSid -ObjectId $objectId
Write-Output $sid

# Output:

# S-1-12-1-1943430372-1249052806-2496021943-3034400218