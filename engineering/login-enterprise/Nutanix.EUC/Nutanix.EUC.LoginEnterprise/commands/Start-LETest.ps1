function Start-LETest {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.String]$testId,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.String]$comment
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        $Body = [ordered]@{
            comment = $comment
        } | ConvertTo-Json
        
        try {
            Invoke-PublicApiMethod -Method "PUT" -Path "v6/tests/$testId/start" -Body $Body -ErrorAction Stop
        }
        catch {
            Write-Error -Message $_ -Level Error
            Exit 1
        }
        
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
