# -----------------------------------------------------------------------------------------------------------------------
# Section - Define Script Variables
# -----------------------------------------------------------------------------------------------------------------------

# User Input Script Variables

# Source Uri - This is the Uri for the Grafana Dashboard you want the report for
$SourceUri = "http://10.57.64.119:3000/d/N5tnL9EVk/login-documents-v3?orgId=1&var-Bucketname=LoginDocuments&var-Bootbucket=BootBucket&var-Year=2023&var-Month=07&var-DocumentName=ENG-Profile-Files-Baseline&var-Comment=Windows_10_Profile_Citrix_UPM_-_All_Off&var-Comment=Windows_10_Profile_Citrix_UPM_No_Cache_-_All_Off&var-Testname=049fd6_8n_A6.5.3.5_AHV_1000V_1000U_KW&var-Testname=8aa73e_8n_A6.5.3.5_AHV_1000V_1000U_KW&var-Run=049fd6_8n_A6.5.3.5_AHV_1000V_1000U_KW_Run1&var-Run=8aa73e_8n_A6.5.3.5_AHV_1000V_1000U_KW_Run1&var-Naming=Comment"

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


if($SkipNetScaler){
    $CitrixNetScaler = $false
} else {
    $CitrixNetScaler = $false
}
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

# Format Data for Influx Query
$FormattedBucket = $($Bucket).replace('.','\.')
$FormattedYear = $($Year).replace('.','\.')
$FormattedMonth = $($Month).replace('.','\.')
$FormattedDocumentName = $($DocumentName).replace('.','\.')
$FormattedComment = $($Comment).replace('.','\.')
$FormattedTestname = $($Testname).replace('.','\.')

# Build Body
$Body = @"
from(bucket:"$($FormattedBucket)")
  |> range(start: 2023-01-01T01:00:00Z, stop: 2023-01-01T02:07:00Z)
  |> filter(fn: (r) => r["Year"] =~ /^$($FormattedYear)$/ )
  |> filter(fn: (r) => r["Month"] =~ /^$($FormattedMonth)$/ )
  |> filter(fn: (r) => r["DocumentName"] =~ /^$($FormattedDocumentName)$/ )
  |> filter(fn: (r) => r["Comment"] =~ /^$($FormattedComment)$/ )
  |> filter(fn: (r) => r["_measurement"] =~ /^$($FormattedTestname)$/ )
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
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=$($endtime)&panelId=$($Panel)&width=1000&height=600&tz=Atlantic%2FCape_Verde"
        
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
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1000&height=600&tz=Atlantic%2FCape_Verde"
        
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
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1000&height=600&tz=Atlantic%2FCape_Verde"
        
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
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1000&height=600&tz=Atlantic%2FCape_Verde"
        
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
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1000&height=600&tz=Atlantic%2FCape_Verde"
        
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
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1000&height=600&tz=Atlantic%2FCape_Verde"
        
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
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1000&height=600&tz=Atlantic%2FCape_Verde"
        
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
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1000&height=600&tz=Atlantic%2FCape_Verde"
        
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
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1000&height=600&tz=Atlantic%2FCape_Verde"
        
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
        $RenderUri = $UpdatedUri + "&from=1672534800000&to=1672538820000&panelId=$($Panel)&width=1000&height=600&tz=Atlantic%2FCape_Verde"
        
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
Add-Content $mdFullFile "# Executive Summary"
Add-Content $mdFullFile "$($BoilerPlateExecSummary)"
Add-Content $mdFullFile "# Introduction"
Add-Content $mdFullFile "## Audience"
Add-Content $mdFullFile "$($BoilerPlateIntroduction)"
Add-Content $mdFullFile "## Purpose"
Add-Content $mdFullFile "This document covers the following subject areas:"
Add-Content $mdFullFile " - Test Detail Specifics."
Add-Content $mdFullFile " - Test Results for $($ReportTitle)."
Add-Content $mdFullFile "## Document Version History "
Add-Content $mdFullFile "| Version Number | Published | Notes |"
Add-Content $mdFullFile "| :---: | --- | --- |"
$Month = get-date -format "MM"
$ReportMonth = (Get-Culture).DateTimeFormat.GetMonthName($Month)  
$ReportYear = get-date -format "yyyy" 
Add-Content $mdFullFile "| 1.0 | $($ReportMonth) $($ReportYear) | Original publication. |"

# -----------------------------------------------------------------------------------------------------------------------
# Section - Test Detail Specifics
# -----------------------------------------------------------------------------------------------------------------------
Add-Content $mdFullFile "# Test Detail Specifics"

