# -----------------------------------------------------------------------------------------------------------------------
# Section - Define Script Variables - to do - PDF / Logo image / Script Params and Switches for false items
# -----------------------------------------------------------------------------------------------------------------------
Write-Host "Setup Script Parameters"

# User Input Script Variables
$maxLength = 65536
[System.Console]::SetIn([System.IO.StreamReader]::new([System.Console]::OpenStandardInput($maxLength), [System.Console]::InputEncoding, $false, $maxLength))

# Source Uri - This is the Uri for the Grafana Dashboard you want the report for
Write-Host "Enter the Uri from Grafana that you would like the NetScaler Report for"
$SourceUri = [System.Console]::ReadLine()

if($SourceUri -eq ""){
    write-host "You MUST enter a Source Uri"
    break
}

# Report Title - This is the Title that you want for your report
Write-Host "Enter the Report Title"
$ReportTitle = [System.Console]::ReadLine()

if($ReportTitle -eq ""){
    write-host "You MUST enter a Report Title"
    break
}


# -----------------------------------------------------------------------------------------------------------------------
# Section - Boiler Plates
# -----------------------------------------------------------------------------------------------------------------------

$BoilerPlateIntroduction = @"
This document is part of the Nutanix Solutions Architecture Artifacts. We wrote it for individuals responsible for designing, building, managing, testing and supporting Nutanix infrastructures. Readers should be familiar with Nutanix and Citrix products as well as familiar with Black Widow testing.
"@

$BoilerPlateExecSummary = @"
Nutanix designed its software to give customers running workloads in a hybrid cloud environment the same experience they expect from on-premises Nutanix clusters. Because Nutanix in a hybrid multicloud environment runs AOS and AHV with the same CLI, UI, and APIs, existing IT processes and third-party integrations continue to work regardless of where they run.

Nutanix AOS can withstand hardware failures and software glitches and ensures that application availability and performance are never compromised. Combining features like native rack awareness with public cloud partition placement groups, Nutanix operates freely in a dynamic hybrid multicloud environment.

In addition to desktop and application performance reliability, you get unlimited scalability, data locality, AHV clones, and a single datastore when you deploy Citrix Virtual Apps and Desktops on Nutanix. Nutanix takes the Citrix commitment to simplicity to another level with streamlined management, reduced rollout time, and lower operating expenses.
"@

$BoilerPlateConclusion = @"
This document is part of the Nutanix Solutions Architecture Artifacts. We wrote it for individuals responsible for designing, building, managing, testing and supporting Nutanix infrastructures with Citrix NetScaler. Readers should be familiar with Nutanix and Citrix products as well as familiar with Black Widow testing.
"@

# -----------------------------------------------------------------------------------------------------------------------
# Section - Display Options and Start Report
# -----------------------------------------------------------------------------------------------------------------------

