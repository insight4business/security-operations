# Problem solved : Cannot see how each access review is configured and which group it covers.
# What it does    : Lists access review definitions with settings and the reviewed group.
# Requires        : Microsoft.Graph.Identity.Governance, Groups; AccessReview.Read.All
# Effect          : read-only
# Known issues    : Header comment copied from creation script (wrong); requests ReadWrite scope though read-only
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
### Creates default access reviews (stage 1 = user; stage 2 = manager) for groups based on CSV data.
###
# Install-Module Microsoft.Graph
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Identity.Governance


##
Connect-MgGraph -Scopes "AccessReview.ReadWrite.All", "Group.Read.All"


## List existing access reviews and groups
$existingAccessReviews = Get-MgIdentityGovernanceAccessReviewDefinition -All
$groups = Get-MgGroup -All


##
$output = @()
foreach ($ar in $existingAccessReviews) {
	Write-Progress -Id 1 -Activity "Processing access reviews..." -Status "($($existingAccessReviews.IndexOf($ar)) / $($existingAccessReviews.Count)) Processing $($ar.DisplayName)" -PercentComplete (($existingAccessReviews.IndexOf($ar) / $existingAccessReviews.Count) * 100)

	$reviewedGroup = [PSCustomObject]@{
		AccessReviewId = $ar.Id
        AccessReviewName = $ar.DisplayName  
        AccessReviewDisplayName = $ar.DisplayName
        # Current descriptions
        AccessReviewDescriptionForAdmins = $ar.DescriptionForAdmins
        AccessReviewDescriptionForReviewers = $ar.DescriptionForReviewers
        # New descriptions
        AccessReviewNew_DescriptionForAdmins = $null
        AccessReviewNew_DescriptionForReviewers = $null
		GroupId = $ar.InstanceEnumerationScope.AdditionalProperties.query -split "groups/|'" | Select-Object -Last 1
		DisplayName = $null
		Description = $null
		# FullObject = $ar
	}

	$group = $groups | Where-Object { $_.Id -eq $reviewedGroup.GroupId }

    if ($group) {
        $reviewedGroup.DisplayName = $group.DisplayName
        $reviewedGroup.Description = $group.Description
    }

	$reviewedGroup.AccessReviewNew_DescriptionForAdmins = "Scheduled access review for group $($reviewedGroup.GroupId). If you have any questions, contact Security team at ENTRE_AQUI_COM_SEU_EMAIL@example.com.`nGroup description: '$($reviewedGroup.Description)'"

	$reviewedGroup.AccessReviewNew_DescriptionForReviewers = "Scheduled access review for group $($reviewedGroup.GroupId). If you have any questions, contact Security team at ENTRE_AQUI_COM_SEU_EMAIL@example.com.`nGroup description: '$($reviewedGroup.Description)'"

    $output += $reviewedGroup

}
Write-Progress -Id 1 -Completed

$output | Export-Excel
