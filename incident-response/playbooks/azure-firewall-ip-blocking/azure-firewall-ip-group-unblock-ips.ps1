# Problem solved : A legitimate IP was blocked and I need to release it.
# What it does    : Automation runbook that removes IPs from the blocked IP Group using managed identity.
# Requires        : Az.Network; Network Contributor
# Effect          : changes-state (review and test before use)
# Known issues    : Hard-coded org resource IDs/names as parameter defaults
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
Import-Module Az.Accounts
Import-Module Az.ManagedServiceIdentity

#
param(
	[parameter(Mandatory=$True)]
	[string[]] $IPAddresses,

	[parameter(Mandatory=$False)]
	[string] $ResourceId = '/subscriptions/ENTRE_AQUI_COM_SEU_ID/resourceGroups/ENTRE_AQUI_COM_SEU_RECURSO/providers/Microsoft.Network/ipGroups/ENTRE_AQUI_COM_SEU_RECURSO'
) 

$SubscriptionId = "ENTRE_AQUI_COM_SEU_ID"
$automationAccount = "ENTRE_AQUI_COM_SEU_RECURSO"
$automationAccountResourceGroup = "ENTRE_AQUI_COM_SEU_RESOURCE_GROUP"

##
if ($IPAddresses) { 
    $startTime = Get-Date
    
    # Ensures you do not inherit an AzContext in your runbook
    Disable-AzContextAutosave -Scope Process | Out-Null
    
    # Connect using a Managed Service Identity
    try {
        $AzureContext = (Connect-AzAccount -Identity).context
        Write-Output $AzureContext
    } catch {
        Write-Output "There is no system-assigned user identity. Aborting."; 
        exit 1
    }
    Write-Output "Connected system-assigned Managed Identity"
    
    # set and store context
    try {
        $AzureContext = Set-AzContext -Subscription $SubscriptionId -DefaultProfile $AzureContext
    } catch {
        Write-Output "Error setting AzureContext"
    }
    
    $ipGroup = Get-AzIpGroup -ResourceId $ResourceId
    # Write-Output "Old IP Group:" 
    # Write-Output $ipGroup
    
    $IPAddresses = [array]($IPAddresses | Select-Object -Unique)
    
    foreach ($IPAddress in $IPAddresses) {
        if (($ipGroup.IpAddresses).contains($IPAddress)) {
            $ipGroup.IpAddresses.Remove($IPAddress) | Out-Null
            Write-Output "IP $IPAddress removed"
        }
    }
    # Write-Output "New IP Group addresses:" 
    # Write-Output $($ipGroup.IpAddresses)
    
    Set-AzIpGroup -IpGroup $ipGroup
    
    Write-Output "`nRemoved $($IPAddresses.Count) IPs from IP Group"
    
    $elapsedTime = (Get-Date) - $startTime
    Write-Output $elapsedTime
    
}

exit 0
