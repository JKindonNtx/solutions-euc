<#
.SYNOPSIS
    Reviews Citrix DaaS Delivery Groups for Adaptive Access configurations (Network Locations) and disables any open Delivery Groups

    https://docs.citrix.com/en-us/citrix-daas/manage-deployment/adaptive-access/adaptive-access-based-on-users-network-location
.DESCRIPTION
    Implements a level of security to restrict resource enumeration based on known locations
.PARAMETER LogPath
    Optional. Logpath output for all operations. Default is C:\Logs\ValidateDaaSEnumerationLockdown.log
.PARAMETER LogRollover
    Optional. Number of days before logfiles are rolled over. Default is 5.
.PARAMETER Region
    Mandatory. The Citrix Cloud DaaS Tenant Region. Either AP-S (Asia Pacific), US (USA), EU (Europe) or JP (Japan).
.PARAMETER CustomerID
    Mandatory. The Citrix Cloud Customer ID.
.PARAMETER ClientID
    Optional. The Citrix Cloud Secure Client ID. Cannot be used with the SecureClientFile Parameter. Must be combined with the ClientSecret parameter.
.PARAMETER ClientSecret
    Optional. The Citrix Cloud Secure Client Secret. Cannot be used with the SecureClientFile Parameter. Must be used with the ClientID parameter.
.PARAMETER SecureClientFile
    Optional. Path to the Citrix Cloud Secure Client CSV. Cannot be used with ClientID or ClientSecret parameters.
.PARAMETER LockdownOpenDeliveryGroups
    Optional. If specified, will disable any Delivery Group that does not have an Smart Access Control defined. Will Tag the Delivery Group with a "DisabledBySecurityScript" Tag. The Tag will be created if it does not exist.
.PARAMETER RemediateDisabledDeliveryGroups
    Optional. If specified, will re-enable any Delivery Group that is tagged with DisabledBySecurityScript and now has an appropriate Smart Access Control defined.
.PARAMETER Whatif
    Optional. Will action the script in a whatif processing mode only.
.EXAMPLE
    .\ValidateDaaSEnumerationLockdown.ps1 -Region US -SecureClientFile "C:\SecureFolder\secureclient.csv" -CustomerID "fakecustID" -LockdownOpenDeliveryGroups -RemediateDisabledDeliveryGroups -Whatif
.EXAMPLE
    .\ValidateDaaSEnumerationLockdown.ps1 -Region US -SecureClientFile "C:\SecureFolder\secureclient.csv" -CustomerID "fakecustID" -LockdownOpenDeliveryGroups
.EXAMPLE
    .\ValidateDaaSEnumerationLockdown.ps1 -Region US -SecureClientFile "C:\SecureFolder\secureclient.csv" -CustomerID "fakecustID"
.NOTES
    Author: James Kindon, Nutanix, 10.08.2023
#>
#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs\ValidateDaaSEnumerationLockdown.log", # Where we log to

    [Parameter(Mandatory = $false)]
    [int]$LogRollover = 5, # Number of days before logfile rollover occurs

    [Parameter(Mandatory = $true)]
    [ValidateSet("AP-S", "EU", "US", "JP")]
    [string]$Region, # The Citrix DaaS Tenant region
    
    [Parameter(Mandatory = $true)]
    [string]$CustomerID, # The Citrix DaaS Customer ID

    [Parameter(Mandatory = $false)]
    [string]$ClientID, # The Citrix Cloud Secure Client ID.

    [Parameter(Mandatory = $false)]
    [string]$ClientSecret, # The Citrix Cloud Secure Client Secret.

    [Parameter(Mandatory = $false)]
    [string]$SecureClientFile, # Path to the Citrix Cloud Secure Client CSV.

    [Parameter(Mandatory = $false)]
    [switch]$LockdownOpenDeliveryGroups, # Disable open Delivery Groups

    [Parameter(Mandatory = $false)] # Reenable Delivery Groups
    [switch]$RemediateDisabledDeliveryGroups,

    [Parameter(Mandatory = $false)]
    [switch]$Whatif # will process in a whatif mode without actually altering anythin

)
#endregion

