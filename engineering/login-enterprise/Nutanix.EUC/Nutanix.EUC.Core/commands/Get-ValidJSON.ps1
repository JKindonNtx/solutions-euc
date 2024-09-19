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
        $Validated_Delivery_Types = @("Citrix","VMware","RAS", "Microsoft", "Omnissa")
        $Validated_Clone_Types = @("MCS", "Instant Clones", "Full Clone", "Linked Clone", "PVS", "Full", "Manual")
        $Validated_SessionCfg =@("ICA","PCoIP","Blast","RDP")
        $Validated_Workload_Profiles = @("Task Worker", "Knowledge Worker", "GPU Worker")
        $Validated_Session_Support = @("multisession", "singlesession")
        #Target Section Hypervisor Settings
        $Validated_Hypervisors = @("AHV","ESXi","Azure")
        #Target Section Citrix Valid Settings
        $Validated_Functional_Levels = @("L5", "L7", "L7_6", "L7_7", "L7_8", "L7_9", "L7_20", "L7_25", "L7_30", "L7_34")
        #Target Section VMWare Horizon Valid Settings
        $Validated_RefreshOsDiskAfterLogoff = @("ALWAYS","NEVER")
        $Validated_User_Assignments = @("DEDICATED","FLOATING")
        $Validated_Provisioning_Modes = @("AllMachinesUpFront","OnDemand","Manual")
        $Validated_Omnissa_Provisioning_Modes = @("Manual")
        #Test Section Valid Settings
        $Validated_Bucket_Names = @("LoginDocuments", "LoginRegression", "AzurePerfData", "PVSPerfData")
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

        # Check that HypervisorType has been defined and is of a valid type
        if ($configFileData.Target.psobject.Properties.Name -notcontains "HypervisorType"){
            Write-Log -Message "You are missing the Target.HypervisorType object in your JSON file." -Level Error
            $ErrorCount ++
        }
        if ($configFileData.Target.HypervisorType -notin $Validated_Hypervisors) {
            Write-Log -Message "Hypervisor Type $($configFileData.Target.HypervisorType) is not a valid type. Please check config file" -Level Error
            $ErrorCount ++
        }

        if ($configFileData.Target.psobject.Properties.Name -notcontains "ForceAlignVMToHost"){
            Write-Log -Message "You are missing the Target.ForceAlignVMToHost object in your JSON file." -Level Error
            $ErrorCount ++
        }
        if ($configFileData.Target.psobject.Properties.Name -notcontains "EnforceHostMaintenanceMode"){
            Write-Log -Message "You are missing the Target.EnforceHostMaintenanceMode object in your JSON file." -Level Error
            $ErrorCount ++
        }

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
        if (($Type -eq "CitrixVAD") -or ($Type -eq "CitrixDaaS")) {
            #Target.FunctionalLevel
            if ($configFileData.Target.FunctionalLevel -notin $Validated_Functional_Levels) {
                Write-Log -Message "Citrix Functional Level Type $($configFileData.Target.FunctionalLevel) is not a valid type. Please check config file" -Level Error
                $ErrorCount ++
            }

            #Target.OrchestrationMethod
            if ($configFileData.Target.psobject.Properties.Name -notcontains "OrchestrationMethod"){
                Write-Log -Message "You are missing the Target.OrchestrationMethod object in your JSON file. This is required to define either API or Snapin (PowerShell) driven automation" -Level Error
                $ErrorCount ++
            }
        }

        if ($Type -eq "CitrixDaaS" -and $configFileData.Target.OrchestrationMethod -eq "API") {
            #CitrixDaaS.Region
            if ($configFileData.CitrixDaaS.psobject.Properties.Name -notcontains "Region"){
                Write-Log -Message "You are missing the CitrixDaaS.Region object in your JSON file. This is required for Citrix DaaS Authentication via API" -Level Error
                $ErrorCount ++
            }
            #CitrixDaaS.CustomerID
            if ($configFileData.CitrixDaaS.psobject.Properties.Name -notcontains "CustomerID"){
                Write-Log -Message "You are missing the CitrixDaaS.CustomerID object in your JSON file. This is required for Citrix DaaS Authentication via API" -Level Error
                $ErrorCount ++
            }
            #CitrixDaaS.ClientID
            if ($configFileData.CitrixDaaS.psobject.Properties.Name -notcontains "ClientID"){
                Write-Log -Message "You are missing the CitrixDaaS.ClientID object in your JSON file. This is required for Citrix DaaS Authentication via API" -Level Error
                $ErrorCount ++
            }
            #CitrixDaaS.ClientSecret
            if ($configFileData.CitrixDaaS.psobject.Properties.Name -notcontains "ClientSecret"){
                Write-Log -Message "You are missing the CitrixDaaS.ClientSecret object in your JSON file. This is required for Citrix DaaS Authentication via API" -Level Error
                $ErrorCount ++
            }
        }

        if ($Type -eq "CitrixVAD" -or $Type -eq "CitrixDaaS") {
            # Check for API specific hosting requirements
            if ($configFileData.Target.OrchestrationMethod -eq "API") {
                # Target.HostingConnectionRootName
                if ($configFileData.Target.psobject.Properties.Name -notcontains "HostingConnectionRootName") {
                    Write-Log -Message "You are missing the Target.HostingConnectionRootName object in your JSON file. This is required for Citrix Hosting Jobs via API" -Level Error
                    $ErrorCount ++
                }
            }

            # Check for API specific hosting requirements with ESXi
            if ($configFileData.Target.OrchestrationMethod -eq "API" -and $configFileData.Target.HypervisorType -eq "ESXi") {
                # Target.vSphereDataCenter
                if ($configFileData.Target.psobject.Properties.Name -notcontains "vSphereDataCenter") {
                    Write-Log -Message "You are missing the Target.vSphereDataCenter object in your JSON file. This is required for Citrix Hosting Jobs via API when using ESXi" -Level Error
                    $ErrorCount ++
                }
                # Target.vSphereCluster
                if ($configFileData.Target.psobject.Properties.Name -notcontains "vSphereCluster") {
                    Write-Log -Message "You are missing the Target.vSphereCluster object in your JSON file. This is required for Citrix Hosting Jobs via API when using ESXi" -Level Error
                    $ErrorCount ++
                }
            }
        }
        
        #endregion Target Section Validation - Citrix

        #region vSphere and hostd service restart
        if ($configFileData.Target.HypervisorType -eq "ESXi" -and $configFileData.vSphere.RestartHostd -eq $true) {
            # This test is going to want to restart the hostd services. Check for required values in the JSON file
            #vSphere.vCenter
            if ($configFileData.vSphere.psobject.Properties.Name -notcontains "vCenter"){
                Write-Log -Message "You are missing the vSphere.vCenter object in your JSON file. This is required for communication to vCenter" -Level Error
                $ErrorCount ++
            }
            #vSphere.User
            if ($configFileData.vSphere.psobject.Properties.Name -notcontains "User"){
                Write-Log -Message "You are missing the vSphere.User object in your JSON file. This is required for communication to vCenter" -Level Error
                $ErrorCount ++
            }
            #vSphere.Password
            if ($configFileData.vSphere.psobject.Properties.Name -notcontains "Password"){
                Write-Log -Message "You are missing the vSphere.Password object in your JSON file. This is required for communication to vCenter" -Level Error
                $ErrorCount ++
            }
            #vSphere.ClusterName
            if ($configFileData.vSphere.psobject.Properties.Name -notcontains "ClusterName"){
                Write-Log -Message "You are missing the vSphere.ClusterName object in your JSON file. This is required for communication to vCenter" -Level Error
                $ErrorCount ++
            }
            #vSphere.Datacenter
            if ($configFileData.vSphere.psobject.Properties.Name -notcontains "DataCenter"){
                Write-Log -Message "You are missing the vSphere.DataCenter object in your JSON file. This is required for communication to vCenter" -Level Error
                $ErrorCount ++
            }
            #vSphere.SshUsername
            if ($configFileData.vSphere.psobject.Properties.Name -notcontains "SshUsername"){
                Write-Log -Message "You are missing the vSphere.SshUsername object in your JSON file. This is required for communication with esxi hosts" -Level Error
                $ErrorCount ++
            }
            #vSphere.SshPassword
            if ($configFileData.vSphere.psobject.Properties.Name -notcontains "SshPassword"){
                Write-Log -Message "You are missing the vSphere.SshPassword object in your JSON file. This is required for communication with esxi hosts" -Level Error
                $ErrorCount ++
            }
        }
        #endregion vSphere and hostd service restart

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

        #region Target Section Validation - Omnissa
        if ($Type -eq "Omnissa") {
            #Target.OmnissaConnectionServer
            if ($ConfigFileData.Target.psobject.Properties.Name -notcontains "OmnissaConnectionServer") {
                Write-Log -Message "You are missing the Target.OmnissaConnectionServer object in your JSON file. This is required for Omnissa Tests" -Level Error
                $ErrorCount ++
            }
            #Target.OmnissaApiUserName
            if ($ConfigFileData.Target.psobject.Properties.Name -notcontains "OmnissaApiUserName") {
                Write-Log -Message "You are missing the Target.OmnissaApiUserName object in your JSON file. This is required for Omnissa Tests" -Level Error
                $ErrorCount ++
            }
            #Target.OmnissaApiPassword
            if ($ConfigFileData.Target.psobject.Properties.Name -notcontains "OmnissaApiPassword") {
                Write-Log -Message "You are missing the Target.OmnissaApiPassword object in your JSON file. This is required for Omnissa Tests" -Level Error
                $ErrorCount ++
            }
            #Target.OmnissaApiDomain
            if ($ConfigFileData.Target.psobject.Properties.Name -notcontains "OmnissaApiDomain") {
                Write-Log -Message "You are missing the Target.OmnissaApiDomain object in your JSON file. This is required for Omnissa Tests" -Level Error
                $ErrorCount ++
            }
            #Target.OmnissaProvisioningMode
            if ($ConfigFileData.Target.psobject.Properties.Name -notcontains "OmnissaProvisioningMode") {
                Write-Log -Message "You are missing the Target.OmnissaProvisioningMode object in your JSON file. This is required for Omnissa Tests" -Level Error
                $ErrorCount ++
            }
            # Provisioning Mode Validation
            if ($configFileData.Target.OmnissaProvisioningMode -notin $Validated_Omnissa_Provisioning_Modes) {
                Write-Log -Message "Omnissa Provisioning Mode Type $($configFileData.Target.OmnissaProvisioningMode) is not a valid type. Please check config file" -Level Error
                $ErrorCount ++
            }
        }
        #endregion Target Section Validation - Omnissa

        #region Target Section Validation - Launcher Cluster
        if ($ConfigFileData.Target.Monitor_Launcher_Cluster_Performance -eq $true) {
            #Target.Launcher_Cluster_CVM
            if ($ConfigFileData.Target.psobject.Properties.Name -notcontains "Launcher_Cluster_CVM") {
                Write-Log -Message "You are missing the Target.Launcher_Cluster_CVM object in your JSON file. This is required for Launcher Cluster Monitoring" -Level Error
                $ErrorCount ++
            }
            #Target.Launcher_Cluster_Host
            if ($ConfigFileData.Target.psobject.Properties.Name -notcontains "Launcher_Cluster_Host") {
                Write-Log -Message "You are missing the Target.Launcher_Cluster_Host object in your JSON file. This is required for Launcher Cluster Monitoring" -Level Error
                $ErrorCount ++
            }
            #Target.Launcher_Cluster_CVM_admin
            if ($ConfigFileData.Target.psobject.Properties.Name -notcontains "Launcher_Cluster_CVM_admin") {
                Write-Log -Message "You are missing the Target.Launcher_Cluster_CVM_admin object in your JSON file. This is required for Launcher Cluster Monitoring" -Level Error
                $ErrorCount ++
            }
            #Target.Launcher_Cluster_CVM_password
            if ($ConfigFileData.Target.psobject.Properties.Name -notcontains "Launcher_Cluster_CVM_password") {
                Write-Log -Message "You are missing the Target.Launcher_Cluster_CVM_password object in your JSON file. This is required for Launcher Cluster Monitoring" -Level Error
                $ErrorCount ++
            }
        }
        #endregion Target Section Validation - Launcher Cluster

        #region Test Section

        #Test.BucketName
        if ($configFileData.Test.BucketName -notin $Validated_Bucket_Names) {
            Write-Log -Message "Test Bucket Name $($configFileData.Target.BucketName) is not a valid type. Please check config file" -Level Error
            $ErrorCount ++
        }

        #Test.RebootLaunchers
        if ($configFileData.Test.psobject.Properties.Name -notcontains "RebootLaunchers"){
            Write-Log -Message "You are missing the Test.RebootLaunchers object in your JSON file. This is required to control LE Launcher reboots" -Level Error
            $ErrorCount ++
        }

        #Test.StartObserverMonitoring
        if ($configFileData.Test.psobject.Properties.Name -notcontains "StartObserverMonitoring"){
            Write-Log -Message "You are missing the Test.StartObserverMonitoring object in your JSON file. This is required for enabling or disabling of Observer monitoring" -Level Error
            $ErrorCount ++
        }

        #Target.Host_root_password
        if ($configFileData.Test.StartObserverMonitoring -eq $true) {
            If ($configFileData.Target.psobject.Properties.Name -notcontains "Host_root_password"){
                Write-Log -Message "You are missing the Target.Host_root_password object in your JSON file. This is required for Observer monitoring settings" -Level Error
                $ErrorCount ++
            }
        }

        #endregion Test Section

        #region Advanced Diagnostics
        if ($ConfigFileData.psobject.Properties.Name -contains "AdvancedDiagnostics") {
            # we have the Advanced Diagnostics Element in the Config file
            #AdvancedDiagnostics.EnableCollectPerf
            if ($ConfigFileData.AdvancedDiagnostics.psobject.Properties.Name -notcontains "EnableCollectPerf") {
                Write-Log -Message "You are missing the AdvancedDiagnostics.EnableCollectPerf object in your JSON file. This is required for collect_perf monitoring" -Level Error
                $ErrorCount ++
            }
            #AdvancedDiagnostics.CollectPerfSampleInterval
            if ($ConfigFileData.AdvancedDiagnostics.psobject.Properties.Name -notcontains "CollectPerfSampleInterval") {
                Write-Log -Message "You are missing the AdvancedDiagnostics.CollectPerfSampleInterval object in your JSON file. This is required for collect_perf monitoring" -Level Error
                $ErrorCount ++
            }
            #AdvancedDiagnostics.CollectPerfSampleFrequency
            if ($ConfigFileData.AdvancedDiagnostics.psobject.Properties.Name -notcontains "CollectPerfSampleFrequency") {
                Write-Log -Message "You are missing the AdvancedDiagnostics.CollectPerfSampleFrequency object in your JSON file. This is required for collect_perf monitoring" -Level Error
                $ErrorCount ++
            }
        }
        #endregion Advanced Diagnostics

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
