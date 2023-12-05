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
- DB Additions
    05.12.2023: Initial Script Creation
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

    [Parameter(Mandatory = $true)]
    [string]$RAReference, # Title for the Report

    [Parameter(Mandatory = $false)]
    [string]$mdFile = "README.MD", # Markdown output file name

    [Parameter(Mandatory = $false)]
    [string]$ImageSuffix, #shortname for image ouput - helpful for multi run documentation. moves an image from image_name.png to image_name_suffix.png

    [Parameter(Mandatory = $false)]
    [string]$influxDbUrl = "http://10.57.64.25:8086/api/v2/query?orgID=a9e06d965633a9ed",  

    [Parameter(Mandatory = $false)]
    [string]$InfluxToken = "8PsWoQV6QTmg98hk-dmVW61RbFs5SPOcVJII56Kp6Qi2E0Svyz6kHOAA8euFO6mzH_cgPODezlRe6qXlLLWgng==",

    [Parameter(Mandatory = $false)]
    [string]$iconsSource = "http://10.57.64.101:3000/public/img/nutanix/",

    [Parameter(Mandatory = $false)]
    [ValidateSet("BootInfo","LoginEnterpriseResults","ClusterResources","LoginTimes","RDA","Applications","NutanixFiles","None")]
    [Array]$ExcludedComponentList = ("None"), # Items to exclude

    [Parameter(Mandatory = $false)]
    [string]$ImageReferenceCSV

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
        $imagePath,
        [switch]$SteadyState
    )

    foreach ($Panel in $Panels) {

        # if steady state then change start time for panel to 1672537916800
        # Build Uri to download image
        $UpdatedUri = $SourceUri.Replace('/d/', '/render/d-solo/')
        if($SteadyState) {
            $Start = "1672537910000"
        } else {
            $Start = "1672534800000"
        }
        $Uri = $UpdatedUri + "&from=$($Start)&to=$($EndTime)&panelId=$($Panel)&width=1600&height=800&tz=Atlantic%2FCape_Verde"

        # Check if the PanelId exists in the imported CSV data
        $matchedEntry = $ImageReferenceList | Where-Object { $_.PanelId -eq $Panel }
        
        #If a match is found, set the ImageName
        if ($matchedEntry) {
            $ImageName = $matchedEntry.ImageName

            if (!$ImageSuffix) {
                if(!$SteadyState){
                    $OutFile = Join-Path -Path $imagePath -ChildPath $ImageName
                } else {
                    $ImageName = $ImageName.Replace(".png", "_ss.png")
                    $OutFile = Join-Path -Path $imagePath -ChildPath $ImageName
                }
            }
            else {
                $ImageName = $ImageName -Replace ".png",""
                $ImageName = $ImageName + "_" + $ImageSuffix + ".png"
                $OutFile = Join-Path -Path $imagePath -ChildPath $ImageName
            }
        }
        else {
            Write-Screen "PanelId $PanelId not found in the CSV"
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

function Add-Title {
    param(
        $Title,
        $mdFullFile
    )

    Add-Content $mdFullFile ""
    Add-Content $mdFullFile "## <span style=""color:#7855FA"">$($Title)</span>"
    Add-Content $mdFullFile ""
} # Add Title Text

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

function Create-MDFile {
    param(
        $mdPath,
        $mdFile
    )

    $mdFullFile = Join-Path -Path $mdPath -ChildPath "$($mdFile).md"

    if (!(Test-Path -Path $mdFullFile)) {
        Write-Screen -Message "Creating Markdown File: $($mdFile)"
        try {
            $mdOutput = New-Item -Path $mdPath -Name "$($mdFile).md" -Force -ItemType File -ErrorAction Stop
        } catch {
            Write-Warning "Failed to create markdown file"
            Write-Warning $_
            Exit 1
        }
    } else {
        ## Create a new one with a date stamp
        Write-Screen -Message "Markdown File: $($mdFile) Already exists, creating a new file with a date stamp"
        try {
            $dateTime = Get-Date
            $formattedDateTime = $dateTime.ToString("yyyy-MM-dd_HH-mm-ss")
            $NewMDFile = ($mdFile + "_" + $formattedDateTime + ".md")
            #$NewMDFile = $NewMDFile -replace "README.MD","README"
            $mdOutput = New-Item -path $mdPath -Name "$NewMDFile" -ErrorAction Stop
            $mdFullFile = $mdPath + "\" + $NewMDFile
            Write-Screen -Message "Markdown file is $($mdFullFile)"
        } catch {
            Write-Warning "Failed to create markdown file"
            Write-Warning $_
            Exit 1
        }
    }

    return $mdOutput
} # Create a Markdown Output File

#endregion Functions

#region Variables
# ============================================================================
# Variables
# ============================================================================
# -----------------------------------------------------------------------------------------------------------------------
# Section - Define Script Variables
# -----------------------------------------------------------------------------------------------------------------------
# User Input Script Variables
$maxLength = 65536
[System.Console]::SetIn([System.IO.StreamReader]::new([System.Console]::OpenStandardInput($maxLength), [System.Console]::InputEncoding, $false, $maxLength))
$icons = @('Nutanix-Logo','bootinfo','hardware','infrastructure','broker','targetvm','loginenterprise','testicon','leresults','hostresources','clusterresources','logintimes','individualruns','appresults','euxmeasurements','filesicon','citrixnetscaler','base_image','sample-eux-score-graph','sample-login-enterprise-graph','rdainfo','appsperf') 
$RAFiles = @('executive-summary', 'introduction', 'application-overview', 'virtual-apps-desktops-nutanix', 'solution-design', 'validation-benchmarking', 'validation-results', 'conclusion', 'appendix')    

#region Report Sections
# -----------------------------------------------------------------------------------------------------------------------
# Sections 
# -----------------------------------------------------------------------------------------------------------------------

if ( $ExcludedComponentList -contains "None" ) {$ExcludedComponentList -eq $null} # Include Everything

if ( $ExcludedComponentList -notcontains "BootInfo" ) { $BootInfo = $true } else { $BootInfo = $false }
if ( $ExcludedComponentList -notcontains "LoginEnterpriseResults" ) { $LoginEnterpriseResults = $true } else { $LoginEnterpriseResults = $false }
if ( $ExcludedComponentList -notcontains "ClusterResources" ) { $ClusterResources = $true } else { $ClusterResources = $false }
if ( $ExcludedComponentList -notcontains "LoginTimes" ) { $LoginTimes = $true } else { $LoginTimes = $false }
if ( $ExcludedComponentList -notcontains "RDA" ) { $RDA = $true } else { $RDA = $false }
if ( $ExcludedComponentList -notcontains "Applications" ) { $Applications = $true } else { $Applications = $false }
if ( $ExcludedComponentList -notcontains "NutanixFiles" ) { $NutanixFiles = $true } else { $NutanixFiles = $false }

#endregion Report Sections

#region Boilerplates
# -----------------------------------------------------------------------------------------------------------------------
# Section - Boiler Plates
# -----------------------------------------------------------------------------------------------------------------------

#region Boiler Plate Exec Summary

$BoilerPlateExecSummary = @"
# Executive Summary

Nutanix designed its software to give customers running workloads in a hybrid cloud environment the same experience they expect from on-premises Nutanix clusters. Because Nutanix in a hybrid multicloud environment runs AOS and AHV with the same CLI, UI, and APIs, existing IT processes and third-party integrations continue to work regardless of where they run.

![Overview of the Nutanix Hybrid Multicloud Software](../images/overview-hybrid-multicloud-software.png "Overview of the Nutanix Hybrid Multicloud Software")

Nutanix AOS can withstand hardware failures and software glitches and ensures that application availability and performance are never compromised. Combining features like native rack awareness with public cloud partition placement groups, Nutanix operates freely in a dynamic hybrid multicloud environment.

Citrix Virtual Apps and Desktops on Nutanix is a powerful solution that offers unrivaled user experience, simple administration, and web-scale flexibility and economics. In this reference architecture, we make recommendations for designing, optimizing, and scaling Citrix Virtual Apps and Desktops deployments on Windows desktops on Nutanix AHV with Citrix Machine Creation Services (MCS) and Citrix Provisioning (PVS). We used Login Virtual Session Indexer (Login VSI) and an intelligent scripting framework on Nutanix to simulate real-world workloads in a Virtual Apps and Desktops environment.

In addition to desktop and application performance reliability, you get unlimited scalability, data locality, AHV clones, and a single datastore when you deploy Citrix Virtual Apps and Desktops on Nutanix. Nutanix takes the Citrix commitment to simplicity to another level with streamlined management, reduced rollout time, and lower operating expenses.
"@

#endregion Boiler Plate Exec Summary

#region BP Introduction

$BoilerPlateIntroduction = @"
# Introduction

## Audience

This reference architecture is part of the Nutanix Solutions Library. We wrote it for individuals responsible for designing, building, managing, and supporting Citrix Virtual Apps and Desktops on Nutanix infrastructures. Readers should be familiar with Nutanix AOS, Prism, AHV, and Citrix Virtual Apps and Desktops.

## Purpose

This document covers the following subject areas:

- Overview of the Nutanix solution.
- Overview of Citrix Virtual Apps and Desktops and its use cases.
- The benefits of running Citrix Virtual Apps and Desktops on Nutanix AHV.
- Design and configuration considerations for building a Citrix Virtual Apps and Desktops solution on Nutanix AHV.
- <UPDATE_HERE>

## Document Version History 

| Version Number | Published | Notes |
| :---: | --- | --- |
| <ADD> | <PREVIOUS> | <VERSIONS> |
| <UPDATE_HERE> | <UPDATE_HERE> | <UPDATE_HERE> |
"@

#region BP Application Overview

$BoilerPlateApplicationOverview = @"
# Application Overview

Citrix Virtual Apps and Desktops is a desktop virtualization solution that transforms desktops and applications into secure, on-demand services available to any user, anywhere, on any device. With Virtual Apps and Desktops, you can deliver individual Windows, web, and SaaS applications, and even full virtual desktops to PCs, Macs, tablets, smartphones, laptops, and thin clients with a high-definition user experience.

Citrix Virtual Apps and Desktops provides a complete virtual desktop and application delivery system by integrating several distributed components with advanced configuration tools that simplify the creation and real-time management of the virtual desktop infrastructure.

The following components make up the core of Virtual Apps and Desktops. For more detailed information about these components and guidance for running them on Nutanix, see the [Citrix Virtual Apps and Desktops on Nutanix best practice guide](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2079-Citrix-Virtual-Apps-and-Desktops:BP-2079-Citrix-Virtual-Apps-and-Desktops).

Delivery Controller
: The Delivery Controller authenticates users, manages the assembly of users' virtual desktop environments, and brokers connections between users and their virtual desktops. It's installed on servers in the datacenter and controls the state of the desktops, starting and stopping them based on demand and administrative configuration. In some editions, the Citrix license needed to run Virtual Apps and Desktops also includes profile management to manage user personalization settings in virtualized or physical Windows environments.

Studio
: Citrix Studio is the management console where you configure and manage your Citrix Virtual Apps and Desktops environment. It provides different wizard-based deployment or configuration scenarios to publish resources using desktops or applications.

Machine Creation Services (MCS)
: Machine Creation Services is the building mechanism of the Citrix Delivery Controller that automates and orchestrates desktop deployment using a single image. MCS communicates with the orchestration layer of your hypervisor, providing a robust and flexible method of image management.

Provisioning (PVS)
: Citrix Provisioning creates and provisions virtual desktops from a single desktop image on demand, optimizing storage utilization and providing a pristine virtual desktop to each user every time they log on. Desktop provisioning also simplifies desktop images, provides optimal flexibility, and offers fewer points of desktop management for both applications and desktops.

Virtual Delivery Agent (VDA)
: The Virtual Delivery Agent is installed on virtual desktops and enables direct FMA (FlexCast Management Architecture) connections between the virtual desktop and user devices.

Workspace app
: The Citrix Workspace app runs on user devices and enables direct HDX connections from user devices to applications and desktops using Citrix Virtual Apps and Desktops. The Citrix Workspace app allows access to published resources from your desktop, Start menu, web browser, or Citrix Workspace app user interface.

FlexCast
: Citrix Virtual Apps and Desktops with FlexCast delivers virtual desktops and applications tailored to meet the diverse performance, security, and flexibility requirements of every worker in your organization. Centralized, single-instance management helps you deploy, manage, and secure user desktops easily and efficiently.

## Provisioning Software Development Kit

The Citrix Provisioning Software Development Kit (SDK) is a recent addition to the Virtual Apps and Desktops platform for developers and technology partners. It applies the power and flexibility of Citrix-provisioned VMs to any hypervisor or cloud infrastructure service you choose.

The SDK enables you to create your own Provisioning plug-in, which you can add to the plug-ins installed by default with the Virtual Apps and Desktops products. Once you install your plug-in, the Delivery Controller services discover and load it automatically. It then appears as a new connection type in Citrix Studio, allowing you to easily connect, configure, and provision on your chosen infrastructure platform using two key features:

1. A set of .NET programming interfaces used to call your Provisioning plug-in whenever it needs to act. Your plug-in takes the form of a .NET assembly (DLL) that implements these interfaces. A plug-in must implement several .NET interfaces, but each is designed to be small and easy to understand. Most interfaces have both a synchronous and an asynchronous variant, allowing you to choose the programming pattern that works best.
2. The Citrix Common Capability Framework, which lets the rest of the product understand the specific custom features of your infrastructure and how you want those features displayed in Citrix Studio. The framework uses a high-level, XML-based description language. Your plug-in uses this language to produce specifications that allow Citrix Studio to intelligently adapt its task flows and wizard pages.

The plug-in you make with the Citrix Provisioning SDK allows you to create the connection between Studio and AHV and gives you access to all the APIs offered through AHV. However, before you can use it, you need to install the Nutanix AHV plug-in for Citrix.

### Nutanix AHV Plug-In for Citrix

We designed the Nutanix AHV plug-in for Citrix (also called the MCS plug-in SDK) to create and manage Citrix-provisioned VMs in an AHV infrastructure environment. We developed the plug-in based on the Citrix-defined plug-in framework.

Install the Nutanix AHV plug-in for Citrix (MCS plug-in SDK) on all Delivery Controllers in the site for single-zone sites. For multizone sites, you must install the AHV plug-in for Citrix on all the primary-zone and satellite-zone Delivery Controllers where you plan to deploy Nutanix. This integration results in the architecture shown in the following figure.

![MCS on AHV Architecture](../images/mcs-on-ahv-architecture.png "MCS on AHV Architecture")

When you load the Nutanix AHV plug-in on an existing Virtual Apps and Desktops installation (versions 7.9 and later), you receive the additional services to deploy and manage your desktops from the Delivery Controller on an AHV cluster, and you have the full native integration that Nutanix supports for Microsoft System Center Virtual Machine Manager (SCVMM) and VMware vCenter.

For detailed information on how to create the connection between Studio and your AHV cluster using the Nutanix AHV plug-in for Citrix, see the Nutanix AHV Plug-In for Citrix: Studio-to-AHV Connection section in the appendix.

Each VM you create from the base has two disks assigned to it: an identity disk and a difference disk. Each VM has a disk chain to the base VM snapshot you used to create the deployed VMs.

![MCS Disk Layout](../images/mcs-disk-layout.png "MCS Disk Layout")

- Base VM: A single base disk residing on a shared datastore that's mounted on the hosts in the cluster and configured with the Studio host connection.
- Identity disk (or ID disk): A very small disk (16 MB maximum) that contains identity information. This information provides a unique name for the VM and allows it to join Active Directory.
- Difference disk (write cache): This disk separates the writes from the base disk, but the system still acts as if the write has been committed to the base disk.

The identity disk and the difference disk together make the provisioned VM unique.

### Nutanix AHV Plug-In for Citrix Provisioning 

You must have the Nutanix AHV plug-in for Citrix configured before you can use the Nutanix AHV plug-in for Citrix Provisioning that we developed using the Citrix Provisioning SDK. This configuration allows the Citrix Virtual Apps and Desktops Setup wizard to create and manage Provisioning target devices on AHV and enables the architecture shown in the following figure.

![Provisioning on AHV Architecture](../images/provisioning-on-ahv-architecture.png "Provisioning on AHV Architecture")

Loading the Nutanix AHV plug-in for Citrix Provisioning on an existing Provisioning installation (versions 7.15 and later):

- Enables you to use Provisioning to deploy and manage your desktops.
- Integrates your AHV cluster with Delivery Controllers.
- Uses the Citrix Virtual Apps and Desktops Setup wizard to deploy device collections in Provisioning and machine catalogs in Citrix Virtual Apps and Desktops.

This plug-in requires the AHV plug-in for Citrix to allow Delivery Controllers to manage workloads running on Nutanix AHV. Install the AHV plug-in for Citrix Provisioning in the farm for single-site farms or in the same site for multisite farms. This setup has the full native integration that Nutanix supports for SCVMM and vCenter.

For more details on how to create a machine catalog with Provisioning, see the Nutanix AHV Plug-In for Citrix Provisioning: Machine Catalog Creation section in the appendix.

Each VM you create has one disk assigned to it except the Provisioning target device VM, which has a streamed vDisk and a write cache together.

![Provisioning Disk Layout](../images/provisioning-disk-layout.png "Provisioning Disk Layout")

- Base VM: A single base disk residing on a shared datastore that's mounted on the hosts in the cluster and configured with the Studio host connection.
- Streamed vDisk: A thin-provisioned virtual disk streamed from Citrix Provisioning that contains the OS and applications.
- Write cache: This disk separates the writes from the base disk, while the system still acts as if the write has been committed to the base disk.
"@
#endregion BP Application Overview

#region BP CVAD on Nutanix

$BoilerPlateCVADonNutanix = @"
# Virtual Apps and Desktops on Nutanix

The Nutanix modular web-scale architecture lets you start small and expand to meet increasing demand—a node, a block, or multiple blocks at a time—with no impact on performance. This design removes the hurdle of a large initial infrastructure purchase, decreasing the time to value for your Virtual Apps and Desktops implementation. Running Citrix Virtual Apps and Desktops on Nutanix enables you to run multiple workloads, all on the same scalable converged infrastructure, while achieving these benefits:

Modular incremental scale
: With the Nutanix solution you can start small and scale up. A single Nutanix block provides dozens of terabytes of storage and hundreds to thousands of virtual desktops in a compact footprint. Given the modularity of the solution, you can granularly scale by node, by block, or with multiple blocks, accurately matching supply with demand and minimizing the up-front capex.


High performance
: By using system memory caching for read I/O and flash storage for read and write I/O, you can deliver high-performance throughput in a compact form factor.

Change management
: Maintain environmental control and separation between development, test, staging, and production environments. Snapshots and fast clones can help share production data with nonproduction jobs without requiring full copies and unnecessary data duplication.

Business continuity and data protection
: User data and desktops are mission-critical and need enterprise-grade data management features, including backup and disaster recovery.

Data efficiency
: Nutanix storage offers both compression and deduplication to help reduce your storage footprint. The compression functionality is truly VM-centric. Unlike traditional solutions that perform compression mainly at the LUN level, the Nutanix solution provides all these capabilities at the VM and file levels, greatly increasing efficiency and simplicity. These capabilities ensure the highest possible compression and decompression performance, even below the block level.

Enterprise-grade cluster management
: Nutanix offers a simplified and intuitive approach to managing large clusters, including a converged GUI that serves as a central point for servers and storage, alert notifications, and the bonjour mechanism that automatically detects new nodes in the cluster.

High-density architecture
: Nutanix uses an advanced server architecture that, using the NX-3000 series as an example, can house eight Intel CPUs (up to 192 cores) and up to 8 TB of memory in a single 2RU appliance. Coupled with data archiving and compression, Nutanix can make the desktop hardware footprint five times smaller.

Time-sliced clusters
: Like public cloud EC2 environments, Nutanix can provide a truly converged cloud infrastructure, allowing you to run your server and desktop virtualization on a single cloud.

## Virtual Apps and Desktops on AHV

The following figure presents the main architectural components of Virtual Apps and Desktops on AHV and the communication path between services.

![Communication Path](../images/communication-path.png "Communication Path")

## AHV Pod Design

The next tables contain highlights from a high-level snapshot of Virtual Apps and Desktops on a Nutanix-hosted virtual desktop pod.

_Table: AHV Services Pod Detail_

| Item | Quantity |
| --- | :---: |
| Number of Delivery Controllers | 2 |
| Number of StoreFront servers | 2 |
| Number of Provisioning servers | 2 |

_Table: AHV Control Pod Detail_

| Item | Quantity |
| --- | :---: |
| Number of AHV hosts | Up to 16 |
| Number of Nutanix clusters | 1 |
| Number of datastores | 1 |
| Number of desktops | Up to 2,475 |

We recommend a maximum of 16 AHV host nodes per Nutanix AHV cluster. We validated Citrix Virtual Apps and Desktops with Windows desktop VDAs, using 3 vCPU and 4 GB of memory per VM and 165 VMs per node, with 2,475 Windows desktop VDAs per AHV cluster.

<note>
One node is calculated as a spare (n + 1).
</note>

If you change the vCPU count or memory, the number of Windows VDAs per node and per cluster change as well.

## Nutanix Compute and Storage

Nutanix provides an ideal combination of high-performance compute and localized storage to meet any demand. True to this capability, this reference architecture contains no reconfiguration or customization of the Nutanix product to optimize for this use case. The following figure shows a high-level example of the relationship between the Nutanix storage pool and containers.

![Nutanix Logical Storage Configuration](../images/nutanix-logical-storage-configuration.png "Nutanix Logical Storage Configuration")

The following table details the Nutanix storage pool and container configuration.

_Table: Nutanix Storage Configuration_

| Name | Role | Details |
| --- | --- | --- |
| SP01 | Main storage pool for all data | SSD + HDD |
| VDI | Container for all VMs | AHV datastore |
| Default-Container | Container for all data (not used here) | AHV datastore |
"@
#endregion BP CVAD on Nutanix

#region BP Solution Design

$BoilerPlateSolutionDesign = @"
# Solution Design

In the following section, we cover the design decisions and rationale for Virtual Apps and Desktops deployments on Nutanix.

_Table: Platform Design Decisions: General_

| Item | Detail | Rationale |
| --- | --- | --- |
| Software versions | Citrix Virtual Apps and Desktops 1912 CU4; Citrix Provisioning 1912 CU4; AOS 5.20.3 |  |
| Minimum size | 3 Nutanix AOS hosts running AHV | Minimum size requirement |
| Scale approach | Incremental modular scale | Allows growth from PoC (hundreds of desktops) to massive scale (thousands of desktops) |
| Scale unit  | Nodes, blocks, or pods | Granular scale to precisely meet capacity demands; scale in n node increments |

_Table: Platform Design Decisions: Nutanix AHV_

| Item | Detail | Rationale |
| --- | --- | --- |
| Cluster size | As many as 16 hosts (minimum of 3 hosts) | Isolated fault domains (best practice) |
| Datastores | 1 Nutanix datastore per pod (Virtual Apps and Desktops server VMs, VM clones, and so on) | Nutanix handles I/O distribution and localization; n-Controller model |
| Infrastructure services | Small deployments: Shared cluster; Large deployments: Dedicated cluster | Dedicated infrastructure cluster for larger deployments (best practice) |

_Table: Platform Design Decisions: Nutanix_
  
| Item | Detail | Rationale |
| --- | --- | --- |
| Cluster size | As many as 16 nodes | Isolated fault domains (best practice) |
| Storage pools | 1 storage pool per cluster | Standard practice; intelligent tiering handles data locality |
| Containers | 1 container for VMs | Standard practice |
| Features and enhancements | Increase CVM memory to 24 to 32+ GB. Turn on deduplication and compression for persistent desktops. Turn on compression only for nonpersistent desktops. (We set the CVM to 32 GB for the RA.) | Best practice |
  
_Table: Platform Design Decisions: Citrix Virtual Apps and Desktops_

| Item | Detail | Rationale |
| --- | --- | --- |
| Delivery Controllers | Minimum: 2 (n + 1); Scale: 1 per additional pod | High availability for Delivery Controllers |
| Users per controller | Up to 5,000 users | Virtual Apps and Desktops best practice |
| Load balancing | Built into Delivery Controllers | Ensures availability of Delivery Controllers; balances load between Delivery Controllers |
| Virtual hardware specs | vCPU: 4; Memory: 4+ GB (local host cache); Disk: 60 GB vDisk | Standard sizing practice |

_Table: Platform Design Decisions: Citrix Provisioning_

| Item | Detail | Rationale |
| --- | --- | --- |
| Provisioning servers | Minimum: 2 (n + 1); Scale: 2 per additional pod | High availability for Provisioning server |
| Load balancing | Built into Provisioning servers | Balances load between Provisioning servers |
| Virtual hardware specs | vCPU: 4; Memory: 12+ GB (number of vDisks); Disk: 60 GB vDisk | Standard sizing practice |
| vDisk store | Dedicated disk on Nutanix or Nutanix Files shared vDisk Store | Standard practice |
| Write cache | On local hard drive | Best practice if the storage can provide enough I/O |

_Table: Platform Design Decisions: Citrix StoreFront_

| Item | Detail | Rationale |
| --- | --- | --- |
| StoreFront servers | Minimum: 2 (n + 1) | High availability for StoreFront servers |
| Load balancing | Citrix NetScaler (including Citrix NetScaler VPX) | Ensures availability of StoreFront servers; balances load between StoreFront servers | 
| Virtual hardware specs | vCPU: 2+; Memory: 4+ GB; Disk: 60 GB vDisk | Standard sizing practice |
| NetScaler virtual appliances | Minimum: 2 | High availability for NetScaler (active-passive) |
| Users per NetScaler virtual appliance | See product data sheet (`https://www.citrix.com/products/citrix-adc/platforms.html`) | Varies per model |
| Load balancing | NetScaler high availability | Ensures availability of NetScaler virtual appliances; balances load between Application Delivery Controller servers and pods |  

_Table: Infrastructure Design Decisions: Active Directory_

| Item | Detail | Rationale |
| --- | --- | --- |
| Global catalog and DNS servers | Minimum: 2 (n + 1) per site | High availability for global catalog and DNS; Microsoft best practice |

_Table: Infrastructure Design Decisions: DHCP_

| Item | Detail | Rationale |
| --- | --- | --- |
| DHCP servers | Nutanix IPAM | High availability for Nutanix IPAM is built in |
| Load balancing | Built-in | Ensures availability of DHCP | 

_Table: Infrastructure Design Decisions: Nutanix Files_

| Item | Detail | Rationale |
| --- | --- | --- |
| Nutanix Files | Minimum: 3 per site | High availability for Nutanix Files servers |
| Load balancing | Built-in | Ensures availability of Nutanix Files; balances load between Nutanix Files servers |

_Table: Infrastructure Design Decisions: SQL Server_

| Item | Detail | Rationale |
| --- | --- | --- |
| SQL Servers | Minimum: 2 (n + 1) per site; Scale: 2 per additional pod | High availability for SQL Servers |
| Data protection | SQL Server clustering, mirroring, or Always On availability groups (including basic availability groups) | Ensures availability of SQL Server instances |

## Desktop Sizing

Nutanix can host Citrix Virtual Apps and Desktops workloads. Densities can vary based on specific images and workloads. For testing, we used [Login VSI](http://www.loginvsi.com), the industry-standard load testing solution for centralized virtualized desktop environments. We based the virtual desktops on knowledge worker workload densities.

The following table contains examples of typical scenarios for desktop deployment and use.

_Table: Desktop Scenario Definition_

| Scenario | Definition |
| --- | --- |
| Task workers | Task workers and administrative workers perform repetitive tasks in a small set of applications, usually at a stationary computer. The applications used by task workers generally require less CPU and memory than those used by knowledge workers. Task workers who work specific shifts might all log on to their virtual desktops at the same time. Task workers include call center analysts, retail employees, and warehouse workers. |
| Office workers | Office workers are similar to task workers, but they use more applications and generate a slightly heavier workload. |
| Knowledge workers | Knowledge workers' daily tasks include accessing the internet, using email, and creating complex documents, presentations, and spreadsheets. Knowledge workers include accountants, sales managers, and marketing research analysts. |
| Power workers | Power workers include application developers and people who use graphics-intensive applications. |

The following table contains initial recommendations for sizing a Windows 10 or 11 desktop. We assume that 1 vCPU is unrealistic for most workloads involving Windows 10 or 11—only assume 1 vCPU per desktop for desktops delivering a single application.

<note>
Modify these general sizing recommendations after a current state analysis.
</note>

_Table: Desktop Scenario Sizing_

| Scenario | vCPU | Memory | Disks |
| --- | :---: | :---: | :---: |
| Task workers | 1 to 2 | 1.5 GB | 40 GB (OS) |
| Office workers | 2 | 2 to 3 GB | 40 GB (OS) |
| Knowledge workers | 2 to 4 | 3 to 6 GB | 80 GB (OS) |
| Power workers | 4 | 6+ GB | 100+ GB (OS) |

## Desktop Optimizations

We generated our design with the following high-level desktop optimization guidelines in mind:

- Size desktops appropriately for each use case.
- Use a mix of applications installed in template images, application layering, and virtualization.
- Disable unnecessary OS services and applications.
- Redirect home directories or use a profile management tool for user profiles and documents.

For more details on desktop optimizations, refer to the [Citrix Windows 10 Optimization Guide](https://support.citrix.com/article/CTX216252) and the [Citrix Optimizer](https://support.citrix.com/article/CTX224676).
"@

#endregion BP Solution Design

#region BP Validation and Benchmarking

$BoilerPlateValidationandBenchmarking = @"
# Validation and Benchmarking

We completed the solution design and testing described in this document with Citrix Virtual Apps and Desktops 7 1912 LTSR CU4 deployed on Nutanix. We used Login VSI 4.1 to validate the performance of Citrix Virtual Apps and Desktops running on Nutanix. This section describes the Login VSI benchmarking method and the infrastructure we used for the tests.

## Login VSI Benchmark

[Login VSI](http://www.loginvsi.com) provides performance insights for virtualized desktop and server environments. Enterprise IT departments use Login VSI products in all phases of VDI operations management—from planning to deployment to change management—for more predictable performance, higher availability, and a more consistent user experience. You can find more information about Login VSI test workloads in the blog post [Login VSI Default Workloads Information](https://support.loginvsi.com/hc/en-us/articles/360001046100-Login-VSI-Workloads-Default-workloads-information).

The following table includes all four workloads available on Login VSI 4.1.

_Table: Login VSI 4.1 Workloads_

| Task Worker | Office Worker | Knowledge Worker | Power Worker |
| --- | --- | --- | --- |
| Light | Medium | Medium | Heavy |
| 1 vCPU | 1 vCPU | 2 vCPU | 2 to 4 vCPU |
| 2 to 3 apps | 4 to 6 apps | 4 to 7 apps | 5 to 9 apps |
| No video | 240p video | 360p video | 720p video |

### Login VSI Workflows

The [Login VSI Default Workloads Information page](https://support.loginvsi.com/hc/en-us/articles/360001046100-Login-VSI-Workloads-Default-workloads-information) captures the Login VSI workflow base layout in detail.

_Table: Login VSI 4.1 Workflows_

| Configurable | Task Worker | Office Worker | Knowledge Worker | Power Worker |
| --- | :---: | :---: | :---: | :---: |
| Apps open | 2 to 7 | 5 to 8 | 5 to 9 | 8 to 12 |
| CPU usage | 70% | 82% | 100% | 119% |
| Disk reads | 79% | 90% | 100% | 133% |
| Disk writes | 77% | 101% | 100% | 123% |
| IOPS | 6 | 8.1 | 8.5 | 10.8 |
| Memory | 1 GB | 1.5 GB | 1.5 GB | 2 GB |
| vCPU | 1 | 1 | 2 | 2+ |

### Interpreting Login VSI Results

Login VSI values represent the time it takes for an application or task to complete (launching Outlook, for example) and aren't in addition to traditional desktop response times. These figures don't refer to the round-trip time (RTT) for network I/O; rather, they refer to the total time to perform an action on the desktop. During the test, we turned on all VMs and started the workload on a new desktop every 30 seconds until all sessions and workloads were active. The workload used a launch window of 2,880 seconds for all tests.

We quantified the evaluation using the [following metrics](https://support.loginvsi.com/hc/en-us/articles/360001069359-Login-VSI-Using-the-Analyzer-and-analyzing-results):

- Minimum Response: The minimum application response time.
- Average Response: The average application response time.
- Maximum Response: The maximum application response time.
- VSI Baseline: The average application response time of the first 15 measurements.
- VSI Index Average: The average response time, dropping the highest and lowest two percent.
- VSImax: If reached, the maximum value of sessions launched before the VSI index average reaches 1,000 ms above the VSI baseline.
- CPU usage during steady state: The state when all the sessions are signed in and continue to use the applications. This state simulates the state of the users during the entire day, rather than just during the logon period.

We recommend that you keep track of these response times as well as the average CPU usage of the hosts used during the test.

_Table: Login VSI Metric Values_

| Metric | Value |
| --- | :---: |
| Very good VSI Baseline | \<800 ms |
| Good VSI Baseline | 800 to 1,200 ms |
| Average VSI Baseline | \>1,200 ms |
| Ideal CPU usage during steady state | \<85% |

### Login VSI Graphs

Login VSI graphs show the values obtained during the launch for each desktop session. The following figure shows an example graph of the test data. The y-axis is the response time in milliseconds, and the x-axis is the number of active sessions.

![Sample Login VSI Graph](../images/sample-login-vsi-graph.png "Sample Login VSI Graph")

## Infrastructure Configuration 

In this section you can read about the hardware we used for this reference architecture.

### Management Infrastructure Cluster

We used one Nutanix NX-3060-G7 cluster with four nodes to host all infrastructure and Citrix services and the Login VSI components. Active Directory services, DNS, DHCP, and the SQL Server also ran inside this cluster, which we designated the management infrastructure cluster. With four nodes we had enough resources available to host these servers. The following table shows the Citrix configuration.

_Table: Citrix Configuration_

| VM | Quantity | vCPU | Memory | Disks |
| --- | :---: | :---: | :---: | :---: |
| Delivery Controllers | 2 | 4 | 8 GB | 1 times 60 GB (OS) |
| StoreFront | 1 | 2 | 4 GB | 1 times 60 GB (OS) |
| SQL | 1 | 4 | 8 GB | 3 times 60 GB (OS, DATA, logs) |

### Login VSI Launcher Cluster

To initiate the sessions to the virtual desktops, Login VSI uses launcher VMs. Depending on the display protocol used, one launcher VM can host up to 25 sessions. For this reference architecture, we used one Nutanix NX-3060-G7 cluster with eight nodes to host 90 launcher VMs. Each launcher VM had 4 vCPU and 4 GB of memory.

### Virtual Desktop Cluster

Eight Nutanix NX-3155G-G8 nodes formed the cluster to host all virtual desktops. The next tables contain the specifications of this cluster.

_Table: Virtual Desktop Cluster Specifications_

| Parameter | Setting |
| --- | --- |
| Block type | Nutanix NX-3155G-G8 |
| Number of blocks | 8 |
| Number of nodes | 8 |
| CPU type | Intel Xeon Gold 6354 |
| Number of CPUs per node | 2 |
| Number of cores per CPU | 18 |
| Memory per node | 1,024 GB |
| Disk config per node | 6 times 1.9 TB SSD |
| Network | 2 times 25 GbE |

_Table: Nutanix Software Specifications_

| Parameter | Setting | 
| --- | --- |
| Nutanix AHV version | 20201105.2244 |
| Nutanix AOS version | 5.20.3 |
| CVM vCPU | 12 |
| CVM memory | 32 GB |
| Redundancy factor | 2 |
| Number of datastores for session-host VMs | 1 |
| Datastore specifications | Compression: On; Compression delay: 0; Deduplication: Off |

_Table: Citrix Software Specifications_ 

| Parameter | Setting |
| --- | --- |
| Citrix Virtual Apps and Desktops version | 7.1912 CU4 |

_Table: Windows 10 Template Image Configuration_ 

| Parameter | Setting |
| --- | --- |
| Operating system | Windows 10 21H2 (x64) |
| Windows updates | 1/11/22 |
| CPU | 2 vCPU |
| Memory | 4 GB |
| Video RAM | 64 MB |
| 3D graphics | Off |
| NICs | 1 |
| Virtual network adapter | Nutanix VirtIO Adapter |
| Virtual SCSI controller 0 | Nutanix VirtIO SCSI passthrough |
| Virtual disk VMDK1 | 64 GB |
| Virtual CD/DVD drive 1 | Client |
| Applications | Adobe Acrobat DC, Adobe Flash Player 11, Doro PDF 1.82, FreeMind, Internet Explorer 11, Microsoft Edge Browser, Microsoft Office 2019 (x64) |
| Citrix Virtual Desktop Agent | 7.1912 CU4 |
| Citrix Provisioning Services Target Device | 7.1912 CU4 |
| Optimizations | Citrix Optimizer |
"@
#endregion BP Validation and Benchmarking

#region BP Conslution
$BoilerPlateConclusion = @"
# Conclusion

The Citrix Virtual Apps and Desktops and Nutanix solution provides a single high-density platform for virtual desktop delivery. This modular, linear scaling approach lets you grow Virtual Apps and Desktops deployments easily. Localized and distributed caching and integrated disaster recovery enable quick deployments and simplify day-to-day operations. Robust self-healing and multistorage controllers deliver high availability in the face of failure or rolling upgrades.
<UPDATE_HERE>
ADD YOUR CONCLUSION DETAILS
"@
#endregion BP Conclusion

#region BP Appendix
$BoilerPlateAppendix = @"
# Appendix

## Hardware Configuration

Storage and compute:

- <UPDATE_HERE>

Network:

- <UPDATE_HERE>

## Software Configuration

Nutanix

- <UPDATE_HERE>

Citrix Virtual Apps and Desktops

- <UPDATE_HERE>

Windows 

- <UPDATE_HERE>

Infrastructure

- <UPDATE_HERE>

## References

1.  [Login Enterprise](https://www.loginvsi.com/)
2.  [Login Enterprise EUX Score](https://support.loginvsi.com/hc/en-us/articles/4408717958162-Login-Enterprise-EUX-Score-#h_01GS8W30049HVB851TX60TDKS3)
3.  [Login Enterprise Workload Templates](https://support.loginvsi.com/hc/en-us/sections/360001765419-Workload-Templates)
4.  <UPDATE_HERE> - ADD ADDITIONAL REFERENCES
"@
#endregion BP Appendix

#endregion Boilerplates

#endregion Variables

#Region Execute
# ============================================================================
# Execute
# ============================================================================

# -----------------------------------------------------------------------------------------------------------------------
# Section - Display Options and Start Report
# -----------------------------------------------------------------------------------------------------------------------

#region Check Image CSV Import
if (!($ImageReferenceCSV)) {
    $ImageReference = (Split-Path $MyInvocation.MyCommand.Path) + "\" + "ImageReferenceRA.csv"
} else {
    $ImageReference = $ImageReferenceCSV
}
Write-Screen "Image CSV reference is set to: $ImageReference"

try {
    $ImageReferenceList = Import-CSV -Path $ImageReference
} catch {
    Write-Screen "Failed to Import CSV: $($ImageReference). Please check source file"
    #Exit 1
}

#endregion Check Image CSV Import

#region Checkoutput Directory
# Convert the Report Title to PascalCase and Create Report Output Directory
Write-Screen -Message "Checking Output Directory"
$Directory = (Get-Culture).TextInfo.ToTitleCase($ReportTitle) -Replace " "
$Directory = "Reports\" + $Directory
$ImagePath = $Directory + "\images"
$md = $Directory + "\md"

if (!(Test-Path -Path $Directory)) {
    Write-Screen -Message "Directory: $($Directory) Does Not Exist, Creating"
    try {
        $ReportsDir = New-Item -Path $Directory -ItemType Directory -ErrorAction Stop
        try {
            $ImagePathDir = New-Item -Path $ImagePath -ItemType Directory -ErrorAction Stop
        } catch {
            Write-Warning "Failed to create Directory"
            Write-Warning $_
            #Exit 1
        }
    } catch {
        Write-Warning "Failed to create Output Directory"
        Write-Warning $_
        #Exit 1
    }
}

#endregion Checkoutput Directory

#region Create Report File
# Create the File path and initial files
$MDFileDetails = New-Object -TypeName psobject 
$i = 1
foreach($File in $RAFiles){
    $DocNum = '{0:d2}' -f $i
    $mdFile = "$($RAReference)-$($DocNum)-$($File)"
    $FileCreated = Create-MDFile -mdPath $md -mdFile $mdFile
    $MDFileDetails | Add-Member -MemberType NoteProperty -Name "$($i)" -Value $FileCreated
    $i++
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
Write-Host "Cluster Resources:             $($ClusterResources)"
Write-Host "Login Times:                   $($LoginTimes)"
Write-Host "Remote Desktop Analysis:       $($RDA)"
Write-Host "Applications:                  $($Applications)"
Write-Host "Nutanix Files:                 $($NutanixFiles)"
Write-Host "Sections Excluded by Param:    $($ExcludedComponentList)"
Write-Host "Image Reference CSV is:        $($ImageReference)"  
Write-Host "
--------------------------------------------------------------------------------------------------------"
#endregion SnazzyHeader

#region Confirmation
# Ask for confirmation to start the build - if no the quit
Do { $confirmationStart = Read-Host "Ready to run the report? [y/n]" } Until (($confirmationStart -eq "y") -or ($confirmationStart -eq "n"))

if ($confirmationStart -eq 'n') { 
    Write-Host (Get-Date) ":Confirmation denied, quitting"
    #Exit 0 
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

#region TestDetails
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

#endregion TestDetails

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

#region Body Steady State EUX Score
# ---------------------------------------------
# Build Body Steady State EUX Score
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
try {
    Write-Screen -Message "Get Remote Display Analytics Details from Influx API"
    $RDADetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $RDABody -ErrorAction Stop
}
catch {
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
try {
    Write-Screen -Message "Get Login Application Details from Influx API"
    $LoginApplicationsDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $LoginApplicationsBody -ErrorAction Stop
}
catch {
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
try {
    Write-Screen -Message "Get Steady State Application Details from Influx API"
    $SSApplicationsDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $SSApplicationsBody -ErrorAction Stop
}
catch {
    Write-Screen -Message "Error Getting Steady State Application Details from Influx API"
    break
}

# Get Test Detail Payload Index
$SSApplicationsOrder = Get-PayloadIndex -TestDetails $SSApplicationsDetails

# Build the Test Detail Results Array
$SSApplicationsResults = Get-PayloadResults -TestDetails $SSApplicationsDetails -Order $SSApplicationsOrder

#endregion Build Body Steady state Application score

#region Build Body Login Times
# ---------------------------------------------
# Build Body Login Times
# ---------------------------------------------
$LoginTimeBody = @"
newNaming = if "$($FormattedNaming)" == "_measurement" then "" else "$($FormattedNaming)"
from(bucket:"$($FormattedBucket)")
|> range(start: 2023-01-01T01:00:00Z, stop: 2023-01-01T01:52:00Z)
|> filter(fn: (r) => r["Year"] =~ /^$($FormattedYear)$/ )
|> filter(fn: (r) => r["Month"] =~ /^$($FormattedMonth)$/ )
|> filter(fn: (r) => r["DocumentName"] =~ /^$($FormattedDocumentName)$/ )
|> filter(fn: (r) => r["Comment"] =~ /^$($FormattedComment)$/ )
|> filter(fn: (r) => r["_measurement"] =~ /^$($FormattedTestname)$/ )
|> filter(fn: (r) => r["InfraTestName"] =~ /^$($FormattedTestRun)$/ )
|> filter(fn: (r) => r["DataType"] == "Raw_Login_Times")
|> filter(fn: (r) => r["_field"] == "result")
|> group(columns: ["_measurement", newNaming, "id"])
|> mean()
|> map(fn: (r) => ({r with Name: string(v: r.$($FormattedNaming))}))
|> map(fn: (r) => ({Name: r.Name, measurement: r._measurement, Value: r._value, LogonPhase: r.id}))
|> sort(columns: ["Name", "measurement"])
"@

Write-Screen -Message "Build Body Payload based on Uri Variables"

# Get the test details table from Influx and Split into individual lines
try {
    Write-Screen -Message "Get Login Time Details from Influx API"
    $LoginTimeDetails = Invoke-RestMethod -Method Post -Uri $influxDbUrl -Headers $WebHeaders -Body $LoginTimeBody -ErrorAction Stop
}
catch {
    Write-Screen -Message "Error Getting Login Time Details from Influx API"
    break
}

# Get Test Detail Payload Index
$LoginTimeOrder = Get-PayloadIndex -TestDetails $LoginTimeDetails

# Build the Test Detail Results Array
$LoginTimeResults = Get-PayloadResults -TestDetails $LoginTimeDetails -Order $LoginTimeOrder

#endregion Build Body Login Times

#endregion Get Data From Influx

# -----------------------------------------------------------------------------------------------------------------------
# Section - Download Icons
# -----------------------------------------------------------------------------------------------------------------------
#region Download Icons
Write-Screen -Message "Downloading Icons"

# Loop through the icons and download the images
foreach($icon in $icons){
    ## Test it first
    $IconOut = (Join-Path -Path $imagePath -ChildPath "$($icon).png")
    if (Test-Path  -Path $IconOut) {
        Write-Screen -Message "Icon File $($IconOut) already exists. Not downloading. Delete the file if you want to re-download it"
    }
    else {
        Get-UriFile -Uri ($iconsSource + "$($icon).png") -OutFile $IconOut
    }
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
    $Panels = @('157', '92', '89', '93')   
    [int]$maxboottime = (($testDetailResults.boottime | measure -Maximum).maximum + 150) * 1000
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
    $Panels = @('10')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
} else {
    Write-Screen -Message "Login Enterprise Results Download Skipped"
}
#endregion Login Enterprise Results

#region Cluster Resources Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Cluster Resources Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($ClusterResources) {
    Write-Screen -Message "Downloading Cluster Resources Graphs"
    # Build the PanelID Array 
    $Panels = @('120', '54', '57', '58', '53', '14')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
} else {
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
    $Panels = @('16', '28', '27', '29')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
} else {
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
    $Panels = @('110', '111', '113', '115')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
} else {
    Write-Screen -Message "Remote Display Analytics Download Skipped"   
}
#endregion Remote Display Analytics Results

#region Applications Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Applications Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($Applications) {
    Write-Screen -Message "Downloading Applications Graphs"
    # Build the PanelID Array 
    $Panels = @('31', '41', '36', '37', '102', '35')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
} else {
    Write-Screen -Message "Applications Download Skipped"  
}
#endregion Applications Results

#region Nutanix Files Results
# -----------------------------------------------------------------------------------------------------------------------
# Section - Nutanix Files Results
# -----------------------------------------------------------------------------------------------------------------------
# Execute if Option Enabled
if ($NutanixFiles) {
    Write-Screen -Message "Downloading Nutanix Files Graphs"
    # Build the PanelID Array 
    $Panels = @('71', '131', '132', '133', '78', '134', '136', '135', '77', '139', '140', '141', '160', '162')  
    $endtime = "1672538820000"
    Get-Graphs -Panels $Panels -EndTime $endtime -SourceUri $SourceUri -imagePath $imagePath
} else {
    Write-Screen -Message "Nutanix Files Download Skipped"
}
#endregion Nutanix Files Results

#endregion Get Results

# -----------------------------------------------------------------------------------------------------------------------
# Section - Create Report
# -----------------------------------------------------------------------------------------------------------------------
#region Create Report

#region Exec Summary
$ExecFile = ($MDFileDetails.1).Name
$ExecMD = Join-Path -Path $md -ChildPath $ExecFile
Write-Screen -Message "Adding Executive Summary"
Add-Content $ExecMD $BoilerPlateExecSummary
#endregion Exec Summary

#region Introduction
$IntroFile = ($MDFileDetails.2).Name
$IntroMD = Join-Path -Path $md -ChildPath $IntroFile
Write-Screen -Message "Adding Introduction"
Add-Content $IntroMD $BoilerPlateIntroduction
#endregion Introduction

#region Application Overview
$AppOverviewFile = ($MDFileDetails.3).Name
$AppOverviewMD = Join-Path -Path $md -ChildPath $AppOverviewFile
Write-Screen -Message "Adding Application Overview"
Add-Content $AppOverviewMD $BoilerPlateApplicationOverview
#endregion Application Overview

#region CVAD on Nutanix
$CVADFile = ($MDFileDetails.4).Name
$CVADMD = Join-Path -Path $md -ChildPath $CVADFile
Write-Screen -Message "Adding CVAD on Nutanix"
Add-Content $CVADMD $BoilerPlateCVADonNutanix
#endregion CVAD on Nutanix

#region Solution Design
$SolutionDesignFile = ($MDFileDetails.5).Name
$SolutionDesignMD = Join-Path -Path $md -ChildPath $SolutionDesignFile
Write-Screen -Message "Adding Solution Design"
Add-Content $SolutionDesignMD $BoilerPlateSolutionDesign
#endregion Solution Design

#region Validation and Benchmarking
$ValidationFile = ($MDFileDetails.6).Name
$ValidationMD = Join-Path -Path $md -ChildPath $ValidationFile
Write-Screen -Message "Adding Solution Design"
Add-Content $ValidationMD $BoilerPlateValidationandBenchmarking
#endregion Validation and Benchmarking

#region Validation Results
$ResultsFile = ($MDFileDetails.7).Name
$ResultMD = Join-Path -Path $md -ChildPath $ResultsFile
Write-Screen -Message "Adding Results"
# UPDATE WITH RESULTS
#endregion Validation Results

#region Conclusion Results
$ConclusionFile = ($MDFileDetails.8).Name
$ConclusionMD = Join-Path -Path $md -ChildPath $ConclusionFile
Write-Screen -Message "Adding Conclusion"
Add-Content $ConclusionMD $BoilerPlateConclusion
#endregion Conclusion Results

#region Appendix
$AppendixFile = ($MDFileDetails.9).Name
$AppendixMD = Join-Path -Path $md -ChildPath $AppendixFile
Write-Screen -Message "Adding Conclusion"
Add-Content $AppendixMD $BoilerPlateAppendix
#endregion Appendix

#endregion Create Report

#endregion Execute