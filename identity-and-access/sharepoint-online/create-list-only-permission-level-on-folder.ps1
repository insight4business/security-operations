# Problem solved : Users should see file names in a folder but not open them.
# What it does    : Creates a custom permission level (view items, browse directories) and applies it to a folder for a user or group.
# Requires        : PnP.PowerShell; Site Owner/Admin
# Effect          : changes-state (review and test before use)
# Known issues    : Portuguese; stray Install-Module and a connection to the tenant root before the real connection; placeholders 'seudominio', 'grupo@example.com', list 'Tests'.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

Install-Module -Name "PnP.PowerShell" -Force
Connect-PnPOnline -Url "https://ENTRE_AQUI_COM_SEU_TENANT.sharepoint.com/" -Interactive


# Configurações principais
$siteUrl = "https://seudominio.sharepoint.com/sites/ENTRE_AQUI_COM_SEU_SITE"
$listName = "Tests"  # Nome interno da biblioteca
$targetFolder = "1"  # Nome da pasta onde aplicar permissão
$userOrGroup = "grupo@example.com"  # Pode ser UPN ou nome do grupo do SharePoint
$customRoleName = "Listar conteúdo"

# Conectar ao site
Connect-PnPOnline -Url $siteUrl -Interactive

# Verificar se o nível de permissão personalizado já existe
$roleExists = Get-PnPRoleDefinition | Where-Object { $_.Name -eq $customRoleName }

if (-not $roleExists) {
    Write-Host "Criando nível de permissão: $customRoleName"
    New-PnPRoleDefinition -Name $customRoleName -Description "Permitir apenas listagem de arquivos e pastas." -BasePermissions @(
        "ViewListItems",      # Ver itens
        "OpenItems",          # Ver propriedades
        "ViewPages",          # Navegar
        "BrowseDirectories"   # Ver estrutura de pastas
    )
}

# Buscar item da pasta alvo
$item = Get-PnPListItem -List $listName -PageSize 1000 | Where-Object { $_["FileLeafRef"] -eq $targetFolder -and $_.FileSystemObjectType -eq "Folder" }

if ($item) {
    Write-Host "Quebrando herança da pasta '$targetFolder'"
    Set-PnPListItemPermission -List $listName -Identity $item.Id -BreakRoleInheritance -ClearExistingPermissions:$true

    Write-Host "Aplicando permissão '$customRoleName' ao usuário/grupo '$userOrGroup'"
    Set-PnPListItemPermission -List $listName -Identity $item.Id -User $userOrGroup -AddRole $customRoleName
} else {
    Write-Host "❌ Pasta '$targetFolder' não encontrada."
}
