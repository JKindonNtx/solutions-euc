function Set-VSIConfigurationVariablesLEGlobal {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$ConfigurationFile,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$LEAppliance ########SVENNNNNNN - SANITY CHECK PLEASE
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

        ########SVENNNNNNN - SANITY CHECK PLEASE
        Get-Variable -Name VSI_* | Where-Object {$_.Name -Like "VSI_Users*" -or $_.Name -like "VSI_LoginEnterprise_*" -or $_.Name -like "VSI_Launchers_*" } -ErrorAction SilentlyContinue | Remove-Variable -ErrorAction SilentlyContinue
        ########SVENNNNNNN!
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
    
    # Process config from envVars, overwrites existing values
    ########SVENNNNNNN - SANITY CHECK PLEASE
    #foreach ($envVar in (Get-ChildItem env:VSI_* | Where-Object {$_.Name -Like "VSI_Users*" -or $_.Name -like "VSI_LoginEnterprise_*" -or $_.Name -like "VSI_Launchers_*" })) { 
    #    $sectionName = $envVar.Name.SubString(4).Split("_")[0]
    #    $propertyName = $envVar.Name.SubString(4).Split("_")[1]
    #    Set-Variable -Name "VSI_$($sectionName)_$($propertyName)" -Value $envVar.Value -Scope Global
    #}
    
    # Expand variables
    ########SVENNNNNNN - SANITY CHECK PLEASE
    Foreach ($VSI_Var in Get-Variable -Scope Global -Name VSI_* | Where-Object {$_.Name -Like "VSI_Users*" -or $_.Name -like "VSI_LoginEnterprise_*" -or $_.Name -like "VSI_Launchers_*" }) {
        $newVal = $VSI_Var.Value
        :loop while ($newVal -match "\$\{.+?\}") {
            foreach ($match in $matches) {
                $sectionName = ($match[0] -replace "\$\{", "" -replace "\}", "").Split(".")[0]
                $propertyName = ($match[0] -replace "\$\{", "" -replace "\}", "").Split(".")[1]
                $TargetVar = $null
                $TargetVar = Get-Variable -Name "VSI_$($sectionName)_$($propertyName)" -errorAction SilentlyContinue
                if ($null -ne $TargetVar) {
                    $expandedMatch = $TargetVar.Value
                    $newVal = $newVal.Replace($match[0], $expandedMatch)
                }
                else { break loop }
            }
        }
            
        $VSI_Var.Value = $newVal
    }
}
