# Problem solved : A user must be removed as admin from a defined set of sites.
# What it does    : Loops a list of site URLs and removes the user as site collection admin.
# Requires        : SPO Management Shell; SharePoint Administrator
# Effect          : destructive (review and test before use)
# Known issues    : Variable $sitesToAdd reused in the remove script (misleading name); URL list of placeholders.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module Microsoft.Online.SharePoint.PowerShell
Import-Module Microsoft.Online.SharePoint.PowerShell

##
# Variables for processing
$TenantAdminURL = "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/"

$Admin = "ENTRE_AQUI_COM_SEU_EMAIL@example.com"

$sitesToAdd = @(
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE"
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE",
    "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE"
)

# Connect to SharePoint Online
Connect-SPOService -Url $TenantAdminURL

# $Sites = Get-SPOSite -Limit ALL
$Sites = Get-SPOSite -Limit ALL | Where-Object { $sitesToAdd -contains $_.URL }

foreach ($Site in $Sites) {
    Write-Output "Removing Site Collection Admin from '$($Site.URL)'"
    # Set-SPOUser -site $Site -LoginName $Admin -IsSiteCollectionAdmin $False
}

