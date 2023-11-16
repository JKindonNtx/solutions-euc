function Get-NTNXStorageUUID {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.String]$Storage
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        try {
            $Containerinfo = Invoke-PublicApiMethodNTNX -Method "GET" -Path "storage_containers" -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }
        
        $Containeritem = $Containerinfo.entities | Where-Object {$_.name -eq $Storage}
        $Response = ($Containeritem.id.split(":"))[2]
        $Response
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
