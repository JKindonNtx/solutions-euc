function Get-NTNXHostIPMI {
    
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.String]$NTNXHost
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        try {
            $NTNXHosts = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts" -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }
        
        $Hostitem = $NTNXHosts.entities | Where-Object {$_.name -eq $NTNXHost}
        $Response2 = $Hostitem.ipmi_address
        $Response2
        
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
