[CmdletBinding()]
param(
    [Parameter(
        Mandatory = $True,
        Position = 0,
        HelpMessage = "Enter your SubscriptionId (where you have owner permissions)"
    )]
    [string]
    $SubscriptionId
)


# init
$blueprintName = "Blueprint-RG-WestEu-vm-win0"
$assignmentName = "Assignment-" + $blueprintName
$assignmentFile = $blueprintName + "\BlueprintAssignment.json"
$assignmentFileOriginal = $blueprintName + "\BlueprintAssignmentOriginal.json"

$SubscriptionIdPlaceholder = "AAAABBBB-CCCC-DDDD-EEEE-FFFFGGGGHHHH"


# subscription select
Select-AzSubscription $SubscriptionId

# create blueprint assignemt file
Copy-Item -Path $assignmentFileOriginal -Destination $assignmentFile -Force
# replace SubscriptionId in blueprint assignment file
((Get-Content -Path $assignmentFile -Raw) -replace $SubscriptionIdPlaceholder, $SubscriptionId) | Set-Content -Path $assignmentFile

# import blueprint
Import-AzBlueprintWithArtifact -Name $blueprintName -InputPath $blueprintName -Force -SubscriptionId $subscriptionId

$bp = Get-AzBlueprint -Name $blueprintName -SubscriptionId $subscriptionId
$bpLastVersion = $bp.Versions[-1]
if ($null -eq $bpLastVersion) {
    [int]$bpVersion = 1
}
else {
    [int]$bpVersion = [int]$bpLastVersion + 1
}

# publish blueprint
Publish-AzBlueprint -Version $bpVersion -Blueprint $bp


# assign blueprint
$assignment = Get-AzBlueprintAssignment -Name $assignmentName -SubscriptionId $subscriptionId -ErrorAction Ignore
if ($null -eq $assignment) {
    "Blueprint Assignment does not exist - New assignment"
    New-AzBlueprintAssignment -Name $assignmentName -Blueprint $bp -SubscriptionId $subscriptionId -AssignmentFile $assignmentFile
}
else {
    "Blueprint Assignment already exists - Updating assignment"
    Set-AzBlueprintAssignment -Name $assignmentName -Blueprint $bp -SubscriptionId $subscriptionId -AssignmentFile $assignmentFile
}


# cleanup
# Remove-Item $assignmentFile
