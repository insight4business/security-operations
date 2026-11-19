# Problem solved : Users who travel or work abroad are blocked by country-based CA and need a controlled, temporary exception.
# What it does    : Takes users, countries and exception type; creates named location, CA policy and exception-group membership.
# Requires        : AzureAD, Az.Accounts (managed identity); Conditional Access Administrator
# Effect          : changes-state (review and test before use)
# Known issues    : deprecated AzureAD module (retired); port to Microsoft.Graph (New-AzureADMSConditionalAccessPolicy); Portuguese comments; derived from vanvfields baseline script; exception group name and email domain client-specific; 'parameters test' draft
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

# https://github.com/vanvfields/Microsoft-365/blob/master/Azure%20AD/Baseline-ConditionalAccessPolicies.ps1

<# INSTRUÇÕES
Necessário realizar a conexão com o Azure AD, através do comando Connect-AzureAD (ou Connect-AzAccount para MacOS)
1. Alterar usuário (utilizando nomenclatura do email)
2. Alterar países permitidos, incluindo o pais de origem e de destino do usuário, separados por vírgula (utilizando sigla ISO). Manter 'US' para os usuários que acessarão recursos através de VMs da Azure.
3. Executar o Script
#>

# Parameters
param (
    [Parameter(Mandatory=$true)]
    [string[]]$userss,
    [Parameter(Mandatory=$true)]
    [string[]]$countries,
    [Parameter(Mandatory=$true)]
    [ValidateSet("Permanent", "Temporary")]
    [string]$exceptionType
)

Import-Module AzureAD
Import-Module Az.Accounts

Connect-AzureAD

# Connect-AzureAD with managed identity
Connect-AzAccount -identity
$context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
$aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken
# Write-Output "Hi I'm $($context.Account.Id)"
Connect-AzureAD -AadAccessToken $aadToken -AccountId $context.Account.Id -TenantId $context.tenant.id


# Usuários para a policy (primeira parte do email)
$allowed_countries = @('BR', 'GB', 'US') + $countries
# Status Policy (Enabled, Disabled, Report-Only)
$state = "Enabled"

# Nomenclatura
$timestamp = (Get-Date -UFormat "%Y-%m-%dT%R:%S")
$policyName = switch ($exceptionType) {
    "Permanent" { "Country Exception CA - $users - $allowed_countries - $timestamp" }
    "Temporary" { "Country Travel Exception CA - $users - $allowed_countries - $timestamp" }
}

# Grupo de exceção para a policy de Conditional Access geral
$exception_group_name = switch ($exceptionType) {
    "Permanent" { "ENTRE_AQUI_COM_SEU_GRUPO" }
    "Temporary" { "ENTRE_AQUI_COM_SEU_GRUPO" }
}
$exception_group = (Get-AzureADGroup -SearchString $exception_group_name).ObjectId


# NAMED LOCATION POLICY -----------------------------------------------------------------------------------
$all_countries = [System.Collections.ArrayList]('AD', 'AE', 'AF', 'AG', 'AI', 'AL', 'AM', 'AO', 'AQ', 'AR', 'AS', 'AT', 'AU', 'AW', 'AX', 'AZ', 'BA', 'BB', 'BD', 'BE', 'BF', 'BG', 'BH', 'BI', 'BJ', 'BL', 'BM', 'BN', 'BO', 'BQ', 'BR', 'BS', 'BT', 'BV', 'BW', 'BY', 'BZ', 'CA', 'CC', 'CD', 'CF', 'CG', 'CH', 'CI', 'CK', 'CL', 'CM', 'CN', 'CO', 'CR', 'CU', 'CV', 'CW', 'CX', 'CY', 'CZ', 'DE', 'DJ', 'DK', 'DM', 'DO', 'DZ', 'EC', 'EE', 'EG', 'EH', 'ER', 'ES', 'ET', 'FI', 'FJ', 'FK', 'FM', 'FO', 'FR', 'GA', 'GB', 'GD', 'GE', 'GF', 'GG', 'GH', 'GI', 'GL', 'GM', 'GN', 'GP', 'GQ', 'GR', 'GS', 'GT', 'GU', 'GW', 'GY', 'HK', 'HM', 'HN', 'HR', 'HT', 'HU', 'ID', 'IE', 'IL', 'IM', 'IN', 'IO', 'IQ', 'IR', 'IS', 'IT', 'JE', 'JM', 'JO', 'JP', 'KE', 'KG', 'KH', 'KI', 'KM', 'KN', 'KP', 'KR', 'KW', 'KY', 'KZ', 'LA', 'LB', 'LC', 'LI', 'LK', 'LR', 'LS', 'LT', 'LU', 'LV', 'LY', 'MA', 'MC', 'MD', 'ME', 'MF', 'MG', 'MH', 'MK', 'ML', 'MM', 'MN', 'MO', 'MP', 'MQ', 'MR', 'MS', 'MT', 'MU', 'MV', 'MW', 'MX', 'MY', 'MZ', 'NA', 'NC', 'NE', 'NF', 'NG', 'NI', 'NL', 'NO', 'NP', 'NR', 'NU', 'NZ', 'OM', 'PA', 'PE', 'PF', 'PG', 'PH', 'PK', 'PL', 'PM', 'PN', 'PR', 'PS', 'PT', 'PW', 'PY', 'QA', 'RE', 'RO', 'RS', 'RU', 'RW', 'SA', 'SB', 'SC', 'SD', 'SE', 'SG', 'SH', 'SI', 'SJ', 'SK', 'SL', 'SM', 'SN', 'SO', 'SR', 'SS', 'ST', 'SV', 'SX', 'SY', 'SZ', 'TC', 'TD', 'TF', 'TG', 'TH', 'TJ', 'TK', 'TL', 'TM', 'TN', 'TO', 'TR', 'TT', 'TV', 'TW', 'TZ', 'UA', 'UG', 'UM', 'US', 'UY', 'UZ', 'VA', 'VC', 'VE', 'VG', 'VI', 'VN', 'VU', 'WF', 'WS', 'YE', 'YT', 'ZA', 'ZM', 'ZW')

