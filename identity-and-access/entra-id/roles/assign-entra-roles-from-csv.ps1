# Problem solved : Role assignments are made ad hoc without a reviewed list.
# What it does    : Reads CSV and assigns directory roles to principals (assignment line commented).
# Requires        : Microsoft.Graph.Identity.Governance; RoleManagement.ReadWrite.Directory
# Effect          : changes-state (review and test before use)
# Known issues    : New-MgRoleManagementDirectoryRoleAssignment commented; path placeholder; prefer PIM eligible assignments
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module Microsoft.Graph
# Install-Module ImportExcel
Import-Module Microsoft.Graph.Identity.Governance
Import-Module ImportExcel


##
$path = "ENTRE_AQUI_COM_SEU_CAMINHO"


##
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory"


## MAIN
$csv = Import-Csv -Path $path -Delimiter ";"


# Assign
foreach ($row in $csv) {
    # New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $row.AssignToId -RoleDefinitionId $row.RoleDefinitionId -DirectoryScopeId $row.DirectoryScopeId

    if ($?) {
        Write-Host "Assigned role '$($row.RoleDisplayName)' to '$($row.AssignToId)' in '$($row.DirectoryScopeType)' '$($row.DirectoryScopeId)' ($($row.DirectoryScopeName))" -ForegroundColor Green
    }
}