# Write out a SNAZZY header
Clear
Write-Host "
_____ _   _  ____   _____             _                      _             
| ____| | | |/ ___| | ____|_ __   __ _(_)_ __   ___  ___ _ __(_)_ __   __ _ 
|  _| | | | | |     |  _| | '_ \ / _` | | '_ \ / _ \/ _ \ '__| | '_ \ / _` |
| |___| |_| | |___  | |___| | | | (_| | | | | |  __/  __/ |  | | | | | (_| |
|_____|\___/ \____| |_____|_| |_|\__, |_|_| |_|\___|\___|_|  |_|_| |_|\__, |
                                 |___/                                |___/ 
"

# Display the selected options selected back to the user
Write-Host "
--------------------------------------------------------------------------------------------------------"
Write-Host "Report Title:                  $($ReportTitle)"
Write-Host "
--------------------------------------------------------------------------------------------------------"

# Ask for confirmation to start the build - if no the quit
Do { $confirmationStart = Read-Host "Ready to run the report? [y/n]" } Until (($confirmationStart -eq "y") -or ($confirmationStart -eq "n"))

if ($confirmationStart -eq 'n') { 
    Write-Host (Get-Date) ":Confirmation denied, quitting"
    exit 
} else {

    # -----------------------------------------------------------------------------------------------------------------------
    # Section - Functions
    # -----------------------------------------------------------------------------------------------------------------------

    # Write formatted output to screen
    Write-Host "Setup Script Functions"

    function Write-Screen {
        param
        (
            $Message
        )

        Write-Host "$(get-date -format "dd/MM/yyyy HH:mm") - $($Message)"
    }

    # Get Uri Variable Information
    function Get-UriVariable {
        param(
            $Uri,
            $Var
        )

        $SourceSplit = $Uri.Split("&") 

        $i = 0
        foreach($Line in $SourceSplit){
            $LineSplit = $Line.Split("=")
            if($LineSplit[0] -eq "$($Var)"){
                If($i -eq 0){
                    $Return = $LineSplit[1]
                    $i++
                } else {
                    $Return = $Return + "|" + $LineSplit[1]
                }
            }
        }

        Write-Screen -Message "Getting Uri Variable $($Var): $($Return)"
        Return $Return
    }

    # Get Test Detail Order Index
    function Get-PayloadIndex {
        param(
            $TestDetails
        )

        $TestDetailSplit = $TestDetails.Split("`n")
        Write-Screen -Message "Split Test Detail Into Array"

        # Set up PSCustom Object for Array Index
        $Return = New-Object -TypeName psobject 
        $Headers = ($TestDetailSplit[0]).Split(",")
        for ($i = 3; $i -le (($Headers).Count - 1) ; $i++)
        {    
            $Value = ($Headers[$i]).Trim()
            $Return | Add-Member -MemberType NoteProperty -Name $i -Value $Value
        
        }

        Write-Screen -Message "Return Test Payload Index"
        Return $Return
    }

    # Get the Test Detail Results
    function Get-PayloadResults {
        param(
            $TestDetails,
            $Order
        )

        $TestDetailSplit = $TestDetails.Split("`n")
        Write-Screen -Message "Split Test Detail Into Array"

        $Return = @()
        $i = 0
        foreach($TestLine in $TestDetailSplit){
            if(!($i -eq 0)){
                $Line = $TestLine.Split(",")
                if(!($null -eq $Line[3])){
                    $Item = New-Object -TypeName psobject 
                    for ($x = 3; $x -le (($Line).Count - 1) ; $x++)
                    {    
                        [string]$Value = $Line[$x]
                        $TrimmedValue = $Value.Trim()
                        [string]$Name = $Order.$x
                        $TrimmedName = $Name.Trim()
                        $Item | Add-Member -MemberType NoteProperty -Name $TrimmedName -Value $TrimmedValue
                    }
                    $Return += $item
                }
            }
            $i++
        }

        Write-Screen -Message "Return Test Payload Results"
        Return $Return
    }

    # Download a file from Uri
    function Get-UriFile{
        param (
            $Uri,
            $OutFile
        )

        $ProgressPreference = 'SilentlyContinue' 

        Write-Screen -Message "Downloading $($OutFile)"
        try {
            $Result = Invoke-WebRequest -Uri $Uri -outfile $OutFile
            Write-Screen -Message "Download Complete"
        } catch {
            Write-Screen -Message "Download $($OutFile) Failed"
        }
    }

    # Get Grafana Graphs
    function Get-Graphs {
        param (
            $Panels,
            $EndTime,
            $SourceUri,
            $imagePath
        )

        foreach($Panel in $Panels){

            # Build Uri to download image
            $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
            $Uri = $UpdatedUri + "&from=1672534800000&to=$($EndTime)&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"

            # Get output Filename
            switch ($Panel)
            {
                158 {$OutFile = Join-Path -Path $imagePath -ChildPath "appliance_test_overview.png"}
                81 {$OutFile = Join-Path -Path $imagePath -ChildPath "appliance_memory_details.png"}
                80 {$OutFile = Join-Path -Path $imagePath -ChildPath "appliance_cpu_details.png"}
                104 {$OutFile = Join-Path -Path $imagePath -ChildPath "appliance_http_details.png"}
                82 {$OutFile = Join-Path -Path $imagePath -ChildPath "appliance_throughput_details.png"}
                127 {$OutFile = Join-Path -Path $imagePath -ChildPath "appliance_ssl_details.png"}
                126 {$OutFile = Join-Path -Path $imagePath -ChildPath "appliance_tcp_details.png"}

                135 {$OutFile = Join-Path -Path $imagePath -ChildPath "cpu_packet_engine.png"}
                136 {$OutFile = Join-Path -Path $imagePath -ChildPath "cpu_management_engine.png"}
                137 {$OutFile = Join-Path -Path $imagePath -ChildPath "cpu_vm_cpu.png"}
                138 {$OutFile = Join-Path -Path $imagePath -ChildPath "cpu_vm_cpu_ready.png"}

                141 {$OutFile = Join-Path -Path $imagePath -ChildPath "throughput_throughput_rx.png"}
                142 {$OutFile = Join-Path -Path $imagePath -ChildPath "throughput_throughput_tx.png"}

                145 {$OutFile = Join-Path -Path $imagePath -ChildPath "ssl_transaction_rate.png"}
                146 {$OutFile = Join-Path -Path $imagePath -ChildPath "ssl_total_transactions.png"}
                147 {$OutFile = Join-Path -Path $imagePath -ChildPath "ssl_ecdhe_transaction_rate.png"}
                148 {$OutFile = Join-Path -Path $imagePath -ChildPath "ssl_ecdhe_total_transactions.png"}

                151 {$OutFile = Join-Path -Path $imagePath -ChildPath "http_request_rate.png"}
                152 {$OutFile = Join-Path -Path $imagePath -ChildPath "http_response_rate.png"}

                157 {$OutFile = Join-Path -Path $imagePath -ChildPath "error_dropped_tx_packets.png"}
                156 {$OutFile = Join-Path -Path $imagePath -ChildPath "error_dropped_rx_packets.png"}
                155 {$OutFile = Join-Path -Path $imagePath -ChildPath "error_tcp_reset_packets.png"}

            }

            # Download the image
            Get-UriFile -Uri $Uri -outfile $OutFile
        }
    }

    # Add Table Headers
    function Add-TableHeaders {
        param (
            $mdFullFile,
            $TableTitle,
            $TableData,
            $TableImage
        )

        # Add the table title
        Write-Screen -Message "Adding Table Header for $($TableTitle)"
        Add-Content $mdFullFile "### $($TableTitle)"

        # Add the Table Headers
        $HeaderLine = ""
        $TableLine = ""
        for ($i = 0; $i -lt (($TableData).Count + 1) ; $i++)
        {    
            if($i -eq 0){
                $HeaderLine = "| $($TableImage) "
                $TableLine = "| --- "
            } else {
                $Name = ($TableData[$i - 1].comment).replace("_", " ")
                $HeaderLine = $HeaderLine + "| $($Name) "
                $TableLine = $TableLine + "| --- "
                if($i -eq ($TableData.Count)){
                    $HeaderLine = $HeaderLine + "|"
                    $TableLine = $TableLine + "|"
                }
            }
        }
        Add-Content $mdFullFile $HeaderLine
        Add-Content $mdFullFile $TableLine
    }

    # Trim Data Item
    function Get-CleanData {
        param (
            $Data
        )

        # Trim the Data
        $TrimmedData = $Data.Trim()

        # Replace Underscores
        $Return = $TrimmedData.Replace("_", " ")

        # Return the trimmed Data
        Return $Return
    }

    # Add Title Text
    function Add-Title{
        param(
            $Title,
            $mdFullFile
        )

        Add-Content $mdFullFile ""
        Add-Content $mdFullFile "## <span style=""color:#7855FA"">$($Title)</span>"
    }

    # Add the Graphs
    function Add-Graphs {
        param(
            $Source,
            $Title,
            $mdFullFile
        )

        # Add Section Title
        Write-Screen -Message "Adding Graphs for $($Title)"

        # Loop through each image and insert it into the document
        foreach($Image in $Source){
            
            # Get Image Title and Image Link
            $TitleRaw = ($Image.BaseName).Replace("_", " ")
            $Title = (Get-Culture).TextInfo.ToTitleCase($TitleRaw)
            $Path = "../images/$($Image.BaseName).png"
            $Link = "<img src=$($Path) alt=$($Title) style=""border: 2px solid #7855FA;"">"
            Add-Content $mdFullFile "$($Link)"
        }
    }

    # -----------------------------------------------------------------------------------------------------------------------
    # Section - Script Variables - do not change
    # -----------------------------------------------------------------------------------------------------------------------

    $influxDbUrl = "http://10.57.64.119:8086/api/v2/query?orgID=bca5b8aeb2b51f2f"
    $InfluxToken = "b4yxMiQGOAlR3JftuLHuqssnwo-SOisbC2O6-7od7noAE5W1MLsZxLF7e63RzvUoiOHObc9G8_YOk1rnCLNblA=="
    Write-Screen -Message "Set InfluxDB Uri: $($influxDbUrl)"

    $iconsSource = "http://10.57.64.119:3000/public/img/nutanix/"
    Write-Screen -Message "Set Icon Uri: $($iconsSource)"

    # -----------------------------------------------------------------------------------------------------------------------
    # Section - Get Data From Influx for Report
    # -----------------------------------------------------------------------------------------------------------------------
    Write-Screen -Message "Gathering Test Data"

    # Build the Influx DB Web Headers
    $WebHeaders = @{
        Authorization = "Token $InfluxToken"
        "Accept" = "application/csv"
        "Content-Type" = "application/vnd.flux"
    }
    Write-Screen -Message "Build InfluxDB Web Headers"

    $FormattedBucket = (Get-UriVariable -Uri $SourceUri -Var "var-Bucketname").Replace('.', '\.')
    $FormattedYear = (Get-UriVariable -Uri $SourceUri -Var "var-Year").Replace('.', '\.')
    $FormattedMonth = (Get-UriVariable -Uri $SourceUri -Var "var-Month").Replace('.', '\.')
    $FormattedDocumentName = (Get-UriVariable -Uri $SourceUri -Var "var-DocumentName").Replace('.', '\.')
    $FormattedComment = (Get-UriVariable -Uri $SourceUri -Var "var-Comment").Replace('.', '\.')
    $FormattedTestname = (Get-UriVariable -Uri $SourceUri -Var "var-Testname").Replace('.', '\.')
    $FormattedNaming = (Get-UriVariable -Uri $SourceUri -Var "var-Naming").Replace('.', '\.')
    Write-Screen -Message "Finished Parsing Uri Variable Information"

    # Build Body