#region Functions
# ============================================================================
# Functions
# ============================================================================
function Write-Log {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [Alias('LogPath')]
        [string]$Path = $LogPath,
       
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info","OK")]
        [string]$Level = "Info",
       
        [Parameter(Mandatory = $false)]
        [switch]$NoClobber
    )

    Begin {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process {
       
        # If the file already exists and NoClobber was specified, do not write to the log.
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
        }

        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
        }

        else {
            # Nothing to see here yet.
        }

        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-host $Message -ForegroundColor Red
                #Write-Error $Message
                $LevelText = 'ERROR:'
            }
            'Warn' {
                Write-Host $Message -ForegroundColor Yellow
                #Write-Warning $Message
                $LevelText = 'WARNING:'
            }
            'Info' {
                Write-Host $Message
                #Write-Verbose $Message
                $LevelText = 'INFO:'
            }
            'OK' {
                Write-Host $Message -ForegroundColor Green
                $LevelText = 'INFO:'
            }
        }
       
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End {
    }
}

function Start-Stopwatch {
    Write-Log -Message "Starting Timer" -Level Info
    $Global:StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
}

function Stop-Stopwatch {
    Write-Log -Message "Stopping Timer" -Level Info
    $StopWatch.Stop()
    if ($StopWatch.Elapsed.TotalSeconds -le 1) {
        Write-Log -Message "Script processing took $($StopWatch.Elapsed.TotalMilliseconds) ms to complete." -Level Info
    }
    else {
        Write-Log -Message "Script processing took $($StopWatch.Elapsed.TotalSeconds) seconds to complete." -Level Info
    }
}

function RollOverlog {
    $LogFile = $LogPath
    $LogOld = Test-Path $LogFile -OlderThan (Get-Date).AddDays(-$LogRollover)
    $RolloverDate = (Get-Date -Format "dd-MM-yyyy")
    if ($LogOld) {
        Write-Log -Message "$LogFile is older than $LogRollover days, rolling over" -Level Info
        $NewName = [io.path]::GetFileNameWithoutExtension($LogFile)
        $NewName = $NewName + "_$RolloverDate.log"
        Rename-Item -Path $LogFile -NewName $NewName
        Write-Log -Message "Old logfile name is now $NewName" -Level Info
    }    
}

function StartIteration {
    Write-Log -Message "--------Starting Iteration--------" -Level Info
    RollOverlog
    Start-Stopwatch
}

function StopIteration {
    Stop-Stopwatch
    Write-Log -Message "--------Finished Iteration--------" -Level Info
}

function Get-CCAccessToken {
    param (
        [string]$ClientID,
        [string]$ClientSecret
    )
    $TokenURL = "https://$($CloudUrl)/cctrustoauth2/root/tokens/clients"
    $Body = @{
        grant_type    = "client_credentials"
        client_id     = $ClientID
        client_secret = $ClientSecret
    }
    $Response = Invoke-WebRequest $tokenUrl -Method POST -Body $Body -UseBasicParsing
    $AccessToken = $Response.Content | ConvertFrom-Json
    return $AccessToken.access_token
}

function Get-CCSiteID {
    param (
        [Parameter(Mandatory = $true)]
        [string] $AccessToken,
        [Parameter(Mandatory = $true)]
        [string] $CustomerID
    )
    $RequestUri = "https://$($CloudUrl)/cvadapis/me"
    $Headers = @{
        "Accept"            = "application/json";
        "Authorization"     = "CWSAuth Bearer=$AccessToken";
        "Citrix-CustomerId" = $CustomerID;
    }
    $Response = Invoke-RestMethod -Uri $RequestUri -Method GET -Headers $Headers
    return $Response.Customers.Sites.Id
}

