# Problem solved : I need the SID of a cloud user to set local permissions.
# What it does    : Translates an AzureAD\UPN account to a SID.
# Requires        : Local user; device joined to Entra ID
# Effect          : read-only
# Known issues    : Placeholder ENTRE_AQUI_COM_SEU_EMAIL@example.com.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
### Get windows SID for azure ad user:

$userPrincipalName = "ENTRE_AQUI_COM_SEU_EMAIL@example.com"

$User = New-Object System.Security.Principal.NTAccount("azuread", $userPrincipalName)
$SID = $User.Translate([System.Security.Principal.SecurityIdentifier]) 
$SID.Value 