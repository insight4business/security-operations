# Problem solved : Folder permissions in a document library drift from the intended group-based model.
# What it does    : Walks a library folder tree, grants a role to a group and removes other direct permissions (controlled by a $readOnly switch).
# Requires        : PnP.PowerShell 1.12; AzureAD module; SharePoint admin
# Effect          : destructive (review and test before use)
# Known issues    : Client-specific folder names ('Application - Online','Credit') and group name comment; AzureAD module retired; large script with placeholder nuget version; test with $readOnly=$true first.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-PackageProvider -Name nuget -MinimumVersion ENTRE_AQUI_COM_SEU_IP -Force
# Install-Module -Name "PnP.PowerShell" -RequiredVersion 1.12.0 -Force -AllowClobber
# Install-Module -Name "AzureAD" -Force
Import-Module PnP.PowerShell
Import-Module AzureAD

$env:PNPPOWERSHELL_UPDATECHECK = 'Off'

# Variables
$readOnly = $true

$siteURL = "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE"
# $siteUrl = "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE"
$parentFolderURL = "/Shared Documents" # Parent Folder's Site Relative Path

$includedLists = @("Documents")
$includedFolders = @("Application - Online")
$targetFolder = "Credit"

$roleName = "Contribute without delete"

$accessGroup = 'ENTRE_AQUI_COM_SEU_ID' # ENTRE_AQUI_COM_SEU_GRUPO-Contributor

# # Setup (run once) https://pnp.github.io/powershell/articles/authentication.html
# Register-PnPManagementShellAccess
  
Function Get-PnPPermissions([Microsoft.SharePoint.Client.SecurableObject]$object) {
    # Determine the type of the object
    Switch ($object.TypedObject.ToString()) {
        "Microsoft.SharePoint.Client.Web" {
            $objectType = "Site"
            $objectURL = $object.URL
            $objectTitle = $object.Title
        }
        "Microsoft.SharePoint.Client.ListItem" {
            $objectType = "Folder"
            # Get the URL of the Folder 
            $folder = Get-PnPProperty -ClientObject $object -Property Folder
            $objectTitle = $object.Folder.Name
            $objectURL = $("{0}{1}" -f $web.Url.Replace($web.ServerRelativeUrl, ''), $object.Folder.ServerRelativeUrl)
        }
        Default { 
            $objectType = $object.BaseType #List, DocumentLibrary, etc
            $objectTitle = $object.Title
            # Get the URL of the List or Library
            $rootFolder = Get-PnPProperty -ClientObject $object -Property RootFolder     
            $objectURL = $("{0}{1}" -f $web.Url.Replace($web.ServerRelativeUrl, ''), $rootFolder.ServerRelativeUrl)
        }
    }
    
    # Get permissions assigned to the object
    Get-PnPProperty -ClientObject $object -Property HasUniqueRoleAssignments, RoleAssignments
  
    # Check if Object has unique permissions
    $hasUniquePermissions = $object.HasUniqueRoleAssignments
      
    # Loop through each permission assigned and extract details
    # $permissionCollection = @()
    Foreach ($roleAssignment in $object.RoleAssignments) { 
        # Get the Permission Levels assigned and Member
        Get-PnPProperty -ClientObject $roleAssignment -Property RoleDefinitionBindings, Member
  
        # Get the Principal Type: User, SP Group, AD Group
        $permissionType = $roleAssignment.Member.PrincipalType
     
        # Get the Permission Levels assigned
        $permissionLevels = $roleAssignment.RoleDefinitionBindings | Select-Object -ExpandProperty Name
  
        # Remove Limited Access
        $permissionLevels = ($permissionLevels | Where-Object { $_ -ne "Limited Access" }) -join "; "
  
        # Leave Principals with no Permissions assigned
        if ($permissionLevels.Length -eq 0) { Continue }
  
        # Check if the Principal is SharePoint group
        if ($permissionType -eq "SharePointGroup") {
            # Get Group Members
            $groupMembers = Get-PnPGroupMember -Identity $roleAssignment.Member.LoginName
                  
            # Leave Empty Groups
            if ($groupMembers.count -eq 0) { Continue }
            $groupUsers = ($groupMembers | Select-Object -ExpandProperty Title | Where-Object { $_ -ne "System Account" }) -join "; "
            if ($groupUsers.Length -eq 0) { Continue }
 
            # Add the Data to Object
            $permissions = [PSCustomObject]@{
                Object               = $objectType
                Title                = $objectTitle
                URL                  = $objectURL
                HasUniquePermissions = $hasUniquePermissions
                Users                = $groupUsers
                Type                 = $permissionType
                Permissions          = $permissionLevels
                GrantedThrough       = "SharePoint Group: $($roleAssignment.Member.LoginName)"

            }

            $global:permissionList.Add($permissions)

        } else {
            # User
            # Add the Data to Object
            $permissions = New-Object PSObject

            $permissions = [PSCustomObject]@{
                Object               = $objectType
                Title                = $objectTitle
                URL                  = $objectURL
                HasUniquePermissions = $hasUniquePermissions
                Users                = $roleAssignment.Member.UserPrincipalName
                Type                 = $permissionType
                Permissions          = $permissionLevels
                GrantedThrough       = "Direct Permissions"
            }

            $global:permissionList.Add($permissions)
        }
    }
    # $global:permissionList.Add($permissionCollection)
}
    
