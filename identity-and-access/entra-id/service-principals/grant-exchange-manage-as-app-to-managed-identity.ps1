# Problem solved : Runbooks cannot manage Exchange Online unattended.
# What it does    : Grants Exchange.ManageAsApp app role and Exchange Administrator role to a managed identity.
# Requires        : Az.Accounts, Microsoft.Graph; AppRoleAssignment.ReadWrite.All, RoleManagement.ReadWrite.Directory
# Effect          : changes-state (review and test before use)
# Known issues    : Uses deprecated Select-MgProfile beta; mutation lines commented; IDs placeholders
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Import-Module Az.Accounts
# Import-Module Microsoft.Graph
# Import-Module Microsoft.Graph.Identity.Governance
# Import-Module Microsoft.Graph.Applications

$subscriptionId = "ENTRE_AQUI_COM_SEU_ID"

Connect-AzAccount -Subscription $subscriptionId | Out-Null
Connect-MgGraph -Scopes AppRoleAssignment.ReadWrite.All,Application.Read.All

Select-MgProfile 'beta'

$MI_ID = (Get-AzADServicePrincipal -DisplayName "ENTRE_AQUI_COM_SEU_RECURSO").Id

$AppRoleID = "ENTRE_AQUI_COM_SEU_ID" # Exchange.ManageAsApp

$ResourceID = (Get-MgServicePrincipal -Filter "AppId eq 'ENTRE_AQUI_COM_SEU_ID'").Id # Office 365 Exchange Online

# New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $MI_ID -PrincipalId $MI_ID -AppRoleId $AppRoleID -ResourceId $ResourceID

#Add Service Principal to Exchange Administrator
$roleId = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Exchange Recipient Administrator'").id

# New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $MI_ID -RoleDefinitionId $roleId -DirectoryScopeId "/"