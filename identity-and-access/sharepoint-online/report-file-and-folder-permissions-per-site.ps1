# Problem solved : We cannot tell who has unique permissions on files and folders in a given site.
# What it does    : Walks one site's lists, folders and items and exports unique permissions to CSV.
# Requires        : PnP.PowerShell; ImportExcel; Site Owner/Admin
# Effect          : read-only
# Known issues    : Report path C:\Temp\SitePermissionRpt.csv hard-coded; Portuguese comment; slow on large sites.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

### listar permissões de arquivos e pastas por sites

# Install-Module PnP.PowerShell
# Install-Module ImportExcel
# Import-Module PnP.PowerShell
# Import-Module ImportExcel

## Parameter
$SiteURL = "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE"
$ReportFile = "C:\Temp\SitePermissionRpt.csv"


# Function to Get Permissions Applied on a particular Object, such as: Web, List, Folder or List Item
Function Get-PnPPermissions([Microsoft.SharePoint.Client.SecurableObject]$Object) {
    # Determine the type of the object
    Switch ($Object.TypedObject.ToString()) {
        "Microsoft.SharePoint.Client.Web" { $ObjectType = "Site" ; $ObjectURL = $Object.URL; $ObjectTitle = $Object.Title }
        "Microsoft.SharePoint.Client.ListItem" { 
            if ($Object.FileSystemObjectType -eq "Folder") {
                $ObjectType = "Folder"
                # Get the URL of the Folder 
                $Folder = Get-PnPProperty -ClientObject $Object -Property Folder
                $ObjectTitle = $Object.Folder.Name
                $ObjectURL = $("{0}{1}" -f $Web.Url.Replace($Web.ServerRelativeUrl, ''), $Object.Folder.ServerRelativeUrl)
            }
            Else {
                # File or List Item 
                # Get the URL of the Object
                Get-PnPProperty -ClientObject $Object -Property File, ParentList
                if ($Object.File.Name -ne $Null) {
                    $ObjectType = "File"
                    $ObjectTitle = $Object.File.Name
                    $ObjectURL = $("{0}{1}" -f $Web.Url.Replace($Web.ServerRelativeUrl, ''), $Object.File.ServerRelativeUrl)
                }
                else {
                    $ObjectType = "List Item"
                    $ObjectTitle = $Object["Title"]
                    # Get the URL of the List Item
                    $DefaultDisplayFormUrl = Get-PnPProperty -ClientObject $Object.ParentList -Property DefaultDisplayFormUrl                     
                    $ObjectURL = $("{0}{1}?ID={2}" -f $Web.Url.Replace($Web.ServerRelativeUrl, ''), $DefaultDisplayFormUrl, $Object.ID)
                }
            }
        } default { 
            $ObjectType = "List or Library"
            $ObjectTitle = $Object.Title

            # Get the URL of the List or Library
            $RootFolder = Get-PnPProperty -ClientObject $Object -Property RootFolder     
            $ObjectURL = $("{0}{1}" -f $Web.Url.Replace($Web.ServerRelativeUrl, ''), $RootFolder.ServerRelativeUrl)
        }
    }
   
    # Get permissions assigned to the object
    Get-PnPProperty -ClientObject $Object -Property HasUniqueRoleAssignments, RoleAssignments
 
    # Check if Object has unique permissions
    $HasUniquePermissions = $Object.HasUniqueRoleAssignments
     
    # Loop through each permission assigned and extract details
    $PermissionCollection = @()
    foreach ($RoleAssignment in $Object.RoleAssignments) { 
        # Get the Permission Levels assigned and Member
        Get-PnPProperty -ClientObject $RoleAssignment -Property RoleDefinitionBindings, Member
 
        # Get the Principal Type: User, SP Group, AD Group
        $PermissionType = $RoleAssignment.Member.PrincipalType
    
        # Get the Permission Levels assigned
        $PermissionLevels = $RoleAssignment.RoleDefinitionBindings | Select -ExpandProperty Name
 
        # Remove Limited Access
        $PermissionLevels = ($PermissionLevels | Where { $_ -ne "Limited Access" }) -join ","
 
        # Leave Principals with no Permissions
        if ($PermissionLevels.Length -eq 0) { Continue }
 
        # Get SharePoint group members
        if ($PermissionType -eq "SharePointGroup") {
            # Get Group Members
            $GroupMembers = Get-PnPGroupMember -Identity $RoleAssignment.Member.LoginName
                 
            # Leave Empty Groups
            if ($GroupMembers.count -eq 0) { Continue }
            $GroupUsers = ($GroupMembers | Select -ExpandProperty Title) -join ","
 
            # Add the Data to Object
            # $Permissions = New-Object PSObject
            # $Permissions | Add-Member NoteProperty Object($ObjectType)
            # $Permissions | Add-Member NoteProperty Title($ObjectTitle)
            # $Permissions | Add-Member NoteProperty URL($ObjectURL)
            # $Permissions | Add-Member NoteProperty HasUniquePermissions($HasUniquePermissions)
            # $Permissions | Add-Member NoteProperty Users($GroupUsers)
            # $Permissions | Add-Member NoteProperty Type($PermissionType)
            # $Permissions | Add-Member NoteProperty Permissions($PermissionLevels)
            # $Permissions | Add-Member NoteProperty GrantedThrough("SharePoint Group: $($RoleAssignment.Member.LoginName)")
            # $PermissionCollection += $Permissions

            $PermissionCollection += [PSCustomObject]@{
                Object = $ObjectType
                Title = $ObjectTitle
                URL = $ObjectURL
                HasUniquePermissions = $HasUniquePermissions
                Users = $GroupUsers
                Type = $PermissionType
                Permissions = $PermissionLevels
                GrantedThrough = "SharePoint Group: $($RoleAssignment.Member.LoginName)"
            }
        } else {
            # Add the Data to Object
            # $Permissions = New-Object PSObject
            # $Permissions | Add-Member NoteProperty Object($ObjectType)
            # $Permissions | Add-Member NoteProperty Title($ObjectTitle)
            # $Permissions | Add-Member NoteProperty URL($ObjectURL)
            # $Permissions | Add-Member NoteProperty HasUniquePermissions($HasUniquePermissions)
            # $Permissions | Add-Member NoteProperty Users($RoleAssignment.Member.Title)
            # $Permissions | Add-Member NoteProperty Type($PermissionType)
            # $Permissions | Add-Member NoteProperty Permissions($PermissionLevels)
            # $Permissions | Add-Member NoteProperty GrantedThrough("Direct Permissions")
            # $PermissionCollection += $Permissions

            $PermissionCollection += [PSCustomObject]@{
                Object = $ObjectType
                Title = $ObjectTitle
                URL = $ObjectURL
                HasUniquePermissions = $HasUniquePermissions
                Users = $RoleAssignment.Member.Title
                Type = $PermissionType
                Permissions = $PermissionLevels
                GrantedThrough = "Direct Permissions"
            }
        }
    }
    # Export Permissions to CSV File
    # $PermissionCollection | Export-CSV $ReportFile -NoTypeInformation -Append
    $outputReport.Add($PermissionCollection)
}
   
