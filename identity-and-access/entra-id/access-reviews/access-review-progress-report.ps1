# Problem solved : Reviewers have not completed reviews and nobody tracks progress.
# What it does    : Collects review instances, decisions and reviewers (with managers) into Excel.
# Requires        : Microsoft.Graph.Identity.Governance, ImportExcel; AccessReview.Read.All, User.Read.All
# Effect          : read-only
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

###
# Install-Module ImportExcel
# Install-Module Microsoft.Graph
Import-Module ImportExcel
Import-Module Microsoft.Graph.Identity.Governance

##
$propertiesToReturn = [PSCustomObject]@{
    Users = @( "Id", "DisplayName", "UserPrincipalName", "AccountEnabled", "JobTitle", "Department", "CompanyName", "Country", "UserType", "CreatedDateTime", "DeletedDateTime")
}

$withManager = $true

##
Connect-MgGraph -Scopes "AccessReview.Read.All"


##
if ($withManager) {
    # USERS
    $users = Get-MgUser -All -Property $propertiesToReturn.Users | Sort-Object DisplayName | Select-Object $propertiesToReturn.Users
    $users | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "MemberType" -Value "User" }
    foreach ($u in $users) {
        Write-Progress -Id 1 -Activity "Processing users information..." -Status "( $($users.IndexOf($u)) / $($users.Count) ) Processing '$($u.DisplayName)'" -PercentComplete (($users.IndexOf($u) / $users.Count) * 100)

        # Get user manager
        try { $managerId = (Get-MgUserManager -UserId $u.Id -ErrorAction SilentlyContinue).Id }
        catch { $managerId = $null }
        
        if ($null -ne $managerId) {
            $manager = $users | Where-Object { $_.Id -eq $managerId } | Select-Object Id, DisplayName, UserPrincipalName
            $u | Add-Member -MemberType NoteProperty -Name "ManagerId" -Value $manager.Id
            $u | Add-Member -MemberType NoteProperty -Name "ManagerDisplayName" -Value $manager.DisplayName
            $u | Add-Member -MemberType NoteProperty -Name "ManagerUPN" -Value $manager.UserPrincipalName
        } else {
            $u | Add-Member -MemberType NoteProperty -Name "ManagerId" -Value $null
            $u | Add-Member -MemberType NoteProperty -Name "ManagerDisplayName" -Value $null
            $u | Add-Member -MemberType NoteProperty -Name "ManagerUPN" -Value $null
        }
    }
    Write-Progress -Id 1 -Completed
}

# Access reviews
$accessReviews = Get-MgIdentityGovernanceAccessReviewDefinition -All

$reviewReport = [System.Collections.Generic.List[Object]]::new()
foreach ($accessReview in $accessReviews) {
    Write-Progress -Id 1 -Activity "Processing access reviews" -Status "($($accessReviews.IndexOf($accessReview)) / $($accessReviews.Count)) Processing '$($accessReview.DisplayName)'" -PercentComplete (($accessReviews.IndexOf($accessReview) / $accessReviews.Count) * 100)

    $instances = $null
    $instances = [array](Get-MgIdentityGovernanceAccessReviewDefinitionInstance -AccessReviewScheduleDefinitionId "$($accessReview.Id)" -All)

    foreach ($instance in $instances) {
        Write-Progress -Id 2 -Parent 1 -Activity "Processing instances" -Status "($($instances.IndexOf($instance)) / $($instances.Count)) Processing '$($instance.Id)'" -PercentComplete (($instances.IndexOf($instance) / $instances.Count) * 100)

        $stages = $null
        $stages = [array](Get-MgIdentityGovernanceAccessReviewDefinitionInstanceStage -AccessReviewInstanceId $instance.Id -AccessReviewScheduleDefinitionId $accessReview.Id)

        foreach ($stage in $stages) {
            Write-Progress -Id 3 -Parent 2 -Activity "Processing stages" -Status "($($stages.IndexOf($stage)) / $($stages.Count)) Processing stage $($stages.IndexOf($stage) + 1)" -PercentComplete (($stages.IndexOf($stage) / $stages.Count) * 100)

            $stageDecisions = $null
            $stageDecisions = [array](Get-MgIdentityGovernanceAccessReviewDefinitionInstanceStageDecision -AccessReviewInstanceId $instance.Id -AccessReviewScheduleDefinitionId $accessReview.Id -AccessReviewStageId $stage.Id)

            foreach ($decision in $stageDecisions) {
                Write-Progress -Id 4 -Parent 3 -Activity "Processing stage decisions" -Status "($($stageDecisions.IndexOf($decision)) / $($stageDecisions.Count)) Processing '$($decision.Principal.AdditionalProperties['userPrincipalName'])'" -PercentComplete (($stageDecisions.IndexOf($decision) / $stageDecisions.Count) * 100)

                $reviewReport.Add([PSCustomObject]@{
                    AccessReviewId = $accessReview.Id
                    AccessReviewName = $accessReview.DisplayName
                    ReviewedObjectType = $decision.Resource.Type
                    ReviewedObjectName = $decision.Resource.DisplayName
                    ReviewedObjectId = $decision.Resource.Id
                    InstanceId = $instance.Id
                    InstanceStatus = $instance.Status
                    InstanceStartDateTime = $instance.StartDateTime
                    InstanceEndDateTime = $instance.EndDateTime
                    ReviewedUserId = $decision.Principal.Id
                    ReviewedUserPrincipalName = $decision.Principal.AdditionalProperties['userPrincipalName']
                    ReviewedUserDisplayName = $decision.Principal.DisplayName
                    StageId = $stage.Id
                    StageStartDateTime = $stage.StartDateTime
                    StageEndDateTime = $stage.EndDateTime
                    StageNumber = $stages.IndexOf($stage) + 1
                    StageStatus = $stage.Status
                    # DecisionApplyResult = $decision.ApplyResult
                    # DecisionInsights = $decision.Insights
                    # DecisionRecommendation = $decision.Recommendation
                    DecisionResult = $decision.Decision
                    DecisionJustification = $decision.Justification
                    ReviewedById = $decision.ReviewedBy.Id
                    ReviewedByDisplayName = $decision.ReviewedBy.DisplayName
                    ReviewedByPrincipalName = $decision.ReviewedBy.UserPrincipalName
                    ReviewedUserManagerId = if ($withManager) { $users | Where-Object { $_.Id -eq $decision.Principal.Id } | Select-Object -ExpandProperty ManagerId }
                    ReviewedUserManagerDisplayName = if ($withManager) { $users | Where-Object { $_.Id -eq $decision.Principal.Id } | Select-Object -ExpandProperty ManagerDisplayName }
                    ReviewedUserManagerUPN = if ($withManager) { $users | Where-Object { $_.Id -eq $decision.Principal.Id } | Select-Object -ExpandProperty ManagerUPN }
                })
            }
            Write-Progress -Id 4 -Parent 3 -Completed
        }
        Write-Progress -Id 3 -Parent 2 -Completed
    }
    Write-Progress -Id 2 -Parent 1 -Completed
}
Write-Progress -Id 1 -Completed


$reviewReport | Export-Excel


# Get-MgIdentityGovernanceAccessReviewDefinitionInstanceContactedReviewer -AccessReviewInstanceId $instance.Id -AccessReviewScheduleDefinitionId $accessReview.Id
# Get-MgIdentityGovernanceAccessReviewDefinitionInstanceStage -AccessReviewInstanceId $instance.Id -AccessReviewScheduleDefinitionId $accessReview.Id