# Problem solved : App registrations have no owner and nobody maintains their secrets.
# What it does    : Exports applications with owners, audience and credential dates.
# Requires        : AzureAD
# Effect          : read-only
# Known issues    : deprecated AzureAD module (retired); port to Microsoft.Graph; no MgGraph equivalent in slice
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###


# Connect-AzureAD


$apps = Get-AzureADApplication -All $true
# $apps += (Get-AzureADDeletedApplication -All $true)

$outputReport = [System.Collections.Generic.List[Object]]::new() # Create output file
foreach ($app in $apps) {
    # Get owner
    $owners = [array](Get-AzureADApplicationOwner -ObjectId $app.ObjectId)

    $outputReport.Add([PSCustomObject]@{
        ObjectId = $app.ObjectId
        AppId = $app.AppId
        DisplayName = $app.DisplayName
        DeletionTimestamp = $app.DeletionTimestamp
        AvailableToOtherTenants = $app.AvailableToOtherTenants
        Homepage = $app.Homepage
        IdentifierUris = [string]($app.IdentifierUris -join ";")
        SignInAudience = $app.SignInAudience
        PasswordCredentials_KeyId = $app.PasswordCredentials.KeyId
        PasswordCredentials_StartDate = $app.PasswordCredentials.StartDate
        PasswordCredentials_EndDate = $app.PasswordCredentials.EndDate
        KeyCredentials_KeyId = $app.KeyCredentials.KeyId
        KeyCredentials_StartDate = $app.KeyCredentials.StartDate
        KeyCredentials_EndDate = $app.KeyCredentials.EndDate
        KeyCredentials_Type = $app.KeyCredentials.Type
        KeyCredentials_Usage = $app.KeyCredentials.Usage
        Owners_UserPrincipalName = [string]($owners.UserPrincipalName -join ";")
        Owners_DisplayName = [string]($owners.DisplayName -join ";")
    })
}

$outputReport | Export-Excel