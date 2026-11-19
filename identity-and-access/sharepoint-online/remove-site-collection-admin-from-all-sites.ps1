# Problem solved : A temporary or former admin is still site collection admin on many sites.
# What it does    : Loops all non-read-only sites and removes the user as site collection admin, building a result report.
# Requires        : SPO Management Shell; SharePoint Administrator
# Effect          : destructive (review and test before use)
# Known issues    : Report variable inconsistent in sibling scripts (typo $siteAdmin in the owner variant).
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module Microsoft.Online.SharePoint
# Import-Module Microsoft.Online.SharePoint

# Variables for processing
$AdminURL = "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/"
$siteAdminUPN = "ENTRE_AQUI_COM_SEU_EMAIL@example.com"
  
# Connect to SharePoint Online
Connect-SPOService -URL $AdminURL

##
$sites = Get-SPOSite -Limit All | Sort-Object Url | Where-Object {$_.LockState -ne 'ReadOnly'}

$outputReport = [System.Collections.Generic.List[Object]]::new() # Create output file
foreach ($site in $sites) {
    Write-Progress -Id 1 -Activity "Processing sites" -Status "[$($sites.IndexOf($site)) / $($sites.Count)] Processing '$($site.Url)'" -PercentComplete (($sites.IndexOf($site) / $sites.Count) * 100)

    # Add Site collection Admin
    Set-SPOUser -Site $site.Url -LoginName $siteAdminUPN -IsSiteCollectionAdmin $false

    if ($?) {
        Write-Host "Site Collection Admin removed from the site: $($site.Url)" -ForegroundColor Green

        # Add to output file
        $outputReport.Add([PSCustomObject]@{
            SiteUrl = $site.Url
            SiteAdmin = $siteAdminUPN
            SiteAdminRemoved = $true
        })
    } else {
        Write-Host "Site Collection Admin removed from the site: $($site.Url)" -ForegroundColor Red

        # Add to output file
        $outputReport.Add([PSCustomObject]@{
            SiteUrl = $site.Url
            SiteAdmin = $siteAdminUPN
            SiteAdminRemoved = $false
        })
    }    
}
Write-Progress -Id 1 -Activity "Processing sites" -Status "DONE" -Completed

$outputReport | Export-Excel
