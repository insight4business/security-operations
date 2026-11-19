# Problem solved : A former owner still sits in the Owners group of many sites.
# What it does    : Removes the user from the Owners group of all non-read-only sites with a report.
# Requires        : SPO Management Shell; SharePoint Administrator
# Effect          : destructive (review and test before use)
# Known issues    : Report uses undefined variable $siteAdmin (bug) instead of $siteAdminUPN.
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

    $siteGroups = Get-SPOSiteGroup -Site $site.Url
    $ownerGroup = $siteGroups | Where-Object {$_.LoginName -like "*Owners*"}

    # Remove as owner
    Remove-SPOUser -Site $site.Url -LoginName $siteAdminUPN -Group $ownerGroup.LoginName

    if ($?) {
        Write-Host "Owner removed from the site: $($site.Url)" -ForegroundColor Green

        # Add to output file
        $outputReport.Add([PSCustomObject]@{
            SiteUrl = $site.Url
            User = $siteAdminUPN
            SiteOwnerRemoved = $true
        })
    } else {
        Write-Host "Failed to remove owner from the site: $($site.Url)" -ForegroundColor Red

        # Add to output file
        $outputReport.Add([PSCustomObject]@{
            SiteUrl = $site.Url
            User = $siteAdminUPN
            SiteOwnerRemoved = $false
        })
    }    
}
Write-Progress -Id 1 -Activity "Processing sites" -Status "DONE" -Completed

$outputReport | Export-Excel
