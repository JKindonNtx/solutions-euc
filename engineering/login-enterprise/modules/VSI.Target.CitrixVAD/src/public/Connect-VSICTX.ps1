function Connect-VSICTX {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'CitrixCloud')]
        $ClientID,
        [Parameter(Mandatory = $true, ParameterSetName = 'CitrixCloud')]
        $Secret,
        [Parameter(Mandatory = $true, ParameterSetName = 'CitrixCloud')]
        $CustomerID,
        [Parameter(Mandatory = $true, ParameterSetName = 'OnPrem')]
        $DDC
    )
    if ($null -ne $DDC) {
        Set-XDCredentials -ProfileType OnPrem -StoreAs ctxonprem
        Get-XDAuthentication -ProfileName ctxonprem
        Get-BrokerSite -AdminAddress $DDC | Out-Null
    }
    if ($null -ne $ClientID) {
        $tokenUrl = 'https://api-us.cloud.com/cctrustoauth2/root/tokens/clients'

        # Obtain bearer token from authorization server
        $response = Invoke-WebRequest $tokenUrl -Method POST -UseBasicParsing -Body @{
            grant_type    = "client_credentials"
            client_id     = $ClientID
            client_secret = $Secret
        }
        $token = $response.Content | ConvertFrom-Json
        $global:VSICTX_AuthHeader = @{
            "Authorization" = "CwsAuth Bearer=$($token.access_token)"
        }
        $global:VSICTX_VADHeader = $global:VSICTX_AuthHeader
        $global:VSICTX_VADHeader += @{
            'Citrix-CustomerId' = $CustomerID
            Accept              = "application/json"
        }
        # Loading of ctx pssnapins has to happen outside of module, because powershell is weird like that
        Set-XDCredentials -ProfileType CloudApi -CustomerId $CustomerID -APIKey $ClientID -SecretKey $Secret -StoreAs ctxcloud
        Get-XDAuthentication -CustomerID $CustomerID -BearerToken $token.access_token
    }
}