function Set-PoshTls {
    <#
    .SYNOPSIS
    Makes sure we use the proper Tls version (1.2 only required for connection to Prism).

    .DESCRIPTION
    Makes sure we use the proper Tls version (1.2 only required for connection to Prism).

    .NOTES
    Author: Stephane Bourdeaud (sbourdeaud@nutanix.com)

    .EXAMPLE
    .\Set-PoshTls
    Makes sure we use the proper Tls version (1.2 only required for connection to Prism).

    .LINK
    https://github.com/sbourdeaud
    #>
    [CmdletBinding(DefaultParameterSetName = 'None')] #make this function advanced

    param 
    (
        
    )

    begin {
    }

    process {
        Write-Log -Message "[SSL] Adding Tls12 support" -Level Info
        [Net.ServicePointManager]::SecurityProtocol = `
        ([Net.ServicePointManager]::SecurityProtocol -bor `
                [Net.SecurityProtocolType]::Tls12)
    }

    end {

    }
} #this function is used to make sure we use the proper Tls version (1.2 only required for connection to Prism)

#endregion

#region Variables
# ============================================================================
# Variables
# ============================================================================
$TagName = "DisabledBySecurityScript"
$TagDescription = "Delivery Group does not contain a Network Location Filter"
#endregion Variables

#Region Execute
# ============================================================================
# Execute
# ============================================================================
StartIteration

#region script parameter reporting
#------------------------------------------------------------
# Script processing detailed reporting
#------------------------------------------------------------
Write-Log -Message "[Script Params] Logging Script Parameter configurations" -Level Info
Write-Log -Message "[Script Params] Script LogPath = $($LogPath)" -Level Info
Write-Log -Message "[Script Params] Script LogRollover = $($LogRollover)" -Level Info
Write-Log -Message "[Script Params] Script Whatif = $($Whatif)" -Level Info
Write-Log -Message "[Script Params] Citrix Cloud Region = $($Region)" -Level Info
Write-Log -Message "[Script Params] Citrix Cloud CustomerID = $($CustomerID)" -Level Info
Write-Log -Message "[Script Params] Citrix Cloud ClientID = $($ClientID)" -Level Info
Write-Log -Message "[Script Params] Citrix Cloud SecureClientFile = $($SecureClientFile)" -Level Info
Write-Log -Message "[Script Params] Citrix Cloud Lockdown Open Delivery Groups = $($LockdownOpenDeliveryGroups)" -Level Info
Write-Log -Message "[Script Params] Citrix Cloud Remediate previously disabled Delivery Groups = $($LockdownOpenDeliveryGroups)" -Level Info
Write-Log -Message "[Script Params] Citrix Cloud Tag Name Variable = $($TagName)" -Level Info

#endregion script parameter reporting

#check PoSH version
if ($PSVersionTable.PSVersion.Major -lt 5) { throw "$(get-date) [ERROR] Please upgrade to Powershell v5 or above (https://www.microsoft.com/en-us/download/details.aspx?id=50395)" }

#region Param Validation
if (!($SecureClientFile) -and !($ClientID)) {
    Write-Log -Message "[PARAM ERROR]: You must specify either SecureClientFile or ClientID parameters to continue" -Level Warn
    StopIteration
    Exit 0
}
if ($SecureClientFile -and ($ClientID -or $ClientSecret)) {
    Write-Log -Message "[PARAM ERROR]: You cannot specify both SecureClientFile and ClientID or ClientSecret together. Invalid parameter options" -Level Warn
    StopIteration
    Exit 0
}
#endregion Param Validation

#region SSL Handling
#------------------------------------------------------------
# Handle Invalid Certs
#------------------------------------------------------------
if ($PSEdition -eq 'Desktop') {
    Write-Log -Message "[SSL] Ignoring invalid certificates" -Level Info
    if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
        $certCallback = @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
public class ServerCertificateValidationCallback
{
public static void Ignore()
{
    if(ServicePointManager.ServerCertificateValidationCallback ==null)
    {
        ServicePointManager.ServerCertificateValidationCallback += 
            delegate
            (
                Object obj, 
                X509Certificate certificate, 
                X509Chain chain, 
                SslPolicyErrors errors
            )
            {
                return true;
            };
    }
}
}
"@
        Add-Type $certCallback
    }
    [ServerCertificateValidationCallback]::Ignore()
}

