# Problem solved : We cannot tell who has access to which SharePoint sites.
# What it does    : Temporarily adds the admin as site owner, collects users, groups and permission levels per site (expanding M365 groups through Graph), then exports to Excel and removes the admin.
# Requires        : PnP.PowerShell; Microsoft.Graph (Group.Read.All); ImportExcel; SharePoint Administrator
# Effect          : changes-state (review and test before use)
# Known issues    : Not purely read-only: it temporarily changes site ownership (Set-PnPTenantSite -Owners). Based on NovaPoint sample. Admin UPN placeholder.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

### Users with access at the Site level
### https://github.com/Barbarur/NovaPointPowerShell/blob/main/Solutions/Report/Permissions%20report%20in%20SharePoint%20Online.md

# Install-Module PnP.PowerShell -Scope CurrentUser
# Install-Module ImportExcel -Scope CurrentUser
# Install-Module Microsoft.Graph -Scope CurrentUser

Remove-Module PnP.PowerShell -Force # Evitar conflito com Microsoft.Graph.Authentication

# Import-Module PnP.PowerShell # Importado no script
Import-Module ImportExcel
# Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Groups

##
$SPOAdminURL = "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com"
$AdminUPN = "ENTRE_AQUI_COM_SEU_EMAIL@example.com"

##
# Connect to Microsoft Graph API
Connect-MgGraph -Scopes "Group.Read.All"

# Get Azure AD Microsoft 365 Groups
$groups = Get-MgGroup -All

##
#################################################################
## REPORT AND LOGS FUNCTIONS
#################################################################
Function Add-ReportRecord($Web, $RoleAssignment, $User, $PermissionLevels) {
    $Record = New-Object PSObject -Property ([ordered]@{
        "SiteName" = $Web.Title
        "SiteUrl" = $Web.Url -Replace ('.*sharepoint.com','')
        "GroupName" = $RoleAssignment.Member.Title
        "UserName" = $User.Title
        "UserUPN" = $User.UserPrincipalName
        "UserEmail" = $User.Email
        "PermissionLevels" = $PermissionLevels
    })
    
    $global:outputReport.Add($Record)
}

Function Add-ScriptLog($Color, $Msg) {
    Write-Host -f $Color $Msg
    $Date = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    $Msg = $Date + " - " + $Msg
    # Add-Content -Path $LogsOutput -Value $Msg
}

#################################################################
# SCRIPT LOGIC
#################################################################
function Get-SitePermissions {
    param (
        $Site
    )

    Connect-PnPOnline -Url $Site.Url -Interactive -ErrorAction Stop
    
    $Web = Get-PnPWeb -Includes RoleAssignments

    Get-UserPermissions -Web $Web
}

function Get-UserPermissions {
    param (
        $Web,
        [System.Collections.Generic.List[Object]]$Report
    )

    ForEach ($RoleAssignment in $Web.RoleAssignments) {
        
        If ( $RoleAssignment.Member.PrincipalType -eq "SharePointGroup" -and ( $RoleAssignment.Member.Title -notlike "*owner*" -or $RoleAssignment.Member.Title -notlike "*member*" ) ) { continue }
        
        Get-PnPProperty -ClientObject $RoleAssignment -Property RoleDefinitionBindings, Member
        
        $PermissionLevels = ($RoleAssignment.RoleDefinitionBindings | Select-Object -ExpandProperty Name | Where-Object { ($_ -ne "Limited Access") -and ($_ -ne "Web-Only Limited Access")} ) -join ","
        If ($PermissionLevels.Length -eq 0) {Continue}

        $collUsers = Get-PnPProperty -ClientObject ($RoleAssignment.Member) -Property Users -ErrorAction SilentlyContinue
        If ($collUsers.Count -eq 0) { continue }

        ForEach ($oUser in $collUsers) {
            If ($oUser.Title -eq "System Account") {Continue}

            Add-ReportRecord -Web $Web -RoleAssignment $RoleAssignment -User $oUser -PermissionLevels $PermissionLevels
        }
    }
}


## Authenticate and get site collections
try {
    # Connect to SharePoint Admin Center
    Import-Module PnP.PowerShell
    
    Connect-PnPOnline -Url $SPOAdminURL -Interactive -ErrorAction Stop
    Add-ScriptLog -Color Cyan -Msg "Connected to SharePoint Admin Center"

    $collSiteCollections = Get-PnPTenantSite -ErrorAction Stop | Where-Object {($_.Title -notlike "" -and $_.Template -notlike "*Redirect*")} | Sort-Object StorageUsageCurrent -Descending
    
    Add-ScriptLog -Color Cyan -Msg "Collected Site Collections"
    Add-ScriptLog -Color Cyan -Msg "Number of Site Collections: $($collSiteCollections.count)"

} catch {
    Add-ScriptLog -Color Red -Msg "Error: $($_.Exception.Message)"
    break
}


##
$outputReport = [System.Collections.Generic.List[Object]]::new()
$siteCounter = 0