#Function to get sharepoint online site permissions report
Function Generate-PnPSitePermissionRpt() {
    [cmdletbinding()]
    Param (    
        [Parameter(Mandatory = $false)] [String] $SiteURL, 
        [Parameter(Mandatory = $false)] [switch] $Recursive,
        [Parameter(Mandatory = $false)] [switch] $ScanFolders,
        [Parameter(Mandatory = $false)] [switch] $IncludeInheritedPermissions
    )  

    # Site admins
    Write-host -f Yellow "Getting Site Collection Administrators..."
    # Get Site Collection Administrators
    $siteAdmins = Get-PnPSiteCollectionAdmin
        
    $siteCollectionAdmins = ($siteAdmins | Select-Object -ExpandProperty Title) -join "; "
    # Add the Data to Object
    $permissions = [PSCustomObject]@{
        Object               = "Site Collection"
        Title                = $web.Title
        URL                  = $web.URL
        HasUniquePermissions = "TRUE"
        Users                = $siteCollectionAdmins
        Type                 = "Site Collection Administrators"
        Permissions          = "Site Owner"
        GrantedThrough       = "Direct Permissions"
    }

    # $permissionCollection += $permissions
    $global:permissionList.Add($permissions)

    # Function to Get Permissions of Folders in a given List
    Function Get-PnPFolderPermission([Microsoft.SharePoint.Client.List]$list) {
        Write-host -f Yellow "`t `t Getting Permissions of Folders in the List:" $list.Title
            
        # Get All Folders from List
        $listItems = Get-PnPListItem -List $list -PageSize 2000
        $folders = $listItems | Where-Object { ($_.FileSystemObjectType -eq "Folder") -and ($_.FieldValues.FileLeafRef -ne "Forms") -and (-not ($_.FieldValues.FileLeafRef.StartsWith("_"))) }

        $itemCounter = 0
        # Loop through each Folder
        ForEach ($folder in $folders) {
            if ($includedFolders -contains $folder.FieldValues.FileLeafRef) {
                # Get Objects with Unique Permissions or Inherited Permissions based on 'IncludeInheritedPermissions' switch
                if ($includeInheritedPermissions) {
                    Get-PnPPermissions -Object $folder
                } else {
                    # Check if Folder has unique permissions
                    $hasUniquePermissions = Get-PnPProperty -ClientObject $folder -Property HasUniqueRoleAssignments
                    if ($hasUniquePermissions -eq $true) {
                        # Call the function to generate Permission report
                        Get-PnPPermissions -Object $folder
                    }
                }
                $itemCounter++
                Write-Progress -PercentComplete ($itemCounter / ($folders.Count) * 100) -Activity "Getting Permissions of Folders in List '$($list.Title)'" -Status "Processing Folder '$($folder.FieldValues.FileLeafRef)' at '$($folder.FieldValues.FileRef)' ($itemCounter of $($folders.Count))" -Id 2 -ParentId 1
            }
        }
        Write-Progress -PercentComplete 100 -Activity "Getting Permissions of Folders in List '$($list.Title)'" -Status "DONE" -Id 2 -ParentId 1
    }

    # Function to Get Permissions of all lists from the given web
    Function Get-PnPListPermission([Microsoft.SharePoint.Client.Web]$web) {
        # Get All Lists from the web
        $lists = Get-PnPProperty -ClientObject $web -Property Lists
    
        # Exclude system lists
        # $excludedLists = @("Access Requests", "App Packages", "appdata", "appfiles", "Apps in Testing", "Cache Profiles", "Composed Looks", "Content and Structure Reports", "Content type publishing error log", "Converted Forms", "Device Channels", "Form Templates", "fpdatasources", "Get started with Apps for Office and SharePoint", "List Template Gallery", "Long Running Operation Status", "Maintenance Log Library", "Images", "site collection images", "Master Docs", "Master Page Gallery", "MicroFeed", "NintexFormXml", "Quick Deploy Items", "Relationships List", "Reusable Content", "Reporting Metadata", "Reporting Templates", "Search Config List", "Site Assets", "Preservation Hold Library", "Site Pages", "Solution Gallery", "Style Library", "Suggested Content Browser Locations", "Theme Gallery", "TaxonomyHiddenList", "User Information List", "Web Part Gallery", "wfpub", "wfsvc", "Workflow History", "Workflow Tasks", "Pages")
          
        $counter = 0
        # Get all lists from the web   
        ForEach ($list in $lists) {
            # Exclude System Lists
            # if ($list.Hidden -eq $False -and $excludedLists -notcontains $list.Title) {
            if ($list.Hidden -eq $False -and $includedLists -contains $list.Title) {
                $counter++
                Write-Progress -PercentComplete ($counter / ($lists.Count) * 100) -Activity "Exporting Permissions from List '$($list.Title)' in $($web.URL)" -Status "Processing Lists $counter of $($lists.Count)" -Id 1

                # Get Item Level Permissions if 'ScanFolders' switch present
                if ($ScanFolders) {
                    # Get Folder Permissions
                    Get-PnPFolderPermission -List $list
                }

                # Get Lists with Unique Permissions or Inherited Permissions based on 'IncludeInheritedPermissions' switch
                if ($includeInheritedPermissions) {
                    Get-PnPPermissions -Object $list
                } else {
                    # Check if List has unique permissions
                    $hasUniquePermissions = Get-PnPProperty -ClientObject $list -Property HasUniqueRoleAssignments
                    if ($hasUniquePermissions -eq $true) {
                        # Call the function to check permissions
                        Get-PnPPermissions -Object $list
                    }
                }
            }
        }
        # $Global:ListPermissions = $Global:PnpPermissions
    }

    # Function to Get Webs's Permissions from given URL
    Function Get-PnPWebPermission([Microsoft.SharePoint.Client.Web]$web) {
        # Call the function to Get permissions of the web
        Write-host -f Yellow "Getting Permissions of the Web: $($web.URL)..."
        Get-PnPPermissions -Object $web

        # Get List Permissions
        Write-host -f Yellow "`t Getting Permissions of Lists and Libraries..."
        Get-PnPListPermission($web)

        # Recursively get permissions from all sub-webs based on the "Recursive" Switch
        if ($recursive) {
            # Get Subwebs of the Web
            $subwebs = Get-PnPProperty -ClientObject $web -Property Webs

            # Iterate through each subsite in the current web
            # Foreach ($subweb in $web.Webs) {
            Foreach ($subweb in $subwebs) {
                # Get Webs with Unique Permissions or Inherited Permissions based on 'IncludeInheritedPermissions' switch
                if ($includeInheritedPermissions) {
                    Get-PnPWebPermission($subweb)
                } else {
                    # Check if the Web has unique permissions
                    $hasUniquePermissions = Get-PnPProperty -ClientObject $subweb -Property HasUniqueRoleAssignments

                    # Get the Web's Permissions
                    if ($hasUniquePermissions -eq $true) { 
                        # Call the function recursively                            
                        Get-PnPWebPermission($subweb)
                    }
                }
            }
        }
    }    
    # Call the function with RootWeb to get site collection permissions
    Get-PnPWebPermission $web
}


