function Get-LEApplications {
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

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        #Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
        Write-Log -Message "Starting Get-LEApplications" -Level Info
    }

    process {
        $Body = @{
            orderBy   = "name"
            direction = "asc"
            count     = 10000
            include   = "none"
        }

        try {
            $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/applications" -Body $Body -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }
        $Response.items
    } # process

    end {
        #Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
        Write-Log -Message "Finishing Get-LEApplications" -Level Info
    } # end

}
