# -----------------------------------------------------------------------------------------------------------------------
# Section - Define Script Variables
# -----------------------------------------------------------------------------------------------------------------------

# User Input Script Variables

# Source Uri - This is the Uri for the Grafana Dashboard you want the report for
$SourceUri = "http://10.57.64.119:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2023&var-Month=07&var-Comment=Windows_10_Profile_Citrix_UPM_-_ABE_On&var-Comment=Windows_10_Profile_Citrix_UPM_-_All_Off&var-Testname=afb1a2_8n_A6.5.3.5_AHV_1000V_1000U_KW&var-Testname=8dcaca_8n_A6.5.3.5_AHV_1000V_1000U_KW&var-Run=8dcaca_8n_A6.5.3.5_AHV_1000V_1000U_KW_Run2&var-Run=afb1a2_8n_A6.5.3.5_AHV_1000V_1000U_KW_Run2&var-Run=afb1a2_8n_A6.5.3.5_AHV_1000V_1000U_KW_Run3&var-Run=8dcaca_8n_A6.5.3.5_AHV_1000V_1000U_KW_Run3&var-Naming=Comment&var-DocumentName=ENG-Profile-Files-Baseline&editPanel=85"

# Report Title - This is the Title that you want for your report
$ReportTitle = "Citrix UPM"

# Sections - Set the sections that you want in your report to $true 
$BootInfo = $true
$LoginEnterpriseResults = $true
$HostResources = $true
$ClusterResources = $true
$LoginTimes = $true
$IndividualRuns = $false
$Applications = $true
$VsiEuxMeasurements = $true
$NutanixFiles = $false
$CitrixNetScaler = $false

# Script Variables - do not change

# Influx DB Uri and Token
$influxDbUrl = "http://10.57.64.119:8086/api/v2/query?orgID=bca5b8aeb2b51f2f"
$InfluxToken = "b4yxMiQGOAlR3JftuLHuqssnwo-SOisbC2O6-7od7noAE5W1MLsZxLF7e63RzvUoiOHObc9G8_YOk1rnCLNblA=="

$BoilerPlateExecSummary = @"
Nutanix designed its software to give customers running workloads in a hybrid cloud environment the same experience they expect from on-premises Nutanix clusters. Because Nutanix in a hybrid multicloud environment runs AOS and AHV with the same CLI, UI, and APIs, existing IT processes and third-party integrations continue to work regardless of where they run.

Nutanix AOS can withstand hardware failures and software glitches and ensures that application availability and performance are never compromised. Combining features like native rack awareness with public cloud partition placement groups, Nutanix operates freely in a dynamic hybrid multicloud environment.

In addition to desktop and application performance reliability, you get unlimited scalability, data locality, AHV clones, and a single datastore when you deploy Citrix Virtual Apps and Desktops on Nutanix. Nutanix takes the Citrix commitment to simplicity to another level with streamlined management, reduced rollout time, and lower operating expenses.
"@

$BoilerPlateIntroduction = @"
This document is part of the Nutanix Solutions Architecture Artifacts. We wrote it for individuals responsible for designing, building, managing, testing and supporting Nutanix infrastructures. Readers should be familiar with Nutanix and Citrix products as well as familiar with Login Enterprise testing.
"@

$BoilerPlateLE = @'
### Login Enterprise

