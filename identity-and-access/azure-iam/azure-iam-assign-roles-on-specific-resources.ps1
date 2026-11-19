# Problem solved : Grant groups access to specific resources.
# What it does    : Assigns roles to objects on a list of resources.
# Requires        : Az.Resources
# Effect          : changes-state (review and test before use)
# Known issues    : Commented client group names (ENTRE_AQUI_COM_SEU_GRUPO*) to scrub
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

$subscriptionId = "ENTRE_AQUI_COM_SEU_ID"

Connect-AzAccount -Subscription $subscriptionId | Out-Null

## MAIN
$rolesToAssign = @(
    # "ENTRE_AQUI_COM_SEU_ID" # Azure Custom Role - Tech Lead - Writer
    # "ENTRE_AQUI_COM_SEU_ID" # Contributor
    # "ENTRE_AQUI_COM_SEU_ID" # Reader
)

$resourcesToAssign = @(
  
)

$objectsToAssignTo = @(
    # "ENTRE_AQUI_COM_SEU_ID" # ENTRE_AQUI_COM_SEU_GRUPO
    # "ENTRE_AQUI_COM_SEU_ID" # ENTRE_AQUI_COM_SEU_GRUPO
    # "ENTRE_AQUI_COM_SEU_ID" # ENTRE_AQUI_COM_SEU_GRUPO
    # "ENTRE_AQUI_COM_SEU_ID" # ENTRE_AQUI_COM_SEU_GRUPO
    # "ENTRE_AQUI_COM_SEU_ID" # ENTRE_AQUI_COM_SEU_GRUPO
    # "ENTRE_AQUI_COM_SEU_ID" # ENTRE_AQUI_COM_SEU_GRUPO
    # "ENTRE_AQUI_COM_SEU_ID" # ENTRE_AQUI_COM_SEU_GRUPO
    # "ENTRE_AQUI_COM_SEU_ID" # ENTRE_AQUI_COM_SEU_GRUPO
    # "ENTRE_AQUI_COM_SEU_ID" # ENTRE_AQUI_COM_SEU_GRUPO
    # "ENTRE_AQUI_COM_SEU_ID" # ENTRE_AQUI_COM_SEU_GRUPO

)

# Assign
foreach ($resource in $resourcesToAssign) {
    foreach ($r in $rolesToAssign) {
        foreach ($o in $objectsToAssignTo) {
            # New-AzRoleAssignment -ObjectId $o -RoleDefinitionId $r -Scope $resource
            if ($?) { Write-Output "Assigned role '$($r)' to '$($o)' in '$($resource)'"}
        } 
    }
}