# Remove os países especificados da lista de bloqueio
foreach ($c in $allowed_countries) {
    $all_countries.Remove($c)
}

# Criação da Policy de Named Location
try { 
    $result_named_location = New-AzureADMSNamedLocationPolicy `
    -OdataType "#microsoft.graph.countryNamedLocation" `
    -DisplayName $policyName `
    -CountriesAndRegions $all_countries  `
    -IncludeUnknownCountriesAndRegions $false

    Write-Output "SUCCESS: Named location"
} catch {
    Write-Output "### FAILED: Named location ###"
    Write-Output $Error[-1].Exception.Message
    exit 1
}

$named_location_id = $result_named_location.Id

# CONDITIONAL ACCESS POLICY -------------------------------------------------------------------------------
# Conditional Access Conditions
$conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
 
$conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
$conditions.Applications.IncludeApplications = "All"
 
$conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition

$user_ids = [System.Collections.ArrayList]@()

# Gets user IDs and add them to the Policy condition
foreach ($u in $users) {
    $u_id = (Get-AzureADUser -ObjectId "$ENTRE_AQUI_COM_SEU_EMAIL@example.com").ObjectId
    $user_ids.Add($u_id)
    if ($null -eq $conditions.Users.IncludeUsers) { $conditions.Users.IncludeUsers = $u_id } 
    else { $conditions.Users.IncludeUsers.Add($u_id) }
}

$conditions.Platforms = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPlatformCondition
$conditions.Platforms.IncludePlatforms = "All"

$conditions.Locations = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessLocationCondition
$conditions.Locations.IncludeLocations = $named_location_id

$conditions.ClientAppTypes = "All"
 
# Conditional Access Controls
$controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
 
$controls._Operator = "OR"
$controls.BuiltInControls = "block"

# Criação da Policy de Conditional Access
try {
    $result_ca = (New-AzureADMSConditionalAccessPolicy `
    -DisplayName $policyName `
    -State $state `
    -Conditions $conditions `
    -GrantControls $controls)

    Write-Output "SUCCESS: Conditional Access Policy"
} catch {
    Write-Output "### FAILED: Conditional Access Policy ###"
    Write-Output $Error[-1].Exception.Message
    exit 1
}

# Adiciona usuários ao grupo de exceção
if ($result_ca.Id) {
    foreach ($uid in $user_ids) {
        # Tenta adicionar usuários ao grupo
        try {
            Add-AzureADGroupMember -InformationAction Continue -ObjectId $exception_group -RefObjectId $uid
            Write-Output "SUCCESS: User $uid added to the specified group"
        } catch {
            # Se usuário já está no grupo
            if ($Error[-1].Exception.Message -Match "One or more added object references already exist for the following modified properties: 'members'") {
                Write-Output "SUCCESS: User $uid already in the specified group"
            # Outros erros
            } else {
                Write-Output "FAILED: Adding user $uid to group"
                Write-Output $Error[-1]
            }  
        }
    }
}