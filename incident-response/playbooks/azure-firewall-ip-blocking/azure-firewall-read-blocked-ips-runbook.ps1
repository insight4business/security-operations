# Problem solved : What is currently blocked?
# What it does    : Reads IP Group addresses.
# Requires        : Az.Network
# Effect          : read-only
# Known issues    : Hard-coded org resource IDs
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

Import-Module Az.Accounts
Import-Module Az.ManagedServiceIdentity

$subscriptionId = "ENTRE_AQUI_COM_SEU_ID"
$automationAccount = "ENTRE_AQUI_COM_SEU_RECURSO"
$automationAccountResourceGroup = "ENTRE_AQUI_COM_SEU_RESOURCE_GROUP"

$resourceId = '/subscriptions/ENTRE_AQUI_COM_SEU_ID/resourceGroups/ENTRE_AQUI_COM_SEU_RECURSO/providers/Microsoft.Network/ipGroups/ENTRE_AQUI_COM_SEU_RECURSO'

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

##
# Connect using a Managed Service Identity
try {
    $azureContext = (Connect-AzAccount -Identity).context
	# Write-Output $azureContext
} catch {
    # Write-Output "There is no system-assigned user identity. Aborting."; 
    exit 1
}
# Write-Output "Connected system-assigned Managed Identity"

# set and store context
try {
	$azureContext = Set-AzContext -Subscription $subscriptionId -DefaultProfile $azureContext
} catch {
	# Write-Output "Error setting azureContext"
    exit 1
}

$IPGroup = Get-AzIpGroup -ResourceId $resourceId
Write-Output ($IPGroup.IpAddresses | ConvertTo-Json)