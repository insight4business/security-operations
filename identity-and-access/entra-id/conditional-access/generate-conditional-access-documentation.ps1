# Problem solved : Nobody can read or document the Conditional Access policy set.
# What it does    : Builds a human-readable Excel/CSV documentation of all CA policies resolving IDs to names.
# Requires        : Microsoft.Graph; Policy.Read.All, Application.Read.All, Group.Read.All, User.Read.All
# Effect          : read-only
# Known issues    : Adapted from third-party nicolonsky/ConditionalAccessDocumentation (check licence/attribution); uses deprecated Select-MgProfile beta; both Windows and macOS $outputPath lines active (second overrides)
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

### https://github.com/nicolonsky/ConditionalAccessDocumentation
###
# Install-Module Microsoft.Graph
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Identity.ConditionalAccess


##
$currentDay = (Get-Date).ToString("yyyy-MM-dd")
$outputPath = "C:\Temp\$currentDay - ConditionalAccessDocumentation" # Windows
$outputPath = "$env:HOME\temp\$currentDay - ConditionalAccessDocumentation" # macOS


## Authentication
Connect-MgGraph -Scopes "Application.Read.All", "Group.Read.All", "Policy.Read.All", "RoleManagement.Read.Directory", "User.Read.All" -ContextScope Process

Select-MgProfile -Name "Beta"

##
function Test-Guid {
    <#
    .SYNOPSIS
    Validates a given input string and checks string is a valid GUID
    .DESCRIPTION
    Validates a given input string and checks string is a valid GUID by using the .NET method Guid.TryParse
    .EXAMPLE
    Test-Guid -InputObject "ENTRE_AQUI_COM_SEU_ID"
    .NOTES
    Uses .NET method [guid]::TryParse()
    #>
    [Cmdletbinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string]$InputObject
    )
    process {
        return [guid]::TryParse($InputObject, $([ref][guid]::Empty))
    }
}

