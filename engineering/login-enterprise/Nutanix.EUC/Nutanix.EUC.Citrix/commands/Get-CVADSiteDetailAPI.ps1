function Get-CVADSiteDetailAPI {
    
    [CmdletBinding()]

    param(
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DDC,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$HostingConnection,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$Zone,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$EncodedAdminCredential,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DomainAdminCredential
    )

    #----------------------------------------------------------------------------------------------------------------------------
    # Check that creds aren't expired before proceeding
    #----------------------------------------------------------------------------------------------------------------------------
    $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

    # Open Array for All Auth Details
    $cvad_environment_details = @()

    #----------------------------------------------------------------------------------------------------------------------------
    # Validate Citrix Site Details
    #----------------------------------------------------------------------------------------------------------------------------
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$DDC/cvad/manage/Sites/"
    #----------------------------------------------------------------------------------------------------------------------------
    try {
        Write-Log -Message "Getting Citrix Site Info" -Level Info
        $cvad_sites = (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items
        $cvad_site_id = $cvad_sites.Id
        # Now get details about the site
        #----------------------------------------------------------------------------------------------------------------------------
        # Set API call detail
        #----------------------------------------------------------------------------------------------------------------------------
        $Method = "Get"
        $RequestUri = "https://$DDC/cvad/manage/Sites/$($cvad_site_id)"
        #----------------------------------------------------------------------------------------------------------------------------
        $cvad_site = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
        Write-Log -Message "Successfully Returned Citrix Site Detail. Site version is $($cvad_site.ProductVersion)" -Level Info
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break #Replace with Exit 1
    }

    # Add details to custom object
    $cvad_site_Object = [PSCustomObject]@{
        cvad_site = $cvad_site
    }
    $cvad_environment_details += $cvad_site_Object

    #----------------------------------------------------------------------------------------------------------------------------
    # Validate Citrix Hosting Details
    #----------------------------------------------------------------------------------------------------------------------------
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$DDC/cvad/manage/hypervisors/$($HostingConnection)"
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
    $cvad_environment_details += $hosting_connection_object

    #----------------------------------------------------------------------------------------------------------------------------
    # Validate Citrix Zone Details
    #----------------------------------------------------------------------------------------------------------------------------
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$DDC/cvad/manage/Zones/$($Zone)"
    #----------------------------------------------------------------------------------------------------------------------------
    try {
        Write-Log -Message "Getting Zone Details for: $($Zone)"
        $zone_detail = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break #Replace with Exit 1
    }

    # Add details to custom object
    $zone_object = [PSCustomObject]@{
        zone_detail = $zone_detail
    }
    $cvad_environment_details += $zone_object

    return $cvad_environment_details
}