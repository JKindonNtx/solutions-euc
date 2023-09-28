<#
.SYNOPSIS
.DESCRIPTION
.PARAMETER SourceUri
    Mandatory String. The URL for the Grafana Report
.PARAMETER ReportTitle
    Mandatory String. The name of the report you are running
.PARAMETER mdFile
    Optional String. Defaults to README.MD
.PARAMETER ImageSuffix
    Optional String. Helps with image namign on multi run. Will add an _suffix value to each image
.PARAMETER influxDbUrl
.PARAMETER InfluxToken
.PARAMETER iconsSource
.PARAMETER ExcludedComponentList
    Optional Array. Excludes specific items from processing. Default Exclusion is "BootInfo","IndividualRuns","NutanixFiles","CitrixNetScaler". Include "none" to Exclude none.
.EXAMPLE
    .\New-GrafanaReport.ps1 -SourceUri "http://grafanareport" -ReportTitle RAS_WinServ2022_Linked_vs_Full_Clone -ImageSuffix 2022_prov
    Will use the "http://grafanareport" Uri, create a folder structure and report based on the "RAS_WinServ2022_Linked_vs_Full_Clone" input and suffix all images with "2022_prov"
.NOTES
- JK Additions
    22.09.2023: Restructured script for useability
    22.09.2023: Fixed output location settings and creation logic
    25.09.2023: Moved inputs to params. SourceUri, ReportTitle, mdFile (defaults to README)
    25.09.2023: Added an image suffix param which will be appended to each image. Helps with multi run documents when doing comparisons. Each test can now have unique image outputs
    25.09.2023: Fixed Markdown formatting functions
    25.09.2023: Fixed Try/Catch runs where they exist (added -ErrorAction handling)
    25.09.2023: Added iterative readme file logic. If readme.md is detected, a new date stamped version will be created alongside it
    25.09.2023: Added a check for image existence. If the file exists, it will no longer be downloaded. This speeds up iterative documentation versions.
    25.09.2023: Fixed Alt Text in image additions, surrounded in "" which helps with longer image names
    25.09.2023: Moved Excluded components to Parameter based
- To Do
 -> Function this sucker - Inject between section headers
    # Add Page Break
    Add-Content $mdFullFile "<div style=""page-break-after: always;""></div>"
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $true)]
    [string]$SourceUri, # The Grafana Source Uri

    [Parameter(Mandatory = $true)]
    [string]$ReportTitle, # Title for the Report

    [Parameter(Mandatory = $false)]
    [string]$mdFile = "README.MD", # Markdown output file name

    [Parameter(Mandatory = $false)]
    [string]$ImageSuffix, #shortname for image ouput - helpful for multi run documentation. moves an image from image_name.png to image_name_suffix.png

    [Parameter(Mandatory = $false)]
    [string]$influxDbUrl = "http://10.57.64.119:8086/api/v2/query?orgID=bca5b8aeb2b51f2f",

    [Parameter(Mandatory = $false)]
    [string]$InfluxToken = "b4yxMiQGOAlR3JftuLHuqssnwo-SOisbC2O6-7od7noAE5W1MLsZxLF7e63RzvUoiOHObc9G8_YOk1rnCLNblA==",

    [Parameter(Mandatory = $false)]
    [string]$iconsSource = "http://10.57.64.119:3000/public/img/nutanix/",

    [Parameter(Mandatory = $false)]
    [ValidateSet("LoginEnterpriseResults","HostResources","ClusterResources","LoginTimes","Applications","VsiEuxMeasurements","RDA","BootInfo","IndividualRuns","NutanixFiles","CitrixNetScaler","None")]
    [Array]$ExcludedComponentList = ("BootInfo","IndividualRuns","NutanixFiles","CitrixNetScaler") # Items to exclude

)

#endregion Params

#region Functions
# ============================================================================
# Functions
# ============================================================================
function Write-Screen {
    param
    (
        $Message
    )

    Write-Host "$(get-date -format "dd/MM/yyyy HH:mm") - $($Message)"
} # Write formatted output to screen

function Get-UriVariable {
    param(
        $Uri,
        $Var
    )

    $SplitURL = $Uri.Split("?")
    $VariableURL = $SplitURL[1]
    $SourceSplit = $VariableURL.Split("&") 

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
} # Get Uri Variable Information

function Get-PayloadIndex {
    param(
        $TestDetails
    )

    $TestDetailSplit = $TestDetails.Split("`n")
    Write-Screen -Message "Split Test Detail Into Array"

    # Set up PSCustom Object for Array Index
    $Return = New-Object -TypeName psobject 
    $Headers = ($TestDetailSplit[0]).Split(",")
    for ($i = 3; $i -le (($Headers).Count - 1) ; $i++) {    
        $Value = ($Headers[$i]).Trim()
        $Return | Add-Member -MemberType NoteProperty -Name $i -Value $Value
        
    }

    Write-Screen -Message "Return Test Payload Index"
    Return $Return
} # Get Test Detail Order Index

