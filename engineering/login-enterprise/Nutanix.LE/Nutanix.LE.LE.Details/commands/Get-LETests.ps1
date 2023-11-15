function Get-LETests {
    <#
    .SYNOPSIS
    Quick Description of the function.

    .DESCRIPTION
    Detailed description of the function.

    .PARAMETER ParameterName
    Description of each parameter being passed into the function.

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
        [Parameter(Mandatory = $false)][ValidateSet('name', 'connector', 'description')][string]$orderBy = "name",
        [Parameter(Mandatory = $false)][ValidateSet('continuousTest', 'loadTest', 'applicationTest')][string] $testType = "loadTest",
        [Parameter(Mandatory = $false)][ValidateSet('asc', 'desc')][string]$Direction = "asc",
        [Parameter(Mandatory = $false)][ValidateSet('environment', 'workload', 'thresholds', 'all', 'none')][string]$include = "none",
        [Parameter(Mandatory = $false)][string]$count = 10000
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        $Body = @{
            testType  = $testType
            orderBy   = $orderBy
            direction = $direction
            count     = $Count
            include   = $Include
        }
        
        $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/tests" -Body $Body
        $Response.items
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
