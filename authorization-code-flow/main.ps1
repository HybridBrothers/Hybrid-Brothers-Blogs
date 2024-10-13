
######################################################
### Made by Cedric Braekevelt (hybridbrothers.com) ###
######################################################

function AuthorizationCodeRetrieval {
  param (
    [Parameter(Mandatory = $true)][String]$clientId,
    [Parameter(Mandatory = $true)][String]$scope,
    [Parameter(Mandatory = $true)][String]$tenantId,
    [Parameter(Mandatory = $true)][String]$redirectUri,
    [Parameter(Mandatory = $false)][Bool]$logoutAfterAuth
  )
  ### Static vars ###
  $authUrl = ('https://login.microsoftonline.com/{0}/oauth2/v2.0/authorize' -f $tenantId)

  ### Optional redirect towards logout page ###
  if ($logoutAfterAuth) {
    $htmlScript = @"
      <script>
        // Function to redirect to another page
        function redirect() {
          window.location.href = "https://login.microsoftonline.com/common/oauth2/logout"; 
        }
        
        // Countdown timer function
        function startCountdown() {
          var countdown = 10; // Countdown in seconds
        
          var countdownInterval = setInterval(function() {
            countdown--;
            
            // Display the countdown
            document.getElementById("countdown").textContent = countdown;
            
            // If countdown reaches 0, redirect to another page
            if (countdown <= 0) {
              clearInterval(countdownInterval);
              redirect();
            }
          }, 1000); // Update every second
        }
        
        // Start the countdown when the page loads
        window.onload = function() {
          startCountdown();
        };
      </script>
"@

    $htmlText = @'
      <p>You will be logged out in <span id="countdown">10</span> seconds.</p>
'@
  }
  else {
    $htmlScript = ""
    $htmlText = @'
      <p>You can close this window now.</p>
'@
  }

  ### Page to be returned after logon ###
  $html = @"
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
      <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">
      <title>Login Successful</title>
      <style>
        body {
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
          background-color: #f5f5f5;
        }
        
        .card {
          padding: 24px;
          width: 400px;
          text-align: center;
        }
        
        .material-icons {
          vertical-align: middle;
        }
      </style>
      $htmlScript
    </head>
    <body>
      <div class="card">
        <h3>You are now logged in!</h3>
        $htmlText
        <i class="material-icons">done</i>
      </div>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
    </body>
    </html>
"@

  ### Generate a random string to use as the code verifier to prevent man in the middle attacks ###
  $code_verifier = [Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(32)).Replace('+', '-').Replace('/', '_').Replace('=', '')
  $code_verifier_bytes = [System.Text.Encoding]::UTF8.GetBytes($code_verifier)
  $code_verifier_hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($code_verifier_bytes)
  $code_challenge = [Convert]::ToBase64String($code_verifier_hash).Replace('+', '-').Replace('/', '_').Replace('=', '')

  $state = -join ([char[]]'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789' | Get-Random -Count 32)

  ### Generate hashtable with querystring values ###
  $params = @{
    response_type         = 'code'
    client_id             = $clientId
    redirect_uri          = $redirectUri
    scope                 = $scope
    prompt                = 'select_account'
    state                 = $state
    code_challenge        = $code_challenge
    code_challenge_method = 'S256'
  }

  ### Convert the hashtable to a querystring using HttpUtility ###
  $queryString = [System.Web.HttpUtility]::ParseQueryString("")
  foreach ($param in $params.GetEnumerator()) {
    $queryString.Add([System.Web.HttpUtility]::UrlEncode($param.Key), $param.Value)
  }
  $queryStringStr = $queryString.ToString()

  ### Construct the complete URI with the querystring ###
  $uri = New-Object System.UriBuilder($authUrl)
  $uri.Query = $queryStringStr

  ### Start listener on localhost ###
  $httpListener = New-Object System.Net.HttpListener
  $httpListener.Prefixes.Add($redirectUri + '/')
  $httpListener.Start()

  ### Start default browser with authorization url ###
  Start-Process $uri

  try {

    ### Async wait for the authorization token to be returned ###
    $contextTask = $httpListener.GetContextAsync()
    while (-not $contextTask.AsyncWaitHandle.WaitOne(200)) { }
    $context = $contextTask.GetAwaiter().GetResult()

    ### Return the html to show that the user is logged in ###
    $response = $context.Response
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
    $response.ContentType = "text/html"
    $response.ContentEncoding = [System.Text.Encoding]::UTF8
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()

    ### Extract the authorizaton code from the response ###
    $authCode = [System.Web.HttpUtility]::ParseQueryString($context.Request.Url.Query)['code']

  }
  catch {
    Write-Warning ("Authorization code retrieval failed: {0}" -f $Error[0].Exception.Message)
  }
  finally {
    $httpListener.Stop()
  }

  return @{
    authcode      = $authCode
    code_verifier = $code_verifier
  } 
}

function AccessTokenRetrieval {
  param (
    [Parameter(Mandatory = $true)][String]$clientId,
    [Parameter(Mandatory = $true)][String]$tenantId,
    [Parameter(Mandatory = $true)][String]$redirectUri,
    [Parameter(Mandatory = $true)][String]$authCode,
    [Parameter(Mandatory = $true)][String]$code_verifier
  )
  ### Static vars ###
  $tokenUrl = ('https://login.microsoftonline.com/{0}/oauth2/v2.0/token' -f $tenantId)

  ### Generate hashtable with querystring values ###
  $body = @{
    grant_type    = 'authorization_code'
    client_id     = $clientId
    redirect_uri  = $redirectUri
    code          = $authCode
    code_verifier = $code_verifier
  }

  ### Call token endpoint to exchange authorization token for access token ###
  $response = Invoke-WebRequest -Method Post -Uri $tokenUrl -Body $body
  if ($response.StatusCode -eq "200") {
    $content = ($response.Content | ConvertFrom-Json)
    return @{
      access_token  = $content.access_token
      refresh_token = $content.refresh_token
      id_token      = $content.id_token
    }
  }
  else {
    Write-Warning "Access Code retrieval failed: $($response.StatusCode)"
  }
}

function PowershellAuthorizationCodeLogin {
  param (
    [Parameter(Mandatory = $false)][String]$clientId = '1950a258-227b-4e31-a9cf-717495945fc2',
    [Parameter(Mandatory = $false)][String]$scope = 'https://management.azure.com/.default openid profile email offline_access',
    [Parameter(Mandatory = $false)][String]$tenantId = 'common',
    [Parameter(Mandatory = $false)][Bool]$logoutAfterAuth = $false
  )
    
  ### Variables ###
  $redirectUri = 'http://localhost:8400'
  $commonParams = @{
    clientId    = $clientId
    tenantId    = $tenantId
    redirectUri = $redirectUri
  }

  ### Call authorization code function ###
  $AuthorizationCodeFlowParams = $commonParams.Clone()
  $AuthorizationCodeFlowParams.Add("logoutAfterAuth", $logoutAfterAuth)
  $AuthorizationCodeFlowParams.Add("scope", $scope)
  $authParams = AuthorizationCodeRetrieval @AuthorizationCodeFlowParams

  ### Call access token function ###
  $accessTokenRetrievalParams = $commonParams.Clone()
  $accessTokenRetrievalParams.Add("authCode", $authParams.authCode)
  $accessTokenRetrievalParams.Add("code_verifier", $authParams.code_verifier)
  $accessToken = AccessTokenRetrieval @accessTokenRetrievalParams

  ### Return access and refresh token if offline_access has been added to scopes ###
  return $accessToken
}

### Call authentication function ###
$tokens = PowershellAuthorizationCodeLogin