function Get-PayloadResults {
    param(
        $TestDetails,
        $Order
    )

    $TestDetailSplit = $TestDetails.Split("`n")
    Write-Screen -Message "Split Test Detail Into Array"

    $Return = @()
    $i = 0
    foreach ($TestLine in $TestDetailSplit) {
        if (!($i -eq 0)) {
            $Line = $TestLine.Split(",")
            if (!($null -eq $Line[3])) {
                $Item = New-Object -TypeName psobject 
                for ($x = 3; $x -le (($Line).Count - 1) ; $x++) {    
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
} # Get the Test Detail Results

function Get-UriFile {
    param (
        $Uri,
        $OutFile
    )

    $ProgressPreference = 'SilentlyContinue' 

    Write-Screen -Message "Downloading $($OutFile)"
    try {
        $Result = Invoke-WebRequest -Uri $Uri -outfile $OutFile
        Write-Screen -Message "Download Complete"
    }
    catch {
        Write-Screen -Message "Download $($OutFile) Failed"
    }
} # Download a file from Uri

function Get-Graphs {
    param (
        $Panels,
        $EndTime,
        $SourceUri,
        $imagePath
    )

    foreach ($Panel in $Panels) {

        # Build Uri to download image
        $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
        $Uri = $UpdatedUri + "&from=1672534800000&to=$($EndTime)&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"

        # Get output Filename
        if (!$ImageSuffix) {
            # Use default image names
            switch ($Panel) {
                85 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time.png" }
                84 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_individual_runs.png" }
                86 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_host_cpu.png" }
                94 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_host_cpu_individual_runs.png" }
                92 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_host_power_usage.png" }
                96 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_host_power_usage_individual_runs.png" }
                89 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_cluster_controller_iops.png" }
                95 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_cluster_controller_iops_individual_runs.png" }
                93 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_cluster_controller_latency.png" }
                97 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_cluster_controller_latency_individual_runs.png" }
                2 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_vsi_max.png" }
                5 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_vsi_max_individual_runs.png" }
                8 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_base.png" }
                4 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_base_individual_runs.png" }
                7 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score.png" }
                6 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_individual_runs.png" }
                99 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_steady_state.png" }
                100 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_steady_state_individual_runs.png" }
                10 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_overlay.png" }
                101 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_timer_scores.png" }
                13 { $OutFile = Join-Path -Path $imagePath -ChildPath "host_resources_cpu_usage.png" }
                83 { $OutFile = Join-Path -Path $imagePath -ChildPath "host_resources_cpu_usage_with_eux_score.png" }
                14 { $OutFile = Join-Path -Path $imagePath -ChildPath "host_resources_power_usage.png" }
                9 { $OutFile = Join-Path -Path $imagePath -ChildPath "host_resources_memory_usage.png" }
                120 { $OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_cpu_usage.png" }
                53 { $OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_cpu_ready.png" }
                54 { $OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_memory_usage.png" }
                57 { $OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_controller_iops.png" }
                58 { $OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_controller_latency.png" }
                61 { $OutFile = Join-Path -Path $imagePath -ChildPath "login_times_average.png" }
                98 { $OutFile = Join-Path -Path $imagePath -ChildPath "login_times_logon_rate_per_minute.png" }
                16 { $OutFile = Join-Path -Path $imagePath -ChildPath "login_times_total_logon_time.png" }
                28 { $OutFile = Join-Path -Path $imagePath -ChildPath "login_times_group_policies.png" }
                27 { $OutFile = Join-Path -Path $imagePath -ChildPath "login_times_user_profile_load.png" }
                29 { $OutFile = Join-Path -Path $imagePath -ChildPath "login_times_connection.png" }
                66 { $OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_eux_score.png" }
                67 { $OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_host_cpu_usage.png" }
                68 { $OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_cluster_controller_iops.png" }
                70 { $OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_total_logon_time.png" }
                69 { $OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_cluster_controller_latency.png" }
                31 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_word_start.png" }
                32 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_word_open_doc.png" }
                33 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_word_save_file.png" }
                34 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_word_open_window.png" }
                37 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_powerpoint_start.png" }
                38 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_powerpoint_save_file.png" }
                39 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_powerpoint_open_window.png" }
                40 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_powerpoint__open_file.png" }
                36 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_excel_start.png" }
                42 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_excel_save_file.png" }
                44 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_excel_open_window.png" }
                43 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_excel_open_file.png" }
                35 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_microsoft_edge_logon.png" }
                41 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_outlook_start.png" }
                102 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_microsoft_edge_page_load.png" }
                15 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_high_compression.png" }
                30 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_cpu_speed.png" }
                45 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_app_speed.png" }
                46 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_app_speed_user_input.png" }
                47 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_disk_appdata.png" }
                48 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_disk_appdata_latency.png" }
                49 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_disk_my_docs.png" }
                50 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_disk_my_docs_latency.png" }
                71 { $OutFile = Join-Path -Path $imagePath -ChildPath "nutanix_files_iops.png" }
                77 { $OutFile = Join-Path -Path $imagePath -ChildPath "nutanix_files_latency.png" }
                78 { $OutFile = Join-Path -Path $imagePath -ChildPath "nutanix_files_throughput.png" }
                79 { $OutFile = Join-Path -Path $imagePath -ChildPath "nutanix_files_connections_and_number_of_files.png" }
                80 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_management_cpu.png" }
                81 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_packet_engine_cpu.png" }
                82 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_memory_usage.png" }
                104 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_network_throughput.png" }
                105 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_load_balancer_packets.png" }
                103 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_load_balancer_connections.png" }
                106 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_load_balancer_request_and_response.png" }
                110 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_fps.png" }
                111 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_latency.png" }
                112 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_rtt.png" }
                115 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_display_protocol_cpu_usage.png" }
                113 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_bandwidth_output.png" }
                116 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_display_protocol_ram_usage.png" }
                117 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_available_bandwidth.png" }
                114 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_available_bandwidth_edt.png" }
            }
        }
        else {
            # Use suffixed image names
            $ImageSuffix = $ImageSuffix.ToLower()
            switch ($Panel) {
                85 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_$($ImageSuffix).png" }
                84 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_individual_runs_$($ImageSuffix).png" }
                86 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_host_cpu_$($ImageSuffix).png" }
                94 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_host_cpu_individual_runs_$($ImageSuffix).png" }
                92 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_host_power_usage_$($ImageSuffix).png" }
                96 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_host_power_usage_individual_runs_$($ImageSuffix).png" }
                89 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_cluster_controller_iops_$($ImageSuffix).png" }
                95 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_cluster_controller_iops_individual_runs_$($ImageSuffix).png" }
                93 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_cluster_controller_latency_$($ImageSuffix).png" }
                97 { $OutFile = Join-Path -Path $imagePath -ChildPath "boot_time_cluster_controller_latency_individual_runs_$($ImageSuffix).png" }
                2 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_vsi_max_$($ImageSuffix).png" }
                5 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_vsi_max_individual_runs_$($ImageSuffix).png" }
                8 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_base_$($ImageSuffix).png" }
                4 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_base_individual_runs_$($ImageSuffix).png" }
                7 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_$($ImageSuffix).png" }
                6 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_individual_runs_$($ImageSuffix).png" }
                99 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_steady_state_$($ImageSuffix).png" }
                100 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_steady_state_individual_runs_$($ImageSuffix).png" }
                10 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_score_overlay_$($ImageSuffix).png" }
                101 { $OutFile = Join-Path -Path $imagePath -ChildPath "le_results_eux_timer_scores_$($ImageSuffix).png" }
                13 { $OutFile = Join-Path -Path $imagePath -ChildPath "host_resources_cpu_usage_$($ImageSuffix).png" }
                83 { $OutFile = Join-Path -Path $imagePath -ChildPath "host_resources_cpu_usage_with_eux_score_$($ImageSuffix).png" }
                14 { $OutFile = Join-Path -Path $imagePath -ChildPath "host_resources_power_usage_$($ImageSuffix).png" }
                9 { $OutFile = Join-Path -Path $imagePath -ChildPath "host_resources_memory_usage_$($ImageSuffix).png" }
                120 { $OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_cpu_usage_$($ImageSuffix).png" }
                53 { $OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_cpu_ready_$($ImageSuffix).png" }
                54 { $OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_memory_usage_$($ImageSuffix).png" }
                57 { $OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_controller_iops_$($ImageSuffix).png" }
                58 { $OutFile = Join-Path -Path $imagePath -ChildPath "cluster_resources_controller_latency_$($ImageSuffix).png" }
                61 { $OutFile = Join-Path -Path $imagePath -ChildPath "login_times_average_$($ImageSuffix).png" }
                98 { $OutFile = Join-Path -Path $imagePath -ChildPath "login_times_logon_rate_per_minute_$($ImageSuffix).png" }
                16 { $OutFile = Join-Path -Path $imagePath -ChildPath "login_times_total_logon_time_$($ImageSuffix).png" }
                28 { $OutFile = Join-Path -Path $imagePath -ChildPath "login_times_group_policies_$($ImageSuffix).png" }
                27 { $OutFile = Join-Path -Path $imagePath -ChildPath "login_times_user_profile_load_$($ImageSuffix).png" }
                29 { $OutFile = Join-Path -Path $imagePath -ChildPath "login_times_connection_$($ImageSuffix).png" }
                66 { $OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_eux_score_$($ImageSuffix).png" }
                67 { $OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_host_cpu_usage_$($ImageSuffix).png" }
                68 { $OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_cluster_controller_iops_$($ImageSuffix).png" }
                70 { $OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_total_logon_time_$($ImageSuffix).png" }
                69 { $OutFile = Join-Path -Path $imagePath -ChildPath "individual_runs_cluster_controller_latency_$($ImageSuffix).png" }
                31 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_word_start_$($ImageSuffix).png" }
                32 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_word_open_doc_$($ImageSuffix).png" }
                33 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_word_save_file_$($ImageSuffix).png" }
                34 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_word_open_window_$($ImageSuffix).png" }
                37 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_powerpoint_start_$($ImageSuffix).png" }
                38 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_powerpoint_save_file_$($ImageSuffix).png" }
                39 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_powerpoint_open_window_$($ImageSuffix).png" }
                40 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_powerpoint__open_file_$($ImageSuffix).png" }
                36 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_excel_start_$($ImageSuffix).png" }
                42 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_excel_save_file_$($ImageSuffix).png" }
                44 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_excel_open_window_$($ImageSuffix).png" }
                43 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_excel_open_file_$($ImageSuffix).png" }
                35 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_microsoft_edge_logon_$($ImageSuffix).png" }
                41 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_outlook_start_$($ImageSuffix).png" }
                102 { $OutFile = Join-Path -Path $imagePath -ChildPath "applications_microsoft_edge_page_load_$($ImageSuffix).png" }
                15 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_high_compression_$($ImageSuffix).png" }
                30 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_cpu_speed_$($ImageSuffix).png" }
                45 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_app_speed_$($ImageSuffix).png" }
                46 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_app_speed_user_input_$($ImageSuffix).png" }
                47 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_disk_appdata_$($ImageSuffix).png" }
                48 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_disk_appdata_latency_$($ImageSuffix).png" }
                49 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_disk_my_docs_$($ImageSuffix).png" }
                50 { $OutFile = Join-Path -Path $imagePath -ChildPath "vsi_eux_disk_my_docs_latency_$($ImageSuffix).png" }
                71 { $OutFile = Join-Path -Path $imagePath -ChildPath "nutanix_files_iops_$($ImageSuffix).png" }
                77 { $OutFile = Join-Path -Path $imagePath -ChildPath "nutanix_files_latency_$($ImageSuffix).png" }
                78 { $OutFile = Join-Path -Path $imagePath -ChildPath "nutanix_files_throughput_$($ImageSuffix).png" }
                79 { $OutFile = Join-Path -Path $imagePath -ChildPath "nutanix_files_connections_and_number_of_files_$($ImageSuffix).png" }
                80 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_management_cpu_$($ImageSuffix).png" }
                81 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_packet_engine_cpu_$($ImageSuffix).png" }
                82 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_memory_usage_$($ImageSuffix).png" }
                104 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_network_throughput_$($ImageSuffix).png" }
                105 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_load_balancer_packets_$($ImageSuffix).png" }
                103 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_load_balancer_connections_$($ImageSuffix).png" }
                106 { $OutFile = Join-Path -Path $imagePath -ChildPath "citrix_netscaler_load_balancer_request_and_response_$($ImageSuffix).png" }
                110 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_fps_$($ImageSuffix).png" }
                111 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_latency_$($ImageSuffix).png" }
                112 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_rtt_$($ImageSuffix).png" }
                115 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_display_protocol_cpu_usage_$($ImageSuffix).png" }
                113 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_bandwidth_output_$($ImageSuffix).png" }
                116 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_display_protocol_ram_usage_$($ImageSuffix).png" }
                117 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_available_bandwidth_$($ImageSuffix).png" }
                114 { $OutFile = Join-Path -Path $imagePath -ChildPath "rdanalyzer_available_bandwidth_edt_$($ImageSuffix).png" }
            }
        }

        # Download the image
        ## Test it first
        if (Test-Path -Path $OutFile) {
            Write-Screen -Message "Image File $($OutFile) already exists. Not downloading. Delete the file if you want to re-download it"
        }
        else {
            Get-UriFile -Uri $Uri -outfile $OutFile
        }
    }
} # Get Grafana Graphs

function Add-TableHeaders {
    param (
        $mdFullFile,
        $TableTitle,
        $TableData,
        $TableImage
    )

    # Add the table title
    Write-Screen -Message "Adding Table Header for $($TableTitle)"
    Add-Content $mdFullFile " "
    Add-Content $mdFullFile "### $($TableTitle)"
    Add-Content $mdFullFile " "

    # Add the Table Headers
    $HeaderLine = ""
    $TableLine = ""
    for ($i = 0; $i -lt (($TableData).Count + 1) ; $i++) {    
        if ($i -eq 0) {
            $HeaderLine = "| $($TableImage) "
            $TableLine = "| --- "
        }
        else {
            $Name = ($TableData[$i - 1].Name).replace("_", " ")
            $HeaderLine = $HeaderLine + "| $($Name) "
            $TableLine = $TableLine + "| --- "
            if ($i -eq ($TableData.Count)) {
                $HeaderLine = $HeaderLine + "|"
                $TableLine = $TableLine + "|"
            }
        }
    }
    Add-Content $mdFullFile $HeaderLine
    Add-Content $mdFullFile $TableLine
} # Add Table Headers
 
function Get-CleanData {
    param (
        $Data
    )
    if (!($null -eq $Data)) {
        # Trim the Data
        $TrimmedData = $Data.Trim()

        # Replace Underscores
        $Return = $TrimmedData.Replace("_", " ")
    }
    else {
        $Return = "No Data"
    }

    # Return the trimmed Data
    Return $Return
} # Trim Data Item

function Add-Title {
    param(
        $Title,
        $mdFullFile
    )

    Add-Content $mdFullFile ""
    Add-Content $mdFullFile "## <span style=""color:#7855FA"">$($Title)</span>"
    Add-Content $mdFullFile ""
} # Add Title Text

function Add-Graphs {
    param(
        $Source,
        $Title,
        $mdFullFile
    )

    # Add Section Title
    Write-Screen -Message "Adding Graphs for $($Title)"

    # Loop through each image and insert it into the document
    foreach ($Image in $Source) {
            
        # Get Image Title and Image Link
        $TitleRaw = ($Image.BaseName).Replace("_", " ")
        $Title = (Get-Culture).TextInfo.ToTitleCase($TitleRaw)
        $Path = "../images/$($Image.BaseName).png"
        $Link = "<img src=$($Path) alt=""$($Title)"" style=""border: 2px solid #7855FA;"">"
        Add-Content $mdFullFile "$($Link)"
    }

    Add-Content $mdFullFile " "

} # Add the Graphs

#endregion Functions

#region Variables
# ============================================================================
# Variables
# ============================================================================
# -----------------------------------------------------------------------------------------------------------------------
# Section - Define Script Variables - to do - PDF / Logo image / Script Params and Switches for false items
# -----------------------------------------------------------------------------------------------------------------------
# User Input Script Variables
$maxLength = 65536
[System.Console]::SetIn([System.IO.StreamReader]::new([System.Console]::OpenStandardInput($maxLength), [System.Console]::InputEncoding, $false, $maxLength))

#region Report Sections
# -----------------------------------------------------------------------------------------------------------------------
# Sections 
# -----------------------------------------------------------------------------------------------------------------------

if ( $ExcludedComponentList -contains "None" ) {$ExcludedComponentList -eq $null} # Include Everything

if ( $ExcludedComponentList -notcontains "ClusterResources" ) { $ClusterResources = $true } else { $ClusterResources = $false }
if ( $ExcludedComponentList -notcontains "LoginEnterpriseResults" ) { $LoginEnterpriseResults = $true } else { $LoginEnterpriseResults = $false }
if ( $ExcludedComponentList -notcontains "HostResources" ) { $HostResources = $true } else { $HostResources = $false }
if ( $ExcludedComponentList -notcontains "LoginTimes" ) { $LoginTimes = $true } else { $LoginTimes = $false }
if ( $ExcludedComponentList -notcontains "Applications" ) { $Applications = $true } else { $Applications = $false }
if ( $ExcludedComponentList -notcontains "VsiEuxMeasurements" ) { $VsiEuxMeasurements = $true } else { $VsiEuxMeasurements = $false }
if ( $ExcludedComponentList -notcontains "RDA" ) { $RDA = $true } else { $RDA = $false }
if ( $ExcludedComponentList -notcontains "BootInfo" ) { $BootInfo = $true } else { $BootInfo = $false }
if ( $ExcludedComponentList -notcontains "IndividualRuns" ) { $IndividualRuns = $true } else { $IndividualRuns = $false }
if ( $ExcludedComponentList -notcontains "NutanixFiles" ) { $NutanixFiles = $true } else { $NutanixFiles = $false }
if ( $ExcludedComponentList -notcontains "CitrixNetScaler" ) { $CitrixNetScaler = $true } else { $CitrixNetScaler = $false }

#endregion Report Sections

#region Boilerplates
# -----------------------------------------------------------------------------------------------------------------------
# Section - Boiler Plates
# -----------------------------------------------------------------------------------------------------------------------

#region Boilerplate Intro
$BoilerPlateIntroduction = @"
This document is part of the Nutanix Solutions Architecture Artifacts. We wrote it for individuals responsible for designing, building, managing, testing and supporting Nutanix infrastructures. Readers should be familiar with Nutanix and Citrix products as well as familiar with Login Enterprise testing.

"@
#endregion Boilerplate Intro

#region Boilerplate Appendix
$BoilerPlateAppendix = @"
### Login Enterprise

[Login VSI](http://www.loginvsi.com/) provides the industry-standard virtual desktop testing platform, Login Enterprise, which helps organizations benchmark and validate the performance and scalability of their virtual desktop solutions. With Login Enterprise, IT teams can reliably measure the effects of changes to their virtual desktop infrastructure on end-user experience and identify performance issues before they impact the business. Login Enterprise uses synthetic user workloads to simulate real-world user behavior, so IT teams can measure the responsiveness and performance of their virtual desktop environment under different scenarios. Login Enterprise has two built-in workloads: The [task worker](https://support.loginvsi.com/hc/en-us/articles/6949195003932-Task-Worker-Out-of-the-box) and [knowledge worker](https://support.loginvsi.com/hc/en-us/articles/6949191203740-Knowledge-Worker-Out-of-the-box).

<note>You can't compare the Login Enterprise workloads to the workloads included in the previous edition of Login VSI. The Login Enterprise workloads are much more resource intensive.</note>

The following table includes both workloads available in Login Enterprise.

_Table: Login Enterprise Workloads_

| **Task Worker** | **Knowledge Worker** |
| --- | --- |
| Light | Medium |
| 2 vCPU | 2 - 4 vCPU |
| 2 - 3 apps | 4 - 6 apps |
| No video | 720p video |

#### Login Enterprise EUX Score

According to the [Login Enterprise documentation](https://support.loginvsi.com/hc/en-us/articles/4408717958162-Login-Enterprise-EUX-Score-), the EUX (End User Experience) Score represents the performance of any Windows machine (virtual, physical, cloud, or on-premises). The score ranges from 0 to 10 and measures the experience of one (minimum) or many virtual users.

<note>As you add more users to your VDI platform, expect your EUX Score to drop. As more users demand a greater share of a VDI systems shared resources, performance and user experience decrease.</note>

We interpret EUX Scores with the grades in the following table.

_Table: EUX Score Grades_

| **EUX Score** | **Grade** |
| --- | --- |
| 1 - 5 | Bad |
| 5 - 6 | Poor |
| 6 - 7 | Average |
| 7 - 8 | Good |
| 8 - 10 | Excellent |

![Sample EUX Score Graph](../images/sample-eux-score-graph.png "Sample EUX Score Graph")

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

### Login Enterprise Graph

The Login Enterprise graph shows the values obtained during the launch for each desktop session. The following figure is an example graph of the test data. The y-axis on the left side measures the EUX Score, the y-axis on the right side measures the number of active sessions, and the x-axis represents the test duration in minutes. We configured our benchmark test to sign in all sessions in 48 minutes, followed by a steady state of 20 minutes.

![Sample Login Enterprise Graph](../images/sample-login-enterprise-graph.png "Sample Login Enterprise Graph")

"@
#endregion Boilerplate Appendix

#region Boilerplate Exec Summary
$BoilerPlateExecSummary = @"
Nutanix designed its software to give customers running workloads in a hybrid cloud environment the same experience they expect from on-premises Nutanix clusters. Because Nutanix in a hybrid multicloud environment runs AOS and AHV with the same CLI, UI, and APIs, existing IT processes and third-party integrations continue to work regardless of where they run.

Nutanix AOS can withstand hardware failures and software glitches and ensures that application availability and performance are never compromised. Combining features like native rack awareness with public cloud partition placement groups, Nutanix operates freely in a dynamic hybrid multicloud environment.

In addition to desktop and application performance reliability, you get unlimited scalability, data locality, AHV clones, and a single datastore when you deploy Citrix Virtual Apps and Desktops on Nutanix. Nutanix takes the Citrix commitment to simplicity to another level with streamlined management, reduced rollout time, and lower operating expenses.
"@
#endregion Boilerplate Exec Summary

#region Boilerplate Conclusion
$BoilerPlateConclusion = @"
This document is part of the Nutanix Solutions Architecture Artifacts. We wrote it for individuals responsible for designing, building, managing, testing and supporting Nutanix infrastructures. Readers should be familiar with Nutanix and Citrix products as well as familiar with Login Enterprise testing.
"@
#endregion Boilerplate Conclusion

#endregion Boilerplates

#endregion Variables

#Region Execute
# ============================================================================
# Execute
# ============================================================================

# -----------------------------------------------------------------------------------------------------------------------
# Section - Display Options and Start Report
# -----------------------------------------------------------------------------------------------------------------------

#region Checkoutput Directory
# Convert the Report Title to PascalCase and Create Report Output Directory
Write-Screen -Message "Checking Output Directory"
$Directory = (Get-Culture).TextInfo.ToTitleCase($ReportTitle) -Replace " "
$Directory = "Reports\" + $Directory
$ImagePath = $Directory + "\images"
$md = $Directory + "\md"
$mdFullFile = $md + "\" + $mdFile

if (!(Test-Path -Path $Directory)) {
    Write-Screen -Message "Directory: $($Directory) Does Not Exist, Creating"
    try {
        $ReportsDir = New-Item -Path $Directory -ItemType Directory -ErrorAction Stop
        try {
            $ImagePathDir = New-Item -Path $ImagePath -ItemType Directory -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to create Directory"
            Write-Warning $_
            Exit 1
        }
    }
    catch {
        Write-Warning "Failed to create Output Directory"
        Write-Warning $_
        Exit 1
    }
}

#endregion Checkoutput Directory

#region Create Report File
# Create the File path and initial file
if (!(Test-Path -Path $mdFullFile)) {
    Write-Screen -Message "Creating Markdown File: $($mdFile)"
    try {
        $mdOutput = New-Item -Path $md -Name $mdFile -Force -ItemType File -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to create markdown file"
        Write-Warning $_
        Exit 1
    }
}
else {
    ## Create a new one with a date stamp
    Write-Screen -Message "Markdown File: $($mdFile) Already exists, creating a new file with a date stamp"
    try {
        $dateTime = Get-Date
        $formattedDateTime = $dateTime.ToString("yyyy-MM-dd_HH-mm-ss")
        $NewMDFile = ($mdFile + "_" + $formattedDateTime + ".MD")
        $NewMDFile = $NewMDFile -replace "README.MD","README"
        $mdOutput = New-Item -path $md -Name $NewMDFile -ErrorAction Stop
        $mdFullFile = $md + "\" + $NewMDFile
        Write-Screen -Message "Markdown file is $($mdFullFile)"
    }
    catch {
        Write-Warning "Failed to create markdown file"
        Write-Warning $_
        Exit 1
    }
}

#endregion Create Report File

#region SnazzyHeader
# Write out a SNAZZY header
Clear-Host
Write-Host "
_____ _   _  ____   _____             _                      _             
| ____| | | |/ ___| | ____|_ __   __ _(_)_ __   ___  ___ _ __(_)_ __   __ _ 
|  _| | | | | |     |  _| | '_ \ / _` | | '_ \ / _ \/ _ \ '__| | '_ \ / _` |
| |___| |_| | |___  | |___| | | | (_| | | | | |  __/  __/ |  | | | | | (_| |
|_____|\___/ \____| |_____|_| |_|\__, |_|_| |_|\___|\___|_|  |_|_| |_|\__, |
                                 |___/                                |___/ 
____            __   _____         _   _               ____                       _   
|  _ \ ___ _ __ / _| |_   _|__  ___| |_(_)_ __   __ _  |  _ \ ___ _ __   ___  _ __| |_ 
| |_) / _ \ '__| |_    | |/ _ \/ __| __| | '_ \ / _` | | |_) / _ \ '_ \ / _ \| '__| __|
|  __/  __/ |  |  _|   | |  __/\__ \ |_| | | | | (_| | |  _ <  __/ |_) | (_) | |  | |_ 
|_|   \___|_|  |_|     |_|\___||___/\__|_|_| |_|\__, | |_| \_\___| .__/ \___/|_|   \__|
                                                |___/            |_|                   
"

# Display the selected options selected back to the user
Write-Host "
--------------------------------------------------------------------------------------------------------"
Write-Host "Report Title:                  $($ReportTitle)"
Write-Host "Report Source URI:             $($SourceUri)"
Write-Host "Report Markdown File:          $($mdFullFile)"
Write-Host "Images Output Path:            $($ImagePath)"
Write-Host "Images Output Suffix:          $($ImageSuffix)"
Write-Host "Sections Selected:"
Write-Host "BootInfo:                      $($BootInfo)"
Write-Host "Login Enterprise Results:      $($LoginEnterpriseResults)"
Write-Host "Host Resources:                $($HostResources)"
Write-Host "Cluster Resources:             $($ClusterResources)"
Write-Host "Login Times:                   $($LoginTimes)"
Write-Host "Remote Desktop Analysis:       $($RDA)"
Write-Host "Individual Runs:               $($IndividualRuns)"
Write-Host "Applications:                  $($Applications)"
Write-Host "Vsi Eux Measurements:          $($VsiEuxMeasurements)"
Write-Host "Nutanix Files:                 $($NutanixFiles)"
Write-Host "Citrix NetScaler:              $($CitrixNetScaler)"
Write-Host "Sections Excluded by Param     $($ExcludedComponentList)"
Write-Host "
--------------------------------------------------------------------------------------------------------"
#endregion SnazzyHeader

#region Confirmation
# Ask for confirmation to start the build - if no the quit
Do { $confirmationStart = Read-Host "Ready to run the report? [y/n]" } Until (($confirmationStart -eq "y") -or ($confirmationStart -eq "n"))

if ($confirmationStart -eq 'n') { 
    Write-Host (Get-Date) ":Confirmation denied, quitting"
    Exit 0 
} 
#endregion Confirmation

Write-Host "Setup Script Functions"
Write-Screen -Message "Set InfluxDB Uri: $($influxDbUrl)"
Write-Screen -Message "Set Icon Uri: $($iconsSource)"

# -----------------------------------------------------------------------------------------------------------------------
# Section - Get Data From Influx for Report
# -----------------------------------------------------------------------------------------------------------------------
#region Get Data From Influx

Write-Screen -Message "Gathering Test Data"
# Build the Influx DB Web Headers
$WebHeaders = @{
    Authorization  = "Token $InfluxToken"
    "Accept"       = "application/csv"
    "Content-Type" = "application/vnd.flux"
}
Write-Screen -Message "Build InfluxDB Web Headers"

$FormattedBucket = (Get-UriVariable -Uri $SourceUri -Var "var-Bucketname").Replace('.', '\.')
$FormattedYear = (Get-UriVariable -Uri $SourceUri -Var "var-Year").Replace('.', '\.')
$FormattedMonth = (Get-UriVariable -Uri $SourceUri -Var "var-Month").Replace('.', '\.')
$FormattedDocumentName = (Get-UriVariable -Uri $SourceUri -Var "var-DocumentName").Replace('.', '\.')
$FormattedComment = (Get-UriVariable -Uri $SourceUri -Var "var-Comment").Replace('.', '\.')
$FormattedTestname = (Get-UriVariable -Uri $SourceUri -Var "var-Testname").Replace('.', '\.')
$FormattedTestRun = (Get-UriVariable -Uri $SourceUri -Var "var-Run").Replace('.', '\.')
$FormattedNaming = (Get-UriVariable -Uri $SourceUri -Var "var-Naming").Replace('.', '\.')
Write-Screen -Message "Finished Parsing Uri Variable Information"

#region Body
# ---------------------------------------------
# Build Body
# ---------------------------------------------
$Body = @"
newNaming = if "$($FormattedNaming)" == "_measurement" then "" else "$($FormattedNaming)"
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
|> map(fn: (r) => ({r with Name: string(v: r.$($FormattedNaming))}))
|> map(fn: (r) => ({Name: r.Name, measurement: r._measurement, run: r.Run, deliverytype: r.DeliveryType, desktopbrokerversion: r.DesktopBrokerVersion, desktopbrokeragentversion: r.DesktopBrokerAgentVersion, clonetype: r.CloneType, sessioncfg: r.SessionCfg, sessionssupport: r.SessionsSupport, nodecount: r.NodeCount, workload: r.Workload, numcpus: r.NumCPUs, numcores: r.NumCores, memorygb: r.MemoryGB, hostgpus: r.HostGPUs, secureboot: r.SecureBoot, vtpm: r.vTPM, credentialguard: r.CredentialGuard, numberofsessions: r.NumberOfSessions, numberofvms: r.NumberOfVMs, targetos: r.TargetOS, targetosversion: r.TargetOSVersion, officeversion: r.OfficeVersion, toolsguestversion: r.ToolsGuestVersion, optimizervendor: r.OptimizerVendor, optimizerversion: r.OptimizationsVersion, gpuprofile: r.GPUProfile, comment: r.Comment, infrassdcount: r.InfraSSDCount, infrasinglenodetest: r.InfraSingleNodeTest, infrahardwaretype: r.InfraHardwareType, infrafullversion: r.InfraFullVersion, infracpubrand: r.InfraCPUBrand, infracputype: r.InfraCPUType, infraaosversion: r.InfraAOSVersion, infrahypervisorbrand: r.InfraHypervisorBrand, infrahypervisorversion: r.InfraHypervisorVersion, infrahypervisortype: r.InfraHypervisorType, infrabios: r.InfraBIOS, infratotalnodes: r.InfraTotalNodes, infracpucores: r.InfraCPUCores, infracputhreadcount: r.InfraCPUThreadCount, infracpusocketcount: r.InfraCPUSocketCount, infracpuspeed: r.InfraCPUSpeed, inframemorygb: r.InfraMemoryGB, bootstart: r.BootStart, boottime: r.BootTime, maxabsoluteactiveactions: r.MaxAbsoluteActiveActions, maxabsolutenewactionsperminute: r.MaxAbsoluteNewActionsPerMinute, maxpercentageactiveactions: r.MaxPercentageActiveActions, vsiproductversion: r.VSIproductVersion, euxversion: r.VSIEUXversion, vsiactivesessioncount: r.VSIactivesessionCount, vsieuxscore: r.VSIEUXscore, vsieuxstate: r.VSIEUXstate, vsivsimax: r.VSIvsiMax, vsivsimaxstate: r.VSIvsiMaxstate, vsivsimaxversion: r.VSIvsiMaxversion}))
|> sort(columns: ["Name", "desktopbrokerversion", "desktopbrokeragentversion", "nodecount", "numberofsessions", "numberofvms", "targetos", "targetosversion", "officeversion", "toolsguestversion", "optimizervendor", "optimizerversion", "gpuprofile", "comment", "infracpubrand", "infracputype", "infraaosversion", "infrahypervisorbrand", "infrahypervisorversion", "infrahypervisortype", "infratotalnodes", "run"])
"@

Write-Screen -Message "Build Body Payload based on Uri Variables"

# Get the test details table from Influx and Split into individual lines
try{
    Write-Screen -Message "Get Test Details from Influx API"
    $TestDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $Body -ErrorAction Stop
} catch {
    Write-Screen -Message "Error Getting Test Details from Influx API"
    break
}

# Get Test Detail Payload Index
$Order = Get-PayloadIndex -TestDetails $TestDetails

# Build the Test Detail Results Array
$TestDetailResults = Get-PayloadResults -TestDetails $TestDetails -Order $Order

#endregion Body

#region Body EUXBase score
# ---------------------------------------------
# Build Body EUXBase score
# ---------------------------------------------
$EUXBaseBody = @"
newNaming = if "$($FormattedNaming)" == "_measurement" then "" else "$($FormattedNaming)"
from(bucket:"$($FormattedBucket)")
|> range(start: 2023-01-01T01:00:00Z, stop: 2023-01-01T02:07:00Z)
|> filter(fn: (r) => r["Year"] =~ /^$($FormattedYear)$/ )
|> filter(fn: (r) => r["Month"] =~ /^$($FormattedMonth)$/ )
|> filter(fn: (r) => r["DocumentName"] =~ /^$($FormattedDocumentName)$/ )
|> filter(fn: (r) => r["Comment"] =~ /^$($FormattedComment)$/ )
|> filter(fn: (r) => r["_measurement"] =~ /^$($FormattedTestname)$/ )
|> filter(fn: (r) => r["InfraTestName"] =~ /^$($FormattedTestRun)$/ )
|> filter(fn: (r) => r._field == "EUXScore")
|> group(columns: ["_measurement", "InfraTestName", newNaming])
|> top(n: 5)
|> mean()
|> map(fn: (r) => ({r with Name: string(v: r.$($FormattedNaming))}))
|> map(fn: (r) => ({Name: r.Name, measurement: r._measurement, VSIBase: r._value}))
|> sort(columns: ["Name", "measurement"])
"@

Write-Screen -Message "Build Body Payload based on Uri Variables"

# Get the test details table from Influx and Split into individual lines
try {
    Write-Screen -Message "Get EUX Base Details from Influx API"
    $EUXBaseDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $EUXBaseBody -ErrorAction Stop
}
catch {
    Write-Screen -Message "Error Getting EUX Base Details from Influx API"
    break
}

# Get Test Detail Payload Index
$EUXBaseOrder = Get-PayloadIndex -TestDetails $EUXBaseDetails

# Build the Test Detail Results Array
$EUXBaseResults = Get-PayloadResults -TestDetails $EUXBaseDetails -Order $EUXBaseOrder

#endregion Body EUXBase score

#region Body Steady State EUC Score
# ---------------------------------------------
# Build Body Steady State EUC Score
# ---------------------------------------------
$SSEUXBody = @"
newNaming = if "$($FormattedNaming)" == "_measurement" then "" else "$($FormattedNaming)"
from(bucket:"$($FormattedBucket)")
|> range(start: 2023-01-01T01:52:00Z, stop: 2023-01-01T02:07:00Z)
|> filter(fn: (r) => r["Year"] =~ /^$($FormattedYear)$/ )
|> filter(fn: (r) => r["Month"] =~ /^$($FormattedMonth)$/ )
|> filter(fn: (r) => r["DocumentName"] =~ /^$($FormattedDocumentName)$/ )
|> filter(fn: (r) => r["Comment"] =~ /^$($FormattedComment)$/ )
|> filter(fn: (r) => r["_measurement"] =~ /^$($FormattedTestname)$/ )
|> filter(fn: (r) => r["InfraTestName"] =~ /^$($FormattedTestRun)$/ )
|> filter(fn: (r) => r._field == "EUXScore")
|> group(columns: ["_measurement", "InfraTestName", newNaming])
|> mean()
|> map(fn: (r) => ({r with Name: string(v: r.$($FormattedNaming))}))
|> map(fn: (r) => ({Name: r.Name, measurement: r._measurement, sseux: r._value}))
|> sort(columns: ["Name", "measurement"])
"@

Write-Screen -Message "Build Body Payload based on Uri Variables"

# Get the test details table from Influx and Split into individual lines
try {
    Write-Screen -Message "Get Steady State EUX Details from Influx API"
    $SSEUXDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $SSEUXBody -ErrorAction Stop
}
catch {
    Write-Screen -Message "Error Getting Steady State EUX Details from Influx API"
    break
}

# Get Test Detail Payload Index
$SSEUXOrder = Get-PayloadIndex -TestDetails $SSEUXDetails

# Build the Test Detail Results Array
$SSEUXResults = Get-PayloadResults -TestDetails $SSEUXDetails -Order $SSEUXOrder

#endregion Body Steady State EUC Score

#region Body Steady state average Host CPU
# ---------------------------------------------
# Build Body Steady State average Host CPU
# ---------------------------------------------
$SSHostCPUBody = @"
newNaming = if "$($FormattedNaming)" == "_measurement" then "" else "$($FormattedNaming)"
from(bucket:"$($FormattedBucket)")
|> range(start: 2023-01-01T01:52:00Z, stop: 2023-01-01T02:07:00Z)
|> filter(fn: (r) => r["Year"] =~ /^$($FormattedYear)$/ )
|> filter(fn: (r) => r["Month"] =~ /^$($FormattedMonth)$/ )
|> filter(fn: (r) => r["DocumentName"] =~ /^$($FormattedDocumentName)$/ )
|> filter(fn: (r) => r["Comment"] =~ /^$($FormattedComment)$/ )
|> filter(fn: (r) => r["_measurement"] =~ /^$($FormattedTestname)$/ )
|> filter(fn: (r) => r["InfraTestName"] =~ /^$($FormattedTestRun)$/ )
|> filter(fn: (r) => r["DataType"] == "Host_Raw")
|> filter(fn: (r) => r["_field"] == "hypervisor_cpu_usage_ppm")
|> group(columns: ["_measurement", "InfraTestName", newNaming])
|> mean()
|> map(fn: (r) => ({r with Name: string(v: r.$($FormattedNaming))}))
|> map(fn: (r) => ({Name: r.Name, measurement: r._measurement, "Host CPU": r._value}))
"@

Write-Screen -Message "Build Body Payload based on Uri Variables"

    # Get the test details table from Influx and Split into individual lines
try {
    Write-Screen -Message "Get Steady State Host CPU Details from Influx API"
    $SSHostCPUDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $SSHostCPUBody -ErrorAction Stop
}
catch {
    Write-Screen -Message "Error Getting Steady State Host CPU Details from Influx API"
    break
}

# Get Test Detail Payload Index
$SSHostCPUOrder = Get-PayloadIndex -TestDetails $SSHostCPUDetails

# Build the Test Detail Results Array
$SSHostCPUResults = Get-PayloadResults -TestDetails $SSHostCPUDetails -Order $SSHostCPUOrder

#endregion Body Steady state average Host CPU

#region Build Body Steady state average Cluster CPU
# ---------------------------------------------
# Build Body Steady State average Cluster CPU
# ---------------------------------------------
$SSClusterCPUBody = @"
newNaming = if "$($FormattedNaming)" == "_measurement" then "" else "$($FormattedNaming)"
from(bucket:"$($FormattedBucket)")
|> range(start: 2023-01-01T01:52:00Z, stop: 2023-01-01T02:07:00Z)
|> filter(fn: (r) => r["Year"] =~ /^$($FormattedYear)$/ )
|> filter(fn: (r) => r["Month"] =~ /^$($FormattedMonth)$/ )
|> filter(fn: (r) => r["DocumentName"] =~ /^$($FormattedDocumentName)$/ )
|> filter(fn: (r) => r["Comment"] =~ /^$($FormattedComment)$/ )
|> filter(fn: (r) => r["_measurement"] =~ /^$($FormattedTestname)$/ )
|> filter(fn: (r) => r["InfraTestName"] =~ /^$($FormattedTestRun)$/ )
|> filter(fn: (r) => r["DataType"] == "Cluster_Raw")
|> filter(fn: (r) => r["_field"] == "hypervisor_cpu_usage_ppm")
|> group(columns: ["_measurement", "InfraTestName", newNaming])
|> mean()
|> map(fn: (r) => ({r with Name: string(v: r.$($FormattedNaming))}))
|> map(fn: (r) => ({Name: r.Name, measurement: r._measurement, "Cluster CPU": r._value}))
"@

Write-Screen -Message "Build Body Payload based on Uri Variables"

# Get the test details table from Influx and Split into individual lines
try {
    Write-Screen -Message "Get Steady State Cluster CPU Details from Influx API"
    $SSClusterCPUDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $SSClusterCPUBody -ErrorAction Stop
}
catch {
    Write-Screen -Message "Error Getting Steady State Cluster CPU Details from Influx API"
    break
}

# Get Test Detail Payload Index
$SSClusterCPUOrder = Get-PayloadIndex -TestDetails $SSClusterCPUDetails

# Build the Test Detail Results Array
$SSClusterCPUResults = Get-PayloadResults -TestDetails $SSClusterCPUDetails -Order $SSClusterCPUOrder

#endregion Build Body Steady state average Cluster CPU

#region Build Body RDA Data
# ---------------------------------------------
# Build Build Body RDA Data
# ---------------------------------------------
$RDABody = @"
newNaming = if "$($FormattedNaming)" == "_measurement" then "" else "$($FormattedNaming)"
from(bucket:"$($FormattedBucket)")
|> range(start: 2023-01-01T01:52:00Z, stop: 2023-01-01T02:07:00Z)
|> filter(fn: (r) => r["Year"] =~ /^$($FormattedYear)$/ )
|> filter(fn: (r) => r["Month"] =~ /^$($FormattedMonth)$/ )
|> filter(fn: (r) => r["Comment"] =~ /^$($FormattedComment)$/ )
|> filter(fn: (r) => r["_measurement"] =~ /^$($FormattedTestname)$/ )
|> filter(fn: (r) => r["DataType"] == "RDA")

|> group(columns: ["_measurement", newNaming, "screenResolutionid","movingImageCompressionConfigurationid","preferredColorDepthid","videoCodecid","VideoCodecUseid","VideoCodecTextOptimizationid","VideoCodecColorspaceid","VideoCodecTypeid","HardwareEncodeEnabledid","VisualQualityid","FramesperSecondid","EDTInUseId"])
|> last()
|> map(fn: (r) => ({r with Name: string(v: r.$($FormattedNaming))}))
|> map(fn: (r) => ({Name: r.Name, measurement: r._measurement, "Screen Resolution": r.screenResolutionid,"Moving Image Compression": r.movingImageCompressionConfigurationid,"Preferred ColorDepth": r.preferredColorDepthid,"Video Codec": r.videoCodecid,"Video Codec Use": r.VideoCodecUseid,"Video Codec Text Optimization": r.VideoCodecTextOptimizationid,"Video Codec Colorspace": r.VideoCodecColorspaceid,"Video Codec Type": r.VideoCodecTypeid,"Hardware Encode Enabled": r.HardwareEncodeEnabledid,"Visual Quality": r.VisualQualityid,"Max FPS": r.FramesperSecondid,"EDT In Use": r.EDTInUseId}))
"@

    Write-Screen -Message "Build Body Payload based on Uri Variables"

    # Get the test details table from Influx and Split into individual lines
    try{
        Write-Screen -Message "Get Remote Display Analytics Details from Influx API"
        $RDADetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $RDABody -ErrorAction Stop
    } catch {
        Write-Screen -Message "Error Getting Remote Display Analytics Details from Influx API"
        break
    }

    # Get Test Detail Payload Index
    $RDADetailsOrder = Get-PayloadIndex -TestDetails $RDADetails

    # Build the Test Detail Results Array
    $RDADetailsResults = Get-PayloadResults -TestDetails $RDADetails -Order $RDADetailsOrder

#endregion Build Body RDA Data

#region Build Body Application score
# ---------------------------------------------
# Build Body Application score
# ---------------------------------------------
$LoginApplicationsBody = @"
newNaming = if "$($FormattedNaming)" == "_measurement" then "" else "$($FormattedNaming)"
from(bucket:"$($FormattedBucket)")
|> range(start: 2023-01-01T01:00:00Z, stop: 2023-01-01T01:52:00Z)
|> filter(fn: (r) => r["Year"] =~ /^$($FormattedYear)$/ )
|> filter(fn: (r) => r["Month"] =~ /^$($FormattedMonth)$/ )
|> filter(fn: (r) => r["DocumentName"] =~ /^$($FormattedDocumentName)$/ )
|> filter(fn: (r) => r["Comment"] =~ /^$($FormattedComment)$/ )
|> filter(fn: (r) => r["_measurement"] =~ /^$($FormattedTestname)$/ )
|> filter(fn: (r) => r["InfraTestName"] =~ /^$($FormattedTestRun)$/ )
|> filter(fn: (r) => r["DataType"] == "Raw_AppMeasurements")
|> filter(fn: (r) => r["_field"] == "result")
|> group(columns: ["_measurement", "InfraTestName", newNaming, "applicationName", "measurementId"])
|> mean()
|> map(fn: (r) => ({r with Name: string(v: r.$($FormattedNaming))}))
|> map(fn: (r) => ({Name: r.Name, measurement: r._measurement, Value: r._value, AppName: r.applicationName, MeasurementId: r.measurementId}))
|> sort(columns: ["Name", "measurement"])
"@

    Write-Screen -Message "Build Body Payload based on Uri Variables"

    # Get the test details table from Influx and Split into individual lines
    try{
        Write-Screen -Message "Get Login Application Details from Influx API"
        $LoginApplicationsDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $LoginApplicationsBody -ErrorAction Stop
    } catch {
        Write-Screen -Message "Error Getting Login Application Details from Influx API"
        break
    }

    # Get Test Detail Payload Index
    $LoginApplicationsOrder = Get-PayloadIndex -TestDetails $LoginApplicationsDetails

    # Build the Test Detail Results Array
    $LoginApplicationsResults = Get-PayloadResults -TestDetails $LoginApplicationsDetails -Order $LoginApplicationsOrder

#endregion Build Body Application score

#region Build Body Steady state Application score
# ---------------------------------------------
# Build Body Steady state Application score
# ---------------------------------------------
$SSApplicationsBody = @"
newNaming = if "$($FormattedNaming)" == "_measurement" then "" else "$($FormattedNaming)"
from(bucket:"$($FormattedBucket)")
|> range(start: 2023-01-01T01:52:00Z, stop: 2023-01-01T02:07:00Z)
|> filter(fn: (r) => r["Year"] =~ /^$($FormattedYear)$/ )
|> filter(fn: (r) => r["Month"] =~ /^$($FormattedMonth)$/ )
|> filter(fn: (r) => r["DocumentName"] =~ /^$($FormattedDocumentName)$/ )
|> filter(fn: (r) => r["Comment"] =~ /^$($FormattedComment)$/ )
|> filter(fn: (r) => r["_measurement"] =~ /^$($FormattedTestname)$/ )
|> filter(fn: (r) => r["InfraTestName"] =~ /^$($FormattedTestRun)$/ )
|> filter(fn: (r) => r["DataType"] == "Raw_AppMeasurements")
|> filter(fn: (r) => r["_field"] == "result")
|> group(columns: ["_measurement", "InfraTestName", newNaming, "applicationName", "measurementId"])
|> mean()
|> map(fn: (r) => ({r with Name: string(v: r.$($FormattedNaming))}))
|> map(fn: (r) => ({Name: r.Name, measurement: r._measurement, Value: r._value, AppName: r.applicationName, MeasurementId: r.measurementId}))
|> sort(columns: ["Name", "measurement"])
"@

    Write-Screen -Message "Build Body Payload based on Uri Variables"

    # Get the test details table from Influx and Split into individual lines
    try{
        Write-Screen -Message "Get Steady State Application Details from Influx API"
        $SSApplicationsDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $SSApplicationsBody -ErrorAction Stop
    } catch {
        Write-Screen -Message "Error Getting Steady State Application Details from Influx API"
        break
    }

    # Get Test Detail Payload Index
    $SSApplicationsOrder = Get-PayloadIndex -TestDetails $SSApplicationsDetails

    # Build the Test Detail Results Array
    $SSApplicationsResults = Get-PayloadResults -TestDetails $SSApplicationsDetails -Order $SSApplicationsOrder

#endregion Build Body Steady state Application score

#endregion Get Data From Influx

# -----------------------------------------------------------------------------------------------------------------------
# Section - Download Icons
# -----------------------------------------------------------------------------------------------------------------------
#region Download Icons
Write-Screen -Message "Downloading Icons"
$icons = @('Nutanix-Logo','bootinfo','hardware','infrastructure','broker','targetvm','loginenterprise','testicon','leresults','hostresources','clusterresources','logintimes','individualruns','appresults','euxmeasurements','filesicon','citrixnetscaler','base_image','sample-eux-score-graph','sample-login-enterprise-graph','rdainfo','appsperf')   

# Loop through the icons and download the images
foreach($icon in $icons){
    Get-UriFile -Uri ($iconsSource + "$($icon).png") -OutFile (Join-Path -Path $imagePath -ChildPath "$($icon).png")
}

#endregion Download Icons

# -----------------------------------------------------------------------------------------------------------------------
# Section - Get Results
# -----------------------------------------------------------------------------------------------------------------------
#region Get Results

#region Boot Info
# -----------------------------------------------------------------------------------------------------------------------
# Section - Boot Info
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($BootInfo) {
    Write-Screen -Message "Downloading Boot Info Graphs"
    # Build the PanelID Array 
    $Panels = @('85', '84', '86', '94', '92', '96', '89', '95', '93', '97')   
    [int]$maxboottime = (($testDetailResults.boottime | measure -Maximum).maximum + 30) * 1000
    $endtime = 1672534800000 + $maxboottime
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
}
else {
    Write-Screen -Message "Boot Info Download Skipped"
}
#endregion Boot Info

#region Login Enterprise Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Login Enterprise Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($LoginEnterpriseResults) {
    Write-Screen -Message "Downloading Login Enterprise Graphs"
    # Build the PanelID Array 
    $Panels = @('2', '5', '8', '4', '7', '6', '99', '100', '10', '101')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
}
else {
    Write-Screen -Message "Login Enterprise Results Download Skipped"
}
#endregion Login Enterprise Results

#region Host Resources Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Host Resources Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($HostResources) {
    Write-Screen -Message "Downloading Host Resources Graphs"
    # Build the PanelID Array 
    $Panels = @('13', '83', '14', '9')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
}
else {
    Write-Screen -Message "Host Resources Download Skipped"
}
#endregion Host Resources Results

#region Cluster Resources Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Cluster Resources Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($ClusterResources) {
    Write-Screen -Message "Downloading Cluster Resources Graphs"
    # Build the PanelID Array 
    $Panels = @('53', '120', '54', '57', '58')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
}
else {
    Write-Screen -Message "Cluster Resources Download Skipped"
}
#endregion Cluster Resources Results

#region Login Times Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Login Times Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($LoginTimes) {
    Write-Screen -Message "Downloading Login Times Graphs"
    # Build the PanelID Array 
    $Panels = @('61', '98', '16', '28', '27', '29')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
}
else {
    Write-Screen -Message "Login Times Download Skipped" 
}
#endregion Login Times Results

#region Remote Display Analytics Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Remote Display Analytics Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($RDA) {
    Write-Screen -Message "Downloading Remote Display Analytics Graphs"
    # Build the PanelID Array 
    $Panels = @('110', '111', '112', '115', '113', '116', '117', '114')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
}
else {
    Write-Screen -Message "Remote Display Analytics Download Skipped"   
}
#endregion Remote Display Analytics Results

#region Individual Runs Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Individual Runs Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($IndividualRuns) {
    Write-Screen -Message "Downloading Individual Runs Graphs"
    # Build the PanelID Array 
    $Panels = @('66', '67', '68', '70', '69')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
}
else {
    Write-Screen -Message "Individual Runs Download Skipped"  
}
#endregion Individual Runs Results

#region Applications Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Applications Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($Applications) {
    Write-Screen -Message "Downloading Applications Graphs"
    # Build the PanelID Array 
    $Panels = @('31', '32', '33', '34', '37', '38', '39', '40', '36', '42', '44', '43', '35', '41', '102')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
}
else {
    Write-Screen -Message "Applications Download Skipped"  
}
#endregion Applications Results

#region VSI EUX Measurements Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - VSI EUX Measurements Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($VsiEuxMeasurements) {
    Write-Screen -Message "Downloading VSI EUX Measurements Graphs"
    # Build the PanelID Array 
    $Panels = @('15', '30', '45', '46', '47', '48', '49', '50')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
}
else {
    Write-Screen -Message "VSI EUX Measurements Download Skipped"  
}
#endregion VSI EUX Measurements Results

#region Nutanix Files Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Nutanix Files Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($NutanixFiles) {
    Write-Screen -Message "Downloading Nutanix Files Graphs"
    # Build the PanelID Array 
    $Panels = @('71', '77', '78', '79')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
}
else {
    Write-Screen -Message "Nutanix Files Download Skipped"
}
#endregion Nutanix Files Results

#region Citrix NetScaler Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Citrix NetScaler Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($CitrixNetScaler) {
    Write-Screen -Message "Downloading Citrix NetScaler Graphs"
    # Build the PanelID Array 
    $Panels = @('80', '81', '82', '104', '105', '103', '106')
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
}
else {
    Write-Screen -Message "Citrix NetScaler Download Skipped"   
}

#endregion Citrix NetScaler Results

#endregion Get Results

# -----------------------------------------------------------------------------------------------------------------------
# Section - Create Report
# -----------------------------------------------------------------------------------------------------------------------
#region Create Report

#region Create Header
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

# Create the Exec Summary
Write-Screen -Message "Adding Executive Summary"
Add-Title -mdFullFile $mdFullFile -Title "Executive Summary"
Add-Content $mdFullFile "$($BoilerPlateExecSummary)"

# Create the Introduction
Write-Screen -Message "Adding Introduction"
Add-Title -mdFullFile $mdFullFile -Title "Introduction"
Add-Content $mdFullFile "### Audience"
Add-Content $mdFullFile " "
Add-Content $mdFullFile "$($BoilerPlateIntroduction)"
Add-Content $mdFullFile "### Purpose"
Add-Content $mdFullFile " "
Add-Content $mdFullFile "This document covers the following subject areas:"
Add-Content $mdFullFile " - Test Detail Specifics."
Add-Content $mdFullFile " - Test Results for $($ReportTitle)."
Add-Content $mdFullFile "  "
Add-Content $mdFullFile "### Document Version History "
Add-Content $mdFullFile "  "
Add-Content $mdFullFile "| Version Number | Published | Notes |"
Add-Content $mdFullFile "| :---: | --- | --- |"
$Month = get-date -format "MM"
$ReportMonth = (Get-Culture).DateTimeFormat.GetMonthName($Month)  
$ReportYear = get-date -format "yyyy" 
Add-Content $mdFullFile "| 1.0 | $($ReportMonth) $($ReportYear) | Original publication. |"
#endregion Create Header

#region Test Detail Specifics
# -----------------------------------------------------------------------------------------------------------------------
# Section - Test Detail Specifics
# -----------------------------------------------------------------------------------------------------------------------
Write-Screen -Message "Add Test Detail Header"
Add-Title -mdFullFile $mdFullFile -Title "Test Details"
#endregion Test Detail Specifics

#region Hardware Specifics
# -----------------------------------------------------------------------------------------------------------------------
# Hardware Specifics Section
# -----------------------------------------------------------------------------------------------------------------------
$Title = "Hardware Specifics"
Write-Screen -Message "Adding $($Title)"

# Get Filtered Data
$HardwareFiltered = $TestDetailResults | Select Name, measurement, infrahardwaretype, infracpubrand, infracputype, infracpuspeed, infracpucores, inframemorygb, infracpusocketcount, nodecount, infratotalnodes, infrassdcount, infrabios, hostgpus, comment | Sort-Object Name | Get-Unique -AsString

# Add the Table Header
Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $Title -TableData $HardwareFiltered -TableImage "<img src=../images/hardware.png alt=$($Title)>"

# Build the Table Dataset
Write-Screen -Message "Building $($Title) Data"
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

foreach ($Record in $HardwareFiltered) {
    $HardwareType = $HardwareType + "$(Get-CleanData -Data ($Record.infrahardwaretype)) | "
    $CPUBrand = $CPUBrand + "$(Get-CleanData -Data ($Record.infracpubrand)) | "
    $CPUSpeed = $CPUSpeed + "$(Get-CleanData -Data ($Record.infracpuspeed)) GHz | "
    $Sockets = $Sockets + "$(Get-CleanData -Data ($Record.infracpusocketcount)) | "
    $CPUCores = $CPUCores + "$(Get-CleanData -Data ($Record.infracpucores)) | "
    [int]$Mem = Get-CleanData -Data ($Record.inframemorygb)
    $MemoryFormatted = '{0:N0}' -f $Mem
    $Memory = $Memory + "$($MemoryFormatted) GB | "
    $Nodes = $Nodes + "$(Get-CleanData -Data ($Record.nodecount)) | "
    $TotalNodes = $TotalNodes + "$(Get-CleanData -Data ($Record.infratotalnodes)) | "
    $SSD = $SSD + "$(Get-CleanData -Data ($Record.infrassdcount)) | "
    $Bios = $Bios + "$(Get-CleanData -Data ($Record.infrabios)) | "
    $HostGPU = $HostGPU + "$(Get-CleanData -Data ($Record.hostgpus)) | "
    $CPUType = $CPUType + "$(Get-CleanData -Data ($Record.infracputype)) | "
}

# Add the Table
Write-Screen -Message "Adding $($Title) Data"
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

#endregion Hardware Specifics

#region Infrastructure Software specifics
# -----------------------------------------------------------------------------------------------------------------------
# Infrastructure Software specifics
# -----------------------------------------------------------------------------------------------------------------------
$Title = "Infrastructure Specifics"
Write-Screen -Message "Adding $($Title)"

# Get Filtered Data
$InfraFiltered = $TestDetailResults | Select Name, measurement, infraaosversion, infrafullversion, infrahypervisorbrand, infrahypervisortype, infrahypervisorversion, comment | Sort-Object Name | Get-Unique -AsString

# Add the Table Header
Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $Title -TableData $HardwareFiltered -TableImage "<img src=../images/infrastructure.png alt=$($Title)>"

# Build the Table Dataset
Write-Screen -Message "Building $($Title) Data"
[string]$infraaosversion = "| **OS Version** | "
[string]$infrafullversion = "| **OS Full Version** | "
[string]$infrahypervisorbrand = "| **Hypervisor Brand** | "
[string]$infrahypervisortype = "| **Hypervisor Type** | "
[string]$infrahypervisorversion = "| **Hypervisor Version** | "

foreach ($Record in $InfraFiltered) {
    $infraaosversion = $infraaosversion + "$(Get-CleanData -Data ($Record.infraaosversion)) | "
    $infrafullversion = $infrafullversion + "$(Get-CleanData -Data ($Record.infrafullversion)) | "
    $infrahypervisorbrand = $infrahypervisorbrand + "$(Get-CleanData -Data ($Record.infrahypervisorbrand)) | "
    $infrahypervisortype = $infrahypervisortype + "$(Get-CleanData -Data ($Record.infrahypervisortype)) | "
    $infrahypervisorversion = $infrahypervisorversion + "$(Get-CleanData -Data ($Record.infrahypervisorversion)) | "
}

# Add the Table
Write-Screen -Message "Adding $($Title) Data"
Add-Content $mdFullFile $infraaosversion
Add-Content $mdFullFile $infrafullversion
Add-Content $mdFullFile $infrahypervisorbrand
Add-Content $mdFullFile $infrahypervisortype
Add-Content $mdFullFile $infrahypervisorversion

#endregion Infrastructure Software specifics

#region Brokering Specifics
# -----------------------------------------------------------------------------------------------------------------------
# Brokering Specifics
# -----------------------------------------------------------------------------------------------------------------------
$Title = "Broker Specifics"
Write-Screen -Message "Adding $($Title)"

# Get Filtered Data
$BrokerFiltered = $TestDetailResults | Select Name, measurement, deliverytype, desktopbrokerversion, sessionssupport, sessioncfg, comment | Sort-Object Name | Get-Unique -AsString

# Add the Table Header
Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $Title -TableData $HardwareFiltered -TableImage "<img src=../images/broker.png alt=$($Title)>"

# Build the Table Dataset
Write-Screen -Message "Building $($Title) Data"
[string]$deliverytype = "| **Delivery Type** | "
[string]$desktopbrokerversion = "| **Desktop Broker Version** | "
[string]$sessionssupport = "| **Session Type** | "
[string]$sessioncfg = "| **Session Config** | "

foreach ($Record in $BrokerFiltered) {
    $deliverytype = $deliverytype + "$(Get-CleanData -Data ($Record.deliverytype)) | "
    $desktopbrokerversion = $desktopbrokerversion + "$(Get-CleanData -Data ($Record.desktopbrokerversion)) | "
    $sessionssupport = $sessionssupport + "$(Get-CleanData -Data ($Record.sessionssupport)) | "
    $sessioncfg = $sessioncfg + "$(Get-CleanData -Data ($Record.sessioncfg)) | "
}

# Add the Table
Write-Screen -Message "Adding $($Title) Data"
Add-Content $mdFullFile $deliverytype
Add-Content $mdFullFile $desktopbrokerversion
Add-Content $mdFullFile $sessionssupport
Add-Content $mdFullFile $sessioncfg

#endregion Brokering Specifics

#region Target VM Specifics
# -----------------------------------------------------------------------------------------------------------------------
# Target VM Specifics
# -----------------------------------------------------------------------------------------------------------------------
$Title = "Target VM Specifics"
Write-Screen -Message "Adding $($Title)"

# Get Filtered Data
$TargetVMFiltered = $TestDetailResults | Select Name, measurement, numcpus, numcores, memorygb, gpuprofile, secureboot, vtpm, credentialguard, targetos, targetosversion, desktopbrokeragentversion, officeversion, clonetype, toolsguestversion, optimizervendor, optimizerversion, comment | Sort-Object Name | Get-Unique -AsString

 # Add the Table Header
Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $Title -TableData $HardwareFiltered -TableImage "<img src=../images/targetvm.png alt=$($Title)>"

# Build the Table Dataset
Write-Screen -Message "Building $($Title) Data"
[string]$numcpus = "| **CPU Sockets** | "
[string]$numcores = "| **Cores per Socket** | "
[string]$memorygb = "| **Memory** | "
[string]$gpuprofile = "| **GPU profile** | "
[string]$secureboot = "| **Secure Boot** | "
[string]$vtpm = "| **Virtual TPM** | "
[string]$credentialguard = "| **Credential Guard** | "
[string]$targetos = "| **Operating System** | "
[string]$targetosversion = "| **Operating System Version** | "
[string]$desktopbrokeragentversion = "| **Desktop Broker Agent Version** | "
[string]$officeversion = "| **Office Version** | "
[string]$clonetype = "| **Clone Type** | "
[string]$toolsguestversion = "| **Guest Tools Version** | "
[string]$optimizervendor = "| **Optimizer Vendor** | "
[string]$optimizerversion = "| **Optimizer Version** | "

foreach ($Record in $TargetVMFiltered) {
    $numcpus = $numcpus + "$(Get-CleanData -Data ($Record.numcpus)) | "
    $numcores = $numcores + "$(Get-CleanData -Data ($Record.numcores)) | "
    $memorygb = $memorygb + "$(Get-CleanData -Data ($Record.memorygb)) GB | "
    $gpuprofile = $gpuprofile + "$(Get-CleanData -Data ($Record.gpuprofile)) | "
    $secureboot = $secureboot + "$(Get-CleanData -Data ($Record.secureboot)) | "
    $vtpm = $vtpm + "$(Get-CleanData -Data ($Record.vtpm)) | "
    $credentialguard = $credentialguard + "$(Get-CleanData -Data ($Record.credentialguard)) | "
    $targetos = $targetos + "$(Get-CleanData -Data ($Record.targetos)) | "
    $targetosversion = $targetosversion + "$(Get-CleanData -Data ($Record.targetosversion)) | "
    $desktopbrokeragentversion = $desktopbrokeragentversion + "$(Get-CleanData -Data ($Record.desktopbrokeragentversion)) | "
    $officeversion = $officeversion + "$(Get-CleanData -Data ($Record.officeversion)) | "
    $clonetype = $clonetype + "$(Get-CleanData -Data ($Record.clonetype)) | "
    $toolsguestversion = $toolsguestversion + "$(Get-CleanData -Data ($Record.toolsguestversion)) | "
    $optimizervendor = $optimizervendor + "$(Get-CleanData -Data ($Record.optimizervendor)) | "
    $optimizerversion = $optimizerversion + "$(Get-CleanData -Data ($Record.optimizerversion)) | "
}

# Add the Table
Write-Screen -Message "Adding $($Title) Data"
Add-Content $mdFullFile $numcpus
Add-Content $mdFullFile $numcores
Add-Content $mdFullFile $memorygb
Add-Content $mdFullFile $gpuprofile
Add-Content $mdFullFile $secureboot
Add-Content $mdFullFile $vtpm
Add-Content $mdFullFile $credentialguard
Add-Content $mdFullFile $targetos
Add-Content $mdFullFile $targetosversion
Add-Content $mdFullFile $desktopbrokeragentversion
Add-Content $mdFullFile $officeversion
Add-Content $mdFullFile $clonetype
Add-Content $mdFullFile $toolsguestversion
Add-Content $mdFullFile $optimizervendor
Add-Content $mdFullFile $optimizerversion

#endregion Target VM Specifics

#region Login Enterprise Specifics
# -----------------------------------------------------------------------------------------------------------------------
# Login Enterprise Specifics
# -----------------------------------------------------------------------------------------------------------------------
$Title = "Login Enterprise Specifics"
Write-Screen -Message "Adding $($Title)"

# Get Filtered Data
$LEspecsFiltered = $TestDetailResults | Select Name, measurement, vsiproductversion, euxversion, vsivsimaxversion, workload, comment | Sort-Object Name | Get-Unique -AsString

# Add the Table Header
Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $Title -TableData $HardwareFiltered -TableImage "<img src=../images/loginenterprise.png alt=$($Title)>"

# Build the Table Dataset
Write-Screen -Message "Building $($Title) Data"
[string]$vsiproductversion = "| **Product Version** | "
[string]$euxversion = "| **EUX Version** | "
[string]$vsivsimaxversion = "| **VSIMax Version** | "
[string]$workload = "| **Workload** | "

foreach ($Record in $LEspecsFiltered) {
    $vsiproductversion = $vsiproductversion + "$(Get-CleanData -Data ($Record.vsiproductversion)) | "
    $euxversion = $euxversion + "$(Get-CleanData -Data ($Record.euxversion)) | "
    $vsivsimaxversion = $vsivsimaxversion + "$(Get-CleanData -Data ($Record.vsivsimaxversion)) | "
    $workload = $workload + "$(Get-CleanData -Data ($Record.workload)) | "
}

# Add the Table
Write-Screen -Message "Adding $($Title) Data"
Add-Content $mdFullFile $vsiproductversion
Add-Content $mdFullFile $euxversion
Add-Content $mdFullFile $vsivsimaxversion
Add-Content $mdFullFile $workload

#endregion Login Enterprise Specifics

#region Test Specifics
# -----------------------------------------------------------------------------------------------------------------------
# Test Specifics
# -----------------------------------------------------------------------------------------------------------------------
$Title = "Test Specifics"
Add-Content $mdFullFile " " 
Write-Screen -Message "Adding $($Title)"

# Get Filtered Data
$TestFiltered = $TestDetailResults | Select Name, measurement, infrasinglenodetest, numberofvms, numberofsessions, comment | Sort-Object Name | Get-Unique -AsString

# Add the Table Header
Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $Title -TableData $HardwareFiltered -TableImage "<img src=../images/testicon.png alt=$($Title)>"

# Build the Table Dataset
Write-Screen -Message "Building $($Title) Data"
[string]$infrasinglenodetest = "| **Single Node Test** | "
[string]$numberofvms = "| **Number Of VMs** | "
[string]$numberofsessions = "| **Number Of Sessions** | "

foreach ($Record in $TestFiltered) {
    $infrasinglenodetest = $infrasinglenodetest + "$(Get-CleanData -Data ($Record.infrasinglenodetest)) | "
    [int]$VMS = Get-CleanData -Data ($Record.numberofvms)
    $VMsFormatted = '{0:N0}' -f $VMS
    $numberofvms = $numberofvms + "$($VMsFormatted) | "
    [int]$Sessions = Get-CleanData -Data ($Record.numberofsessions)
    $SessionsFormatted = '{0:N0}' -f $Sessions
    $numberofsessions = $numberofsessions + "$($SessionsFormatted) | "
}

# Add the Table
Write-Screen -Message "Adding $($Title) Data"
Add-Content $mdFullFile $infrasinglenodetest
Add-Content $mdFullFile $numberofvms
Add-Content $mdFullFile $numberofsessions

#endregion Test Specifics

#region Test Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Test Results
# -----------------------------------------------------------------------------------------------------------------------
Add-Title -mdFullFile $mdFullFile -Title "Test Results"
#endregion Test Results

#region Boot Information
# -----------------------------------------------------------------------------------------------------------------------
# Section - Boot Information
# -----------------------------------------------------------------------------------------------------------------------
if ($BootInfo) {

    $Title = "Boot Information"
    Add-Content $mdFullFile " " 
    Add-Content $mdFullFile "### $($Title)"

    # Add Boot Information Table
    $Title = "Boot Parmeters"
    Write-Screen -Message "Adding $($Title)"

    # Get Filtered Data
    $BootFiltered = $TestDetailResults | Select Name, measurement, maxabsoluteactiveactions, maxabsolutenewactionsperminute, maxpercentageactiveactions, comment | Sort-Object Name | Get-Unique -AsString

    # Add the Table Header
    Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $Title -TableData $HardwareFiltered -TableImage "<img src=../images/bootinfo.png alt=$($Title)>"

    # Build the Table Dataset
    Write-Screen -Message "Building $($Title) Data"
    [string]$maxabsoluteactiveactions = "| **Max Absolute Active Actions** | "
    [string]$maxabsolutenewactionsperminute = "| **Max Absolute Actions Per Minute** | "
    [string]$maxpercentageactiveactions = "| **Max Percentage Active Actions** | "

    foreach ($Record in $BootFiltered) {
        $maxabsoluteactiveactions = $maxabsoluteactiveactions + "$(Get-CleanData -Data ($Record.maxabsoluteactiveactions)) | "
        $maxabsolutenewactionsperminute = $maxabsolutenewactionsperminute + "$(Get-CleanData -Data ($Record.maxabsolutenewactionsperminute)) | "
        $maxpercentageactiveactions = $maxpercentageactiveactions + "$(Get-CleanData -Data ($Record.maxpercentageactiveactions)) | "
    }

    # Add the Table
    Write-Screen -Message "Adding $($Title) Data"
    Add-Content $mdFullFile $maxabsoluteactiveactions
    Add-Content $mdFullFile $maxabsolutenewactionsperminute
    Add-Content $mdFullFile $maxpercentageactiveactions

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq '.png') -and ($_.Name -like "boot_time*") } | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Boot Information" -mdFullFile $mdFullFile

}
#endregion Boot Information

#region Login Enterprise Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Login Enterprise Results
# -----------------------------------------------------------------------------------------------------------------------
if ($LoginEnterpriseResults) {

    $Title = "Login Enterprise"
    Add-Content $mdFullFile " " 
    Add-Content $mdFullFile "### $($Title)"

    Add-Content $mdFullFile " "
    Add-Content $mdFullFile "|  | **EUX Base** | **Difference in %** |"
    Add-Content $mdFullFile "| --- | --- | --- |"

    [decimal]$MaxValue = [math]::Round(($EUXBaseResults.VSIBase | measure -Maximum).maximum, 1)

    foreach ($Result in $EUXBaseResults) {
        $Name = $(Get-CleanData -Data ($Result.Name))
        [decimal]$VSIBase = [math]::Round($(Get-CleanData -Data ($Result.VSIBase)), 1).ToString("#.0")
        [decimal]$Percent = [math]::Round((100 - (($VSIBase / $MaxValue) * 100)), 1)
        if ($Percent -eq 0) {
            $PercentValue = "Highest EUX Base"
        }
        else {
            $PercentValue = "-$($Percent)% from Highest EUX Base"
        }
        $Line = "| $($Name) | $($VSIBase) | $($PercentValue) |"
        Add-Content $mdFullFile $Line
    }
    Add-Content $mdFullFile " "

    Add-Content $mdFullFile "|  | **EUX Score (Steady State)** | **Difference in %** |"
    Add-Content $mdFullFile "| --- | --- | --- |"

    [decimal]$MaxValue = [math]::Round(($SSEUXResults.sseux | measure -Maximum).maximum, 1)

    foreach ($Result in $SSEUXResults) {
        $Name = $(Get-CleanData -Data ($Result.Name))
        [decimal]$SSEUXBase = [math]::Round($(Get-CleanData -Data ($Result.sseux)), 1).ToString("#.0")
        [decimal]$Percent = [math]::Round((100 - (($SSEUXBase / $MaxValue) * 100)), 1)
        if ($Percent -eq 0) {
            $PercentValue = "Highest EUX Score"
        }
        else {
            $PercentValue = "-$($Percent)% from Highest EUX Score"
        }
        $Line = "| $($Name) | $($SSEUXBase) | $($PercentValue) |"
        Add-Content $mdFullFile $Line
    }
    Add-Content $mdFullFile " "

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq '.png') -and ($_.Name -like "le_results*") } | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Login Enterprise" -mdFullFile $mdFullFile
}
#endregion Login Enterprise Results

#region Host Resources Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Host Resources Results
# -----------------------------------------------------------------------------------------------------------------------
if ($HostResources) {

    $Title = "Host Resources"
    Add-Content $mdFullFile " " 
    Add-Content $mdFullFile "### $($Title)"

    Add-Content $mdFullFile " "
    Add-Content $mdFullFile "|  | **Host CPU (Steady State)** | **Difference in %** |"
    Add-Content $mdFullFile "| --- | --- | --- |"

    [decimal]$MinValue = [math]::Round(($SSHostCPUResults."Host CPU" | measure -Minimum).minimum, 1)

    foreach ($Result in $SSHostCPUResults) {
        $Name = $(Get-CleanData -Data ($Result.Name))
        [decimal]$SSHostCPU = [math]::Round($(Get-CleanData -Data ($Result."Host CPU")), 1).ToString("#.0")
        [decimal]$Percent = [math]::Round(($SSHostCPU - $MinValue), 1)
        if ($Percent -eq 0) {
            $PercentValue = "Lowest CPU Value"
        }
        else {
            $PercentValue = "$($Percent)% Higher CPU Usage"
        }
        $Line = "| $($Name) | $($SSHostCPU) % | $($PercentValue) |"
        Add-Content $mdFullFile $Line
    }
    Add-Content $mdFullFile " "

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq '.png') -and ($_.Name -like "host_resources*") } | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Host Resources" -mdFullFile $mdFullFile
        
}
#endregion Host Resources Results

#region Cluster Resources Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Cluster Resources Results
# -----------------------------------------------------------------------------------------------------------------------
if ($ClusterResources) {

    $Title = "Cluster Resources"
    Add-Content $mdFullFile "### $($Title)"

    Add-Content $mdFullFile " "
    Add-Content $mdFullFile "|  | **Cluster CPU (Steady State)** | **Difference in %** |"
    Add-Content $mdFullFile "| --- | --- | --- |"

    [decimal]$MinValue = [math]::Round(($SSClusterCPUResults."Cluster CPU" | measure -Minimum).minimum, 1)

    foreach ($Result in $SSClusterCPUResults) {
        $Name = $(Get-CleanData -Data ($Result.Name))
        [decimal]$SSClusterCPU = [math]::Round($(Get-CleanData -Data ($Result."Cluster CPU")), 1).ToString("#.0")
        [decimal]$Percent = [math]::Round(($SSClusterCPU - $MinValue), 1)
        if ($Percent -eq 0) {
            $PercentValue = "Lowest CPU Value"
        }
        else {
            $PercentValue = "$($Percent)% Higher CPU Usage"
        }
        $Line = "| $($Name) | $($SSClusterCPU) % | $($PercentValue) |"
        Add-Content $mdFullFile $Line
    }
    Add-Content $mdFullFile " "

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq '.png') -and ($_.Name -like "cluster_resources*") } | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Cluster Resources" -mdFullFile $mdFullFile   
}
#endregion Cluster Resources Results

#region Login Times Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Login Times Results
# -----------------------------------------------------------------------------------------------------------------------
if ($LoginTimes) {

    $Title = "Login Times"
    Add-Content $mdFullFile "### $($Title)"

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq '.png') -and ($_.Name -like "login_times*") } | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Login Times" -mdFullFile $mdFullFile
}
#endregion Login Times Results

#region Remote Display Analytics Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Remote Display Analytics Results
# -----------------------------------------------------------------------------------------------------------------------
if ($RDA) {

    $Title = "Remote Display Analytics"
    Add-Content $mdFullFile "### $($Title)"

    # Add Information Table
    Write-Screen -Message "Adding $($Title)"

    # Get Filtered Data
    $RDAFiltered = $RDADetailsResults | Select Name, "Screen Resolution", "Moving Image Compression", "Visual Quality", "Video Codec Text Optimization", "EDT In Use", "Video Codec Use", "Video Codec Colorspace", "Video Codec Type", "Max FPS", "Hardware Encode Enabled", "comment", "measurement", "Preferred ColorDepth", "Video Codec" | Sort-Object Name | Get-Unique -AsString

    # Add the Table Header
    Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $Title -TableData $RDAFiltered -TableImage "<img src=../images/rdainfo.png alt=$($Title)>"

    # Build the Table Dataset
    Write-Screen -Message "Building $($Title) Data"
    [string]$ScreenResolution = "| **Screen Resolution** | "
    [string]$MovingImageCompression = "| **Moving Image Compression** | "
    [string]$VisualQuality = "| **Visual Quality** | "
    [string]$VideoCodecTextOptimization = "| **Video Codec Text Optimization** | "
    [string]$EDTInUse = "| **EDT In Use** | "
    [string]$VideoCodecUse = "| **Video Codec Use** | "
    [string]$VideoCodecColorspace = "| **Video Codec Colorspace** | "
    [string]$VideoCodecType = "| **Video Codec Type** | "
    [string]$MaxFPS = "| **Max FPS** | "
    [string]$HardwareEncodeEnabled = "| **Hardware Encode Enabled** | "
    [string]$PreferedColorDepth = "| **Prefered Color Depth** | "
    [string]$VideoCodec = "| **Video Codec** | "

    foreach ($Record in $RDAFiltered) {
        $ScreenResolution = $ScreenResolution + "$(Get-CleanData -Data ($Record."Screen Resolution")) | "
        $MovingImageCompression = $MovingImageCompression + "$(Get-CleanData -Data ($Record."Moving Image Compression")) | "
        $VisualQuality = $VisualQuality + "$(Get-CleanData -Data ($Record."Visual Quality")) | "
        $VideoCodecTextOptimization = $VideoCodecTextOptimization + "$(Get-CleanData -Data ($Record."Video Codec Text Optimization")) | "
        $EDTInUse = $EDTInUse + "$(Get-CleanData -Data ($Record."EDT In Use")) | "
        $VideoCodecUse = $VideoCodecUse + "$(Get-CleanData -Data ($Record."Video Codec Use")) | "
        $VideoCodecColorspace = $VideoCodecColorspace + "$(Get-CleanData -Data ($Record."Video Codec Colorspace")) | "
        $VideoCodecType = $VideoCodecType + "$(Get-CleanData -Data ($Record."Video Codec Type")) | "
        $MaxFPS = $MaxFPS + "$(Get-CleanData -Data ($Record."Max FPS")) | "
        $HardwareEncodeEnabled = $HardwareEncodeEnabled + "$(Get-CleanData -Data ($Record."Hardware Encode Enabled")) | "
        $PreferedColorDepth = $PreferedColorDepth + "$(Get-CleanData -Data ($Record."Preferred ColorDepth")) | "
        $VideoCodec = $VideoCodec + "$(Get-CleanData -Data ($Record."Video Codec")) | "
    }

    # Add the Table
    Write-Screen -Message "Adding $($Title) Data"
    Add-Content $mdFullFile $ScreenResolution
    Add-Content $mdFullFile $MaxFPS
    Add-Content $mdFullFile $PreferedColorDepth
    Add-Content $mdFullFile $VisualQuality
    Add-Content $mdFullFile $EDTInUse
    Add-Content $mdFullFile $MovingImageCompression
    Add-Content $mdFullFile $HardwareEncodeEnabled
    Add-Content $mdFullFile $VideoCodec
    Add-Content $mdFullFile $VideoCodecUse
    Add-Content $mdFullFile $VideoCodecType
    Add-Content $mdFullFile $VideoCodecTextOptimization
    Add-Content $mdFullFile $VideoCodecColorspace

    Add-Content $mdFullFile " "

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq '.png') -and ($_.Name -like "rdanalyzer*") } | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Remote Desktop Analytics" -mdFullFile $mdFullFile

}
#endregion Remote Display Analytics Results

#region Individual Runs Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Individual Runs Results
# -----------------------------------------------------------------------------------------------------------------------
if ($IndividualRuns) {

    $Title = "Individual Runs"
    Add-Content $mdFullFile "### $($Title)"

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq '.png') -and ($_.Name -like "individual_runs*") } | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Individual Runs" -mdFullFile $mdFullFile
}


