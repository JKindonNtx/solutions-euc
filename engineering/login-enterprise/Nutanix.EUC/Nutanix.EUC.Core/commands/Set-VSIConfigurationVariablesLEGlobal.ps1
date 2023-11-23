function Set-VSIConfigurationVariablesLEGlobal {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$ConfigurationFile,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$LEAppliance
    )

    if ($null -ne $ConfigurationFile) {
        
        Write-Log -Message "Parsing config file $ConfigurationFile" -Level Info
        try {
            $configFile = Get-Content -Path $ConfigurationFile -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break #Temporary! Replace with #Exit 1
        }
            
        $configFile = $configFile -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
    
        try {
            $config = $configFile | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break #Temporary! Replace with #Exit 1
        }

        Get-Variable -Name VSI_* | Where-Object {$_.Name -Like "VSI_Users*" -or $_.Name -like "VSI_LoginEnterprise_*" -or $_.Name -like "VSI_Launchers_*" } -ErrorAction SilentlyContinue | Remove-Variable -ErrorAction SilentlyContinue
        
        # Process config from configflie
        foreach ($section in $config.PSObject.Properties | Where-Object {$_.Name -eq $LEAppliance}) {
            foreach ($var in $section.Value.PSObject.Properties) { 
                foreach ($Obj in $var.Value) {
                    foreach ($Obj in $Obj.PSObject.Properties) {
                        Set-Variable -Name "VSI_$($var.Name)_$($Obj.Name)" -Value $Obj.Value -Scope Global
                    }
                }
            }
        }
    }
}