## MAIN
try {
    # Warning
    if ($readOnly) {
        Write-Host "`n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!`n[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")]`nRunning in read-only mode!`nNo changes will be made to the environment!`n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!`n" -f Cyan
    } else {
        Write-Host "`n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!`n[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")]`nRunning in read-write mode!`nChanges will be made to the environment!`n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!`n" -f Red
        Write-Host "Press any key to continue..."
        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | out-null
    }

    $startTime = Get-Date

    # Connect to Azure AD and get users from the group that will have access to the folder
    Write-Host "Log in with an account that has administator permissions in Azure AD:" -f Yellow
    Connect-AzureAD
    $members = Get-AzureADGroupMember -ObjectId $accessGroup

    # Connect to SharePoint Online site
    Write-Host "Log in with an account that has administator permissions in the specified SharePoint Online:" -f Yellow 
    Connect-PnPOnline -Url $siteURL -Interactive    
    $web = Get-PnPWeb

    Write-Host "-------------------------------------------------" -f Yellow

    # Create a report file
    $global:permissionList = [System.Collections.Generic.List[Object]]::new() # Create output file
    Generate-PnPSitePermissionRpt -SiteURL $siteURL -Recursive -ScanFolders -IncludeInheritedPermissions
    
    Write-Host "-------------------------------------------------" -f Yellow
    Write-Host "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] ----- CHECKING PERMISSIONS AND GRANTING PERMISSIONS! -----`n" -f Yellow

    foreach ($folderName in $includedFolders) {
        # Get Application-Online folder items
        $folders = Get-PnPFolderItem -FolderSiteRelativeUrl "$parentFolderURL/$folderName" -ItemType Folder

        # Create or access the folders
        foreach ($folder in $folders) {
            Write-Progress -PercentComplete ($folders.IndexOf($folder) / ($folders.Count) * 100) -Activity "Processing Folder '$($folder.Name)'" -Status "Processing Folder $($folders.IndexOf($folder)) of $($folders.Count)" -Id 3
            try {
                $currentFolder = Get-PnPFolder -Url "$parentFolderURL/$folderName/$($folder.Name)/$targetFolder"
            } catch {
                if (!$readOnly) { $currentFolder = Resolve-PnPFolder -SiteRelativePath "$parentFolderURL/$folderName/$($folder.Name)/$targetFolder" }
                Write-Output "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Created folder '$parentFolderURL/$folderName/$($folder.Name)/$targetFolder'"
            }

            # Set credit folder permissions
            # Reset folder permissions    
            # if (!readOnly) { Get-PnPFolder -Url $currentFolder.ServerRelativeUrl | Set-PnPFolderPermission -List "$parentFolderURL" -InheritPermissions }

            # Iterate through each member of the group and set the '$roleName' permission
            foreach ($member in $members) {
                # Check if the user already has the '$roleName' permission
                $check = $false
                foreach ($permission in ($global:permissionList | Where-Object { $_.URL -like "*$($currentFolder.ServerRelativeUrl)*" })) {
                    if ($permission.Users -eq $member.UserPrincipalName -and $permission.Permissions -eq "$roleName") {
                        $check = $true
                    }
                }
            
                # Set permissions for users that are in the group
                if ($check) {
                    Write-Output "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] User '$($member.UserPrincipalName)' already has '$roleName' permissions on '$($currentFolder.ServerRelativeUrl)'"
                }
                else {
                    if (!$readOnly) { Set-PnPFolderPermission -List "$parentFolderURL" -Identity $currentFolder.ServerRelativeUrl -User $member.UserPrincipalName -AddRole $roleName }
                    Write-Output "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Set permissions for '$($member.UserPrincipalName)' on '$($currentFolder.ServerRelativeUrl)'"
                }
            }
        }
        Write-Progress -PercentComplete 100 -Activity "Processing folders" -Status "Done" -Id 3

        Write-Host "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Set permissions for users in group '$accessGroup'!`n" -f Yellow 

        Write-Host "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] ----- RECHECKING PERMISSIONS AND REMOVING UNAUTHORIZED USERS! -----`n" -f Yellow
    
        # Get Application-OnLine folder items
        $folders = Get-PnPFolderItem -FolderSiteRelativeUrl "$parentFolderURL/$folderName" -ItemType Folder

        # Access the folders for rechecking permissions
        foreach ($folder in $folders) {
            $currentFolder = Get-PnPFolder -Url "$parentFolderURL/$folderName/$($folder.Name)/$targetFolder"

            # $global:permissionList | Where-Object {$_.URL -like "*$($currentFolder.ServerRelativeUrl)*"} | Select-Object Object, Title, Users, Type, Permissions, GrantedThrough | Format-Table
        
            # Set credit folder permissions
            Write-Host "`n[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Checking permissions for '$($currentFolder.ServerRelativeUrl)'" -f Yellow 
            foreach ($permission in ($global:permissionList | Where-Object { $_.URL -like "*$($currentFolder.ServerRelativeUrl)*" })) {
                # Write-Host "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Permission: '$($permission.Users)' has '$($permission.Permissions)' permissions on $($permission.Object) '$($permission.Title)' ($($permission.URL))"

                # Remove permissions for users that are not in the group (ignore read permissions, and default group permissions)
                if ($permission.Permissions -ne 'Read' `
                        -and $permission.Users -notin ($members.UserPrincipalName) `
                        -and ($permission.Users -ne "$($web.Title) Owners" -and $permission.Permissions -ne "Full Control") `
                        -and ($permission.Users -ne "$($web.Title) Members" -and $permission.Permissions -ne "Edit") `
                        -and ($permission.Users -ne "$($web.Title) Visitors" -and $permission.Permissions -ne "Read")
                ) {
                    # -and $permission.Users -notin $siteDefaultGroups
                    Write-Output "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Removing permissions for '$($permission.Users)' on $($permission.Object) '$($permission.Title)' ($($permission.URL))"
                    if (!$readOnly) { Set-PnPFolderPermission -List "$parentFolderURL" -Identity $currentFolder.ServerRelativeUrl -User $member.UserPrincipalName -RemoveRole $($permission.Permissions) }
                }
            }
        }
   
        # Break inherited non-read permissions for Credit folder
    }

} catch {
    Write-Host "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Error: $($_.Exception.Message)" -foregroundcolor Red
    Write-Output "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Error: $($_.Exception.Message)"
}

$elapsedTime = (Get-Date) - $startTime
Write-Output $elapsedTime
