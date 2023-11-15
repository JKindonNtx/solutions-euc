function New-LEAccountGroup {
    <#
    .SYNOPSIS
    Quick Description of the function.

    .DESCRIPTION
    Detailed description of the function.

    .PARAMETER Name
    Description of each parameter being passed into the function.

    .PARAMETER Filter

    .PARAMETER Condition

    .PARAMETER Description

    .PARAMETER MemberIds

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
    [CmdletBinding(DefaultParametersetName = 'None')]

    Param (
        [Parameter(Position = 0, Mandatory = $true)] [string]$Name,
        [Parameter(ParameterSetName = 'Filter', Mandatory = $false)][switch]$Filter,
        [Parameter(ParameterSetName = 'Filter', Mandatory = $true)][string]$Condition,
        [Parameter(Mandatory = $false)][string]$Description,
        [Parameter(Mandatory = $false)][Array]$MemberIds
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        if ($Filter -eq $false) {
            $Body = @{
                'type'      = "Selection"
                groupId     = New-Guid
                name        = $Name
                description = $Description
                memberIds   = $MemberIds
            } | ConvertTo-Json
        }
        else {
            $Body = @{
                'type'      = "Filter"
                groupId     = New-Guid
                name        = $Name
                description = $Description
                condition   = $Condition
            } | ConvertTo-Json
        }

        $ExistingAccountGroup = Get-LEAccountGroups | Where-Object { $_.name -eq $Name }

        if ($null -ne $ExistingAccountGroup) {
            Remove-LEAccountGroups -ids $ExistingAccountGroup.groupId
        }

        try {
            $Response = Invoke-PublicApiMethod -Method "POST" -Path "v6/account-groups" -Body $Body -ErrorAction Stop
            $Response.id
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
