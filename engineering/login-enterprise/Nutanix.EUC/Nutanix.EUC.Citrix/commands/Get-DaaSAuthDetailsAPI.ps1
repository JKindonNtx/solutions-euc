function Get-DaaSAuthDetailsAPI {
    param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$ClientID,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$ClientSecret,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$CustomerID,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DomainAdminCredential,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$CloudUrl
    )

    # we are grabbing the current time. We use this to compare against the globally set $Global:daas_token_validation_expiry value (set once we get the SiteID)
    $daas_token_current_time = Get-Date

    #Check and Set DaaS token expiry detail
    try { $daas_token_validation_expiry = $daas_token_validation_expiry } catch { $daas_token_validation_expiry = $null }

    if ([string]::IsNullOrEmpty($daas_token_validation_expiry)) {
        # This must be our first run, as the date has not been set.
        #--------------------------------------------
        # Get the DaaS Access Token
        #--------------------------------------------
        $TokenURL = "https://$($CloudUrl)/cctrustoauth2/root/tokens/clients"
        $Body = @{
            grant_type    = "client_credentials"
            client_id     = $ClientID
            client_secret = $ClientSecret
        }
        try {
            $Response = Invoke-WebRequest $tokenUrl -Method POST -Body $Body -UseBasicParsing -ErrorAction Stop
        }
        catch {
            Write-Log -Message "Failed to return token. Exiting" -Level Error
            Break #Replace with Exit 1
        }

        $AccessToken = $Response.Content | ConvertFrom-Json

        if (-not ([string]::IsNullOrEmpty($AccessToken))) {
            Write-Log -Message "Successfully returned Token" -Level Info
        } else {
            Write-Log -Message "Failed to return token. Exiting" -Level Error
            Break #Replace with Exit 1
        }

        #--------------------------------------------
        # Get the DaaS Site ID
        #--------------------------------------------
        Write-Log -Message "Retrieving DaaS Site ID" -Level Info

        $RequestUri = "https://$($CloudUrl)/cvadapis/me"
        $Headers = @{
            "Accept"            = "application/json";
            "Authorization"     = "CWSAuth Bearer=$($AccessToken.access_token)";
            "Citrix-CustomerId" = "$CustomerID";
        }

        try {
            $Response = Invoke-RestMethod -Uri $RequestUri -Method GET -Headers $Headers -ErrorAction Stop
        }
        catch {
            Write-Log -Message "Failed to return Site ID. Exiting" -Level Error
            Break #Replace with Exit 1
        }

        $SiteID = $Response.Customers.Sites.Id

        if (-not ([String]::IsNullOrEmpty($SiteID))) {
            Write-Log -Message "Successfully returned DaaS Site ID: $($SiteID)" -Level Info
        } else {
            Write-Log -Message "Failed to return Site ID. Exiting" -Level Error
            Break #Replace with Exit 1
        }

        # Set the global variable for Token Time Expiration. This has to occur after the Site ID call has been made. We use this to control when we next make another call. We are using a 1.5 hr buffer window (token should be valid for 2)
        $Global:daas_token_validation_expiry = (Get-Date).AddHours(1.5)

        $daas_token_validation_expiry = $Global:daas_token_validation_expiry

        $token_remaining_minutes = [math]::Round((($daas_token_validation_expiry - $daas_token_current_time).TotalMinutes))
        Write-Log -Message "Validation completed successfully. Initial Token expiration is $($daas_token_validation_expiry). $($token_remaining_minutes) minutes remaining" -Level Info

        #--------------------------------------------
        # Set the headers
        #--------------------------------------------
        Write-Log -Message "Set Standard Auth Heathers for DaaS API Calls" -Level Info
        $Headers = @{
            "Accept"            = "application/json";
            "Authorization"     = "CWSAuth Bearer=$($AccessToken.access_token)";
            "Citrix-CustomerId" = "$CustomerID";
            "Citrix-InstanceId" = "$SiteID";
            "X-AdminCredential" = "Basic $DomainAdminCredential";
        }
    }
    else {
        # we have a token, time to check it
        if ($daas_token_current_time -gt $daas_token_validation_expiry) {
            # This means the current time is newer than the expiration time. We need to get a new token
            Write-Log -Message "Token has expired at $($daas_token_validation_expiry), refreshing. Current comparison time is $($daas_token_current_time)" -Level Info
            #--------------------------------------------
            # Get the DaaS Access Token
            #--------------------------------------------
            $TokenURL = "https://$($CloudUrl)/cctrustoauth2/root/tokens/clients"
            $Body = @{
                grant_type    = "client_credentials"
                client_id     = $ClientID
                client_secret = $ClientSecret
            }
            try {
                $Response = Invoke-WebRequest $tokenUrl -Method POST -Body $Body -UseBasicParsing -ErrorAction Stop
            }
            catch {
                Write-Log -Message "Failed to return token. Exiting" -Level Error
                Break #Replace with Exit 1
            }

            $AccessToken = $Response.Content | ConvertFrom-Json

            if (-not ([string]::IsNullOrEmpty($AccessToken))) {
                Write-Log -Message "Successfully returned Token" -Level Info
            } else {
                Write-Log -Message "Failed to return token. Exiting" -Level Error
                Break #Replace with Exit 1
            }

            #--------------------------------------------
            # Get the DaaS Site ID
            #--------------------------------------------
            Write-Log -Message "Retrieving DaaS Site ID" -Level Info

            $RequestUri = "https://$($CloudUrl)/cvadapis/me"
            $Headers = @{
                "Accept"            = "application/json";
                "Authorization"     = "CWSAuth Bearer=$($AccessToken.access_token)";
                "Citrix-CustomerId" = "$CustomerID";
            }

            try {
                $Response = Invoke-RestMethod -Uri $RequestUri -Method GET -Headers $Headers -ErrorAction Stop
            }
            catch {
                Write-Log -Message "Failed to return Site ID. Exiting" -Level Error
                Break #Replace with Exit 1
            }

            $SiteID = $Response.Customers.Sites.Id

            if (-not ([String]::IsNullOrEmpty($SiteID))) {
                Write-Log -Message "Successfully returned DaaS Site ID: $($SiteID)" -Level Info
            } else {
                Write-Log -Message "Failed to return Site ID. Exiting" -Level Error
                Break #Replace with Exit 1
            }
    
            # Set the global variable for Token Time Expiration. This has to occur after the Site ID call has been made. We use this to control when we next make another call. We are using a 1.5 hr buffer window (token should be valid for 2)
            $Global:daas_token_validation_expiry = (Get-Date).AddHours(1.5)

            Write-Log -Message "Validation completed successfully. New token expiration is $($daas_token_validation_expiry)" -Level Info

            #--------------------------------------------
            # Set the updated headers
            #--------------------------------------------
            Write-Log -Message "Set Standard Auth Heathers for DaaS API Calls" -Level Info
            $Headers = @{
                "Accept"            = "application/json";
                "Authorization"     = "CWSAuth Bearer=$($AccessToken.access_token)";
                "Citrix-CustomerId" = "$CustomerID";
                "Citrix-InstanceId" = "$SiteID";
                "X-AdminCredential" = "Basic $DomainAdminCredential";
            }
        }
        else {
            # Our token is still OK
            $token_remaining_minutes = [math]::Round((($daas_token_validation_expiry - $daas_token_current_time).TotalMinutes))
            Write-Log -Message "Token is valid. Token expiration is $($daas_token_validation_expiry). Current comparison time is $($daas_token_current_time). $($token_remaining_minutes) minutes remaining" -Level Info
        }
    }

    # we need to send back the headers for use in future calls
    Return $Headers

}