$Body = @"
newNaming = if "$($FormattedNaming)" == "_measurement" then "" else "$($FormattedNaming)"
from(bucket:"$($FormattedBucket)")
|> range(start: 2023-01-01T01:00:00Z, stop: 2023-01-01T02:07:00Z)
|> filter(fn: (r) => r["Year"] =~ /^$($FormattedYear)$/ )
|> filter(fn: (r) => r["Month"] =~ /^$($FormattedMonth)$/ )
|> filter(fn: (r) => r["DocumentName"] =~ /^$($FormattedDocumentName)$/ )
|> filter(fn: (r) => r["Comment"] =~ /^$($FormattedComment)$/ )
|> filter(fn: (r) => r["_measurement"] =~ /^$($FormattedTestname)$/ )
|> group(columns: ["_measurement", "Threads", "ParallelConnections", "TestType", "InfraCPUCores", "InfraCPUSocketCount", "InfraCPUSpeed", "InfraHypervisorType", "InfraTotalNodes", "InfraCPUType", "InfraHypervisorVersion", "InfraAOSVersion", "InfraTestName", "Comment", "NetScalerDescription", "NetScalerVersion", "NetScalervCPU", "NetScalerMemory"])
|> last()
|> map(fn: (r) => ({measurement: r._measurement, "TestThreads": r.Threads, "TestParallelConnections": r.ParallelConnections, "TTestType": r.TestType, "Clusternodes": r.InfraTotalNodes, "Node CPU Cores": r.InfraCPUCores, "Node CPU Sockets": r.InfraCPUSocketCount, "CPU Speed": r.InfraCPUSpeed, "Hypervisor version": r.InfraHypervisorVersion, "AOS": r.InfraAOSVersion, Hypervisor: r.InfraHypervisorType, "CPU": r.InfraCPUType, Testname: r.InfraTestName, "comment": r.Comment, "NSDescription": r.NetScalerDescription, "NSVersion": r.NetScalerVersion, "NSvCPU": r.NetScalervCPU, "NSMemory": r.NetScalerMemory}))
"@
    Write-Screen -Message "Build Body Payload based on Uri Variables"

    # Get the test details table from Influx and Split into individual lines
    try{
        Write-Screen -Message "Get Test Details from Influx API"
        $TestDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $Body
    } catch {
        Write-Screen -Message "Error Getting Test Details from Influx API"
        break
    }

    # Get Test Detail Payload Index
    $Order = Get-PayloadIndex -TestDetails $TestDetails

    # Build the Test Detail Results Array
    $TestDetailResults = Get-PayloadResults -TestDetails $TestDetails -Order $Order

    # -----------------------------------------------------------------------------------------------------------------------
    # Section - Create Directory
    # -----------------------------------------------------------------------------------------------------------------------

    # Convert the Report Title to PascalCase and Create Report Output Directory
    Write-Screen -Message "Checking Output Directory"
    $Directory = (Get-Culture).TextInfo.ToTitleCase($ReportTitle) -Replace " "
    if(!(Test-Path -Path $Directory)){
        Write-Screen -Message "Directory: $($Directory) Does Not Exist, Creating"
        $dir = New-Item $Directory -type Directory
        $md = New-Item  (Join-Path -Path $Directory -ChildPath "md") -type Directory
        $images = New-Item  (Join-Path -Path $Directory -ChildPath "images") -type Directory
        $imagePath = Join-Path -Path $dir.Name -ChildPath $images.Name
        $mdPath = Join-Path -Path $dir.Name -ChildPath $md.Name
        Write-Screen -Message "Created Images Directory: $($imagePath)"
        Write-Screen -Message "Created Markdown Directory $($mdPath)"
    } else {
        Write-Screen -Message "Directory: $($Directory) Already Exists, Please Change Report Title"
        break 
    }

    # -----------------------------------------------------------------------------------------------------------------------
    # Section - Download Icons
    # -----------------------------------------------------------------------------------------------------------------------
    Write-Screen -Message "Downloading Icons"
    $icons = @('Nutanix-Logo','bootinfo','hardware','infrastructure','broker','targetvm','loginenterprise','testicon','leresults','hostresources','clusterresources','logintimes','individualruns','appresults','euxmeasurements','filesicon','citrixnetscaler','base_image','sample-eux-score-graph','sample-login-enterprise-graph','rdainfo','appsperf')   

    # Loop through the icons and download the images
    foreach($icon in $icons){
        Get-UriFile -Uri ($iconsSource + "$($icon).png") -OutFile (Join-Path -Path $imagePath -ChildPath "$($icon).png")
    }

    # -----------------------------------------------------------------------------------------------------------------------
    # Section - Download NetScaler Graphs
    # -----------------------------------------------------------------------------------------------------------------------

    Write-Screen -Message "Downloading NetScaler Graphs"

    # Build the PanelID Array 
    $Panels = @('158','81','80','104','82','127','126','135','136','137','138','141','142','145','146','147','148','151','152','157','156','155')  
    $endtime = "1672538820000"
        
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath

    # -----------------------------------------------------------------------------------------------------------------------
    # Section - Create Report
    # -----------------------------------------------------------------------------------------------------------------------

    # Create the File path and initial file
    $mdFullFile = Join-Path -Path $mdPath -ChildPath "README.MD"
    $mdFile = "README.MD"
    if(!(Test-Path -Path $mdFullFile)){
        Write-Screen -Message "Creating Markdown File: $($mdFile)"
        $mdOutput = New-Item -Path $mdPath -Name $mdFile -ItemType File
    } else {
        Write-Screen -Message "Markdown File: $($mdFile) Already Exists, Please Delete and Re-run Script"
        break
    }

    # -----------------------------------------------------------------------------------------------------------------------
    # Section - Create Header
    # -----------------------------------------------------------------------------------------------------------------------

    # Center Section
    Add-Content $mdFullFile "<div style=""text-align: center;"">"

    # Add Nutanix Logo
    Write-Screen -Message "Adding Nutanix Logo and Header Image"
    $Link = "<img src=../images/Nutanix-Logo.png alt=Nutanix>"
    Add-Content $mdFullFile "$($Link)"

    # Add Team Title
    Add-Content $mdFullFile "<h1> Solutions and Performance Engineering - EUC </h1>"

    # Add Boiler Plate Image
    $Link = "<img src=../images/base_image.png alt=Nutanix>"
    Add-Content $mdFullFile "$($Link)"

    # Create the Title 
    Write-Screen -Message "Adding Report Title"
    Add-Content $mdFullFile "<h1> $($ReportTitle) </h1>"

    # End Centering
    Add-Content $mdFullFile "</div>"

    # Add Page Break
    Add-Content $mdFullFile "<div style=""page-break-after: always;""></div>"

    # Create the Exec Summary
    Write-Screen -Message "Adding Executive Summary"
    Add-Title -mdFullFile $mdFullFile -Title "Executive Summary"
    Add-Content $mdFullFile "$($BoilerPlateExecSummary)"

    # Create the Introduction
    Write-Screen -Message "Adding Introduction"
    Add-Title -mdFullFile $mdFullFile -Title "Introduction"
    Add-Content $mdFullFile "### Audience"
    Add-Content $mdFullFile "$($BoilerPlateIntroduction)"
    Add-Content $mdFullFile "### Purpose"
    Add-Content $mdFullFile "This document covers the following subject areas:"
    Add-Content $mdFullFile " - Test Detail Specifics."
    Add-Content $mdFullFile " - Test Results for $($ReportTitle)."
    Add-Content $mdFullFile "### Document Version History "
    Add-Content $mdFullFile "| Version Number | Published | Notes |"
    Add-Content $mdFullFile "| :---: | --- | --- |"
    $Month = get-date -format "MM"
    $ReportMonth = (Get-Culture).DateTimeFormat.GetMonthName($Month)  
    $ReportYear = get-date -format "yyyy" 
    Add-Content $mdFullFile "| 1.0 | $($ReportMonth) $($ReportYear) | Original publication. |"

    # Add Page Break
    Add-Content $mdFullFile "<div style=""page-break-after: always;""></div>"

    # -----------------------------------------------------------------------------------------------------------------------
    # Section - Test Detail Specifics
    # -----------------------------------------------------------------------------------------------------------------------
    Write-Screen -Message "Add Test Detail Header"
    Add-Title -mdFullFile $mdFullFile -Title "Test Details"

    # -----------------------------------------------------------------------------------------------------------------------
    # Hardware Specifics Section
    # -----------------------------------------------------------------------------------------------------------------------
    $Title = "Hardware Specifics"
    Write-Screen -Message "Adding $($Title)"

    # Get Filtered Data
    $HardwareFiltered = $TestDetailResults | Select comment, measurement, Testname, "Hypervisor", "Hypervisor Version", AOS, Clusternodes, "CPU Speed", "Node CPU Sockets", "Node CPU Cores" | Sort-Object Name | Get-Unique -AsString

    # Add the Table Header
    Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $Title -TableData $HardwareFiltered -TableImage "<img src=../images/hardware.png alt=$($Title)>"

    # Build the Table Dataset
    Write-Screen -Message "Building $($Title) Data"
    [string]$Hypervisor = "| **Hypervisor** | "
    [string]$HypervisorVersion = "| **Hypervisor Version** | "
    [string]$AOS = "| **AOS** | "
    [string]$Clusternodes = "| **Cluster Nodes** | "
    [string]$CPUSpeed = "| **CPU Speed** | "
    [string]$NodeCPUSockets = "| **Node CPU Sockets** | "
    [string]$NodeCPUCores = "| **Node CPU Cores** | "

    foreach($Record in $HardwareFiltered){
        $Hypervisor = $Hypervisor + "$(Get-CleanData -Data ($Record.Hypervisor)) | "
        $HypervisorVersion = $HypervisorVersion + "$(Get-CleanData -Data ($Record."Hypervisor Version")) | "
        $AOS = $AOS + "$(Get-CleanData -Data ($Record.AOS)) | "
        $Clusternodes = $Clusternodes + "$(Get-CleanData -Data ($Record.Clusternodes)) | "
        $CPUSpeed = $CPUSpeed + "$(Get-CleanData -Data ($Record."CPU Speed")) | "
        $NodeCPUSockets = $NodeCPUSockets + "$(Get-CleanData -Data ($Record."Node CPU Sockets")) | "
        $NodeCPUCores = $NodeCPUCores + "$(Get-CleanData -Data ($Record."Node CPU Cores")) | "
    }

    # Add the Table
    Write-Screen -Message "Adding $($Title) Data"
    Add-Content $mdFullFile $Hypervisor
    Add-Content $mdFullFile $HypervisorVersion
    Add-Content $mdFullFile $AOS
    Add-Content $mdFullFile $Clusternodes
    Add-Content $mdFullFile $CPUSpeed
    Add-Content $mdFullFile $NodeCPUSockets
    Add-Content $mdFullFile $NodeCPUCores

    # -----------------------------------------------------------------------------------------------------------------------
    # NetScaler Specifics Section
    # -----------------------------------------------------------------------------------------------------------------------
    $Title = "NetScaler Specifics"
    Write-Screen -Message "Adding $($Title)"

    # Get Filtered Data
    $NetScalerFiltered = $TestDetailResults | Select comment, measurement, Testname, "NSDescription", "NSVersion", NSvCPU, NSMemory | Sort-Object Name | Get-Unique -AsString

    # Add the Table Header
    Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $Title -TableData $NetScalerFiltered -TableImage "<img src=../images/citrixnetscaler.png alt=$($Title)>"

    # Build the Table Dataset
    Write-Screen -Message "Building $($Title) Data"
    [string]$NSDescription = "| **NetScaler Type** | "
    [string]$NSVersion = "| **NetScaler Version** | "
    [string]$NSvCPU = "| **vCPU's** | "
    [string]$NSMemory = "| **Memory** | "

    foreach($Record in $NetScalerFiltered){
        $NSDescription = $NSDescription + "$(Get-CleanData -Data ($Record.NSDescription)) | "
        $NSVersion = $NSVersion + "$(Get-CleanData -Data ($Record."NSVersion")) | "
        $NSvCPU = $NSvCPU + "$(Get-CleanData -Data ($Record.NSvCPU)) | "
        $NSMemory = $NSMemory + "$(Get-CleanData -Data ($Record.NSMemory)) | "
    }

    # Add the Table
    Write-Screen -Message "Adding $($Title) Data"
    Add-Content $mdFullFile $NSDescription
    Add-Content $mdFullFile $NSVersion
    Add-Content $mdFullFile $NSvCPU
    Add-Content $mdFullFile $NSMemory

    # -----------------------------------------------------------------------------------------------------------------------
    # Test Specifics Section
    # -----------------------------------------------------------------------------------------------------------------------
    $Title = "Black Widow Test Specifics"
    Write-Screen -Message "Adding $($Title)"

    # Get Filtered Data
    $BWFiltered = $TestDetailResults | Select comment, measurement, Testname, "TTestType", "TestThreads", TestParallelConnections | Sort-Object Name | Get-Unique -AsString

    # Add the Table Header
    Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $Title -TableData $BWFiltered -TableImage "<img src=../images/leresults.png alt=$($Title)>"

    # Build the Table Dataset
    Write-Screen -Message "Building $($Title) Data"
    [string]$TTestType = "| **Test Type** | "
    [string]$TestThreads = "| **Threads** | "
    [string]$TestParallelConnections = "| **Parallel Connections** | "

    foreach($Record in $BWFiltered){
        $TTestType = $TTestType + "$(Get-CleanData -Data ($Record.TTestType)) | "
        $TestThreads = $TestThreads + "$(Get-CleanData -Data ($Record."TestThreads")) | "
        $TestParallelConnections = $TestParallelConnections + "$(Get-CleanData -Data ($Record.TestParallelConnections)) | "
    }

    # Add the Table
    Write-Screen -Message "Adding $($Title) Data"
    Add-Content $mdFullFile $TTestType
    Add-Content $mdFullFile $TestThreads
    Add-Content $mdFullFile $TestParallelConnections

    # Add Page Break
    Add-Content $mdFullFile "<div style=""page-break-after: always;""></div>"

    # -----------------------------------------------------------------------------------------------------------------------
    # Section - Test Results
    # -----------------------------------------------------------------------------------------------------------------------
    Add-Title -mdFullFile $mdFullFile -Title "Test Results"

    # -----------------------------------------------------------------------------------------------------------------------
    # Section - Citrix NetScaler Graphing
    # -----------------------------------------------------------------------------------------------------------------------

    $Title = "Citrix NetScaler Appliance Overview"
    Add-Content $mdFullFile "### $($Title)"

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "appliance*")} | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Appliance Information" -mdFullFile $mdFullFile

    Add-Content $mdFullFile " "

    # Add Page Break
    Add-Content $mdFullFile "<div style=""page-break-after: always;""></div>"

    $Title = "CPU Detail"
    Add-Content $mdFullFile " "
    Add-Content $mdFullFile "### $($Title)"

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "cpu*")} | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "CPU Information" -mdFullFile $mdFullFile

    Add-Content $mdFullFile " "

    # Add Page Break
    Add-Content $mdFullFile "<div style=""page-break-after: always;""></div>"

    $Title = "Throughput Detail"
    Add-Content $mdFullFile " "
    Add-Content $mdFullFile "### $($Title)"

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "throughput*")} | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Throughput Information" -mdFullFile $mdFullFile

    Add-Content $mdFullFile " "
    
    # Add Page Break
    Add-Content $mdFullFile "<div style=""page-break-after: always;""></div>"

    $Title = "SSL Detail"
    Add-Content $mdFullFile " "
    Add-Content $mdFullFile "### $($Title)"

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "ssl*")} | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "SSL Information" -mdFullFile $mdFullFile

    Add-Content $mdFullFile " "

    # Add Page Break
    Add-Content $mdFullFile "<div style=""page-break-after: always;""></div>"

    $Title = "HTTP Detail"
    Add-Content $mdFullFile " "
    Add-Content $mdFullFile "### $($Title)"

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "http*")} | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "HTTP Information" -mdFullFile $mdFullFile

    Add-Content $mdFullFile " "

    # Add Page Break
    Add-Content $mdFullFile "<div style=""page-break-after: always;""></div>"

    $Title = "Error Detail"
    Add-Content $mdFullFile " "
    Add-Content $mdFullFile "### $($Title)"

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "error*")} | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Error Information" -mdFullFile $mdFullFile

    Add-Content $mdFullFile " "

    # Add Page Break
    Add-Content $mdFullFile "<div style=""page-break-after: always;""></div>"

    # -----------------------------------------------------------------------------------------------------------------------
    # Section - Conclusion
    # -----------------------------------------------------------------------------------------------------------------------
    Write-Screen -Message "Adding Conclusion"
    Add-Title -mdFullFile $mdFullFile -Title "Conclusion"
    Add-Content $mdFullFile "$($BoilerPlateConclusion)"

}