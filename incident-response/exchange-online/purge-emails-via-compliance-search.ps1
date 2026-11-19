# Problem solved : A phishing or misdirected e-mail must be removed from user mailboxes.
# What it does    : Connects to Security & Compliance and runs a HardDelete purge action on an existing Compliance search.
# Requires        : ExchangeOnlineManagement (Connect-IPPSSession); eDiscovery Manager + Search And Purge role
# Effect          : destructive (review and test before use)
# Known issues    : HardDelete is irreversible; search name contains personal names ('ENTRE_AQUI_COM_SEU_NOME email to ENTRE_AQUI_COM_SEU_NOME') that must be removed; add a preview step.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###

Import-Module ExchangeOnlineManagement

$userPrincipalName = 'ENTRE_AQUI_COM_SEU_EMAIL@example.com'
$searchName = 'ENTRE_AQUI_COM_SEU_NOME email to ENTRE_AQUI_COM_SEU_NOME'


##
# 1. Create search in (https://compliance.microsoft.com/contentsearchv2?viewid=search&tid=ENTRE_AQUI_COM_SEU_ID)
# 2. Check search results
# 3. Purge emails


Connect-IPPSSession -UserPrincipalName $userPrincipalName

# New-ComplianceSearchAction -SearchName $searchName -Purge -PurgeType SoftDelete
New-ComplianceSearchAction -SearchName $searchName -Purge -PurgeType HardDelete