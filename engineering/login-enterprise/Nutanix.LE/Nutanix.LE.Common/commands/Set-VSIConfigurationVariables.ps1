function Set-VSIConfigurationVariables {
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
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$ConfigurationFile,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$ImageConfiguration
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        if ($null -ne $ConfigurationFile) {
        
            Write-Log -Message "Parsing config file $ConfigurationFile" -Level Info
            try {
                $configFile = Get-Content -Path $ConfigurationFile -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Exit 1
            }
            
            $configFile = $configFile -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
    
            try {
                $config = $configFile | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Exit 1
            }
            
            Get-Variable -Name VSI_* -ErrorAction SilentlyContinue | Remove-Variable -ErrorAction SilentlyContinue
    
            # Process config from configflie
            foreach ($section in $config.PSObject.Properties) {
                foreach ($var in $section.Value.PSObject.Properties) { 
                    Set-Variable -Name "VSI_$($section.Name)_$($var.Name)" -Value $var.Value -Scope Global
                }
            }
    
        }
    
        if ($null -ne $ImageConfiguration) {
            Write-Log -Message "Processing Image Configuration" -Level Validation
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
    } # process

    end {
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
