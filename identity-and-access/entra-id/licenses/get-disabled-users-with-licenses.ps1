# Problem solved : Leavers' accounts are disabled but keep paid licenses and a live footprint.
# What it does    : Lists disabled users with every license they still hold, to Excel.
# Requires        : Microsoft.Graph.Users, ImportExcel; User.Read.All
# Effect          : read-only
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module Microsoft.Graph.Authentication
# Install-Module Microsoft.Graph.Users
# Install-Module ImportExcel

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users
Import-Module ImportExcel

##
# Licenses display names (DO NOT REMOVE)
$licenseInformation = [PSCustomObject]@{
    Forms_Pro_USL = "Dynamics 365 Customer Voice USL"
    O365_BUSINESS_ESSENTIALS = "Microsoft 365 Business Basic"
    PROJECTPROFESSIONAL = "Project Plan 3"
    VISIOCLIENT = "Visio Plan 2"
    SPE_E5 = "Microsoft 365 E5"
    ENTERPRISEPACK = "Office 365 E3"
    DESKLESSPACK = "Office 365 F3"
    MCOPSTN1 = "Microsoft Teams Domestic Calling Plan"
    MCOPSTN2 = "Microsoft Teams Domestic and International Calling Plan"
    STANDARDPACK = "Office 365 E1"
    MCOEV = "Microsoft Teams Phone Standard"
    POWER_BI_PRO = "Power BI Pro"
    TEAMS_EXPLORATORY = "Microsoft Teams Exploratory"
    SPE_E3 = "Microsoft 365 E3"
    CCIBOTS_PRIVPREV_VIRAL = "Power Virtual Agents Viral Trial"
    RIGHTSMANAGEMENT_ADHOC = "Rights Management Adhoc"
    FLOW_FREE = "Microsoft Power Automate Free"
    TVM_Premium_Add_on = "Microsoft Defender Vulnerability Management Add-on"
    STREAM = "Microsoft Stream Trial"
    POWER_BI_STANDARD = "Power BI (free)"
    MCOPSTNC = "Communications Credits"
}

##
Connect-MgGraph

# Get all disabled users
$users = Get-MgUser -All -Filter "accountEnabled eq false"

$report = @()

# Get license for all users
foreach ($user in $users) {
    Write-Progress -Id 1 -Activity "Checking users..." -Status "($($users.IndexOf($user)) / $($users.count)) Processing '$($user.UserPrincipalName)'" -PercentComplete (($users.IndexOf($user) / $users.Count) * 100)

    $licenses = [array](Get-MgUserLicenseDetail -UserId $user.Id)

    foreach ($license in $licenses) {
        Write-Progress -Id 2 -ParentId 1 -Activity "Checking licenses for '$($user.UserPrincipalName)'..." -Status "($($licenses.IndexOf($license)) / $($licenses.count))" -PercentComplete (($licenses.IndexOf($license) / $licenses.Count) * 100)

        $report += [PSCustomObject]@{
            User = $user.DisplayName
            UPN = $user.UserPrincipalName
            JobTitle = $user.JobTitle
            AccountEnabled = $user.AccountEnabled
            LicenseSku = $license.SkuId
            LicenseName = $license.SkuPartNumber
            LicenseDisplayName = $licenseInformation.$($license.SkuPartNumber)
        }
    }
    Write-Progress -Id 2 -ParentId 1 -Completed
}
Write-Progress -Id 1 -Completed


$report | Export-Excel