#endregion Individual Runs Results

#region Applications Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Applications Results
# -----------------------------------------------------------------------------------------------------------------------
if ($Applications) {

    $Title = "Applications"
    Add-Content $mdFullFile " "
    Add-Content $mdFullFile "### $($Title)"

    Add-Content $mdFullFile " "
        
    $TableTitle = "Login Phase Performance Comparison"
    Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $TableTitle -TableData ($LoginApplicationsResults | select-object -Property Name | Get-Unique -AsString | Sort-Object -Property Name) -TableImage "<img src=../images/appsperf.png alt=$($Title)>"

    $LoginApplicationsList = $LoginApplicationsResults | select-object -Property AppName, MeasurementId -Unique | Sort-Object -Property AppName, MeasurementId

    foreach ($Record in $LoginApplicationsList) {
        $AppName = $record.appname
        $MeasurementId = $record.measurementid
        $App = (Get-CleanData -Data $record.appname)
        if ($App.StartsWith("(")) {
            $Application = $App.SubString(5, ($App.Length) - 5)
        }
        else {
            $Application = $App
        }
        $Act = (Get-CleanData -Data $record.measurementid)
        $TextInfo = (Get-Culture).TextInfo
        $Action = $TextInfo.ToTitleCase($Act)
        $RowHeader = "$($Application) - $($Action)"
        $Data = "| $($RowHeader) | "
        $i = 1
        foreach ($Line in $LoginApplicationsResults | Sort-Object -Property Name) {
            if ($Line.AppName -eq $AppName) {
                if ($Line.MeasurementId -eq $MeasurementId) {
                    $Seconds = [math]::Round(($Line.value / 1000), 2)
                    $FormattedSeconds = $Seconds.ToString("0.00")
                    if (!($i -eq 1)) {
                        if ($Seconds -gt $BaseNumber) {
                            $Percentage = (($Seconds / $BaseNumber) * 100) - 100
                            $FormattedPercentage = $Percentage.ToString("0.00")
                            $PerfTag = "<span style=""color:#E82727"">$($FormattedPercentage) % Slower</span>"
                        }
                        else {
                            if ($Seconds -eq $BaseNumber) {
                                $PerfTag = "Equal"
                            }
                            else {
                                $Percentage = 100 - (($Seconds / $BaseNumber) * 100)
                                $FormattedPercentage = $Percentage.ToString("0.00")
                                $PerfTag = "<span style=""color:#30DC41"">$($FormattedPercentage) % Faster</span>"
                            }
                        }
                        $Data = $Data + "$($FormattedSeconds) seconds - $($PerfTag) | "
                    }
                    else {
                        $BaseNumber = $Seconds
                        $Data = $Data + "$($FormattedSeconds) seconds | "
                    }
                    $i++
                }
            }
        }
        Add-Content $mdFullFile $Data
    }

    Add-Content $mdFullFile " "

    $TableTitle = "Steady State Performance Comparison"
    Add-TableHeaders -mdFullFile $mdFullFile -TableTitle $TableTitle -TableData ($SSApplicationsResults | select-object -Property Name | Get-Unique -AsString | Sort-Object -Property Name) -TableImage "<img src=../images/appsperf.png alt=$($Title)>"

    $SSApplicationsList = $SSApplicationsResults | select-object -Property AppName, MeasurementId -Unique | Sort-Object -Property AppName, MeasurementId

    foreach ($Record in $SSApplicationsList) {
        $AppName = $record.appname
        $MeasurementId = $record.measurementid
        $App = (Get-CleanData -Data $record.appname)
        if ($App.StartsWith("(")) {
            $Application = $App.SubString(5, ($App.Length) - 5)
        }
        else {
            $Application = $App
        }
        $Act = (Get-CleanData -Data $record.measurementid)
        $TextInfo = (Get-Culture).TextInfo
        $Action = $TextInfo.ToTitleCase($Act)
        $RowHeader = "$($Application) - $($Action)"
        $Data = "| $($RowHeader) | "
        $i = 1
        foreach ($Line in $SSApplicationsResults | Sort-Object -Property Name) {
            if ($Line.AppName -eq $AppName) {
                if ($Line.MeasurementId -eq $MeasurementId) {
                    $Seconds = [math]::Round(($Line.value / 1000), 2)
                    $FormattedSeconds = $Seconds.ToString("0.00")
                    if (!($i -eq 1)) {
                        if ($Seconds -gt $BaseNumber) {
                            $Percentage = (($Seconds / $BaseNumber) * 100) - 100
                            $FormattedPercentage = $Percentage.ToString("0.00")
                            $PerfTag = "<span style=""color:#E82727"">$($FormattedPercentage) % Slower</span>"
                        }
                        else {
                            if ($Seconds -eq $BaseNumber) {
                                $PerfTag = "Equal"
                            }
                            else {
                                $Percentage = 100 - (($Seconds / $BaseNumber) * 100)
                                $FormattedPercentage = $Percentage.ToString("0.00")
                                $PerfTag = "<span style=""color:#30DC41"">$($FormattedPercentage) % Faster</span>"
                            }
                        }
                        $Data = $Data + "$($FormattedSeconds) seconds - $($PerfTag) | "
                    }
                    else {
                        $BaseNumber = $Seconds
                        $Data = $Data + "$($FormattedSeconds) seconds | "
                    }
                    $i++
                }
            }
        }
        Add-Content $mdFullFile $Data
    }

    Add-Content $mdFullFile " "

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq '.png') -and ($_.Name -like "applications*") } | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Applications" -mdFullFile $mdFullFile

}

