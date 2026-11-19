# Problem solved : Inactive accounts stay enabled and unnoticed.
# What it does    : Exports users with last sign-in activity to Excel.
# Requires        : Microsoft.Graph.Beta.Users, ImportExcel; AuditLog.Read.All, Directory.Read.All
# Effect          : read-only
# Known issues    : Uses beta endpoint; requires Entra ID P1/P2
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Beta.Users
Import-Module ImportExcel

##
Connect-MgGraph -Scopes "Directory.Read.All", "AuditLog.Read.All"
# Select-MgProfile -Name "beta"

# $users = Get-MgBetaUser -All -Filter "AccountEnabled eq true" -Property @('Id','displayName','userPrincipalName','signInActivity','JobTitle','Department','AccountEnabled','CreatedDateTIme') | Select-Object Id,displayName,userPrincipalName,signInActivity,JobTitle,Department,AccountEnabled,CreatedDateTIme

$users = Get-MgBetaUser -All -Property @('Id','displayName','userPrincipalName','signInActivity','JobTitle','Department','AccountEnabled','CreatedDateTIme') | Select-Object Id,displayName,userPrincipalName,signInActivity,JobTitle,Department,AccountEnabled,CreatedDateTIme



$outputReport = @()
foreach ($u in $users) {
    $outputReport += [PSCustomObject]@{
        AccountObjectId = $u.Id
        DisplayName = $u.displayName
        UserPrincipalName = $u.userPrincipalName
        LastSignInDateTime = $u.signInActivity.LastSignInDateTime
        LastNonInteractiveSignInDateTime = $u.signInActivity.LastNonInteractiveSignInDateTime
        JobTitle = $u.JobTitle
        Department = $u.Department
        AccountEnabled = $u.AccountEnabled
        CreatedDateTIme = $u.CreatedDateTIme
    }
}

$outputReport 

$outputReport | Export-Excel

# $users = Get-MgUser -All -Filter "AccountEnabled eq true" | Select-Object accountObjectId,displayName,userPrincipalName,signInActivity,JobTitle,Department,AccountEnabled,CreatedDateTIme
# $users = Get-MgUser -All -Filter "AccountEnabled eq true"
#  -Property "displayName,userPrincipalName,signInActivity,JobTitle,Department,AccountEnabled" 
