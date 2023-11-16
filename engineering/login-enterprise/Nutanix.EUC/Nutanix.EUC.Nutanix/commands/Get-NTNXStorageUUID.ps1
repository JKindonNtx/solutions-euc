function Get-NTNXStorageUUID {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.String]$Storage
    )

        try {
            $Containerinfo = Invoke-PublicApiMethodNTNX -Method "GET" -Path "storage_containers" -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }
        
        $Containeritem = $Containerinfo.entities | Where-Object {$_.name -eq $Storage}
        $Response = ($Containeritem.id.split(":"))[2]
        $Response
}
