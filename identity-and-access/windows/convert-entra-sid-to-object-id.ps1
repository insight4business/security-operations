# Problem solved : I see an S-1-12-1-* SID on a device and need the Entra ID user it belongs to.
# What it does    : Function that converts the SID back into the Object ID GUID.
# Requires        : None (pure conversion)
# Effect          : read-only
# Known issues    : Contains a sample SID; third-party author credit (Oliver Kieselbach) - keep attribution/check licence.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

function Convert-AzureAdSidToObjectId {
    <#
    .SYNOPSIS
    Convert a Azure AD SID to Object ID
        
    .DESCRIPTION
    Converts an Azure AD SID to Object ID.
    Author: Oliver Kieselbach (oliverkieselbach.com)
    The script is provided "AS IS" with no warranties.
        
    .PARAMETER ObjectID
    The SID to convert
    #>

    param([String] $Sid)

    $text = $sid.Replace('S-1-12-1-', '')
    $array = [UInt32[]]$text.Split('-')

    $bytes = New-Object 'Byte[]' 16
    [Buffer]::BlockCopy($array, 0, $bytes, 0, 16)
    [Guid]$guid = $bytes

    return $guid
}


$sid = "S-1-12-1-1943430372-1249052806-2496021943-3034400218"
$objectId = Convert-AzureAdSidToObjectId -Sid $sid
Write-Output $objectId

# Output:

# Guid
# ----
# ENTRE_AQUI_COM_SEU_ID