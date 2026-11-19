# Problem solved : Group memberships are never re-certified by users and managers.
# What it does    : Creates two-stage (user, manager) recurring access reviews for each group in a CSV.
# Requires        : Microsoft.Graph.Identity.Governance, Groups; AccessReview.ReadWrite.All, Group.Read.All
# Effect          : changes-state (review and test before use)
# Known issues    : CSV path placeholder; review CSV delimiter ';'
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
### Creates default access reviews (stage 1 = user; stage 2 = manager) for groups based on CSV data.
###
# Install-Module Microsoft.Graph
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Identity.Governance
Import-Module Microsoft.Graph.Groups


##
Connect-MgGraph -Scopes "AccessReview.ReadWrite.All", "Group.Read.All"


## Read from CSV
# CSV Fields: GroupId, GroupDisplayName, FallbackReviewersGroupId, Stage1Duration, Stage2Duration, RecurrenceIntervalInMonths, RecurrenceStartDate, RequireJustification, AutoApplyDecisions, DefaultDecisionEnabled, DefaultDecision
$path = "ENTRE_AQUI_COM_SEU_CAMINHO"

$csv = Import-Csv -Path $path -Delimiter ";"


## List existing access reviews
$existingAccessReviews = Get-MgIdentityGovernanceAccessReviewDefinition -All
$groups = Get-MgGroup -All


##
foreach ($row in $csv) {
	$reviewedGroup = [PSCustomObject]@{
		Id = $row.GroupId
		DisplayName = $row.GroupDisplayName
		GroupDetails = $groups | Where-Object { $_.Id -eq $row.GroupId }
	}


	$accessReview = [PSCustomObject]@{
		displayName = "Group Access Review - $($reviewedGroup.DisplayName)"
		descriptionForAdmins = "Scheduled access review for group $($reviewedGroup.Id). If you have any questions, contact Security team at ENTRE_AQUI_COM_SEU_EMAIL@example.com.`nGroup description: $($reviewedGroup.GroupDetails.Description)"
		descriptionForReviewers = "Scheduled access review for group $($reviewedGroup.Id). If you have any questions, contact Security team at ENTRE_AQUI_COM_SEU_EMAIL@example.com.`nGroup description: $($reviewedGroup.GroupDetails.Description)"
	}

	$result = $null

	# If access review does not exist, create it
	if ($accessReview.displayName -notin ($existingAccessReviews.DisplayName)) {
		$fallbackReviewersGroupId = $row.FallbackReviewersGroupId

		## 
		# Create an access review on a group with multiple stages
		$params = @{
			displayName = $accessReview.displayName
			descriptionForAdmins = $accessReview.descriptionForAdmins
			descriptionForReviewers =  $accessReview.descriptionForReviewers
			scope = @{
				"@odata.type" = "#microsoft.graph.accessReviewQueryScope"
				query = "/groups/$($reviewedGroup.Id)/transitiveMembers"
				queryType = "MicrosoftGraph"
			}
			stageSettings = @(
				@{
					stageId = "1"
					durationInDays = $row.Stage1Duration
					decisionsThatWillMoveToNextStage = @(
						"NotReviewed"
						"Approve"
						"DontKnow"
					)
					reviewers = @()
				}
				@{
					stageId = "2"
					dependsOn = @(
						"1"
					)
					durationInDays = $row.Stage2Duration
					recommendationsEnabled = $true
					reviewers = @(
						@{
							query = "./manager"
							queryType = "MicrosoftGraph"
							queryRoot = "decisions"
						}
					)
					fallbackReviewers = @(
						@{
							query = "/groups/$fallbackReviewersGroupId/transitiveMembers"
							queryType = "MicrosoftGraph"
						}
					)
				}
			)
			settings = @{
				instanceDurationInDays = 30
				mailNotificationsEnabled = $true
				reminderNotificationsEnabled = $true
				justificationRequiredOnApproval = $row.RequireJustification
				defaultDecisionEnabled = $row.DefaultDecisionEnabled
				defaultDecision = $row.DefaultDecision
				autoApplyDecisionsEnabled = $row.AutoApplyDecisions
				recommendationsEnabled = $false
				decisionHistoriesForReviewersEnabled = $true
				recurrence = @{
					pattern = @{
						type = "absoluteMonthly"
						interval = $($row.RecurrenceIntervalInMonths)
						dayOfMonth = 0
					}
					range = @{
						type = "noEnd"
						startDate = "$($row.RecurrenceStartDate)"
					}
				}
			}
		}

		# $result = New-MgIdentityGovernanceAccessReviewDefinition -BodyParameter $params
		if ($?) { Write-Host "Created access review '$($accessReview.displayName)'..." -ForegroundColor Green }
	} else {
		Write-Host "Access review '$($accessReview.displayName)' already exists." -ForegroundColor Yellow
	}
	
	if ($result) {
        $targetGroup = ($result.Scope.AdditionalProperties.query -split "/")[2]
        if ($targetGroup -ne $reviewedGroup.Id) {
            Write-Host "ERROR: Access review '$($accessReview.displayName)' created incorrectly" -ForegroundColor Red
        }
    }
}
