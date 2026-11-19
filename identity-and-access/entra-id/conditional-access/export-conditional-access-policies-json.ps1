# Problem solved : CA policies change with no backup or baseline for rollback.
# What it does    : Exports every CA policy and named location to JSON files.
# Requires        : Microsoft.Graph.Identity.ConditionalAccess; Policy.Read.All
# Effect          : read-only
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module Microsoft.Graph
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Identity.ConditionalAccess


##
$currentDay = (Get-Date).ToString("yyyy-MM-dd")
# $outputPath = "C:\Temp\$currentDay - Conditional Access Policies" # Windows
$outputPath = "$env:HOME\temp\$currentDay - Conditional Access Policies" # macOS


## Authentication
Connect-MgGraph -Scopes "Application.Read.All", "Group.Read.All", "Policy.Read.All", "RoleManagement.Read.Directory", "User.Read.All" -ContextScope Process


##
# Create output folder if it doesn't exist
if (-not (Test-Path $outputPath)) { New-Item -ItemType Directory -Path $outputPath }

# Get Conditional Access Policies
$conditionalAccessPolicies = Get-MgIdentityConditionalAccessPolicy -ExpandProperty "*" -All -ErrorAction Stop
#Get Conditional Access Named / Trusted Locations
$namedLocations = Get-MgIdentityConditionalAccessNamedLocation -All -ErrorAction Stop | Group-Object -Property Id -AsHashTable
if (-not $namedLocations) { $namedLocations = @{} }

foreach ($ca in $conditionalAccessPolicies) {
    $outputFilePath = "$($ca.DisplayName).json"
    $outputFilePath = $outputFilePath.Replace(":","-").Replace("/","_")
    try {
        $ca | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputPath\$outputFilePath" -Force
    } catch {
        Write-Host "Error while exporting $($ca.DisplayName) to '$outputPath\$outputFilePath'"
        Write-Error $_.Exception.Message
    }

    Start-Sleep 1
}
