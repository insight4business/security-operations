# Problem solved : A Sentinel incident needs immediate IP containment.
# What it does    : Runbook adds IP addresses to the blocked IP Group via managed identity.
# Requires        : Az.Network; Network Contributor
# Effect          : changes-state (review and test before use)
# Known issues    : Hard-coded org resource IDs as parameter defaults
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

param(
	[parameter(Mandatory=$True)]
	[string[]] $IPAddresses,

	[parameter(Mandatory=$False)]
	[string] $ResourceId = '/subscriptions/ENTRE_AQUI_COM_SEU_ID/resourceGroups/ENTRE_AQUI_COM_SEU_RECURSO/providers/Microsoft.Network/ipGroups/ENTRE_AQUI_COM_SEU_RECURSO'
)

Import-Module Az.Accounts
Import-Module Az.ManagedServiceIdentity

$SubscriptionId = "ENTRE_AQUI_COM_SEU_ID"
$automationAccount = "ENTRE_AQUI_COM_SEU_RECURSO"
$automationAccountResourceGroup = "ENTRE_AQUI_COM_SEU_RESOURCE_GROUP"

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
# $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
try {
	$AzureContext = Set-AzContext -Subscription $SubscriptionId -DefaultProfile $AzureContext
	# $AzureContext = Set-AzContext -Tenant $AzureContext.Tenant -DefaultProfile $AzureContext
} catch {
	Write-Output "Error setting AzureContext"
}

# # Connects using the Managed Service Identity of the named user-assigned managed identity
# $identity = Get-AzUserAssignedIdentity -ResourceGroupName "ENTRE_AQUI_COM_SEU_RESOURCE_GROUP" -Name "ENTRE_AQUI_COM_SEU_RECURSO" -DefaultProfile $AzureContext

# Write-Output "Connected user-assigned Managed Identity"

# # validates assignment only, not perms
# if ((Get-AzAutomationAccount -ResourceGroupName $automationAccountResourceGroup `
# 		-Name $automationAccount `
# 		-DefaultProfile $AzureContext).Identity.UserAssignedIdentities.Values.PrincipalId.Contains($identity.PrincipalId))
# 	{
# 	$AzureContext = (Connect-AzAccount -Identity -AccountId $identity.ClientId).context

# 	# set and store context
# 	$AzureContext = Set-AzContext -SubscriptionId $SubscriptionId -DefaultProfile $AzureContext
# 	# $AzureContext = Set-AzContext -Tenant $AzureContext.Tenant -DefaultProfile $AzureContext
# 	}
# else {
# 	Write-Output "Invalid or unassigned user-assigned managed identity"
# 	exit 1
# }

$ipGroup = Get-AzIpGroup -ResourceId $ResourceId
Write-Output "Old IP Group:" 
Write-Output $ipGroup

foreach ($IPAddress in $IPAddresses) {
	if (($ipGroup.IpAddresses).contains($IPAddress)) {
		Write-Output "IP $IPAddress Already Blocked"
	} else {
		$ipGroup.IpAddresses.Add($IPAddress)
	}
}
Write-Output "New IP Group addresses:" 
Write-Output $($ipGroup.IpAddresses)

Set-AzIpGroup -IpGroup $ipGroup

$elapsedTime = (Get-Date) - $startTime
Write-Output $elapsedTime

exit 0