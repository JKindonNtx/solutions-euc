function Get-LELauncherGroups {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$orderBy = "Name",
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$Direction = "asc",
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)] [string]$Count = "50",
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)] [string]$Include = "none"
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        $Body = @{
            orderBy   = $orderBy
            direction = $Direction
            count     = $Count
            include   = $Include
        }
    
        try {
            $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/launcher-groups" -Body $Body -ErrorAction Stop
            $Response.items
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }
        
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
