function Set-VSIConfigurationVariables {
    param(
        $ConfigurationFile,
        $ImageConfiguration
    )
    
    if ($null -ne $ConfigurationFile) {
        
        Write-Log "Parsing config file $ConfigurationFile" -level Info
        $configFile = Get-Content -Path $ConfigurationFile
        $configFile = $configFile -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'

        $config = $configFile | ConvertFrom-Json
        
        Get-Variable -Name VSI_* -ErrorAction SilentlyContinue | Remove-Variable -ErrorAction SilentlyContinue
        
        # Process config from configflie
        foreach ($section in $config.PSObject.Properties) {
            foreach ($var in $section.Value.PSObject.Properties) { 
                Set-Variable -Name "VSI_$($section.Name)_$($var.Name)" -Value $var.Value -Scope Global
            }
        }
    }

    if ($null -ne $ImageConfiguration) {
        Write-Log "Parsing Image Configuration" -level Info
        foreach ($var in $ImageConfiguration.PSObject.Properties) {
            Set-Variable -Name "VSI_Target_$($var.Name)" -Value $var.Value -Scope Global
        }
    }

    # Process config from envVars, overwrites existing values
    foreach ($envVar in (Get-ChildItem env:VSI_*)) {
        $sectionName = $envVar.Name.SubString(4).Split("_")[0]
        $propertyName = $envVar.Name.SubString(4).Split("_")[1]
        Set-Variable -Name "VSI_$($sectionName)_$($propertyName)" -Value $envVar.Value -Scope Global
    }

    # Expand variables
    Foreach ($VSI_Var in Get-Variable -Scope Global -Name VSI_* -Exclude VSI_Target_ImagesToTest) {
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
    
    #  if ($null -ne $ImageConfiguration) {

    #        if (($null -ne (Get-Variable -Scope Global -Name VSI_Target_LogonsPerMinute -ErrorAction SilentlyContinue)) -And ($VSI_Target_LogonsPerMinute -gt 0)) {                
    #           Set-Variable -Name VSI_Target_RampupInMinutes -Scope Global -Value ([Math]::Round($VSI_Target_NumberOfSessions / $VSI_Target_LogonsPerMinute, 0, [MidpointRounding]::AwayFromZero))        
    #          Write-VSILog "Using LogonsPerMinute: $VSI_Target_LogonsPerMinute"
    #     }
    #    else {
    #       Write-VSILog "Using VSI_Target_RampupInMinutes: $VSI_Target_RampupInMinutes"
    #  }
    #
    #       if ($global:VSI_Target_RampupInMinutes -eq 0) {
    #          $global:VSI_Target_RampupInMinutes = 1
    #     }
    # }
    #    
}