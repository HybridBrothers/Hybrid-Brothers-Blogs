[CmdletBinding()]
param (
    [Parameter (Mandatory=$true)]
    [string] $resourceGroupName,
    [Parameter (Mandatory=$true)]
    [string] $workspaceName
)


# --------------------
# Set parameters
# --------------------
# Get the context
$context = Get-AzContext
$azureProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azureProfile)
# Save auth header and subscription
$token = $profileClient.AcquireAccessToken($context.Subscription.TenantId)
$authHeader = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $token.AccessToken
}
$SubscriptionId = $context.Subscription.Id
# Create body
$body = @{
    "subscriptions" = @($SubscriptionId)
}
# Generate URL
$uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$workspaceName/providers/Microsoft.SecurityInsights/alertruletemplates?api-version=2022-11-01-preview"


# --------------------
# Save templates
# --------------------
# Get templates and convert them
$verdict = Invoke-RestMethod -Uri $uri -Method Get -Headers $authHeader -Body $body
$templates = $verdict.value | ConvertTo-Json -Depth 10 | ConvertFrom-Json
# Loop through each template
$templates | ForEach-Object {
    # Replace illegal characters
    $displayName = $_.properties.displayName
    if ($displayName -match '/') { 
        $displayname = $displayName.replace('/', ' or ') | Out-Null
    }
    # Add required parameter that is not included in template
    $_.properties | Add-Member -NotePropertyName "suppressionDuration" -NotePropertyValue "PT5H"
    $_.properties | Add-Member -NotePropertyName "suppressionEnabled" -NotePropertyValue $false
    $_.properties | Add-Member -NotePropertyName "enabled" -NotePropertyValue $true
    $_.properties | Add-Member -NotePropertyName "alertRuleTemplateName" -NotePropertyValue $_.name
    $_.properties | Add-Member -NotePropertyName "templateVersion" -NotePropertyValue $_.properties.version
    # Save correct kind under correct folder
    if ($_.kind -eq "MLBehaviorAnalytics") { $_ | ConvertTo-Json -Depth 10 | Out-File -Force -FilePath ".\ml\$($displayName).json" }
    elseif ($_.kind -eq "Scheduled") { $_ | ConvertTo-Json -Depth 10 | Out-File -Force -FilePath ".\scheduled\$($displayName).json" }
    elseif ($_.kind -eq "ThreatIntelligence") { $_ | ConvertTo-Json -Depth 10 | Out-File -Force -FilePath ".\ti\$($displayName).json" }
    elseif ($_.kind -eq "MicrosoftSecurityIncidentCreation") { $_ | ConvertTo-Json -Depth 10 | Out-File -Force -FilePath ".\microsoft-security\$($displayName).json" }
    elseif ($_.kind -eq "Fusion") { $_ | ConvertTo-Json -Depth 10 | Out-File -Force -FilePath ".\fusion\$($displayName).json" }
    elseif ($_.kind -eq "NRT") { $_ | ConvertTo-Json -Depth 10 | Out-File -Force -FilePath ".\nrt\$($displayName).json" }
    else { $_ | ConvertTo-Json -Depth 10 | Out-File -Force -FilePath "$($displayName).json" }
}