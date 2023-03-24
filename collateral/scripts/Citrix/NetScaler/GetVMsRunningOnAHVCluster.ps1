# Adding Snapins
add-pssnapin *citrix*

# Grabbing hosting connection details
$connections = get-childitem -path 'xdhyp:\connections'

# Loop thru hosting connections and select the AHV-based hosting Connections
foreach ($connection in $connections) {
    if ($connection.PluginId -eq "AcropolisFactory") {
        write-host "$($connection.PSChildName) is an AHV Cluster"
        
        #Collecting the Hosting Connection Unique identifier
        $ZoneUuid = $connection.ZoneUid.Guid

        # Grabbing the Machine Catalogs that are based on the above hosting connection
        $AHVCatalogs = Get-BrokerCatalog | Where-Object { $_.ZoneUid -eq "$ZoneUuid" }

        foreach ($AVHCatalog in $AHVCatalogs) {
            # Grab number of desktops per catalog
            $NumberofDesktops = $avhcatalog.AvailableCount
            # Add to cumulative number of desktopsvariable
            $TotalNumberofDesktops += $NumberofDesktops
        }
        Write-host "The total number of VMs on this cluster provisioned by Citrix is $($TotalNumberofDesktops)"

    }
    else { 
        #write-host "$($connection.PSChildName): this is not AHV"
    }
}

Remove-Variable * -ErrorAction SilentlyContinue
