function Remove-LELauncherGroups {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][array]$ids
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting Remove-LELauncherGroups" -Level Info
    }

    process {
        $Body = ConvertTo-Json @($ids)

        try {
            $Response = Invoke-PublicApiMethod -Method "DELETE" -Path "v6/launcher-groups" -Body $Body
            $Response.id
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }
        
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing Remove-LELauncherGroups" -Level Info
    } # end

}