# Function to get sharepoint online site permissions report
Function Generate-PnPSitePermissionRpt() {
    [cmdletbinding()]
    Param (    
        [Parameter(Mandatory = $false)] [String] $SiteURL, 
        [Parameter(Mandatory = $false)] [String] $ReportFile,         
        [Parameter(Mandatory = $false)] [switch] $Recursive,
        [Parameter(Mandatory = $false)] [switch] $ScanItemLevel,
        [Parameter(Mandatory = $false)] [switch] $IncludeInheritedPermissions       
    )

    Try {
        # Connect to the Site
        Connect-PnPOnline -URL $SiteURL -Interactive -ReturnConnection
        # Get the Web
        $Web = Get-PnPWeb
 
        Write-host -f Yellow "Getting Site Collection Administrators..."
        # Get Site Collection Administrators
        $SiteAdmins = Get-PnPSiteCollectionAdmin
         
        $SiteCollectionAdmins = ($SiteAdmins | Select -ExpandProperty Title) -join ","
        # Add the Data to Object
        # $Permissions = New-Object PSObject
        # $Permissions | Add-Member NoteProperty Object("Site Collection")
        # $Permissions | Add-Member NoteProperty Title($Web.Title)
        # $Permissions | Add-Member NoteProperty URL($Web.URL)
        # $Permissions | Add-Member NoteProperty HasUniquePermissions("TRUE")
        # $Permissions | Add-Member NoteProperty Users($SiteCollectionAdmins)
        # $Permissions | Add-Member NoteProperty Type("Site Collection Administrators")
        # $Permissions | Add-Member NoteProperty Permissions("Site Owner")
        # $Permissions | Add-Member NoteProperty GrantedThrough("Direct Permissions")

        $Permissions = [PSCustomObject]@{
            Object = "Site Collection"
            Title = $Web.Title
            URL = $Web.URL
            HasUniquePermissions = "TRUE"
            Users = $SiteCollectionAdmins
            Type = "Site Collection Administrators"
            Permissions = "Site Owner"
            GrantedThrough = "Direct Permissions"
        }
               
        # Export Permissions to CSV File
        # $Permissions | Export-CSV $ReportFile -NoTypeInformation
        $outputReport.Add($Permissions)
   
        # Function to Get Permissions of All List Items of a given List
        Function Get-PnPListItemsPermission([Microsoft.SharePoint.Client.List]$List) {
            Write-host -f Yellow "`t `t Getting Permissions of List Items in the List:"$List.Title
  
            # Get All Items from List in batches
            $ListItems = Get-PnPListItem -List $List -PageSize 500
  
            $ItemCounter = 0
            # Loop through each List item
            foreach ($ListItem in $ListItems) {
                # Get Objects with Unique Permissions or Inherited Permissions based on 'IncludeInheritedPermissions' switch
                if ($IncludeInheritedPermissions) {
                    Get-PnPPermissions -Object $ListItem
                } else {
                    # Check if List Item has unique permissions
                    $HasUniquePermissions = Get-PnPProperty -ClientObject $ListItem -Property HasUniqueRoleAssignments
                    if ($HasUniquePermissions -eq $True) {
                        # Call the function to generate Permission report
                        Get-PnPPermissions -Object $ListItem
                    }
                }
                $ItemCounter++
                Write-Progress -PercentComplete ($ItemCounter / ($List.ItemCount) * 100) -Activity "Processing Items $ItemCounter of $($List.ItemCount)" -Status "Searching Unique Permissions in List Items of '$($List.Title)'"
            }
        }
 
        # Function to Get Permissions of all lists from the given web
        Function Get-PnPListPermission([Microsoft.SharePoint.Client.Web]$Web) {
            # Get All Lists from the web
            $Lists = Get-PnPProperty -ClientObject $Web -Property Lists
   
            # Exclude system lists
            $ExcludedLists = @("Access Requests", "App Packages", "appdata", "appfiles", "Apps in Testing", "Cache Profiles", "Composed Looks", "Content and Structure Reports", "Content type publishing error log", "Converted Forms",
                "Device Channels", "Form Templates", "fpdatasources", "Get started with Apps for Office and SharePoint", "List Template Gallery", "Long Running Operation Status", "Maintenance Log Library", "Images", "site collection images"
                , "Master Docs", "Master Page Gallery", "MicroFeed", "NintexFormXml", "Quick Deploy Items", "Relationships List", "Reusable Content", "Reporting Metadata", "Reporting Templates", "Search Config List", "Site Assets", "Preservation Hold Library",
                "Site Pages", "Solution Gallery", "Style Library", "Suggested Content Browser Locations", "Theme Gallery", "TaxonomyHiddenList", "User Information List", "Web Part Gallery", "wfpub", "wfsvc", "Workflow History", "Workflow Tasks", "Pages")
             
            $Counter = 0
            # Get all lists from the web   
            foreach ($List in $Lists) {
                # Exclude System Lists
                if ($List.Hidden -eq $False -and $ExcludedLists -notcontains $List.Title) {
                    $Counter++
                    Write-Progress -PercentComplete ($Counter / ($Lists.Count) * 100) -Activity "Exporting Permissions from List '$($List.Title)' in $($Web.URL)" -Status "Processing Lists $Counter of $($Lists.Count)"
 
                    # Get Item Level Permissions if 'ScanItemLevel' switch present
                    if ($ScanItemLevel) {
                        # Get List Items Permissions
                        Get-PnPListItemsPermission -List $List
                    }
 
                    # Get Lists with Unique Permissions or Inherited Permissions based on 'IncludeInheritedPermissions' switch
                    if ($IncludeInheritedPermissions) {
                        Get-PnPPermissions -Object $List
                    } else {
                        # Check if List has unique permissions
                        $HasUniquePermissions = Get-PnPProperty -ClientObject $List -Property HasUniqueRoleAssignments
                        if ($HasUniquePermissions -eq $True) {
                            # Call the function to check permissions
                            Get-PnPPermissions -Object $List
                        }
                    }
                }
            }
        }
   
        #Function to Get Webs's Permissions from given URL
        Function Get-PnPWebPermission([Microsoft.SharePoint.Client.Web]$Web) {
            # Call the function to Get permissions of the web
            Write-host -f Yellow "Getting Permissions of the Web: $($Web.URL)..." 
            Get-PnPPermissions -Object $Web
   
            # Get List Permissions
            Write-host -f Yellow "`t Getting Permissions of Lists and Libraries..."
            Get-PnPListPermission($Web)
 
            # Recursively get permissions from all sub-webs based on the "Recursive" Switch
            if ($Recursive) {
                # Get Subwebs of the Web
                $Subwebs = Get-PnPProperty -ClientObject $Web -Property Webs
 
                # Iterate through each subsite in the current web
                foreach ($Subweb in $web.Webs) {
                    # Get Webs with Unique Permissions or Inherited Permissions based on 'IncludeInheritedPermissions' switch
                    if ($IncludeInheritedPermissions) {
                        Get-PnPWebPermission($Subweb)
                    } else {
                        # Check if the Web has unique permissions
                        $HasUniquePermissions = Get-PnPProperty -ClientObject $SubWeb -Property HasUniqueRoleAssignments
   
                        # Get the Web's Permissions
                        if ($HasUniquePermissions -eq $true) { 
                            # Call the function recursively                            
                            Get-PnPWebPermission($Subweb)
                        }
                    }
                }
            }
        }
 
        # Call the function with RootWeb to get site collection permissions
        Get-PnPWebPermission $Web
   
        Write-host -f Green "`n*** Site Permission Report Generated Successfully!***"
    } catch {
        write-host -f Red "Error Generating Site Permission Report!" $_.Exception.Message
    }
}

##
$outputReport = [System.Collections.Generic.List[Object]]::new() # Create output file

# Call the function to generate permission report
Generate-PnPSitePermissionRpt -SiteURL $SiteURL -ReportFile $ReportFile -Recursive
# Generate-PnPSitePermissionRpt -SiteURL $SiteURL -ReportFile $ReportFile -Recursive -ScanItemLevel -IncludeInheritedPermissions

$outputReport | Export-Excel