function Resolve-MgObject {
    <#
    .SYNOPSIS
    Resolve a Microsoft Graph item to display name
    .DESCRIPTION
    Resolves a Microsoft Graph Directory Object to a Display Name when possible
    .EXAMPLE
    
    .NOTES
    
    #>
    [Cmdletbinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string]$InputObject
    )
    process {
        if (Test-Guid -InputObject $InputObject) {
            try {
                # use hashtable as cache to limit API calls
                if ($displayNameCache.ContainsKey($InputObject)) {
                    Write-Debug "Cached display name for `"$InputObject`""
                    return $displayNameCache[$InputObject]
                }
                else {
                    $directoryObject = Get-MgDirectoryObject -DirectoryObjectId $InputObject -ErrorAction Stop
                    $displayName = $directoryObject.AdditionalProperties["displayName"]
                    $displayNameCache[$InputObject] = $displayName
                    return $displayName
                }
            }
            catch {
                Write-Warning "Unable to resolve directory object with ID $InputObject, might have been deleted!"
            }
        }
        return $InputObject
    }
}

if (-not $(Get-MgContext)) {
    Throw "Authentication needed, call 'Connect-Graph -Scopes `"Application.Read.All`", `"Group.Read.All`", `"Policy.Read.All`", `"RoleManagement.Read.Directory`", `"User.Read.All`""
}

if ((Get-MgProfile).Name.ToLower() -ne "beta") {
    Write-Warning "You might miss some Conditional Access Policies as you are using the v1.0 Microsoft Graph Endpoint!"
    Write-Warning "You can switch to the beta endpoint with: `"Select-MgProfile -Name `"beta`"`""
}

Write-Progress -PercentComplete -1 -Activity "Fetching conditional access policies and related data from Graph API"

# Get Conditional Access Policies
$conditionalAccessPolicies = Get-MgIdentityConditionalAccessPolicy -ExpandProperty "*" -All -ErrorAction Stop
#Get Conditional Access Named / Trusted Locations
$namedLocations = Get-MgIdentityConditionalAccessNamedLocation -All -ErrorAction Stop | Group-Object -Property Id -AsHashTable
if (-not $namedLocations) { $namedLocations = @{} }
# Get Azure AD Directory Role Templates
$directoryRoleTemplates = Get-MgDirectoryRoleTemplate -All -ErrorAction Stop | Group-Object -Property Id -AsHashTable
# Service Principals
$servicePrincipals = Get-MgServicePrincipal -All -ErrorAction Stop | Group-Object -Property AppId -AsHashTable
# Init report 
$documentation = [System.Collections.Generic.List[Object]]::new()
# Cache for resolved display names
$displayNameCache = @{}

# Process all Conditional Access Policies
foreach ($policy in $conditionalAccessPolicies) {

    # Display some progress (based on policy count)
    $currentIndex = $conditionalAccessPolicies.indexOf($policy) + 1

    $progress = @{
        Activity         = "Generating Conditional Access Documentation..."
        PercentComplete  = [Decimal]::Divide($currentIndex, $conditionalAccessPolicies.Count) * 100
        CurrentOperation = "Processing Policy `"$($policy.DisplayName)`""
    }
    if ($currentIndex -eq $conditionalAccessPolicies.Count) { $progress.Add("Completed", $true) }

    Write-Progress @progress

    Write-Output "Processing policy `"$($policy.DisplayName)`""
    
    try {
        # Resolve object IDs of included users
        $includeUsers = [System.Collections.Generic.List[Object]]::new()
        $policy.Conditions.Users.IncludeUsers | ForEach-Object {
            $includeUsers.Add((Resolve-MgObject -InputObject $PSItem))
        }
        # Resolve object IDs of excluded users
        $excludeUsers = [System.Collections.Generic.List[Object]]::new()
        $policy.Conditions.Users.ExcludeUsers | ForEach-Object {
            $excludeUsers.Add((Resolve-MgObject -InputObject $PSItem))
        }
        # Resolve object IDs of included groups
        $includeGroups = [System.Collections.Generic.List[Object]]::new()
        $policy.Conditions.Users.IncludeGroups | ForEach-Object {
            $includeGroups.Add((Resolve-MgObject -InputObject $PSItem))
        }
        # Resolve object IDs of excluded groups
        $excludeGroups = [System.Collections.Generic.List[Object]]::new()
        $policy.Conditions.Users.ExcludeGroups | ForEach-Object {
            $excludeGroups.Add((Resolve-MgObject -InputObject $PSItem))
        }
        # Resolve object IDs of included roles
        $includeRoles = [System.Collections.Generic.List[Object]]::new()
        $policy.Conditions.Users.IncludeRoles | ForEach-Object {
            if ($directoryRoleTemplates.ContainsKey($PSItem)) {
                $includeRoles.Add(($directoryRoleTemplates[$PSItem].DisplayName))
            }
            else {
                $includeRoles.Add($PSItem)
            }
        }

        # Resolve object IDs of excluded roles
        $excludeRoles = [System.Collections.Generic.List[Object]]::new()
        $policy.Conditions.Users.ExcludeRoles | ForEach-Object {
            if ($directoryRoleTemplates.ContainsKey($PSItem)) {
                $excludeRoles.Add(($directoryRoleTemplates[$PSItem].DisplayName))
            }
            else {
                $excludeRoles.Add($PSItem)
            }
        }
        # Resolve object IDs of included apps
        $includeApps = [System.Collections.Generic.List[Object]]::new()
        $policy.Conditions.Applications.IncludeApplications | ForEach-Object {
            if ($servicePrincipals.ContainsKey($PSItem)) {
                $includeApps.Add(($servicePrincipals[$PSItem].DisplayName))
            }
            else {
                $includeApps.Add($PSItem)
            }
        }
        # Resolve object IDs of excluded apps
        $excludeApps = [System.Collections.Generic.List[Object]]::new()
        $policy.Conditions.Applications.ExcludeApplications | ForEach-Object {
            if ($servicePrincipals.ContainsKey($PSItem)) {
                $excludeApps.Add(($servicePrincipals[$PSItem].DisplayName))
            }
            else {
                $excludeApps.Add($PSItem)
            }
        }

        $includeServicePrincipals = [System.Collections.Generic.List[Object]]::new()
        $excludeServicePrincipals = [System.Collections.Generic.List[Object]]::new()

        $policy.Conditions.ClientApplications.IncludeServicePrincipals | ForEach-Object {
            if ((-not [string]::IsNullOrEmpty($PSItem)) -and $servicePrincipals.ContainsKey($PSItem)) {
                $includeServicePrincipals.Add(($servicePrincipals[$PSItem].DisplayName))
            }
            else {
                $includeServicePrincipals.Add($PSItem)
            }
        }
        $policy.Conditions.ClientApplications.ExcludeServicePrincipals | ForEach-Object {
            if ((-not [string]::IsNullOrEmpty($PSItem)) -and $servicePrincipals.ContainsKey($PSItem)) {
                $excludeServicePrincipals.Add(($servicePrincipals[$PSItem].DisplayName))
            }
            else {
                $excludeServicePrincipals.Add($PSItem)
            }
        }
        
        $includeAuthenticationContext = [System.Collections.Generic.List[Object]]::new()
        $policy.Conditions.Applications.IncludeAuthenticationContextClassReferences | ForEach-Object {
            $context = Get-MgIdentityConditionalAccessAuthenticationContextClassReference -Filter "Id eq '$PSItem'"
            $includeAuthenticationContext.Add($context.DisplayName)
        }

        # Resolve object IDs of included locations
        $includeLocations = [System.Collections.Generic.List[Object]]::new()
        $policy.conditions.Locations.IncludeLocations | ForEach-Object {
            if ($PSItem -and $namedLocations.ContainsKey($PSItem)) {
                $includeLocations.Add($namedLocations[$PSItem].DisplayName)
            }
            else {
                $includeLocations.Add($PSItem)
            }
        }
        # Resolve object IDs of excluded locations
        $excludeLocations = [System.Collections.Generic.List[Object]]::new()
        $policy.conditions.Locations.ExcludeLocations | ForEach-Object {
            if ($PSItem -and $namedLocations.ContainsKey($PSItem)) {
                $excludeLocations.Add(($namedLocations[$PSItem].DisplayName))
            }
            else {
                $excludeLocations.Add($PSItem)
            }
        }

        # delimiter for arrays in csv report
        $separator = ";"
        # when terms of use are present just add a generic hint.
        if ($policy.GrantControls.TermsOfUse) { $policy.GrantControls.BuiltInControls += "termsOfUse" }
        if ($policy.GrantControls.AuthenticationStrength) { $policy.GrantControls.BuiltInControls += "authenticationStrength" }

        # construct entry for report
        $documentation.Add(
            [PSCustomObject]@{
                Name                                      = $policy.DisplayName
                # Conditions
                IncludeUsers                              = $includeUsers -join $separator
                IncludeGroups                             = $includeGroups -join $separator
                IncludeRoles                              = $includeRoles -join $separator

                ExcludeUsers                              = $excludeUsers -join $separator
                ExcludeGuestOrExternalUserTypes           = $policy.Conditions.Users.ExcludeGuestsOrExternalUsers.guestOrExternalUserTypes
                ExcludeGuestOrExternalUserTenants         = $policy.Conditions.Users.ExcludeGuestsOrExternalUsers.externalTenants.AdditionalProperties["members"] -join $separator

                ExcludeGroups                             = $excludeGroups -join $separator
                ExcludeRoles                              = $excludeRoles -join $separator

                IncludeApps                               = $includeApps -join $separator
                ExcludeApps                               = $excludeApps -join $separator

                ApplicationFilterMode                     = $policy.Conditions.Applications.ApplicationFilter.mode
                ApplicationFilterRule                     = $policy.Conditions.Applications.ApplicationFilter.rule

                IncludeAuthenticationContext              = $includeAuthenticationContext -join $separator
                IncludeUserActions                        = $policy.Conditions.Applications.IncludeUserActions -join $separator
                ClientAppTypes                            = $policy.Conditions.ClientAppTypes -join $separator

                IncludePlatforms                          = $policy.Conditions.Platforms.IncludePlatforms -join $separator
                ExcludePlatforms                          = $policy.Conditions.Platforms.ExcludePlatforms -join $separator

                IncludeLocations                          = $includeLocations -join $separator
                ExcludeLocations                          = $excludeLocations -join $separator

                DeviceFilterMode                          = $policy.Conditions.Devices.DeviceFilter.Mode
                DeviceFilterRule                          = $policy.Conditions.Devices.DeviceFilter.Rule

                SignInRiskLevels                          = $policy.Conditions.SignInRiskLevels -join $separator
                UserRiskLevels                            = $policy.Conditions.UserRiskLevels -join $separator
                ServicePrincipalRiskLevels                = $policy.Conditions.servicePrincipalRiskLevels -join $separator
               
                # Workload Identity Protection
                IncludeServicePrincipals                  = $includeServicePrincipals -join $separator
                ExcludeServicePrincipals                  = $excludeServicePrincipals -join $separator
                ServicePrincipalFilterMode                = $policy.Conditions.ClientApplications.ServicePrincipalFilter.mode
                ServicePrincipalFilter                    = $policy.Conditions.ClientApplications.ServicePrincipalFilter.rule
               
                # Grantcontrols
                GrantControls                             = $policy.GrantControls.BuiltInControls -join $separator
                GrantControlsOperator                     = $policy.GrantControls.Operator
                AuthenticationStrength                    = $policy.GrantControls.AuthenticationStrength.DisplayName
                AuthenticationStrengthAllowedCombinations = $policy.GrantControls.AuthenticationStrength.AllowedCombinations -join $separator

                # Session controls
                ApplicationEnforcedRestrictions           = $policy.SessionControls.ApplicationEnforcedRestrictions.IsEnabled
                CloudAppSecurity                          = $policy.SessionControls.CloudAppSecurity.IsEnabled
                DisableResilienceDefaults                 = $policy.SessionControls.DisableResilienceDefaults
                PersistentBrowser                         = $policy.SessionControls.PersistentBrowser.Mode
                SignInFrequency                           = "$($policy.SessionControls.SignInFrequency.Value) $($policy.SessionControls.SignInFrequency.Type)"

                # State
                State                                     = $policy.State
            }
        )
    }
    catch {
        Throw $_
        Write-Error $PSItem
    }
}

# Export report as csv
# $documentation | Export-Csv -Path "$outputPath.csv" -NoTypeInformation
$documentation | Export-Excel -Path "$outputPath.xlsx"

Write-Output "Exported Documentation to '$($outputPath)'"
