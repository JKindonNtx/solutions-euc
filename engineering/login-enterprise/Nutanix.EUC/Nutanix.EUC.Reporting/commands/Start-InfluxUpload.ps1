function Start-InfluxUpload {
<#
    .SYNOPSIS
    Uploads the test data to InfluxDB.

    .DESCRIPTION
    This function will take the test run data and upload the results to the Influx DB.

    .PARAMETER influxDbUrl
    The Influx DB Uri.

    .PARAMETER ResultsPath
    The path to the results file.

    .PARAMETER Token
    The Influx Authentication Token.

    .PARAMETER Boot
    Switch to enable Boot upload.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    This function will return boolean value $true or $false based on the result of the test data addition.

    .EXAMPLE
    PS> Start-InfluxUpload
    Uploads the test data set to Influx.

    .LINK
    Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Help/Start-InfluxUpload.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Nutanix.EUC

#>

    [CmdletBinding()]

    param(
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][string]$influxDbUrl,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][string]$ResultsPath,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][string]$Token,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$File,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$Started,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$BucketName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.Boolean]$IsAzureVM
    )

    begin {

        # Set strict mode 
        # Set-StrictMode -Version Latest

        # Read in the Config File
        $JSONFile = Join-Path $ResultsPath "TestConfig.json"

        if(Test-Path -Path $JSONFile){
            $ConfigFound = $true
            # Read in the Config File
            $JSON = Get-Content -Path $JSONFile -Raw | ConvertFrom-Json

            # Get the Test Details from the JSON File
            $MeasurementName = $($JSON.TestInfra.TestName)
            $MeasurementDetail = $MeasurementName -Split '_Run'
            $MeasurementName = $MeasurementDetail[0]
            $Run = $MeasurementDetail[1]

            # Calculate the Fixed Start Date
            $StartDate = [DateTime] "01/01/2023 1:00 AM"
            $UnixStartedDate = Get-Date -Date $StartDate -UFormat %s
            $NewStartDate = $UnixStartedDate.Split(".")
            $FormattedStartDate = $NewStartDate[0]

            # Build Web Header
            $WebHeaders = @{
                Authorization = "Token $Token"
            }

            # Build VSI Results Data
            if($JSON.Target.ImagesToTest.EUXEnabled){
                $vsiresult = Import-CSV "$($ResultsPath)\VSI-results.csv"
                $VSIProductVersion = $vsiresult.productVersion
                $VSIEUXVersion = $vsiresult."EUX version"
                $VSIActiveSessionCount = $vsiresult.activesessionCount
                $VSIEUXScore = $vsiresult."EUX score"
                $VSIEUXState = $vsiresult."EUX state"
                $VSIMax = $vsiresult.vsiMax
                $VSIMaxState = $vsiresult."vsiMax state"
                $VSIMaxVersion = $vsiresult."vsiMax version"
            } else {
                $VSIProductVersion = "N/A"
                $VSIEUXVersion = "N/A"
                $VSIActiveSessionCount = "0"
                $VSIEUXScore = "0"
                $VSIEUXState = "0"
                $VSIMax = "0"
                $VSIMaxState = "0"
                $VSIMaxVersion = "0"
            }

            # Build Unix Start Date based on new Started Date
            $UnixStarted = Get-Date -Date $Started -UFormat %s
            $NewStarted = $UnixStarted.Split(".")
            $FormattedStarted = $NewStarted[0]
            $DeltaTime = $FormattedStarted - $FormattedStartDate
            
            # Build Influx Upload Uri
            $influxDbUrl = $influxDbUrl + "&bucket=$($BucketName)"
            
            # Get the Current Month and Year
            $CurrentYear = get-date -Format yyyy
            $CurrentMonth = get-date -Format MM

        } else {
            $ConfigFound = $false
        }
    }
    
    process {

        if($ConfigFound){

            # Build Tags
            $TopLevelTag = $File.BaseName
            if ($IsAzureVM -eq $true) {
                # This is an Azure VM, so set specific tags for Azure 
                $Tag = (
                    "Run=$($Run)," +
                    "DataType=$($TopLevelTag)," +
                    "Year=$($CurrentYear)," +
                    "Month=$($CurrentMonth)," +
                    "DocumentName=$($JSON.Test.DocumentName)," +
                    "DeliveryType=$($JSON.Target.DeliveryType)," +
                    "DesktopBrokerVersion=$($JSON.Target.DesktopBrokerVersion)," +
                    "DesktopBrokerAgentVersion=$($JSON.Target.ImagesToTest.DesktopBrokerAgentVersion)," +
                    "CloneType=$($JSON.Target.CloneType)," +
                    "SessionCfg=$($JSON.Target.SessionCfg)," +
                    "SessionsSupport=$($JSON.Target.SessionsSupport)," +
                    "Workload=$($JSON.Target.Workload)," +
                    "NumCPUs=$($JSON.AzureGuestDetails.VM_CPU_LogicalProcs)," +
                    "NumCores=$($JSON.AzureGuestDetails.VM_CPU_Cores)," +
                    "MemoryGB=$($JSON.AzureGuestDetails.VM_Memory_Size)," +
                    "HostGPUs=$($JSON.TestInfra.HostGPUs)," +
                    "SecureBoot=$($JSON.AzureGuestDetails.VM_secureBoot)," +
                    "vTPM=$($JSON.AzureGuestDetails.VM_vTPM)," +
                    "CredentialGuard=$($JSON.AzureGuestDetails.VM_Credential_Guard)," +
                    "AutocalcVMs=$($JSON.Target.ImagesToTest.AutocalcVMs)," +
                    "Max=$($JSON.Target.ImagesToTest.Max)," +
                    "NumberOfSessions=$($JSON.Target.ImagesToTest.NumberOfSessions)," +
                    "NumberOfVMs=$($JSON.Target.ImagesToTest.NumberOfVMs)," +
                    "TargetOS=$($JSON.Target.ImagesToTest.TargetOS)," +
                    "TargetOSVersion=$($JSON.Target.ImagesToTest.TargetOSVersion)," +
                    "OfficeVersion=$($JSON.Target.ImagesToTest.OfficeVersion)," +
                    "ToolsGuestVersion=$($JSON.Target.ImagesToTest.ToolsGuestVersion)," +
                    "OptimizerVendor=$($JSON.Target.ImagesToTest.OptimizerVendor)," +
                    "OptimizationsVersion=$($JSON.Target.ImagesToTest.OptimizationsVersion)," +
                    "GPUProfile=$($JSON.Target.ImagesToTest.GPUProfile)," +
                    "Comment=$($JSON.Target.ImagesToTest.Comment)," +
                    "InfraTestName=$($JSON.TestInfra.TestName)," +
                    "InfraCPUBrand=$($JSON.AzureGuestDetails.VM_CPU_Manufacturer)," +
                    "InfraCPUType=$($JSON.AzureGuestDetails.VM_CPU_Name)," +
                    "InfraCPUSpeed=$($JSON.AzureGuestDetails.VM_CPU_ClockSpeed)," +
                    "InfraBIOS=$($JSON.AzureGuestDetails.VM_Bios_NameBIOS)," +
                    "BootStart=$($JSON.TestInfra.BootStart)," +                    
                    "BootTime=$($JSON.TestInfra.Boottime)," +
                    "VSIproductVersion=$($VSIProductVersion)," +
                    "VSIEUXversion=$($VSIEUXVersion)," +
                    "VSIactivesessionCount=$($VSIActiveSessionCount)," +
                    "VSIEUXscore=$($VSIEUXScore)," +
                    "VSIEUXstate=$($VSIEUXState)," +
                    "VSIvsiMax=$($VSIMax)," +  
                    "VSIvsiMaxstate=$($VSIMaxState)," + 
                    "VSIvsiMaxversion=$($VSIMaxVersion)," +
                    #// Azure Components that are not captured above
                    "AzVMName=$($JSON.AzureGuestDetails.VM_Name)," +
                    "AzVMLoc=$($JSON.AzureGuestDetails.VM_Location)," +
                    "AzVMOffer=$($JSON.AzureGuestDetails.VM_Offer)," +
                    "AzVMSize=$($JSON.AzureGuestDetails.VM_Size)," +
                    "AzVMCPUCaption=$($JSON.AzureGuestDetails.VM_CPU_Caption)," +
                    "AzVMCPUThreadCount=$($JSON.AzureGuestDetails.VM_CPU_ThreadCount)," +
                    "AzVMAccelNetwork=$($JSON.AzureGuestDetails.VM_AcceleratedNetworking)," +
                    "AzVMpageFile=$($JSON.AzureGuestDetails.VM_pageFile)," +
                    "AzOSType=$($JSON.AzureGuestDetails.OS_Type)," +
                    "AzOSOffer=$($JSON.AzureGuestDetails.OS_Offer)," +
                    "AzOSDeployedVer=$($JSON.AzureGuestDetails.OS_Deployed_Version)," +
                    "AzOSDeployedSku=$($JSON.AzureGuestDetails.OS_Deployed_Sku)," +
                    "AzOSRunningVer=$($JSON.AzureGuestDetails.OS_Running_Version)," +
                    "AzDiskType=$($JSON.AzureGuestDetails.Disk_Type)," +
                    "AzDiskSize=$($JSON.AzureGuestDetails.Disk_Size)," +
                    "AzDiskCaching=$($JSON.AzureGuestDetails.Disk_Caching)," +
                    "AzDiskEncryp=$($JSON.AzureGuestDetails.Disk_Encryption)," +
                    "AzDiskWriteAccel=$($JSON.AzureGuestDetails.Disk_Write_Accelerator)," +
                    "AzDiskTempDiskSize=$($JSON.AzureGuestDetails.Disk_TempDisk_Size)"
                )
            } else {
                # This is a noraml test, not an Azure VM. So set the normal tags
                $Tag = (
                    "Run=$($Run)," +
                    "DataType=$($TopLevelTag)," +
                    "Year=$($CurrentYear)," +
                    "Month=$($CurrentMonth)," +
                    "DocumentName=$($JSON.Test.DocumentName)," +
                    "DeliveryType=$($JSON.Target.DeliveryType)," +
                    "DesktopBrokerVersion=$($JSON.Target.DesktopBrokerVersion)," +
                    "DesktopBrokerAgentVersion=$($JSON.Target.ImagesToTest.DesktopBrokerAgentVersion)," +
                    "CloneType=$($JSON.Target.CloneType)," +
                    "SessionCfg=$($JSON.Target.SessionCfg)," +
                    "SessionsSupport=$($JSON.Target.SessionsSupport)," +
                    "NodeCount=$($JSON.Target.NodeCount)," +
                    "Workload=$($JSON.Target.Workload)," +
                    "NumCPUs=$($JSON.Target.ImagesToTest.NumCpus)," +
                    "NumCores=$($JSON.Target.ImagesToTest.NumCores)," +
                    "MemoryGB=$($JSON.Target.ImagesToTest.MemoryGB)," +
                    "HostGPUs=$($JSON.TestInfra.HostGPUs)," +
                    "SecureBoot=$($JSON.Target.ImagesToTest.SecureBoot)," +
                    "vTPM=$($JSON.Target.ImagesToTest.vTPM)," +
                    "CredentialGuard=$($JSON.Target.ImagesToTest.CredentialGuard)," +
                    "AutocalcVMs=$($JSON.Target.ImagesToTest.AutocalcVMs)," +
                    "Max=$($JSON.Target.ImagesToTest.Max)," +
                    "NumberOfSessions=$($JSON.Target.ImagesToTest.NumberOfSessions)," +
                    "NumberOfVMs=$($JSON.Target.ImagesToTest.NumberOfVMs)," +
                    "TargetOS=$($JSON.Target.ImagesToTest.TargetOS)," +
                    "TargetOSVersion=$($JSON.Target.ImagesToTest.TargetOSVersion)," +
                    "OfficeVersion=$($JSON.Target.ImagesToTest.OfficeVersion)," +
                    "ToolsGuestVersion=$($JSON.Target.ImagesToTest.ToolsGuestVersion)," +
                    "OptimizerVendor=$($JSON.Target.ImagesToTest.OptimizerVendor)," +
                    "OptimizationsVersion=$($JSON.Target.ImagesToTest.OptimizationsVersion)," +
                    "GPUProfile=$($JSON.Target.ImagesToTest.GPUProfile)," +
                    "Comment=$($JSON.Target.ImagesToTest.Comment)," +
                    "InfraSSDCount=$($JSON.TestInfra.SSDCount)," +
                    "InfraSingleNodeTest=$($JSON.TestInfra.SingleNodeTest)," +
                    "InfraTestName=$($JSON.TestInfra.TestName)," +
                    "InfraHardwareType=$($JSON.TestInfra.HardwareType)," +
                    "InfraFullVersion=$($JSON.TestInfra.FullVersion)," +
                    "InfraCPUBrand=$($JSON.TestInfra.CPUBrand)," +
                    "InfraCPUType=$($JSON.TestInfra.CPUType)," +
                    "InfraAOSVersion=$($JSON.TestInfra.AOSVersion)," +
                    "InfraHypervisorBrand=$($JSON.TestInfra.HypervisorBrand)," +
                    "InfraHypervisorVersion=$($JSON.TestInfra.HypervisorVersion)," +
                    "InfraHypervisorType=$($JSON.TestInfra.HypervisorType)," +
                    "InfraBIOS=$($JSON.TestInfra.BIOS)," +
                    "InfraTotalNodes=$($JSON.TestInfra.TotalNodes)," +
                    "InfraCPUCores=$($JSON.TestInfra.CPUCores)," +
                    "InfraCPUThreadCount=$($JSON.TestInfra.CPUThreadCount)," +
                    "InfraCPUSocketCount=$($JSON.TestInfra.CPUSocketCount)," +
                    "InfraCPUSpeed=$($JSON.TestInfra.CPUSpeed)," +
                    "InfraMemoryGB=$($JSON.TestInfra.MemoryGB)," +
                    "BootStart=$($JSON.TestInfra.BootStart)," +                    
                    "BootTime=$($JSON.TestInfra.Boottime)," +
                    "MaxAbsoluteActiveActions=$($JSON.TestInfra.MaxAbsoluteActiveActions)," +
                    "MaxAbsoluteNewActionsPerMinute=$($JSON.TestInfra.MaxAbsoluteNewActionsPerMinute)," +
                    "MaxPercentageActiveActions=$($JSON.TestInfra.MaxPercentageActiveActions)," +
                    "VSIproductVersion=$($VSIProductVersion)," +
                    "VSIEUXversion=$($VSIEUXVersion)," +
                    "VSIactivesessionCount=$($VSIActiveSessionCount)," +
                    "VSIEUXscore=$($VSIEUXScore)," +
                    "VSIEUXstate=$($VSIEUXState)," +
                    "VSIvsiMax=$($VSIMax)," +  
                    "VSIvsiMaxstate=$($VSIMaxState)," + 
                    "VSIvsiMaxversion=$($VSIMaxVersion)"
                )
            }

            # Check for Blank Tag Value
            If($Tag -like "*=,*"){
                $TagValidated = $false
            } else {
                $TagValidated = $true
            }

            if($TagValidated){

                # Set the Base Tag
                $basetag = $tag

                # Get the CSV File Data
                $csvFilePath = $File
                $csvData = Import-Csv $csvFilePath

                # Get the CSV File Headers
                $headers = $csvData | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    
                # Process each line of the CSV File
                foreach ($line in $csvData) {

                    # Initialize Fields and set Tag to Base Tag
                    $fields = ""
                    $tag = $basetag

                    # Looop through headers and process data values
                    foreach($Header in $Headers){
                        if(($header -ne "Timestamp")){
                            if(($header -like "*Id") -or ($header -like "*Name*") -or ($header -like "*timer*") -or ($header -like "*instance*") -or ($header -like "*userSessionKey*")){
                                $Data = $($line.$($Header))
                                $tag = $tag + ",$($Header)=$($Data)"
                            } else {
                                $Data = $($line.$($Header))
                                $Fields = $Fields + "$($Header)=$($Data),"
                            }
                        }
                    }

                    # Remove last comma from fields and replace Null values
                    $Fields = $Fields.TrimEnd(",")
                    $Fields = $Fields.Replace('null', '0')

                    # Format the Tag to allow for influx upload
                    $tag = $tag.replace(' ','_')
                    $tag = $tag.replace('=,','=0,')
                    $tag = $tag.replace('\','-')
                    $tag = $tag.replace('%','pct')

                    # Get the timestamp for the line and calculate the delta Start Time
                    $CSVDate = $($line.Timestamp)
                    $UnixDate = Get-Date -Date $CSVDate -UFormat %s
                    $NewDate = $UnixDate.Split(".")
                    $FormattedDate = $newdate[0] - $DeltaTime   

                    # Build the body
                    $Body = "$measurementName,$tag $fields $FormattedDate"

                    # Upload the data to Unflux
                    $null = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $Body
                }

                $Return = $true
            } else {
                $Return = $false
            }

        } else {

            $Return = $false
        }

    }
    
    end {

        return $Return
    }
    
}