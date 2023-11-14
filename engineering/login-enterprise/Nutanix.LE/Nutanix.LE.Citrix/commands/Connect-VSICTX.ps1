function Connect-VSICTX {
    <#
    .SYNOPSIS
    Connects to the Citrix Environment

    .DESCRIPTION
    Connects to the Citrix Environment. Either DaaS or CVAD

    .PARAMETER ClientID
    The Citrix Cloud Client ID

    .PARAMETER Secret
    The Citrix Cloud Client Secret

    .PARAMETER CustomerID
    The Citrix Cloud Customer ID

    .PARAMETER DDC
    The Citrix On Prem DDC

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    None

#>
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'CitrixCloud')]
        [String]$ClientID,
        [Parameter(Mandatory = $true, ParameterSetName = 'CitrixCloud')]
        [String]$Secret,
        [Parameter(Mandatory = $true, ParameterSetName = 'CitrixCloud')]
        [String]$CustomerID,
        [Parameter(Mandatory = $true, ParameterSetName = 'OnPrem')]
        [String]$DDC
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        if ($null -ne $DDC) {
            try {
                Write-Log -Message "Handling Citrix Credentials and Validating Citrix On Prem Site" -Level Info
                Set-XDCredentials -ProfileType OnPrem -StoreAs ctxonprem -ErrorAction Stop
                Get-XDAuthentication -ProfileName ctxonprem -ErrorAction Stop
                Get-BrokerSite -AdminAddress $DDC -ErrorAction Stop | Out-Null
                Write-Log -Message "Validation completed successfully" -Level Info
            }
            catch {
                Write-Log -Message "Failed to get Citrix Site details" -Level Error
                Write-Log -Message $_ -Level Error
                Exit 1
            }
    
        }

        if ($null -ne $ClientID) {
            Write-Log -Message "Handling Citrix Credentials and Validating Citrix Cloud DaaS" -Level Info
            $tokenUrl = 'https://api-us.cloud.com/cctrustoauth2/root/tokens/clients'
    
            # Obtain bearer token from authorization server
            try {
                $response = Invoke-WebRequest $tokenUrl -Method POST -UseBasicParsing -Body @{
                    grant_type    = "client_credentials"
                    client_id     = $ClientID
                    client_secret = $Secret
                } -ErrorAction Stop
            }
            catch {
                Write-Log -Message "Failed to Get Citrix DaaS Details" -Level Error
                Write-Log -Message $_  -Level Error
                Exit 1
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
            try {
                Set-XDCredentials -ProfileType CloudApi -CustomerId $CustomerID -APIKey $ClientID -SecretKey $Secret -StoreAs ctxcloud -ErrorAction Stop
                Get-XDAuthentication -CustomerID $CustomerID -BearerToken $token.access_token -ErrorAction Stop
                Write-Log -Message "Validation completed successfully"  -Level Info
            }
            catch {
                Write-Log -Message "Failed to get Citrix DaaS details" -Level Error
                Write-Log -Message $_ -Level Error
                Exit 1
            }
        }
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
