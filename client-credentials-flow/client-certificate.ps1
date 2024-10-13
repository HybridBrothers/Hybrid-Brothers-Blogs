
######################################################
### Made by Cedric Braekevelt (hybridbrothers.com) ###
######################################################

function JWTTokenRetrieval {    
    param (
        [Parameter(Mandatory = $true)][System.Security.Cryptography.X509Certificates.X509Certificate2]$privatecertificate,
        [Parameter(Mandatory = $true)][String]$clientId,
        [Parameter(Mandatory = $true)][String]$tenantId,
        [Parameter(Mandatory = $true)][int]$jwtValidityInSeconds
    )

    ### JWT Headers ###
    $headers = @{
        typ = "JWT"
        alg = "RS512" 
        x5t = ([Convert]::ToBase64String($privatecertificate.GetCertHash())).Replace('+', '-').Replace('/', '_')
    }

    ### JWT Payload ###
    $payload = @{
        iss = $clientId
        sub = $clientId
        exp = [int][double]::parse((Get-Date -Date $((Get-Date).addseconds($jwtValidityInSeconds).ToUniversalTime()) -UFormat %s)) 
        aud = ("https://login.microsoftonline.com/{0}/oauth2/token" -f $tenantId)
        jti = [guid]::NewGuid()  
        nbf = [math]::Round((New-TimeSpan -Start (Get-Date) -End ((Get-Date).ToUniversalTime())).TotalSeconds, 0)
    }
        
    ### Parse both headers and payload to JSON and base64 encode ###
    $headersBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($headers | ConvertTo-Json -Compress))).Split('=')[0].Replace('+', '-').Replace('/', '_')
    $payloadBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Compress))).Split('=')[0].Replace('+', '-').Replace('/', '_')
    
    ### Combine both headers and payload into one object ###
    $rawPackage = [System.Text.Encoding]::UTF8.GetBytes("$($headersBase64).$($payloadBase64)")
    
    ### Sign package with private key of the certificate ###
    $signedPackage = [Convert]::ToBase64String($privatecertificate.PrivateKey.SignData($rawPackage, [Security.Cryptography.HashAlgorithmName]::SHA512, [Security.Cryptography.RSASignaturePadding]::Pkcs1))
    
    ### Combine both headers, payload and signature into one object. This is the JWT ###
    $token = "$($headersBase64).$($payloadBase64).$($signedPackage)"
    return $token
}

function PowershellClientCredentialsLogin {
    param (
        [Parameter(Mandatory = $true)][String]$clientId,
        [Parameter(Mandatory = $true)][String]$tenantId,
        [Parameter(Mandatory = $true)][System.Security.Cryptography.X509Certificates.X509Certificate2]$privatecertificate,
        [Parameter(Mandatory = $false)][int]$jwtValidityInSeconds = 30,
        [Parameter(Mandatory = $false)][String]$scope = 'https://management.azure.com/.default'
    )
    ### Static vars ###
    $tokenUrl = ('https://login.microsoftonline.com/{0}/oauth2/v2.0/token' -f $tenantId)

    ### Build the body for the JWT generation function ###
    $JWTParams = @{
        privatecertificate   = $privatecertificate
        clientId             = $clientId
        tenantId             = $tenantId
        jwtValidityInSeconds = $jwtValidityInSeconds
    }
        
    ### Build the body for the clientCertificate flow ###
    $body = @{
        client_id             = $clientId
        tenant                = $tenantId
        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
        client_assertion      = JWTTokenRetrieval @JWTParams
        grant_type            = "client_credentials"
        scope                 = $scope
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

### Option A: Retrieve certificate with private key from Azure Key Vault ###
$keyVaultName = "{KevVaultName}"
$certificateName = "{CertificateName}"
$privateCertficate = [Convert]::FromBase64String((Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $certificateName -AsPlainText))
$privateCertificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList (, $privateCertficate) 

### Option B: Retrieve certificate with private key from file system ###
$clearPassword = "hybridbrothers.com"
$privateCertificateObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList ("private.pfx", $clearPassword)  

### Retrieve access token using client certificate ###
$tokens = PowershellClientCredentialsLogin -tenantId "{TenantId}" -clientId "{ClientId}" -privatecertificate $privateCertificateObject