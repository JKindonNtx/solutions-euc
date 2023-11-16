function Get-NTNXHostIPMI {
    
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.String]$NTNXHost
    )

        try {
            $NTNXHosts = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts" -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }
        
        $Hostitem = $NTNXHosts.entities | Where-Object {$_.name -eq $NTNXHost}
        $Response2 = $Hostitem.ipmi_address
        $Response2
        


}
