
######################################################
### Made by Cedric Braekevelt (hybridbrothers.com) ###
######################################################

function PowershellClientCredentialsLogin {
    param (
        [Parameter(Mandatory = $true)][String]$clientId,
        [Parameter(Mandatory = $true)][String]$tenantId,
        [Parameter(Mandatory = $true)][String]$clientSecret,
        [Parameter(Mandatory = $false)][String]$scope = 'https://management.azure.com/.default'
    )
    ### Static vars ###
    $tokenUrl = ('https://login.microsoftonline.com/{0}/oauth2/v2.0/token' -f $tenantId)

    ### Build the body for the clientSecret flow ###
    $body = @{
        client_id     = $clientId
        tenant        = $tenantId
        client_secret = $clientSecret
        grant_type    = "client_credentials"
        scope         = $scope
    }

    ### Call token endpoint to retrieve access token ###
    $response = Invoke-WebRequest -Method Post -Uri $tokenUrl -Body $body
    if ($response.StatusCode -eq "200") {
        $content = ($response.Content | ConvertFrom-Json)
        return @{
            access_token = $content.access_token
        }
    }
    else {
        Write-Warning "Access Code retrieval failed: $($response.StatusCode)"
    }
}

### Retrieve access token using client secret ###
$tokens = PowershellClientCredentialsLogin -tenantId "{TenantId}" -clientId "{ClientId}" -clientSecret "{ClientSecret}"