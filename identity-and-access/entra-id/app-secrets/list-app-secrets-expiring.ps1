# Problem solved : App secrets expire unnoticed and break integrations, or old secrets linger.
# What it does    : Exports every app registration key/secret with expiry date, owners and creator to Excel.
# Requires        : Microsoft.Graph.Applications, ImportExcel; Application.Read.All
# Effect          : read-only
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

Import-Module ImportExcel
Import-Module Microsoft.Graph.Applications

Connect-MgGraph

##
$applications = Get-MgApplication -All

$report = @()
foreach ($app in $applications) {
    Write-Progress -Id 1 -Activity "Processing applications" -Status "($($applications.IndexOf($app)) / $($applications.Count)) Processing '$($app.DisplayName)'" -PercentComplete (($applications.IndexOf($app) / $applications.Count) * 100)

    # If there are any keys or secrets, get the owners and the user who created the application
    if ($app.KeyCredentials.Count -gt 0 -or $app.PasswordCredentials.Count -gt 0) {
        $owners = Get-MgApplicationOwner -All -ApplicationId $app.Id
        $createdBy = Get-MgApplicationCreatedOnBehalfOf -ApplicationId $app.Id -ErrorAction SilentlyContinue
    }

    foreach ($key in $app.KeyCredentials) {
        $report += [PSCustomObject]@{
            Id = $app.Id
            AppId = $app.AppId
            DisplayName = $app.DisplayName
            AppCreatedDateTime = $app.CreatedDateTime.ToString("yyyy-MM-dd")
            CreatedById = $createdBy.Id
            CreatedByUPN = $createdBy.AdditionalProperties.userPrincipalName
            KeyId = $key.KeyId
            KeyDisplayName = $key.DisplayName
            KeyStartDateTime = $key.StartDateTime.ToString("yyyy-MM-dd")
            KeyEndDateTime = $key.EndDateTime.ToString("yyyy-MM-dd")
            Key = "Certificate"
            Owners = $owners.AdditionalProperties.userPrincipalName -join ", "
        }
    }
    
    foreach ($pw in $app.PasswordCredentials) {
        $report += [PSCustomObject]@{
            Id = $app.Id
            AppId = $app.AppId
            DisplayName = $app.DisplayName
            AppCreatedDateTime = $app.CreatedDateTime.ToString("yyyy-MM-dd")
            CreatedById = $createdBy.Id
            CreatedByUPN = $createdBy.AdditionalProperties.userPrincipalName
            KeyId = $pw.KeyId
            KeyDisplayName = $pw.DisplayName
            KeyStartDateTime = $pw.StartDateTime.ToString("yyyy-MM-dd")
            KeyEndDateTime = $pw.EndDateTime.ToString("yyyy-MM-dd")
            Key = "Secret"
            Owners = $owners.AdditionalProperties.userPrincipalName -join ", "
        }
    }
}
Write-Progress -Id 1 -Activity "Processing applications" -Status "Completed" -Completed


$report | Export-Excel