#endregion Applications Results

#region VSI EUX Measurements Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - VSI EUX Measurements Results
# -----------------------------------------------------------------------------------------------------------------------
if ($VsiEuxMeasurements) {

    $Title = "VSI EUX Measurements"
    Add-Content $mdFullFile "### $($Title)"

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq '.png') -and ($_.Name -like "vsi_eux*") } | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "VSI EUX Measurements" -mdFullFile $mdFullFile
}
#endregion VSI EUX Measurements Results

#region Nutanix Files Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Nutanix Files Results
# -----------------------------------------------------------------------------------------------------------------------
if ($NutanixFiles) {

    $Title = "Nutanix Files"
    Add-Content $mdFullFile "### $($Title)"

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq '.png') -and ($_.Name -like "nutanix_files*") } | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Nutanix Files" -mdFullFile $mdFullFile
}
#endregion Nutanix Files Results

#region Citrix NetScaler Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Citrix NetScaler Results
# -----------------------------------------------------------------------------------------------------------------------
if ($CitrixNetScaler) {

    $Title = "Citrix NetScaler"
    Add-Content $mdFullFile "### $($Title)"

    $Source = Get-Childitem -Path $imagePath -recurse |  Where-Object { ($_.extension -eq '.png') -and ($_.Name -like "citrix_netscaler*") } | Sort-Object CreationTime
    Add-Graphs -Source $Source -Title "Citrix NetScaler" -mdFullFile $mdFullFile
}
#endregion Citrix NetScaler Results

#region Conclusion
# -----------------------------------------------------------------------------------------------------------------------
# Section - Conclusion
# -----------------------------------------------------------------------------------------------------------------------
Write-Screen -Message "Adding Conclusion"
Add-Title -mdFullFile $mdFullFile -Title "Conclusion"
Add-Content $mdFullFile "$($BoilerPlateConclusion)"
#endregion Conclusion

#region Appendix
# -----------------------------------------------------------------------------------------------------------------------
# Section - Appendix
# -----------------------------------------------------------------------------------------------------------------------
Write-Screen -Message "Adding Appendix"
Add-Title -mdFullFile $mdFullFile -Title "Appendix"
Add-Content $mdFullFile "$($BoilerPlateAppendix)"
#endregion Appendix

#endregion Create Report

#endregion Execute