Set-PoshTls
#endregion SSL Handling

#region Citrix Cloud Info Gathering
#------------------------------------------------------------
# Set Cloud API URL based on Region
#------------------------------------------------------------
switch ($Region) {
    'AP-S' { 
        $CloudUrl = "api-ap-s.cloud.com"
    }
    'EU' {
        $CloudUrl = "api-eu.cloud.com"
    }
    'US' {
        $CloudUrl = "api-us.cloud.com"
    }
    'JP' {
        $CloudUrl = "api.citrixcloud.jp"
    }
}

Write-Log -Message "[Citrix Cloud] Resource URL is $($CloudUrl)" -Level Info

#region Citrix Auth
#------------------------------------------------------------
# Handle Secure Client CSV Input
#------------------------------------------------------------
if ($SecureClientFile) {
    Write-Log -Message "[Citrix Cloud] Importing Secure Client: $($SecureClientFile)" -Level Info
    try {
        $SecureClient = Import-Csv -Path $SecureClientFile -ErrorAction Stop
        $ClientID = $SecureClient.ID
        $ClientSecret = $SecureClient.Secret
    }
    catch {
        Write-Log -Message "[Citrix Cloud] Failed to import Secure Client File" -Level Warn
        Exit 1
        StopIteration
    }
}

#------------------------------------------------------------
# Authenticate against Citrix Cloud DaaS and grab Site info
#------------------------------------------------------------
Write-Log -Message "[Citrix Cloud] Creating Citrix Cloud acccess token" -Level Info
$AccessToken = Get-CCAccessToken -ClientID $ClientID -ClientSecret $ClientSecret

Write-Log -Message "[Citrix Cloud] Getting Citrix Cloud Site ID" -Level Info
$SiteID = Get-CCSiteID -CustomerID $CustomerID -AccessToken $AccessToken 
Write-Log -Message "[Citrix Cloud] Citrix Cloud Site ID is: $($SiteID)" -Level Info

#------------------------------------------------------------
# Set Auth Headers for Citrix DaaS API calls
#------------------------------------------------------------
$headers = @{
    Authorization       = "CwsAuth Bearer=$($AccessToken)"
    'Citrix-CustomerId' = $CustomerID
    Accept              = 'application/json'
}

#endregion Citrix Auth

#endregion Citrix Cloud Info Gathering

#Region Tag Handling
if ($LockdownOpenDeliveryGroups) {
    # Check tag exists
    #----------------------------------------------------------------------------------------------------------------------------                
    # Set API call detail                
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://api-us.cloud.com/cvadapis/$SiteID/Tags/$($TagName)"
    $Payload = $null
    #----------------------------------------------------------------------------------------------------------------------------
    Write-Log -Message "[Tag] Validating Citrix DaaS Tag $($TagName) exists" -Level Info
    try {
        $TagExists = Invoke-RestMethod -Method $Method -Headers $headers -Uri $RequestUri -Body $Payload -ContentType "application/json" -ErrorAction Stop
        if ($TagExists) {
            Write-Log -Message "[Tag] Tag $($TagName) exists" -Level OK
        }
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        Write-Log -Message "[Tag] $($TagName) does not exist. Attempting to create" -Level Info
        if (!$Whatif) {
            # We are executing
            Write-Log -Message "[Tag] Tag $($TagName) does not exist. Attempting to create" -Level Info
            #----------------------------------------------------------------------------------------------------------------------------
            # Set API call detail 
            #----------------------------------------------------------------------------------------------------------------------------
            $Method = "Post"
            $RequestUri = "https://api-us.cloud.com/cvadapis/$SiteID/Tags"
            $PayloadContent = @{
                Name = $TagName
                Description = $TagDescription
            }
            $Payload = $PayloadContent | ConvertTo-Json
            #----------------------------------------------------------------------------------------------------------------------------
            try {
                $CreateTag = Invoke-RestMethod -Method $Method -Headers $headers -Uri $RequestUri -Body $Payload -ContentType "application/json" -ErrorAction Stop
                Write-Log -Message "[Tag] Tag $($TagName) created successfully " -Level OK
            }
            catch {
                Write-Log -Message "[Tag] Tag $($TagName) failed to create" -Level Error
                Write-Log -Message $_ -Level Error
                StopIteration
                Exit 1
            }
        }
        else {
            # We are in whatif mode
            Write-Log -Message "[WHATIF] [Tag] Would create Tag $($TagName)" -Level Warn
        }
    }
    catch {
        Write-Log -Message "[Tag] Could not validate Citrix DaaS Tag $($TagName) exists" -Level Error
        Write-Log -Message $_ -Level Error
        StopIteration
        Exit 1
    }
}

