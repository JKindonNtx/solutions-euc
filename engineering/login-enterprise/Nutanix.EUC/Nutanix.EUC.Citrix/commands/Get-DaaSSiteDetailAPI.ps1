function Get-DaaSSiteDetailAPI {
    [CmdletBinding()]

    param(
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$CloudUrl,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$HostingConnection,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$Zone,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$CustomerID,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$ClientID,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$ClientSecret,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DomainAdminCredential
    )

    #----------------------------------------------------------------------------------------------------------------------------
    # Check that creds aren't expired before proceeding
    #----------------------------------------------------------------------------------------------------------------------------
    $Global:Headers = Get-DaaSAuthDetailsAPI -CustomerID $CustomerID -ClientID $ClientID -ClientSecret $ClientSecret -CloudUrl $CloudUrl -DomainAdminCredential $DomainAdminCredential

    # Open Array for All Auth Details
    $daas_environment_details = @()

    #----------------------------------------------------------------------------------------------------------------------------
    # Validate Citrix Site Details
    #----------------------------------------------------------------------------------------------------------------------------
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$CloudUrl/cvad/manage/Sites/cloudxdsite"
    #----------------------------------------------------------------------------------------------------------------------------
    try {
        Write-Log -Message "Getting Citrix DaaS Site Info" -Level Info
        $daas_site = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
        Write-Log -Message "Successfully Returned Citrix DaaS Site Detail. Site version is $($daas_site.ProductVersion)" -Level Info
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break #Replace with Exit 1
    }

    # Add details to custom object
    $daas_site_Object = [PSCustomObject]@{
        daas_site = $daas_site
    }
    $daas_environment_details += $daas_site_Object

    #----------------------------------------------------------------------------------------------------------------------------
    # Validate Citrix Hosting Details
    #----------------------------------------------------------------------------------------------------------------------------
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$CloudUrl/cvad/manage/hypervisors/$($HostingConnection)"
    #----------------------------------------------------------------------------------------------------------------------------
    try {
        Write-Log -Message "Getting Hosting Connection Details for: $($HostingConnection)"
        $hosting_connection_detail = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break #Replace with Exit 1
    }

    # Add details to custom object
    $hosting_connection_object = [PSCustomObject]@{
        hosting_connection_detail = $hosting_connection_detail
    }
    $daas_environment_details += $hosting_connection_object

    #----------------------------------------------------------------------------------------------------------------------------
    # Validate Citrix Zone Details
    #----------------------------------------------------------------------------------------------------------------------------
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$CloudUrl/cvad/manage/Zones/$($Zone)"
    #----------------------------------------------------------------------------------------------------------------------------
    try {
        Write-Log -Message "Getting Zone Details for: $($Zone)"
        $zone_detail = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
    }
    catch {
        if ($_ -like "*Object does not exist.*") {
            Write-Log -Message "The specified Zone: $($Zone) does not exist in the DaaS Tenant. Please check the configuration." -Level Error
            Break #Replace with Exit 1
        }
        Write-Log -Message $_ -Level Error
        Break #Replace with Exit 1
    }

    # Add details to custom object
    $zone_object = [PSCustomObject]@{
        zone_detail = $zone_detail
    }
    $cvad_environment_details += $zone_object

    return $daas_environment_details
}