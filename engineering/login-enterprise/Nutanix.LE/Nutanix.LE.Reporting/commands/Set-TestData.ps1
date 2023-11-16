function Set-TestData {
<#
    .SYNOPSIS
    Add a Nutanix Login Enterprise Test Data run to Grafana.

    .DESCRIPTION
    This function will add test data to the Tests influx bucket in Grafana to enable test tracking via Grafana.

    .PARAMETER TestName
    The test name.

    .PARAMETER RunNumber
    The test run number.

    .PARAMETER ConfigFile
    The test run config file with the test data.

    .PARAMETER InfluxUri
    The Influx DB Uri.

    .PARAMETER InfluxBucket
    The Influx DB Bucketname.

    .PARAMETER Status
    The Test Status.

    .PARAMETER CurrentMessage
    The Test CurrentMessage.

    .PARAMETER ErrorMessage
    (Optional) The error message.

    .PARAMETER CurrentPhase
    The percent completion of the current test.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    This function will return boolean value $true or $false based on the result of the test data addition.

    .EXAMPLE
    PS> Set-TestData -ConfigFile "DaveConfig.jsonc" -TestName "990965_8n_A6.5.4_ESXi_1303V_1303U_KW" -RunNumber "1" -InfluxUri "http://1.1.1.1:8086/api/v2/write?org=Nutanix&precision=s" -InfluxBucket "Tests" -Status "Error" -PercentComplete "15" -ErrorMessage "Test"
    Adds the test data based on the $ConfigFile JSON file and Test Name passed in.

    .LINK
    Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Help/Set-TestData.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Nutanix.LE

#>
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$ConfigFile,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$TestName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$RunNumber,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$InfluxUri,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$InfluxBucket,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][ValidateSet("Planned","Running","Complete","Error","UploadError")]$Status,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)]$ErrorMessage,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$CurrentPhase,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$TotalPhase,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$CurrentMessage
    )

    begin{

        # Set strict mode 
        Set-StrictMode -Version Latest

        # Read in the Config File
        if(Test-Path -Path $ConfigFile){
            $ConfigFound = $true
            $ConfigJSON = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        } else {
            $ConfigFound = $false
        }

    }

    process {

        if($ConfigFound){

            # Build Web Headers
            $WebHeaders = @{
                Authorization = "Token $($ConfigJSON.TestInfra.InfluxToken)"
            }

            # Build Unix Date
            $StartDate = Get-Date
            $UnixStartedDate = Get-Date -Date $StartDate -UFormat %s
            $NewStartDate = $UnixStartedDate.Split(".")
            $FormattedStartDate = $NewStartDate[0]
            $CurrentYear = get-date -Format yyyy
            $CurrentMonth = get-date -Format MM

            # Build Influx DB Url
            $influxDbUri = $InfluxUri + "&bucket=$($InfluxBucket)"

            # Build the test status
            switch ($Status)
            {
                "Planned" { $StatusInt = "0"}
                "Running" { $StatusInt = "1"}
                "Complete" { $StatusInt = "2"}
                "Error" { $StatusInt = "3"}
                "UploadError" { $StatusInt = "4" }
            }
            $Fields = "TestStatus=$($StatusInt)"

            # Build the Test Tags
            $LEAppliance = ($ConfigJSON.Users.BaseName).Replace("VSI", "")
            $Tag = (
                "Run=$($RunNumber)," +
                "ImageIterations=$($ConfigJSON.Target.ImageIterations)," +
                "DataType=TestInfo," +
                "Document=$($ConfigJSON.Test.DocumentName)," +
                "Status=$($Status)," +
                "CurrentPhase=$($CurrentPhase)," +
                "TotalPhases=$($TotalPhase)," +
                "CurrentMessage=$($CurrentMessage)," +
                "Year=$($CurrentYear)," +
                "Month=$($CurrentMonth)," +
                "DeliveryType=$($ConfigJSON.Target.DeliveryType)," +
                "DesktopBrokerVersion=$($ConfigJSON.Target.DesktopBrokerVersion)," +
                "DesktopBrokerAgentVersion=$($ConfigJSON.Target.ImagesToTest.DesktopBrokerAgentVersion)," +
                "CloneType=$($ConfigJSON.Target.CloneType)," +
                "SessionCfg=$($ConfigJSON.Target.SessionCfg)," +
                "SessionsSupport=$($ConfigJSON.Target.SessionsSupport)," +
                "NodeCount=$($ConfigJSON.Target.NodeCount)," +
                "Workload=$($ConfigJSON.Target.Workload)," +
                "NumCPUs=$($ConfigJSON.Target.ImagesToTest.NumCpus)," +
                "NumCores=$($ConfigJSON.Target.ImagesToTest.NumCores)," +
                "MemoryGB=$($ConfigJSON.Target.ImagesToTest.MemoryGB)," +
                "HostGPUs=$($ConfigJSON.TestInfra.HostGPUs)," +
                "SecureBoot=$($ConfigJSON.Target.ImagesToTest.SecureBoot)," +
                "vTPM=$($ConfigJSON.Target.ImagesToTest.vTPM)," +
                "CredentialGuard=$($ConfigJSON.Target.ImagesToTest.CredentialGuard)," +
                "AutocalcVMs=$($ConfigJSON.Target.ImagesToTest.AutocalcVMs)," +
                "Max=$($ConfigJSON.Target.ImagesToTest.Max)," +
                "NumberOfSessions=$($ConfigJSON.Target.ImagesToTest.NumberOfSessions)," +
                "NumberOfVMs=$($ConfigJSON.Target.ImagesToTest.NumberOfVMs)," +
                "TargetOS=$($ConfigJSON.Target.ImagesToTest.TargetOS)," +
                "TargetOSVersion=$($ConfigJSON.Target.ImagesToTest.TargetOSVersion)," +
                "OfficeVersion=$($ConfigJSON.Target.ImagesToTest.OfficeVersion)," +
                "ToolsGuestVersion=$($ConfigJSON.Target.ImagesToTest.ToolsGuestVersion)," +
                "OptimizerVendor=$($ConfigJSON.Target.ImagesToTest.OptimizerVendor)," +
                "OptimizationsVersion=$($ConfigJSON.Target.ImagesToTest.OptimizationsVersion)," +
                "GPUProfile=$($ConfigJSON.Target.ImagesToTest.GPUProfile)," +
                "Comment=$($ConfigJSON.Target.ImagesToTest.Comment)," +
                "InfraSSDCount=$($ConfigJSON.TestInfra.SSDCount)," +
                "InfraSingleNodeTest=$($ConfigJSON.TestInfra.SingleNodeTest)," +
                "InfraTestName=$($ConfigJSON.TestInfra.TestName)," +
                "InfraHardwareType=$($ConfigJSON.TestInfra.HardwareType)," +
                "InfraFullVersion=$($ConfigJSON.TestInfra.FullVersion)," +
                "InfraCPUBrand=$($ConfigJSON.TestInfra.CPUBrand)," +
                "InfraCPUType=$($ConfigJSON.TestInfra.CPUType)," +
                "InfraAOSVersion=$($ConfigJSON.TestInfra.AOSVersion)," +
                "InfraHypervisorBrand=$($ConfigJSON.TestInfra.HypervisorBrand)," +
                "InfraHypervisorVersion=$($ConfigJSON.TestInfra.HypervisorVersion)," +
                "InfraHypervisorType=$($ConfigJSON.TestInfra.HypervisorType)," +
                "InfraBIOS=$($ConfigJSON.TestInfra.BIOS)," +
                "InfraTotalNodes=$($ConfigJSON.TestInfra.TotalNodes)," +
                "InfraCPUCores=$($ConfigJSON.TestInfra.CPUCores)," +
                "InfraCPUThreadCount=$($ConfigJSON.TestInfra.CPUThreadCount)," +
                "InfraCPUSocketCount=$($ConfigJSON.TestInfra.CPUSocketCount)," +
                "InfraCPUSpeed=$($ConfigJSON.TestInfra.CPUSpeed)," +
                "InfraMemoryGB=$($ConfigJSON.TestInfra.MemoryGB)," +
                "MaxAbsoluteActiveActions=$($ConfigJSON.TestInfra.MaxAbsoluteActiveActions)," +
                "MaxAbsoluteNewActionsPerMinute=$($ConfigJSON.TestInfra.MaxAbsoluteNewActionsPerMinute)," +
                "MaxPercentageActiveActions=$($ConfigJSON.TestInfra.MaxPercentageActiveActions)," + 
                "DataCenter=$($ConfigJSON.testinfra.Datacenter)," + 
                "ClusterName=$($ConfigJSON.testinfra.ClusterName)," + 
                "LEAppliance=$($LEAppliance)," + 
                "User=$($ConfigJSON.Target.CVM_admin)"
            )

            if(($StatusInt -eq "3") -or ($StatusInt -eq "4")){
                $Tag = $Tag + ",ErrorMessage=$($ErrorMessage)"
            } else {
                $Tag = $Tag + ",ErrorMessage=None"
            }

            # Clean the spaces in the Tags
            $NewTag = $Tag.Replace("=,", "=0,")
            $Tag = Set-CleanData -Data $NewTag

            # Update Influx DB
            $Body = "$TestName,$Tag $Fields $FormattedStartDate"
            try {
                Invoke-RestMethod -Method Post -Uri $influxDbUri -Headers $WebHeaders -Body $Body
                $Return = $true
            } catch {
                $Return = $false
            }

        } else {

            # Config File not found - returning $false
            $Return = $false

        }

    } # process

    end {

        # Return data for the function
        return $Return

    } # end

}
