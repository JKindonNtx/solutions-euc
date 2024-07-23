function Get-CVADSiteDetail {
    
    [CmdletBinding()]

    param(
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DDC,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$HostingConnection,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$Zone
    )

    # Open Array for All Auth Details
    $cvad_environment_details = @()

    Connect-VSICTX -DDC $DDC

    #----------------------------------------------------------------------------------------------------------------------------
    # Validate Citrix Site Details
    #----------------------------------------------------------------------------------------------------------------------------
    try {
        Write-Log -Message "Getting Citrix Site Info" -Level Info
        $cvad_site = Get-BrokerSite -AdminAddress $DDC -ErrorAction Stop
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

    try {
        Write-Log -Message "Getting Hosting Connection Details for: $($HostingConnection)"
        $hosting_connection_detail = Get-ChildItem XDHyp:\HostingUnits -AdminAddress $DDC -ErrorAction Stop | Where-Object {$_.PSChildName -eq $HostingConnection}
        if (-not $hosting_connection_detail){
            Write-Log -Message "Hosting Unit $($HostingConnection) not found" -Level Warn
            Exit 1
        }
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
    try {
        Write-Log -Message "Getting Zone Details for: $($Zone)"
        $zone_detail = Get-ConfigZone -Name $Zone -AdminAddress $DDC -ErrorAction Stop
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