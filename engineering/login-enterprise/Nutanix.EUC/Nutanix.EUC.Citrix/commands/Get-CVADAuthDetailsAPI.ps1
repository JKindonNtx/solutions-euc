function Get-CVADAuthDetailsAPI {
    param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DDC,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$EncodedAdminCredential,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DomainAdminCredential
    )

    # we are grabbing the current time. We use this to compare against the globally set $Global:cvad_token_validation_expiry value (set once we get the SiteID)
    $cvad_token_current_time = Get-Date

    #Check and Set cvad token expiry detail
    try { $cvad_token_validation_expiry = $cvad_token_validation_expiry } catch { $cvad_token_validation_expiry = $null }

    if ([string]::IsNullOrEmpty($cvad_token_validation_expiry)) {
        # This must be our first run, as the date has not been set.
        #--------------------------------------------
        # Get the CVAD Access Token
        #--------------------------------------------
        Write-Log -Message "Retrieving CVAD Access Token" -Level Info
        $TokenURL = "https://$DDC/cvad/manage/Tokens"
        $Headers = @{
            Accept = "application/json"
            Authorization = "Basic $EncodedAdminCredential"
        }

        try {
            $Response = Invoke-WebRequest -Uri $TokenURL -Method Post -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
        }
        catch {
            Write-Log -Message "Failed to return token. Exiting" -Level Error
            Break #Replace with Exit 1
        }
        
        $AccessToken = $Response.Content | ConvertFrom-Json

        if (-not ([string]::IsNullOrEmpty($AccessToken))) {
            Write-Log -Message "Successfully returned Token" -Level Info
        }
        else {
            Write-Log -Message "Failed to return token. Exiting" -Level Error
            Break #Replace with Exit 1
        }

        #--------------------------------------------
        # Get the CVAD Site ID
        #--------------------------------------------
        Write-Log -Message "Retrieving CVAD Site ID" -Level Info

        $URL = "https://$DDC/cvad/manage/Me"
        $Headers = @{
            "Accept"            = "application/json";
            "Authorization"     = "CWSAuth Bearer=$($AccessToken.Token)";
            "Citrix-CustomerId" = "CitrixOnPremises";
        }

        try {
            $Response = Invoke-WebRequest -Uri $URL -Method Get -Header $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
        }
        catch {
            Write-Log -Message "Failed to return Site ID. Exiting" -Level Error
            Break #Replace with Exit 1
        }

        $SiteID = $Response.Content | ConvertFrom-Json

        if (-not ([String]::IsNullOrEmpty($SiteID))) {
            Write-Log -Message "Successfully returned CVAD Site ID: $($SiteID.Customers.Sites.Id)" -Level Info
        }
        else {
            Write-Log -Message "Failed to return Site ID. Exiting" -Level Error
            Break #Replace with Exit 1
        }

        # Set the global variable for Token Time Expiration. This has to occur after the Site ID call has been made. We use this to control when we next make another call. We are using a 1.5 hr buffer window (token should be valid for 2)
        $Global:cvad_token_validation_expiry = (Get-Date).AddHours(1.5)

        $cvad_token_validation_expiry = $Global:cvad_token_validation_expiry

        $token_remaining_minutes = [math]::Round((($cvad_token_validation_expiry - $cvad_token_current_time).TotalMinutes))
        Write-Log -Message "Validation completed successfully. Initial Token expiration is $($cvad_token_validation_expiry). $($token_remaining_minutes) minutes remaining" -Level Info

        #--------------------------------------------
        # Set the headers
        #--------------------------------------------

        Write-Log -Message "Set Standard Auth Heathers for CVAD API Calls" -Level Info
        $Headers = @{
            "Accept"            = "application/json";
            "Authorization"     = "CWSAuth Bearer=$($AccessToken.Token)";
            "Citrix-CustomerId" = "CitrixOnPremises";
            "Citrix-InstanceId" = "$($SiteID.Customers.Sites.Id)";
            "X-AdminCredential" = "Basic $DomainAdminCredential";
        }
    }
    else {
        # we have a token, time to check it
        if ($cvad_token_current_time -gt $cvad_token_validation_expiry) {
            # This means the current time is newer than the expiration time. We need to get a new token
            Write-Log -Message "Token has expired at $($cvad_token_validation_expiry), refreshing. Current comparison time is $($cvad_token_current_time)" -Level Info
            #--------------------------------------------
            # Get the CVAD Access Token
            #--------------------------------------------
            Write-Log -Message "Retrieving CVAD Access Token" -Level Info
            $TokenURL = "https://$DDC/cvad/manage/Tokens"
            $Headers = @{
                Accept = "application/json"
                Authorization = "Basic $EncodedAdminCredential"
            }

            try {
                $Response = Invoke-WebRequest -Uri $TokenURL -Method Post -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            }
            catch {
                Write-Log -Message "Failed to return token. Exiting" -Level Error
                Break #Replace with Exit 1
            }
            
            $AccessToken = $Response.Content | ConvertFrom-Json

            if (-not ([string]::IsNullOrEmpty($AccessToken))) {
                Write-Log -Message "Successfully returned Token" -Level Info
            }
            else {
                Write-Log -Message "Failed to return token. Exiting" -Level Error
                Break #Replace with Exit 1
            }

            #--------------------------------------------
            # Get the CVAD Site ID
            #--------------------------------------------
            Write-Log -Message "Retrieving CVAD Site ID" -Level Info

            $URL = "https://$DDC/cvad/manage/Me"
            $Headers = @{
                "Accept"            = "application/json";
                "Authorization"     = "CWSAuth Bearer=$($AccessToken.Token)";
                "Citrix-CustomerId" = "CitrixOnPremises";
            }

            try {
                $Response = Invoke-WebRequest -Uri $URL -Method Get -Header $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
            }
            catch {
                Write-Log -Message "Failed to return Site ID. Exiting" -Level Error
                Break #Replace with Exit 1
            }

            $SiteID = $Response.Content | ConvertFrom-Json

            if (-not ([String]::IsNullOrEmpty($SiteID))) {
                Write-Log -Message "Successfully returned CVAD Site ID: $($SiteID.Customers.Sites.Id)" -Level Info
            }
            else {
                Write-Log -Message "Failed to return Site ID. Exiting" -Level Error
                Break #Replace with Exit 1
            }
    
            # Set the global variable for Token Time Expiration. This has to occur after the Site ID call has been made. We use this to control when we next make another call. We are using a 1.5 hr buffer window (token should be valid for 2)
            $Global:cvad_token_validation_expiry = (Get-Date).AddHours(1.5)

            Write-Log -Message "Validation completed successfully. New token expiration is $($cvad_token_validation_expiry)" -Level Info

            #--------------------------------------------
            # Set the updated headers
            #--------------------------------------------

            Write-Log -Message "Set Standard Auth Heathers for CVAD API Calls" -Level Info
            $Headers = @{
                "Accept"            = "application/json";
                "Authorization"     = "CWSAuth Bearer=$($AccessToken.Token)";
                "Citrix-CustomerId" = "CitrixOnPremises";
                "Citrix-InstanceId" = "$($SiteID.Customers.Sites.Id)";
                "X-AdminCredential" = "Basic $DomainAdminCredential";
            }
        }
        else {
            # Our token is still OK
            $token_remaining_minutes = [math]::Round((($cvad_token_validation_expiry - $cvad_token_current_time).TotalMinutes))
            Write-Log -Message "Token is valid. Token expiration is $($cvad_token_validation_expiry). Current comparison time is $($cvad_token_current_time). $($token_remaining_minutes) minutes remaining" -Level Info
        }
    }

    # we need to send back the headers for use in future calls
    Return $Headers

}