# Loop through the TestDetailResults and output a table for each entry

foreach($Test in $TestDetailResults){
    $TestTitle = ($Test.comment).Replace("_", " ")
    Add-Content $mdFullFile "## Test Name - $($TestTitle)"
    Add-Content $mdFullFile "| Item | Detail |"
    Add-Content $mdFullFile "| --- | --- |"
    Add-Content $mdFullFile "| Measurement Name | $($Test.measurement) |"
    Add-Content $mdFullFile "| AOS Version | $($Test.AOS) |"
    Add-Content $mdFullFile "| Broker Agent Version | $($Test.BrokerAgentVersion) |"
    Add-Content $mdFullFile "| Broker Version | $($Test.BrokerVersion) |"
    Add-Content $mdFullFile "| Credential Guard Enabled | $($Test.CG) |"
    $CPU = ($Test.CPU).Replace("_", " ")
    Add-Content $mdFullFile "| CPU Type | $($CPU) |"
    Add-Content $mdFullFile "| CPU Speed | $($Test.CPUSpeed) |"
    Add-Content $mdFullFile "| Clone Type | $($Test.CloneType) |"
    Add-Content $mdFullFile "| Cluster Nodes | $($Test.Clusternodes) |"
    Add-Content $mdFullFile "| EUX Score | $($Test.EUXScore) |"
    Add-Content $mdFullFile "| Hypervisor | $($Test.Hypervisor) |"
    Add-Content $mdFullFile "| Hypervisor Version | $($Test.Hypervisorversion) |"
    Add-Content $mdFullFile "| Hypervisor Node CPU Sockets | $($Test.NodeCPUSockets) |"
    Add-Content $mdFullFile "| Hypervisor Node CPU Cores | $($Test.NodeCPUCores) |"
    Add-Content $mdFullFile "| VM CPU Sockets | $($Test.NumCPUs) |"
    Add-Content $mdFullFile "| VM CPU Cores | $($Test.NumCores) |"
    Add-Content $mdFullFile "| VM Memory | $($Test.MemGB) |"
    $OS = ($Test.OS).Replace("_", " ")
    Add-Content $mdFullFile "| VM Operating System | $($OS) |"
    Add-Content $mdFullFile "| VM Operating System Version | $($Test.OSVersion) |"
    $Office = ($test.Office).Replace("_", " ")
    Add-Content $mdFullFile "| VM Office Version | $($Office) |"
    Add-Content $mdFullFile "| Secure Boot Enabled | $($Test.SecureBoot) |"
    Add-Content $mdFullFile "| Session Type | $($Test.Sessiontype) |"
    Add-Content $mdFullFile "| Session Config | $($Test.SessionConfig) |"
    Add-Content $mdFullFile "| Test Nodes | $($Test.Testnodes) |"
    Add-Content $mdFullFile "| VSI Max | $($Test.VSImax) |"
    Add-Content $mdFullFile "| VSI Max State | $($Test.VSImaxstate) |"
    Add-Content $mdFullFile "| VSI Version | $($Test.VSIversion) |"
    Add-Content $mdFullFile "| VSI Workload | $($Test.WorkLoad) |"
    Add-Content $mdFullFile "| Total Number Of Sessions | $($Test.numberOfSessions) |"
    Add-Content $mdFullFile "| Total Number Of VMs | $($Test.numberOfVMs) |"
}

# -----------------------------------------------------------------------------------------------------------------------
# Section - Test Results
# -----------------------------------------------------------------------------------------------------------------------
Add-Content $mdFullFile "# Test Results"

# -----------------------------------------------------------------------------------------------------------------------
# Section - Boot Info
# -----------------------------------------------------------------------------------------------------------------------

# Execute if Option Enabled
if($BootInfo){

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq  '.png') -and ($_.Name -like "boot_time*")} | Sort-Object CreationTime

    # Add Section Title
    Add-Content $mdFullFile "## Boot Information Test Results"

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
    Add-Content $mdFullFile "## Login Enterprise Test Results"

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
    Add-Content $mdFullFile "## Host Resources Test Results"

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
    Add-Content $mdFullFile "## Cluster Resources Test Results"

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
    Add-Content $mdFullFile "## Login Times Test Results"

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
    Add-Content $mdFullFile "## Individual Runs Test Results"

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
    Add-Content $mdFullFile "## Application Test Results"

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
    Add-Content $mdFullFile "## VSI EUX Test Results"

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
    Add-Content $mdFullFile "## Nutanix Files Test Results"

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
    Add-Content $mdFullFile "## Citrix NetScaler Test Results"

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