function Get-ValidJSON {
    <#
.SYNOPSIS
Validates that key items defined in the configuration file are valid against a defined list

.DESCRIPTION
Validates that key items defined in the configuration file are valid against a defined list

.PARAMETER ConfigFile
The configuration file to parse and validate

#>
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)][String]$ConfigFile,
        [Parameter(Mandatory = $true)][String]$Type
        #$ConfigFile = "C:\DevOps\solutions-euc\engineering\login-enterprise\ExampleConfig-Test-Template.jsonc"
    )

    begin{
        $Return = $false

        #Target Section Valid Settings
        $Validated_Delivery_Types = @("Citrix","VMware","RAS")
        $Validated_Clone_Types = @("MCS", "Instant Clones", "Full Clone", "Linked Clone", "PVS")
        $Validated_SessionCfg =@("ICA","PCoIP","Blast","RDP")
        $Validated_Workload_Profiles = @("Task Worker", "Knowledge Worker")
        $Validated_Session_Support = @("multisession", "singlesession")
        #Target Section Citrix Valid Settings
        $Validated_Functional_Levels = @("L7_9", "L5", "L7", "L7_6", "L7_7", "L7_8", "L7_9", "L7_20", "L7_25")
        #Target Section VMWare Horizon Valid Settings
        $Validated_RefreshOsDiskAfterLogoff = @("ALWAYS","NEVER")
        $Validated_User_Assignments = @("DEDICATED","FLOATING")
        $Validated_Provisioning_Modes = @("AllMachinesUpFront","OnDemand")
        #Test Section Valid Settings
        $Validated_Bucket_Names = @("LoginDocuments", "LoginRegression")
    }

    process{

        $ErrorCount = 0

        #First Grab the JSON and import it
        try {
            $configFileData = (Get-Content -Path $ConfigFile -ErrorAction Stop)
        }
        catch {
            Write-Log -Message "Failed to import config file: $($configFile)" -Level Error
            Write-Log -Message $_ -Level Error
            Exit 1
        }

        #Now clean and convert the JSON (PowerShell 5.1 requirement)
        $configFileData = $configFileData -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'

        try {
            $configFileData  = $configFileData | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }

        #Validate the provided settings

        #region Target Section Validation - General

        #Target.DeliveryType
        if ($configFileData.Target.DeliveryType -notin $Validated_Delivery_Types) {
            Write-Log -Message "Delivery Type $($configFileData.Target.DeliveryType) is not a valid type. Please check config file" -Level Error
            $ErrorCount ++
        }

        #Target.CloneType
        if ($configFileData.Target.CloneType -notin $Validated_Clone_Types) {
            Write-Log -Message "Clone Type: $($configFileData.Target.CloneType) is not a valid type. Please check config file" -Level Error
            $ErrorCount ++
        }

        #Target.SessionCfg
        if ($configFileData.Target.SessionCfg -notin $Validated_SessionCfg) {
            Write-Log -Message "SessionCfg Type: $($configFileData.Target.SessionCfg) is not a valid type. Please check config file" -Level Error
            $ErrorCount ++
        }

        #Target.Workload
        if ($configFileData.Target.Workload -notin $Validated_Workload_Profiles ) {
            Write-Log -Message "Worker Profile: $($configFileData.Target.Workload) is not a valid type. Please check config file" -Level Error
            $ErrorCount ++
        }

        #Target.SessionsSupport
        if ($configFileData.Target.SessionsSupport -notin $Validated_Session_Support ) {
            Write-Log -Message "Session Support: $($configFileData.Target.SessionsSupport) is not a valid type. Please check config file" -Level Error
            $ErrorCount ++
        }

        #endregion Target Section Validation - General
        
        #region Target Section Validation - Citrix
        if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
            #Target.FunctionalLevel
            if ($configFileData.Target.FunctionalLevel -notin $Validated_Functional_Levels) {
                Write-Log -Message "Citrix Functional Level Type $($configFileData.Target.FunctionalLevel) is not a valid type. Please check config file" -Level Error
                $ErrorCount ++
            }
        }
        
        #endregion Target Section Validation - Citrix

        #region Target Section Validation - Horizon
        if ($Type -eq "Horizon") {
            #Target.RefreshOsDiskAfterLogoff
            if ($configFileData.Target.RefreshOsDiskAfterLogoff -notin $Validated_RefreshOsDiskAfterLogoff) {
                Write-Log -Message "Horizon RefreshOsDiskAfterLogoff Type $($configFileData.Target.RefreshOsDiskAfterLogoff) is not a valid type. Please check config file" -Level Error
                $ErrorCount ++
            }

            #Target.UserAssignment
            if ($configFileData.Target.UserAssignment -notin $Validated_User_Assignments) {
                Write-Log -Message "Horizon UserAssignment Type $($configFileData.Target.UserAssignment) is not a valid type. Please check config file" -Level Error
                $ErrorCount ++
            }

            #Target.ProvisioningMode
            if ($configFileData.Target.ProvisioningMode -notin $Validated_Provisioning_Modes) {
                Write-Log -Message "Horizon ProvisioningMode Type $($configFileData.Target.ProvisioningMode) is not a valid type. Please check config file" -Level Error
                $ErrorCount ++
            }
        }
        #endregion Target Section Validation - Horizon

        #region Test Section

        #Test.BucketName
        if ($configFileData.Test.BucketName -notin $Validated_Bucket_Names) {
            Write-Log -Message "Test Bucket Name $($configFileData.Target.BucketName) is not a valid type. Please check config file" -Level Error
            $ErrorCount ++
        }

        #endregion Test Section

        # Validate based on error count
        if ($ErrorCount -gt 0) {
            $JSONPass = $false
        }
        else {
            $JSONPass = $true
        }
        
        # Settings are good to go
        if($JSONPass){
            $Return = $true
        }
    }

    end {
        Return $Return
    }
}
