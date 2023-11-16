function New-LEAccountGroup {

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