#endRegion Tag Handling

#region Delivery Group Validation
# Get the Delivery Groups          
#----------------------------------------------------------------------------------------------------------------------------                
# Set API call detail                
#----------------------------------------------------------------------------------------------------------------------------
$Method = "Get"
$RequestUri = "https://$($CloudUrl)/cvadapis/$SiteID/DeliveryGroups"
$Payload = $null
#----------------------------------------------------------------------------------------------------------------------------
try {
    Write-Log -Message "[Delivery Groups] Retrieving Delivery Groups from Citrix DaaS" -Level Info
    $DeliveryGroups = Invoke-RestMethod -Method $Method -Headers $headers -Uri $RequestUri -Body $Payload -ContentType "application/json" -ErrorAction Stop
    Write-Log -Message "[Delivery Groups] Retrieved $($DeliveryGroups.Items.Count) Delivery Groups" -Level Info
}
catch {
    Write-Log -Message "[Delivery Groups] Failed to retrieve Delivery Groups from Citrix DaaS" -Level Error
    Write-Log -Message $_ -Level Error
    StopIteration
    Exit 1
}

#Process the Delivery Groups
foreach ($DG in $DeliveryGroups.Items) {
    # Get the DG Detail
    #----------------------------------------------------------------------------------------------------------------------------                
    # Set API call detail                
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://api-us.cloud.com/cvadapis/$SiteID/DeliveryGroups/$($DG.Name)"
    $Payload = $null
    #----------------------------------------------------------------------------------------------------------------------------
    Write-Log -Message "[Delivery Group $($DG.Name)] Testing for enumeration lockdown" -Level Info
    try {
        $DGDetails = Invoke-RestMethod -Method $Method -Headers $headers -Uri $RequestUri -Body $Payload -ContentType "application/json" -ErrorAction Stop

        $LocationFilters = $DGDetails.SimpleAccessPolicy.IncludedSmartAccessTags
        $DGStatus = $DGDetails.Enabled
        $DGMaintenanceMode = $DGDetails.InMaintenanceMode

        if (!($LocationFilters)) {
            Write-Log -Message "[Delivery Group $($DG.Name)] ==> Is open to all locations for enumeration" -Level Error
            if ($DGStatus -eq "True") {
                Write-Log -Message "[Delivery Group $($DG.Name)] ==> Is enabled" -Level Error
                if ($DGMaintenanceMode -eq "True") {
                    Write-Log -Message "[Delivery Group $($DG.Name)] ==> Is in Maintenance mode" -Level OK
                }
                else {
                    Write-Log -Message "[Delivery Group $($DG.Name)] ==> Is not in in Maintenance mode" -Level Error
                }
                if ($LockdownOpenDeliveryGroups) {
                    if (!$Whatif) {
                        #we are executing
                        Write-Log -Message "[Delivery Group $($DG.Name)] ====> Will be disabled" -Level Warn
                        #----------------------------------------------------------------------------------------------------------------------------                
                        # Set API call detail                
                        #----------------------------------------------------------------------------------------------------------------------------
                        $Method = "Patch"
                        $RequestUri = "https://api-us.cloud.com/cvadapis/$SiteID/DeliveryGroups/$($DG.Name)"
                        $PayloadContent = @{
                            Enabled = $False
                        }
                        $Payload = $PayloadContent | ConvertTo-Json
                        #----------------------------------------------------------------------------------------------------------------------------
                        try {
                            $DisableDeliveryGroup = Invoke-RestMethod -Method $Method -Headers $headers -Uri $RequestUri -Body $Payload -ContentType "application/json" -ErrorAction Stop
                            Write-Log -Message "[Delivery Group $($DG.Name)] ====> Has been disabled. Applying Tag: $($TagName)" -Level OK
                            # now set Tag
                            #----------------------------------------------------------------------------------------------------------------------------
                            # Set API call detail 
                            #----------------------------------------------------------------------------------------------------------------------------
                            $Method = "Post"
                            $RequestUri = "https://api-us.cloud.com/cvadapis/$SiteID/DeliveryGroups/$($DG.Name)/Tags/$($TagName)"
                            $Payload = $null
                            #----------------------------------------------------------------------------------------------------------------------------
                            try {
                                $TagApplied = Invoke-RestMethod -Method $Method -Headers $headers -Uri $RequestUri -Body $Payload -ContentType "application/json" -ErrorAction Stop
                                Write-log -Message "[Delivery Group $($DG.Name)] ====> Tag $($TagName) has been applied to Delivery Group" -Level OK
                            }
                            catch {
                                Write-Log -Message "[Delivery Group $($DG.Name)] ====> Failed to apply tag $($TagName)" -Level Error
                                Write-Log -Message $_ -Level Error
                            }
                        }
                        catch {
                            Write-Log -Message "[Delivery Group $($DG.Name)] ====> Was not disabled" -Level Error
                            Write-Log -Message $_ -Level Error
                        }
                    }
                    else {
                        # We are in whatif Mode
                        Write-Log -Message "[WHATIF] [Delivery Group $($DG.Name)] ====> Would be disabled with Tag: $($TagName) applied" -Level Warn
                    }
                }
            }
            else {
                Write-Log -Message "[Delivery Group $($DG.Name)] ==> Is disabled" -Level OK
            }
        }
        else {
            Write-Log -Message "[Delivery Group $($DG.Name)] ==> Contains $($LocationFilters.Count) Filters" -Level Info
            $NetworkLocationFiltercount = 0
            $NotNetworkLocationFiltercount = 0
            foreach ($Filter in $LocationFilters) {
                if ($Filter.Filter -like "LOCATION_TAG_*") {
                    Write-Log -Message "[Delivery Group $($DG.Name)] ====> Farm Filter Network Location is: $($Filter.Farm) with Filter: $($Filter.Filter)" -level OK
                    $NetworkLocationFiltercount += 1
                }
                else {
                    Write-Log -Message "[Delivery Group $($DG.Name)] ====> Farm Filter is not a Network Location filter: $($Filter.Farm) with Filter: $($Filter.Filter)" -Level Warn
                    $NotNetworkLocationFiltercount += 1
                }
            }
    
            if ($NetworkLocationFiltercount -gt 0) {
                Write-Log -Message "[Delivery Group $($DG.Name)] ====> Contains $($NetworkLocationFiltercount) Network Location Filters" -Level OK
                if ($DGStatus -ne "True") {
                    if ($RemediateDisabledDeliveryGroups) {
                        #----------------------------------------------------------------------------------------------------------------------------
                        # Set API Call Detail
                        #----------------------------------------------------------------------------------------------------------------------------
                        $Method = "Get"
                        $RequestUri = "https://api-us.cloud.com/cvadapis/$SiteID/DeliveryGroups/$($DG.Name)/Tags"
                        $Payload = $null
                        #----------------------------------------------------------------------------------------------------------------------------
                        try {
                            Write-Log -Message "[Delivery Group $($DG.Name)] Checking to see if previously disabled by this script" -Level Info
                            $DGTags = Invoke-RestMethod -Method $Method -Headers $headers -Uri $RequestUri -Body $Payload -ContentType "application/json" -ErrorAction Stop
                            $DGTags = $DGTags.Items.name
                            if ($TagName -in $DGTags) {
                                Write-Log -Message "[Delivery Group $($DG.Name)] ====> $($TagName) Found. Delivery Group Will be re-enabled" -Level Info
                                if (!$WhatIf) {
                                    # We are executing
                                    #----------------------------------------------------------------------------------------------------------------------------
                                    # Set the API Call Detail
                                    #----------------------------------------------------------------------------------------------------------------------------
                                    $Method = "Patch"
                                    $RequestUri = "https://api-us.cloud.com/cvadapis/$SiteID/DeliveryGroups/$($DG.Name)"
                                    $PayloadContent = @{
                                        Enabled = $True
                                    }
                                    $Payload = $PayloadContent | ConvertTo-Json
                                    #----------------------------------------------------------------------------------------------------------------------------
                                    try {
                                        $EnableDeliveryGroup = Invoke-RestMethod -Method $Method -Headers $headers -Uri $RequestUri -Body $Payload -ContentType "application/json" -ErrorAction Stop
                                        Write-Log -Message "[Delivery Group $($DG.Name)] ====> Has been enabled. Removing Tag $($TagName)" -Level OK
                                        # remove tag
                                        #----------------------------------------------------------------------------------------------------------------------------
                                        # Set the API Call Detail
                                        #----------------------------------------------------------------------------------------------------------------------------
                                        $Method = "Delete"
                                        $RequestUri = "https://api-us.cloud.com/cvadapis/$SiteID/DeliveryGroups/$($DG.Name)/Tags/$($TagName)"
                                        $Payload = $null
                                        #----------------------------------------------------------------------------------------------------------------------------
                                        try {
                                            $RemoveTagFromDG = Invoke-RestMethod -Method $Method -Headers $headers -Uri $RequestUri -Body $Payload -ContentType "application/json" -ErrorAction Stop
                                            Write-Log -Message "[Delivery Group $($DG.Name)] ====> $($TagName) has been removed" -Level OK
                                        }
                                        catch {
                                            Write-Log -Message "[Delivery Group $($DG.Name)] ====> $($TagName) has not been removed" -Level Error
                                            Write-Log -Message $_ -Level Error
                                        }
                                    }
                                    catch {
                                        Write-Log -Message "[Delivery Group $($DG.Name)] ====> Could not be enabled" -Level Error
                                        Write-Log -Message $_ -Level Error
                                    }
                                }
                                else {
                                    #We are in Whatif Mode
                                    Write-Log -Message "[WHATIF] [Delivery Group $($DG.Name)] ====> Would have been re-enabled" -Level Warn
                                }
                            }
                            else {
                                Write-Log -Message "[Delivery Group $($DG.Name)] was not previously disabled by this script. Not performing any action" -Level Info
                            }
                        }
                        catch {
                            Write-Log -Message "[Delivery Group $($DG.Name)] ====> Unable to identify if Delivery Group was previously disabled by this script" -Level Warn
                        }
                    }
                }
            }

            if ($NotNetworkLocationFiltercount -gt 0) {
                Write-Log -Message "[Delivery Group $($DG.Name)] ====> Contains $($NotNetworkLocationFiltercount) Filters not used for Adaptive Access" -Level Warn
            }
        }
    }
    catch {
        Write-Log -Message "[Delivery Group] Failed to get Delivery Group $($DG.Name)" -Level Error
        Write-Log -Message $_ -Level Error
    }
}

#endregion Delivery Group Validation

StopIteration
Exit 0
#endregion
