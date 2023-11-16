function Get-NTNXHostUUID {

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
        $Response = $Hostitem.uuid
        $Response
        


}
