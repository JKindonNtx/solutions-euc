function Set-LELauncherGroup {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.String]$LauncherGroupName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.String]$NamingPattern
    )

    begin {
        # Set strict mode 
        # Set-StrictMode -Version Latest
        Write-Log -Message "Starting Set-LELauncherGroup" -Level Info
    }

    process {
        $ExistingLauncherGroup = Get-LELauncherGroups | Where-Object { $_.name -eq $LauncherGroupName }
        if ($null -ne $ExistingLauncherGroup) {
            Remove-LELauncherGroups -ids $ExistingLauncherGroup.id
        }
        $NamingPattern = $NamingPattern -replace "_", ""
        $launcherNames = Get-LELaunchers | Where-Object { $_.machineName -like "$($NamingPattern)*" } | Select-Object -ExpandProperty machineName
        New-LELauncherGroup -Name $LauncherGroupName -LauncherNames $LauncherNames | Out-Null
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing Set-LELauncherGroup" -Level Info
    } # end

}
