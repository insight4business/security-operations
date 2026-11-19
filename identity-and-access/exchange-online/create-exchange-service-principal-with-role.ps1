# Problem solved : An application needs Exchange Online rights and we want them least-privilege.
# What it does    : Registers the Entra app as an Exchange service principal and assigns the View-Only Recipients management role.
# Requires        : ExchangeOnlineManagement module; Exchange Administrator; app and object IDs
# Effect          : changes-state (review and test before use)
# Known issues    : AppId/ObjectId/resource name placeholders; includes unused Get-ServicePrincipal and Get-ManagementRole calls.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

### Create Exchange service principals linked to Azure AD service principals
### Assign roles to this service principal
###
# ExchangeOnlineManagement

Connect-ExchangeOnline

## MAIN
# Create a new service principal in Exchange Online
# New-ServicePrincipal -AppId <Client Application ID in AAD> -ObjectId <Service principal object ID in AAD> -DisplayName <name>
New-ServicePrincipal -AppId "ENTRE_AQUI_COM_SEU_ID" -ObjectId "ENTRE_AQUI_COM_SEU_ID" -DisplayName "ENTRE_AQUI_COM_SEU_RECURSO"

$sp = Get-ServicePrincipal


# Get available roles
$rgs = Get-ManagementRole | Sort-Object Name

# Assign Exchange Role
# New-ManagementRoleAssignment [[-Name] <String>] -Role <RoleIdParameter> -App <ObjectID, AppID, or DisplayName> -CustomResourceScope <Management Scope> (or -RecipientAdministrativeUnitScope)
New-ManagementRoleAssignment -Name "Recipients Reader - ENTRE_AQUI_COM_SEU_RECURSO" -Role "View-Only Recipients" -App "ENTRE_AQUI_COM_SEU_ID" # Add Recipients Reader role to ENTRE_AQUI_COM_SEU_RECURSO



# Test permission
Test-ServicePrincipalAuthorization -Identity 'ENTRE_AQUI_COM_SEU_ID' -Resource 'ENTRE_AQUI_COM_SEU_EMAIL@example.com'