[Login VSI](http://www.loginvsi.com/) provides the industry-standard virtual desktop testing platform, Login Enterprise, which helps organizations benchmark and validate the performance and scalability of their virtual desktop solutions. With Login Enterprise, IT teams can reliably measure the effects of changes to their virtual desktop infrastructure on end-user experience and identify performance issues before they impact the business. Login Enterprise uses synthetic user workloads to simulate real-world user behavior, so IT teams can measure the responsiveness and performance of their virtual desktop environment under different scenarios. Login Enterprise has two built-in workloads: The [task worker](https://support.loginvsi.com/hc/en-us/articles/6949195003932-Task-Worker-Out-of-the-box) and [knowledge worker](https://support.loginvsi.com/hc/en-us/articles/6949191203740-Knowledge-Worker-Out-of-the-box).

<note>You can't compare the Login Enterprise workloads to the workloads included in the previous edition of Login VSI. The Login Enterprise workloads are much more resource intensive.</note>

The following table includes both workloads available in Login Enterprise.

_Table: Login Enterprise Workloads_

| **Task Worker** | **Knowledge Worker** |
| --- | --- |
| Light | Medium |
| 2 vCPU | 2 / 4 vCPU |
| 2 / 3 apps | 4 / 6 apps |
| No video | 720p video |

#### Login Enterprise EUX Score

According to the [Login Enterprise documentation](https://support.loginvsi.com/hc/en-us/articles/4408717958162-Login-Enterprise-EUX-Score-), the EUX (End User Experience) Score represents the performance of any Windows machine (virtual, physical, cloud, or on-premises). The score ranges from 0 to 10 and measures the experience of one (minimum) or many virtual users.

<note>As you add more users to your VDI platform, expect your EUX Score to drop. As more users demand a greater share of a VDI system’s shared resources, performance and user experience decrease.</note>

We interpret EUX Scores with the grades in the following table.

_Table: EUX Score Grades_

| **EUX Score** | **Grade** |
| --- | --- |
| 1 / 5 | Bad |
| 5 /  6 | Poor |
| 6 / 7 | Average |
| 7 / 8 | Good |
| 8 / 10 | Excellent |

#### Login Enterprise VSImax

For our test results, we used the 2023 EUX Score's version of VSImax. In this version, a number of triggers determine the VSImax (or the maximum number of users). These triggers are CPU- and disk-related operations and can determine whether the user experience is acceptable. EUX Scores below 5.5 are one example of a trigger.

We found that we could use this version of the VSImax to do an A/B comparison, but the VSImax on its own doesn't represent the maximum user density accurately. For a more realistic maximum number of users, we suggest using the number of active users at the moment when the EUX Score is 85 to 90 percent of the initial EUX Score.

<note>In the 2023 release of EUX Score, the disk-related operations of EUX have an unrealistic impact on storage. In our testing, we discovered that the IOPS are up to 10 times higher when the EUX metrics are enabled, with a read-to-write ratio of 70:30 percent during the steady state. In reality, a knowledge worker has a much lower I/O profile and a read-to-write ratio of 20 percent to 30 percent reads and 70 percent to 80 percent writes.</note>

#### Login Enterprise Metrics

We quantified the evaluation using the following metrics:

- EUX base: The average EUX Score of the first 5 minutes.
- EUX Score: The average EUX Score for the entire test.
- Steady State Score: The average EUX Score starting 5 minutes after the final logon to the end of the test.
- Average logon time: The average user logon time.
- VSImax: If reached, the maximum value of sessions launched before the VSI Index Average reaches one of the thresholds.
- Maximum CPU usage: The maximum observed CPU usage during the test.
- CPU usage during steady state: The average CPU usage during the steady state, or the state when all the sessions are active and using applications. This state simulates user activity during the entire day, rather than just during the logon period.

The Baseline and Steady State EUX Scores provide additional dimensions to the simulated user experience. The Standard EUX Score provides a single score for the entire test duration, including the login period and the application interaction period. As you add more users to the system you're testing, it works harder, and the user experience diminishes. The Steady State and Baseline EUX Scores describe the user experience during specific periods of the test run.

Baseline EUX Score
: The Baseline EUX Score represents the best possible performance of the system and is the average EUX Score of the best 5 minutes of the test. This score indicates how the system performs when it's not under stress. Typically you capture the Baseline EUX Score at the beginning of the test before the system is fully loaded.

Steady State EUX Score
: The steady state represents the period after all users have logged on (login storm) and the system has started to normalize. The Steady State EUX Score is the average of the EUX Scores captured between 5 minutes after all sessions have logged in and at the end of the test.

'@

# -----------------------------------------------------------------------------------------------------------------------
# Section - Get Data From Influx for Report
# -----------------------------------------------------------------------------------------------------------------------

# Split the Source Uri into an array
$SourceSplit = $SourceUri.Split("&") 

# Build the Influx DB Web Headers
$WebHeaders = @{
    Authorization = "Token $InfluxToken"
    "Accept" = "application/csv"
    "Content-Type" = "application/vnd.flux"
}

# Get Bucket Information from the Source Uri
$i = 0
foreach($Line in $SourceSplit){
    $LineSplit = $Line.Split("=")
    if($LineSplit[0] -eq "var-Bucketname"){
        If($i -eq 0){
            $Bucket = $LineSplit[1]
            $i++
        } else {
            $Bucket = $Bucket + "|" + $LineSplit[1]
        }
    }
}

# Get Year Information from the Source Uri
$i = 0
foreach($Line in $SourceSplit){
    $LineSplit = $Line.Split("=")
    if($LineSplit[0] -eq "var-Year"){
        If($i -eq 0){
            $Year = $LineSplit[1]
            $i++
        } else {
            $Year = $Year + "|" + $LineSplit[1]
        }
    }
}

# Get Month Information from the Source Uri
$i = 0
foreach($Line in $SourceSplit){
    $LineSplit = $Line.Split("=")
    if($LineSplit[0] -eq "var-Month"){
        If($i -eq 0){
            $Month = $LineSplit[1]
            $i++
        } else {
            $Month = $Month + "|" + $LineSplit[1]
        }
    }
}

# Get Reference Information from the Source Uri
$i = 0
foreach($Line in $SourceSplit){
    $LineSplit = $Line.Split("=")
    if($LineSplit[0] -eq "var-DocumentName"){
        If($i -eq 0){
            $DocumentName = $LineSplit[1]
            $i++
        } else {
            $DocumentName = $DocumentName + "|" + $LineSplit[1]
        }
    }
}

# Get Comment Information from the Source Uri
$i = 0
foreach($Line in $SourceSplit){
    $LineSplit = $Line.Split("=")
    if($LineSplit[0] -eq "var-Comment"){
        If($i -eq 0){
            $Comment = $LineSplit[1]
            $i++
        } else {
            $Comment = $Comment + "|" + $LineSplit[1]
        }
    }
}

# Get Test Name Information from the Source Uri
$i = 0
foreach($Line in $SourceSplit){
    $LineSplit = $Line.Split("=")
    if($LineSplit[0] -eq "var-Testname"){
        If($i -eq 0){
            $Testname = $LineSplit[1]
            $i++
        } else {
            $Testname = $Testname + "|" + $LineSplit[1]
        }
    }
}

# Get Run Information from the Source Uri
$i = 0
foreach($Line in $SourceSplit){
    $LineSplit = $Line.Split("=")
    if($LineSplit[0] -eq "var-Run"){
        If($i -eq 0){
            $TestRun = $LineSplit[1]
            $i++
        } else {
            $TestRun = $TestRun + "|" + $LineSplit[1]
        }
    }
}

# Format Data for Influx Query
$FormattedBucket = $($Bucket).replace('.','\.')
$FormattedYear = $($Year).replace('.','\.')
$FormattedMonth = $($Month).replace('.','\.')
$FormattedDocumentName = $($DocumentName).replace('.','\.')
$FormattedComment = $($Comment).replace('.','\.')
$FormattedTestname = $($Testname).replace('.','\.')
$FormattedTestRun = $($TestRun).replace('.','\.')

# Build Body
$Body = @"
from(bucket:"$($FormattedBucket)")
  |> range(start: 2023-01-01T01:00:00Z, stop: 2023-01-01T02:07:00Z)
  |> filter(fn: (r) => r["Year"] =~ /^$($FormattedYear)$/ )
  |> filter(fn: (r) => r["Month"] =~ /^$($FormattedMonth)$/ )
  |> filter(fn: (r) => r["DocumentName"] =~ /^$($FormattedDocumentName)$/ )
  |> filter(fn: (r) => r["Comment"] =~ /^$($FormattedComment)$/ )
  |> filter(fn: (r) => r["_measurement"] =~ /^$($FormattedTestname)$/ )
  |> filter(fn: (r) => r["InfraTestName"] =~ /^$($FormattedTestRun)$/ )
  |> filter(fn: (r) => r._field == "EUXScore")
  |> last()
  |> map(fn: (r) => ({measurement: r._measurement, run: r.Run, deliverytype: r.DeliveryType, desktopbrokerversion: r.DesktopBrokerVersion, desktopbrokeragentversion: r.DesktopBrokerAgentVersion, clonetype: r.CloneType, sessioncfg: r.SessionCfg, sessionssupport: r.SessionsSupport, nodecount: r.NodeCount, workload: r.Workload, numcpus: r.NumCPUs, numcores: r.NumCores, memorygb: r.MemoryGB, hostgpus: r.HostGPUs, secureboot: r.SecureBoot, vtpm: r.vTPM, credentialguard: r.CredentialGuard, numberofsessions: r.NumberOfSessions, numberofvms: r.NumberOfVMs, targetos: r.TargetOS, targetosversion: r.TargetOSVersion, officeversion: r.OfficeVersion, toolsguestversion: r.ToolsGuestVersion, optimizervendor: r.OptimizerVendor, optimizerversion: r.OptimizationsVersion, gpuprofile: r.GPUProfile, comment: r.Comment, infrassdcount: r.InfraSSDCount, infrasinglenodetest: r.InfraSingleNodeTest, infrahardwaretype: r.InfraHardwareType, infrafullversion: r.InfraFullVersion, infracpubrand: r.InfraCPUBrand, infracputype: r.InfraCPUType, infraaosversion: r.InfraAOSVersion, infrahypervisorbrand: r.InfraHypervisorBrand, infrahypervisorversion: r.InfraHypervisorVersion, infrahypervisortype: r.InfraHypervisorType, infrabios: r.InfraBIOS, infratotalnodes: r.InfraTotalNodes, infracpucores: r.InfraCPUCores, infracputhreadcount: r.InfraCPUThreadCount, infracpusocketcount: r.InfraCPUSocketCount, infracpuspeed: r.InfraCPUSpeed, inframemorygb: r.InfraMemoryGB, bootstart: r.BootStart, boottime: r.BootTime, maxabsoluteactiveactions: r.MaxAbsoluteActiveActions, maxabsolutenewactionsperminute: r.MaxAbsoluteNewActionsPerMinute, maxpercentageactiveactions: r.MaxPercentageActiveActions, vsiproductversion: r.VSIproductVersion, euxversion: r.VSIEUXversion, vsiactivesessioncount: r.VSIactivesessionCount, vsieuxscore: r.VSIEUXscore, vsieuxstate: r.VSIEUXstate, vsivsimax: r.VSIvsiMax, vsivsimaxstate: r.VSIvsiMaxstate, vsivsimaxversion: r.VSIvsiMaxversion}))
  |> sort(columns: ["desktopbrokerversion", "desktopbrokeragentversion", "nodecount", "numberofsessions", "numberofvms", "targetos", "targetosversion", "officeversion", "toolsguestversion", "optimizervendor", "optimizerversion", "gpuprofile", "comment", "infracpubrand", "infracputype", "infraaosversion", "infrahypervisorbrand", "infrahypervisorversion", "infrahypervisortype", "infratotalnodes", "run"])
"@

# Get the test details table from Influx and Split into individual lines
$TestDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $Body
$TestDetailSplit = $TestDetails.Split("`n")

# Set up PSCustom Object for Array Index
$Order = New-Object -TypeName psobject 
$Headers = ($TestDetailSplit[0]).Split(",")
for ($i = 3; $i -le (($Headers).Count - 1) ; $i++)
{    
    [string]$Value = $Headers[$i]
    $Order | Add-Member -MemberType NoteProperty -Name $i -Value $Value

}

# Build the Test Detail Results Array
$TestDetailResults = @()
$i = 0
foreach($TestLine in $TestDetailSplit){
    if(!($i -eq 0)){
        $Line = $TestLine.Split(",")
        if(!($null -eq $Line[3])){
            $Item = New-Object -TypeName psobject 
            for ($x = 3; $x -le (($Line).Count - 1) ; $x++)
            {    
                [string]$Name = $Order.$x
                $TrimmedName = $Name.Trim()
                $Item | Add-Member -MemberType NoteProperty -Name $TrimmedName -Value $Line[$x]

            }
            $TestDetailResults += $item
        }
    }
    $i++
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Create Directory
# -----------------------------------------------------------------------------------------------------------------------

# Convert the Report Title to PascalCase and Create Report Output Directory
$Directory = (Get-Culture).TextInfo.ToTitleCase($ReportTitle) -Replace " "
if(!(Test-Path -Path $Directory)){
    $dir = New-Item $Directory -type Directory
    $md = New-Item  (Join-Path -Path $Directory -ChildPath "md") -type Directory
    $images = New-Item  (Join-Path -Path $Directory -ChildPath "images") -type Directory
    $imagePath = Join-Path -Path $dir.Name -ChildPath $images.Name
    $mdPath = Join-Path -Path $dir.Name -ChildPath $md.Name
} else {
    write-host "Directory: $($Directory) already exists, please enter a different report title"
    break 
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Boot Info
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($BootInfo){

    # Build the PanelID Array 
    $Panels = @('85','84','86','94','92','96','89','95','93','97')   
    [int]$maxboottime = (($testDetailResults.boottime | measure -Maximum).maximum + 30) * 1000
    $endtime = 1672534800000 + $maxboottime
    # Loop through the panels and download the images
    foreach($Panel in $Panels){

        # Replace /d/ in Source Uri to Render
        $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
        
        # Append the Rendering Uri to the Base Uri
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=$($endtime)&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
        
        # Get output Filename
        switch ($Panel)
        {
            85 {$OutFile = Join-Path -Path $imagePath -ChildPath "boot_time.png"}
            84 {$OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_individual_runs.png"}
            86 {$OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_host_cpu.png"}
            94 {$OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_host_cpu_individual_runs.png"}
            92 {$OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_host_power_usage.png"}
            96 {$OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_host_power_usage_individual_runs.png"}
            89 {$OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_cluster_controller_iops.png"}
            95 {$OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_cluster_controller_iops_individual_runs.png"}
            93 {$OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_cluster_controller_latency.png"}
            97 {$OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_cluster_controller_latency_individual_runs.png"}
        }

        # Download the image
        Invoke-WebRequest -Uri $RenderUri -outfile $OutFile
    }
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Login Enterprise Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($LoginEnterpriseResults){

    # Build the PanelID Array 
    $Panels = @('2','5','8','4','7','6','99','100','10','101')  

    # Loop through the panels and download the images
    foreach($Panel in $Panels){

        # Replace /d/ in Source Uri to Render
        $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
        
        # Append the Rendering Uri to the Base Uri
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
        
        # Get output Filename
        switch ($Panel)
        {
            2 {$OutFile = Join-Path -Path $imagePath -ChildPath "le_results_vsi_max.png"}
            5 {$OutFile = Join-Path -Path $imagePath -ChildPath "le_results_vsi_max_individual_runs.png"}
            8 {$OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_base.png"}
            4 {$OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_base_individual_runs.png"}
            7 {$OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score.png"}
            6 {$OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_individual_runs.png"}
            99 {$OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_steady_state.png"}
            100 {$OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_steady_state_individual_runs.png"}
            10 {$OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_overlay.png"}
            101 {$OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_timer_scores.png"}
        }

        # Download the image
        Invoke-WebRequest -Uri $RenderUri -outfile $OutFile
    }
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Host Resources Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($HostResources){

    # Build the PanelID Array 
    $Panels = @('13','83','14','9')  

    # Loop through the panels and download the images
    foreach($Panel in $Panels){

        # Replace /d/ in Source Uri to Render
        $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
        
        # Append the Rendering Uri to the Base Uri
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
        
        # Get output Filename
        switch ($Panel)
        {
            13 {$OutFile = Join-Path -Path $imagePath -ChildPath "host_resources_cpu_usage.png"}
            83 {$OutFile = Join-Path -Path $imagePath -ChildPath "host_resources_cpu_usage_with_eux_score.png"}
            14 {$OutFile = Join-Path -Path $imagePath -ChildPath "host_resources_power_usage.png"}
            9 {$OutFile = Join-Path -Path $imagePath -ChildPath "host_resources_memory_usage.png"}
        }

        # Download the image
        Invoke-WebRequest -Uri $RenderUri -outfile $OutFile
    }
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Cluster Resources Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($ClusterResources){

    # Build the PanelID Array 
    $Panels = @('53','54','57','58')  

    # Loop through the panels and download the images
    foreach($Panel in $Panels){

        # Replace /d/ in Source Uri to Render
        $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
        
        # Append the Rendering Uri to the Base Uri
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
        
        # Get output Filename
        switch ($Panel)
        {
            53 {$OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_cpu_usage.png"}
            54 {$OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_memory_usage.png"}
            57 {$OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_controller_iops.png"}
            58 {$OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_controller_latency.png"}
        }

        # Download the image
        Invoke-WebRequest -Uri $RenderUri -outfile $OutFile
    }
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Login Times Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($LoginTimes){

    # Build the PanelID Array 
    $Panels = @('61','98','16','28','27','29')  

    # Loop through the panels and download the images
    foreach($Panel in $Panels){

        # Replace /d/ in Source Uri to Render
        $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
        
        # Append the Rendering Uri to the Base Uri
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
        
        # Get output Filename
        switch ($Panel)
        {
            61 {$OutFile = Join-Path -Path $imagePath -ChildPath "login_times_average.png"}
            98 {$OutFile = Join-Path -Path $imagePath -ChildPath "login_times_logon_rate_per_minute.png"}
            16 {$OutFile = Join-Path -Path $imagePath -ChildPath "login_times_total_logon_time.png"}
            28 {$OutFile = Join-Path -Path $imagePath -ChildPath "login_times_group_policies.png"}
            27 {$OutFile = Join-Path -Path $imagePath -ChildPath "login_times_user_profile_load.png"}
            29 {$OutFile = Join-Path -Path $imagePath -ChildPath "login_times_connection.png"}
        }

        # Download the image
        Invoke-WebRequest -Uri $RenderUri -outfile $OutFile
    }
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Individual Runs Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($IndividualRuns){

    # Build the PanelID Array 
    $Panels = @('66','67','68','70','69')  

    # Loop through the panels and download the images
    foreach($Panel in $Panels){

        # Replace /d/ in Source Uri to Render
        $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
        
        # Append the Rendering Uri to the Base Uri
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
        
        # Get output Filename
        switch ($Panel)
        {
            66 {$OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_eux_score.png"}
            67 {$OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_host_cpu_usage.png"}
            68 {$OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_cluster_controller_iops.png"}
            70 {$OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_total_logon_time.png"}
            69 {$OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_cluster_controller_latency.png"}
        }

        # Download the image
        Invoke-WebRequest -Uri $RenderUri -outfile $OutFile
    }
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Applications Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($Applications){

    # Build the PanelID Array 
    $Panels = @('31','32','33','34','37','38','39','40','36','42','44','43','35','41','102')  

    # Loop through the panels and download the images
    foreach($Panel in $Panels){

        # Replace /d/ in Source Uri to Render
        $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
        
        # Append the Rendering Uri to the Base Uri
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
        
        # Get output Filename
        switch ($Panel)
        {
            31 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_word_start.png"}
            32 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_word_open_doc.png"}
            33 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_word_save_file.png"}
            34 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_word_open_window.png"}
            37 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_powerpoint_start.png"}
            38 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_powerpoint_save_file.png"}
            39 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_powerpoint_open_window.png"}
            40 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_powerpoint__open_file.png"}
            36 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_excel_start.png"}
            42 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_excel_save_file.png"}
            44 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_excel_open_window.png"}
            43 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_excel_open_file.png"}
            35 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_microsoft_edge_logon.png"}
            41 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_outlook_start.png"}
            102 {$OutFile = Join-Path -Path $imagePath -ChildPath "applications_microsoft_edge_page_load.png"}
        }

        # Download the image
        Invoke-WebRequest -Uri $RenderUri -outfile $OutFile
    }
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - VSI EUX Measurements Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($VsiEuxMeasurements){

    # Build the PanelID Array 
    $Panels = @('15','30','45','46','47','48','49','50')  

    # Loop through the panels and download the images
    foreach($Panel in $Panels){

        # Replace /d/ in Source Uri to Render
        $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
        
        # Append the Rendering Uri to the Base Uri
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
        
        # Get output Filename
        switch ($Panel)
        {
            15 {$OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_high_compression.png"}
            30 {$OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_cpu_speed.png"}
            45 {$OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_app_speed.png"}
            46 {$OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_app_speed_user_input.png"}
            47 {$OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_disk_appdata.png"}
            48 {$OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_disk_appdata_latency.png"}
            49 {$OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_disk_my_docs.png"}
            50 {$OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_disk_my_docs_latency.png"}
        }

        # Download the image
        Invoke-WebRequest -Uri $RenderUri -outfile $OutFile
    }
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Nutanix Files Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($NutanixFiles){

    # Build the PanelID Array 
    $Panels = @('71','77','78','79')  

    # Loop through the panels and download the images
    foreach($Panel in $Panels){

        # Replace /d/ in Source Uri to Render
        $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
        
        # Append the Rendering Uri to the Base Uri
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
        
        # Get output Filename
        switch ($Panel)
        {
            71 {$OutFile = Join-Path -Path $imagePath -ChildPath "nutanix_files_iops.png"}
            77 {$OutFile = Join-Path -Path $imagePath -ChildPath "nutanix_files_latency.png"}
            78 {$OutFile = Join-Path -Path $imagePath -ChildPath "nutanix_files_throughput.png"}
            79 {$OutFile = Join-Path -Path $imagePath -ChildPath "nutanix_files_connections_and_number_of_files.png"}
        }

        # Download the image
        Invoke-WebRequest -Uri $RenderUri -outfile $OutFile
    }
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Citrix NetScaler Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($CitrixNetScaler){

    # Build the PanelID Array 
    $Panels = @('80','81','82','104','105','103','106')

    # Loop through the panels and download the images
    foreach($Panel in $Panels){

        # Replace /d/ in Source Uri to Render
        $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
        
        # Append the Rendering Uri to the Base Uri
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
        
        # Get output Filename
        switch ($Panel)
        {
            80 {$OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_management_cpu.png"}
            81 {$OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_packet_engine_cpu.png"}
            82 {$OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_memory_usage.png"}
            104 {$OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_network_throughput.png"}
            105 {$OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_load_balancer_packets.png"}
            103 {$OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_load_balancer_connections.png"}
            106 {$OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_load_balancer_request_and_response.png"}
        }

        # Download the image
        Invoke-WebRequest -Uri $RenderUri -outfile $OutFile
    }
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Create Report
# -----------------------------------------------------------------------------------------------------------------------

# Create the File path and initial file
$mdFullFile = Join-Path -Path $mdPath -ChildPath "$($Directory).md"
$mdFile = "$($Directory).md"
if(!(Test-Path -Path $mdFullFile)){
    $mdOutput = New-Item -Path $mdPath -Name $mdFile -ItemType File
} else {
    Write-Host "Markdown file $($mdFile) already exists, please delete the file and re-run the script"
    break
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Create Header
# -----------------------------------------------------------------------------------------------------------------------

# Create the Title and Introduction
Add-Content $mdFullFile "# $($ReportTitle)"
Add-Content $mdFullFile "## Executive Summary"
Add-Content $mdFullFile "$($BoilerPlateExecSummary)"
Add-Content $mdFullFile "## Introduction"
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

# -----------------------------------------------------------------------------------------------------------------------
# Section - Test Detail Specifics
# -----------------------------------------------------------------------------------------------------------------------
Add-Content $mdFullFile "## Test Detail Specifics"

# Hardware Specifics Section
$HardwareFiltered = $TestDetailResults | Select measurement, infrahardwaretype, infracpubrand, infracputype, infracpuspeed, infracpucores, inframemorygb, infracpusocketcount, nodecount, infratotalnodes, infrassdcount, infrabios, hostgpus, comment | Sort-Object measurement | Get-Unique -AsString
Add-Content $mdFullFile "### Hardware Specifics"

$HeaderLine = ""
$TableLine = ""
for ($i = 0; $i -lt (($HardwareFiltered).Count + 1) ; $i++)
{    
    if($i -eq 0){
        $HeaderLine = "| "
        $TableLine = "| --- "
    } else {
        $Comment = ($HardwareFiltered[$i - 1].comment).replace("_", " ")
        $HeaderLine = $HeaderLine + "| $($Comment) "
        $TableLine = $TableLine + "| --- "
        if($i -eq ($HardwareFiltered.Count)){
            $HeaderLine = $HeaderLine + "|"
            $TableLine = $TableLine + "|"
        }
    }
}
Add-Content $mdFullFile $HeaderLine
Add-Content $mdFullFile $TableLine

[string]$HardwareType = "| **Hardware Type** | "
[string]$CPUBrand = "| **CPU Brand** | "
[string]$CPUType = "| **CPU Type** | "
[string]$CPUSpeed = "| **CPU Speed** | "
[string]$CPUCores = "| **CPU Cores Per Node** | "
[string]$Memory = "| **Memory Per Node** | "
[string]$Sockets = "| **Socket Count** | "
[string]$Nodes = "| **Nodes In Test** | "
[string]$TotalNodes = "| **Nodes In Cluster** | "
[string]$SSD = "| **SSD Count Per Node** | "
[string]$Bios = "| **BIOS Version** | "
[string]$HostGPU = "| **Host GPU Type** | "

foreach($Record in $HardwareFiltered){
    $Hardware = $Record.infrahardwaretype
    $HWTrim = $Hardware.trim()
    $HardwareType = $HardwareType + "$($HWTrim) | "
    $CPUBrand = $CPUBrand + "$($Record.infracpubrand) | "
    $CPUSpeed = $CPUSpeed + "$($Record.infracpuspeed) GHz | "
    $Sockets = $Sockets + "$($Record.infracpusocketcount) | "
    $CPUCores = $CPUCores + "$($Record.infracpucores) | "
    $Memory = $Memory + "$($Record.inframemorygb) GB | "
    $Nodes = $Nodes + "$($Record.nodecount) | "
    $TotalNodes = $TotalNodes + "$($Record.infratotalnodes) | "
    $SSD = $SSD + "$($Record.infrassdcount) | "
    $Bios = $Bios + "$($Record.infrabios) | "
    $HostGPU = $HostGPU + "$($Record.hostgpus) | "
    $CT = ($Record.infracputype).Replace("_", " ")
    $CPUType = $CPUType + "$($CT) | "
}

Add-Content $mdFullFile $HardwareType
Add-Content $mdFullFile $Bios
Add-Content $mdFullFile $CPUBrand
Add-Content $mdFullFile $CPUType
Add-Content $mdFullFile $CPUSpeed
Add-Content $mdFullFile $CPUBrand
Add-Content $mdFullFile $Sockets
Add-Content $mdFullFile $CPUCores
Add-Content $mdFullFile $Memory
Add-Content $mdFullFile $SSD
Add-Content $mdFullFile $HostGPU
Add-Content $mdFullFile $Nodes
Add-Content $mdFullFile $TotalNodes

# Infra software specifics
$InfraFiltered = $TestDetailResults | Select measurement, infraaosversion, infrafullversion, infrahypervisorbrand, infrahypervisortype, infrahypervisorversion, comment | Sort-Object measurement | Get-Unique -AsString

Add-Content $mdFullFile "### Infrastructure Specifics"

$HeaderLine = ""
$TableLine = ""
for ($i = 0; $i -lt (($InfraFiltered).Count + 1) ; $i++)
{    
    if($i -eq 0){
        $HeaderLine = "| "
        $TableLine = "| --- "
    } else {
        $Comment = ($InfraFiltered[$i - 1].comment).replace("_", " ")
        $HeaderLine = $HeaderLine + "| $($Comment) "
        $TableLine = $TableLine + "| --- "
        if($i -eq ($InfraFiltered.Count)){
            $HeaderLine = $HeaderLine + "|"
            $TableLine = $TableLine + "|"
        }
    }
}
Add-Content $mdFullFile $HeaderLine
Add-Content $mdFullFile $TableLine

[string]$infraaosversion = "| **OS Version** | "
[string]$infrafullversion = "| **OS Full Version** | "
[string]$infrahypervisorbrand = "| **Hypervisor Brand** | "
[string]$infrahypervisortype = "| **Hypervisor Type** | "
[string]$infrahypervisorversion = "| **Hypervisor Version** | "

foreach($Record in $InfraFiltered){
    $infraaosversion = $infraaosversion + "$($Record.infraaosversion) | "
    $infrafullversion = $infrafullversion + "$($Record.infrafullversion) | "
    $infrahypervisorbrand = $infrahypervisorbrand + "$($Record.infrahypervisorbrand) | "
    $infrahypervisortype = $infrahypervisortype + "$($Record.infrahypervisortype) | "
    $infrahypervisorversion = $infrahypervisorversion + "$($Record.infrahypervisorversion) | "
}

Add-Content $mdFullFile $infraaosversion
Add-Content $mdFullFile $infrafullversion
Add-Content $mdFullFile $infrahypervisorbrand
Add-Content $mdFullFile $infrahypervisortype
Add-Content $mdFullFile $infrahypervisorversion

# Broker Specifics
$BrokerFiltered = $TestDetailResults | Select measurement, deliverytype, desktopbrokerversion, sessionssupport, sessioncfg, comment | Sort-Object measurement | Get-Unique -AsString

Add-Content $mdFullFile "### Brokering Specifics"

$HeaderLine = ""
$TableLine = ""
for ($i = 0; $i -lt (($BrokerFiltered).Count + 1) ; $i++)
{    
    if($i -eq 0){
        $HeaderLine = "| "
        $TableLine = "| --- "
    } else {
        $Comment = ($BrokerFiltered[$i - 1].comment).replace("_", " ")
        $HeaderLine = $HeaderLine + "| $($Comment) "
        $TableLine = $TableLine + "| --- "
        if($i -eq ($BrokerFiltered.Count)){
            $HeaderLine = $HeaderLine + "|"
            $TableLine = $TableLine + "|"
        }
    }
}
Add-Content $mdFullFile $HeaderLine
Add-Content $mdFullFile $TableLine

[string]$deliverytype = "| **Delivery Type** | "
[string]$desktopbrokerversion = "| **Desktop Broker Version** | "
[string]$sessionssupport = "| **Session Type** | "
[string]$sessioncfg = "| **Session Config** | "

foreach($Record in $BrokerFiltered){
    $deliverytype = $deliverytype + "$($Record.deliverytype) | "
    $desktopbrokerversion = $desktopbrokerversion + "$($Record.desktopbrokerversion) | "
    $sessionssupport = $sessionssupport + "$($Record.sessionssupport) | "
    $sessioncfg = $sessioncfg + "$($Record.sessioncfg) | "
}

Add-Content $mdFullFile $deliverytype
Add-Content $mdFullFile $desktopbrokerversion
Add-Content $mdFullFile $sessionssupport
Add-Content $mdFullFile $sessioncfg

# Target VM


# LE Specifics


# Test Specifics
$TestFiltered = $TestDetailResults | Select measurement, infrasinglenodetest, numberofvms, numberofsessions, vsiactivesessioncount, vsieuxsscore, vsieuxstate, vsivsimax, vsivsimaxstate, comment | Sort-Object measurement | Get-Unique -AsString

Add-Content $mdFullFile "### Test Specifics"

$HeaderLine = ""
$TableLine = ""
for ($i = 0; $i -lt (($TestFiltered).Count + 1) ; $i++)
{    
    if($i -eq 0){
        $HeaderLine = "| "
        $TableLine = "| --- "
    } else {
        $Comment = ($TestFiltered[$i - 1].comment).replace("_", " ")
        $HeaderLine = $HeaderLine + "| $($Comment) "
        $TableLine = $TableLine + "| --- "
        if($i -eq ($TestFiltered.Count)){
            $HeaderLine = $HeaderLine + "|"
            $TableLine = $TableLine + "|"
        }
    }
}
Add-Content $mdFullFile $HeaderLine
Add-Content $mdFullFile $TableLine

[string]$infrasinglenodetest = "| **Single Node Test** | "
[string]$numberofvms = "| **Number Of VMs** | "
[string]$numberofsessions = "| **Number Of Sessions** | "
[string]$vsiactivesessioncount = "| **VSI Active Session Count** | "
[string]$vsieuxsscore = "| **VSI EUX Score** | "
[string]$vsieuxstate = "| **VSI EUX State** | "
[string]$vsivsimax = "| **VSI Max** | "
[string]$vsivsimaxstate = "| **VSI Max State** | "

foreach($Record in $TestFiltered){
    $infrasinglenodetest = $infrasinglenodetest + "$($Record.infrasinglenodetest) | "
    $numberofvms = $numberofvms + "$($Record.numberofvms) | "
    $numberofsessions = $numberofsessions + "$($Record.numberofsessions) | "
    $vsiactivesessioncount = $vsiactivesessioncount + "$($Record.vsiactivesessioncount) | "
    $vsieuxsscore = $vsieuxsscore + "$($Record.vsieuxsscore) | "
    $vsieuxstate = $vsieuxstate + "$($Record.vsieuxstate) | "
    $vsivsimax = $vsivsimax + "$($Record.vsivsimax) | "
    $vsivsimaxstate = $vsivsimaxstate + "$($Record.vsivsimaxstate) | "
}

Add-Content $mdFullFile $infrasinglenodetest
Add-Content $mdFullFile $numberofvms
Add-Content $mdFullFile $numberofsessions
Add-Content $mdFullFile $vsiactivesessioncount
Add-Content $mdFullFile $vsieuxsscore
Add-Content $mdFullFile $vsieuxstate
Add-Content $mdFullFile $vsivsimax
Add-Content $mdFullFile $vsivsimaxstate


# -----------------------------------------------------------------------------------------------------------------------
# Section - Test Results
# -----------------------------------------------------------------------------------------------------------------------
Add-Content $mdFullFile "## Test Results"

# -----------------------------------------------------------------------------------------------------------------------
# Section - Boot Info
# -----------------------------------------------------------------------------------------------------------------------

# Boot Params - before boot info screenshots

$BootFiltered = $TestDetailResults | Select measurement, maxabsoluteactiveactions, maxabsolutenewactionsperminute, maxpercentageactiveactions, comment | Sort-Object measurement | Get-Unique -AsString

Add-Content $mdFullFile "### Boot Parameters"

$HeaderLine = ""
$TableLine = ""
for ($i = 0; $i -lt (($BootFiltered).Count + 1) ; $i++)
{    
    if($i -eq 0){
        $HeaderLine = "| "
        $TableLine = "| --- "
    } else {
        $Comment = ($BootFiltered[$i - 1].comment).replace("_", " ")
        $HeaderLine = $HeaderLine + "| $($Comment) "
        $TableLine = $TableLine + "| --- "
        if($i -eq ($BootFiltered.Count)){
            $HeaderLine = $HeaderLine + "|"
            $TableLine = $TableLine + "|"
        }
    }
}
Add-Content $mdFullFile $HeaderLine
Add-Content $mdFullFile $TableLine

[string]$maxabsoluteactiveactions = "| **Max Absolute Active Actions** | "
[string]$maxabsolutenewactionsperminute = "| **Max Absolute Actions Per Minute** | "
[string]$maxpercentageactiveactions = "| **Max Percentage Active Actions** | "

foreach($Record in $BootFiltered){
    $maxabsoluteactiveactions = $maxabsoluteactiveactions + "$($Record.maxabsoluteactiveactions) | "
    $maxabsolutenewactionsperminute = $maxabsolutenewactionsperminute + "$($Record.maxabsolutenewactionsperminute) | "
    $maxpercentageactiveactions = $maxpercentageactiveactions + "$($Record.maxpercentageactiveactions) | "
}

Add-Content $mdFullFile $maxabsoluteactiveactions
Add-Content $mdFullFile $maxabsolutenewactionsperminute
Add-Content $mdFullFile $maxpercentageactiveactions

# Execute if Option Enabled
if($BootInfo){

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "boot_time*")} | Sort-Object CreationTime

    # Add Section Title
    Add-Content $mdFullFile "### Boot Information Test Results"

    # Loop through each image and insert it into the document
    foreach($Image in $Source){
        
        # Get Image Title and Image Link
        $TitleRaw = ($Image.BaseName).Replace("_", " ")
        $Title = (Get-Culture).TextInfo.ToTitleCase($TitleRaw)
        $Path = "../images/$($Image.BaseName).png"
        $ImageLink = "![$($Title)]($($Path) ""$($Title)"")"
        
        #Add Content to document
        #Add-Content $mdFullFile "### $($Title)"
        Add-Content $mdFullFile "$($ImageLink)"
    }

}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Login Enterprise Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($LoginEnterpriseResults){

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "le_results*")} | Sort-Object CreationTime

    # Add Section Title
    Add-Content $mdFullFile "### Login Enterprise Test Results"

    # Loop through each image and insert it into the document
    foreach($Image in $Source){
        
        # Get Image Title and Image Link
        $TitleRaw = ($Image.BaseName).Replace("_", " ")
        $Title = (Get-Culture).TextInfo.ToTitleCase($TitleRaw)
        $Path = "../images/$($Image.BaseName).png"
        $ImageLink = "![$($Title)]($($Path) ""$($Title)"")"
        
        #Add Content to document
        #Add-Content $mdFullFile "### $($Title)"
        Add-Content $mdFullFile "$($ImageLink)"
    }

}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Host Resources Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($HostResources){

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "host_resources*")} | Sort-Object CreationTime

    # Add Section Title
    Add-Content $mdFullFile "### Host Resources Test Results"

    # Loop through each image and insert it into the document
    foreach($Image in $Source){
        
        # Get Image Title and Image Link
        $TitleRaw = ($Image.BaseName).Replace("_", " ")
        $Title = (Get-Culture).TextInfo.ToTitleCase($TitleRaw)
        $Path = "../images/$($Image.BaseName).png"
        $ImageLink = "![$($Title)]($($Path) ""$($Title)"")"
        
        #Add Content to document
        #Add-Content $mdFullFile "### $($Title)"
        Add-Content $mdFullFile "$($ImageLink)"
    }

}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Cluster Resources Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($ClusterResources){

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "cluster_resources*")} | Sort-Object CreationTime

    # Add Section Title
    Add-Content $mdFullFile "### Cluster Resources Test Results"

    # Loop through each image and insert it into the document
    foreach($Image in $Source){
        
        # Get Image Title and Image Link
        $TitleRaw = ($Image.BaseName).Replace("_", " ")
        $Title = (Get-Culture).TextInfo.ToTitleCase($TitleRaw)
        $Path = "../images/$($Image.BaseName).png"
        $ImageLink = "![$($Title)]($($Path) ""$($Title)"")"
        
        #Add Content to document
        #Add-Content $mdFullFile "### $($Title)"
        Add-Content $mdFullFile "$($ImageLink)"
    }

}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Login Times Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($LoginTimes){

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "login_times*")} | Sort-Object CreationTime

    # Add Section Title
    Add-Content $mdFullFile "### Login Times Test Results"

    # Loop through each image and insert it into the document
    foreach($Image in $Source){
        
        # Get Image Title and Image Link
        $TitleRaw = ($Image.BaseName).Replace("_", " ")
        $Title = (Get-Culture).TextInfo.ToTitleCase($TitleRaw)
        $Path = "../images/$($Image.BaseName).png"
        $ImageLink = "![$($Title)]($($Path) ""$($Title)"")"
        
        #Add Content to document
        #Add-Content $mdFullFile "### $($Title)"
        Add-Content $mdFullFile "$($ImageLink)"
    }

}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Individual Runs Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($IndividualRuns){

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "individual_runs*")} | Sort-Object CreationTime

    # Add Section Title
    Add-Content $mdFullFile "### Individual Runs Test Results"

    # Loop through each image and insert it into the document
    foreach($Image in $Source){
        
        # Get Image Title and Image Link
        $TitleRaw = ($Image.BaseName).Replace("_", " ")
        $Title = (Get-Culture).TextInfo.ToTitleCase($TitleRaw)
        $Path = "../images/$($Image.BaseName).png"
        $ImageLink = "![$($Title)]($($Path) ""$($Title)"")"
        
        #Add Content to document
        #Add-Content $mdFullFile "### $($Title)"
        Add-Content $mdFullFile "$($ImageLink)"
    }

}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Applications Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($Applications){

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "applications*")} | Sort-Object CreationTime

    # Add Section Title
    Add-Content $mdFullFile "### Application Test Results"

    # Loop through each image and insert it into the document
    foreach($Image in $Source){
        
        # Get Image Title and Image Link
        $TitleRaw = ($Image.BaseName).Replace("_", " ")
        $Title = (Get-Culture).TextInfo.ToTitleCase($TitleRaw)
        $Path = "../images/$($Image.BaseName).png"
        $ImageLink = "![$($Title)]($($Path) ""$($Title)"")"
        
        #Add Content to document
        #Add-Content $mdFullFile "### $($Title)"
        Add-Content $mdFullFile "$($ImageLink)"
    }

}

# -----------------------------------------------------------------------------------------------------------------------
# Section - VSI EUX Measurements Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($VsiEuxMeasurements){

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "vsi_eux*")} | Sort-Object CreationTime

    # Add Section Title
    Add-Content $mdFullFile "### VSI EUX Test Results"

    # Loop through each image and insert it into the document
    foreach($Image in $Source){
        
        # Get Image Title and Image Link
        $TitleRaw = ($Image.BaseName).Replace("_", " ")
        $Title = (Get-Culture).TextInfo.ToTitleCase($TitleRaw)
        $Path = "../images/$($Image.BaseName).png"
        $ImageLink = "![$($Title)]($($Path) ""$($Title)"")"
        
        #Add Content to document
        #Add-Content $mdFullFile "### $($Title)"
        Add-Content $mdFullFile "$($ImageLink)"
    }
    
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Nutanix Files Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($NutanixFiles){

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "nutanix_files*")} | Sort-Object CreationTime

    # Add Section Title
    Add-Content $mdFullFile "### Nutanix Files Test Results"

    # Loop through each image and insert it into the document
    foreach($Image in $Source){
        
        # Get Image Title and Image Link
        $TitleRaw = ($Image.BaseName).Replace("_", " ")
        $Title = (Get-Culture).TextInfo.ToTitleCase($TitleRaw)
        $Path = "../images/$($Image.BaseName).png"
        $ImageLink = "![$($Title)]($($Path) ""$($Title)"")"
        
        #Add Content to document
        #Add-Content $mdFullFile "### $($Title)"
        Add-Content $mdFullFile "$($ImageLink)"
    }

}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Citrix NetScaler Results
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($CitrixNetScaler){

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "citrix_netscaler*")} | Sort-Object CreationTime

    # Add Section Title
    Add-Content $mdFullFile "### Citrix NetScaler Test Results"

    # Loop through each image and insert it into the document
    foreach($Image in $Source){
        
        # Get Image Title and Image Link
        $TitleRaw = ($Image.BaseName).Replace("_", " ")
        $Title = (Get-Culture).TextInfo.ToTitleCase($TitleRaw)
        $Path = "../images/$($Image.BaseName).png"
        $ImageLink = "![$($Title)]($($Path) ""$($Title)"")"
        
        #Add Content to document
        #Add-Content $mdFullFile "### $($Title)"
        Add-Content $mdFullFile "$($ImageLink)"
    }

}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Conclusion
# -----------------------------------------------------------------------------------------------------------------------

$BoilerPlateConclusion = @"
This document is part of the Nutanix Solutions Architecture Artifacts. We wrote it for individuals responsible for designing, building, managing, testing and supporting Nutanix infrastructures. Readers should be familiar with Nutanix and Citrix products as well as familiar with Login Enterprise testing.
"@

Add-Content $mdFullFile "## Conclusion"
Add-Content $mdFullFile "$($BoilerPlateConclusion)"

# -----------------------------------------------------------------------------------------------------------------------
# Section - Appendix
# -----------------------------------------------------------------------------------------------------------------------

Add-Content $mdFullFile "## Appendix"
Add-Content $mdFullFile "$($BoilerPlateLE)"