foreach($oSiteCollection in $collSiteCollections[0..5]) {
    $PercentComplete = [math]::Round($siteCounter/$collSiteCollections.Count * 100, 2)
    Add-ScriptLog -Color Yellow -Msg "$($PercentComplete)% Completed - Processing Site Collection: $($oSiteCollection.Title)"
    
    Write-Progress -Id 1 -Activity "Processing Site Collections" -Status "Processing Site Collection: $($oSiteCollection.Title)" -PercentComplete $PercentComplete

    $siteCounter++
    
    try {
        Set-PnPTenantSite -Url $oSiteCollection.Url -Owners $AdminUPN

        Get-SitePermissions -Site $oSiteCollection

        try {
            $collSubsites = Get-PnPSubWeb -Recurse -Includes HasUniqueRoleAssignments

            $subSiteCounter = 0
            ForEach($oSubsite in $collSubsites) {
                $PercentComplete = [math]::Round( $PercentComplete + ( ($subSiteCounter / $collSubsites.Count) * 100 ), 2 )
                Add-ScriptLog -Color Yellow -Msg "$($PercentComplete)% Completed - Processing Subsite: $($oSubsite.Title)"
            
                $subSiteCounter++

                Get-SitePermissions -Site $oSubsite
            }
        } catch {
            Add-ScriptLog -Color Red -Msg "Error processing Subsite: $($oSiteCollection.Url)"
            Add-ScriptLog -Color Red -Msg "Error message: $($_.Exception.Message)"
        }
    } catch {
        Add-ScriptLog -Color Red -Msg "Error processing Site Collection: $($oSiteCollection.Url)"
        Add-ScriptLog -Color Red -Msg "Error message: $($_.Exception.Message)"
    }

    # Remove Site Collection Admin
    Remove-PnPSiteCollectionAdmin -Owners $AdminUPN
}
Write-Progress -Id 1 -Activity "Processing Site Collections" -Status "DONE" -PercentComplete 100

# Close status notification
$PercentComplete = [math]::Round($siteCounter/$collSiteCollections.Count * 100, 1)
Add-ScriptLog -Color Cyan -Msg "$($PercentComplete)% Completed - Finished running script"


##
$outputReportOriginal = [System.Collections.Generic.List[Object]]::new()
foreach ($item in $outputReport) {
    $outputReportOriginal.Add($item)
}


## Run from here to test
$outputReportCopy = [System.Collections.Generic.List[Object]]::new()
foreach ($item in $outputReportOriginal) {
    $outputReportCopy.Add($item)
}

$outputReport = [System.Collections.Generic.List[Object]]::new()
foreach ($item in $outputReportOriginal) {
    $outputReport.Add($item)
}

foreach ($row in $outputReportCopy) {
    Write-Progress -Id 1 -Activity "Treating report data..." -Status "Processing Site: $($row.SiteName)" -PercentComplete ($outputReportCopy.IndexOf($row) / $outputReportCopy.Count * 100)

    $currentGroup, $members, $owners = $null

    if ($row.UserName -like "$($row.SiteName)*") {
        # Get group owners
        $currentGroup = $groups | Where-Object { $_.DisplayName -eq $row.SiteName }

        if ($currentGroup.count -eq 0) {
            Add-ScriptLog -Color Red -Msg "Error: No group found with the name '$($row.SiteName)'"
            continue
        } elseif ($currentGroup.count -gt 1) {
            Add-ScriptLog -Color Red -Msg "Error: More than one group found with the name $($row.SiteName)"
            continue
        } else {
            if ($row.UserName -eq "$($row.SiteName) Owners") {
                $owners = Get-MgGroupOwner -GroupId $currentGroup.Id

                foreach ($o in $owners) {
                    $outputReport.Add([PSCustomObject]@{
                        "SiteName" = $row.SiteName
                        "SiteUrl" = $row.SiteUrl
                        "GroupName" = $row.GroupName
                        "UserName" = $o.AdditionalProperties.displayName
                        "UserUPN" = $o.AdditionalProperties.userPrincipalName
                        "UserEmail" = $o.AdditionalProperties.mail
                        "PermissionLevels" = $row.PermissionLevels
                    })
                }
                $outputReport.Remove($row) | Out-Null
            } elseif ($row.UserName -eq "$($row.SiteName) Members") {
                $members = Get-MgGroupMember -GroupId $currentGroup.Id

                foreach ($m in $members) {
                    $outputReport.Add([PSCustomObject]@{
                        "SiteName" = $row.SiteName
                        "SiteUrl" = $row.SiteUrl
                        "GroupName" = $row.GroupName
                        "UserName" = $m.AdditionalProperties.displayName
                        "UserUPN" = $m.AdditionalProperties.userPrincipalName
                        "UserEmail" = $m.AdditionalProperties.mail
                        "PermissionLevels" = $row.PermissionLevels
                    })
                }
                $outputReport.Remove($row) | Out-Null
            }
        }
    }
}
Write-Progress -Id 1 -Activity "Treating report data..." -Status "DONE" -PercentComplete 100

##
$outputReport | Export-Excel
