# Problem solved : I need to read/modify the blocked IP Group.
# What it does    : Reads an IP Group and (commented) adds an address.
# Requires        : Az.Network
# Effect          : changes-state (review and test before use)
# Known issues    : Core logic is commented; org resource ID
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

$subscriptionId = "ENTRE_AQUI_COM_SEU_ID"

Connect-AzAccount -SubscriptionId $subscriptionId 

##
$IPGroup = Get-AzIpGroup -ResourceId '/subscriptions/ENTRE_AQUI_COM_SEU_ID/resourceGroups/ENTRE_AQUI_COM_SEU_RECURSO/providers/Microsoft.Network/ipGroups/ENTRE_AQUI_COM_SEU_RECURSO'

Write-Output $IPGroup

# if (($IPGroup.IpAddresses).Contains()) {
#     $IPGroup.IpAddresses.Add("ENTRE_AQUI_COM_SEU_IP/24")
# }





# $result = Set-AzIpGroup -IpGroup $IPGroup
