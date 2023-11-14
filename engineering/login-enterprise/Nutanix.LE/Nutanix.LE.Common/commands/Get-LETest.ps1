function Get-LETest {
    <#
    .SYNOPSIS
    Quick Description of the function.

    .DESCRIPTION
    Detailed description of the function.

    .PARAMETER testId
    Description of each parameter being passed into the function.

    .PARAMETER include

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    What the function returns.

    .EXAMPLE
    PS> function-template -parameter "parameter detail"
    Description of the example.

    .LINK
    Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Help/function-template.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Nutanix.LE

#>
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)] 
        [string] $testId,

        [Parameter(Mandatory = $false)] 
        [ValidateSet('none', 'environment', 'workload', 'thresholds', 'all')] 
        [string] $include = "all"
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        $Body = @{
            include = $include
        }
    
        try {
            $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/tests/$testId" -Body $Body -ErrorAction Stop
        }
        catch {
            Write-Log -Message "Failed to retrieve test info" -Level Error
            Write-Log -Message $_ -Level Error
            Exit 1
        }
        $Response
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
