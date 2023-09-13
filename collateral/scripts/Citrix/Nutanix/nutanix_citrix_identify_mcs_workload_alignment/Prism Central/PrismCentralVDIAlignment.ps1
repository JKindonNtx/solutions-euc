<#
.SYNOPSIS
    Identifies Citrix MCS workloads based on Identity Disks and Reports on cross pollination of General Workloads. Attempts to identify PVS workloads but this is more indicative than anything solid
.DESCRIPTION
    Designed to be able to identify where Citrix Provisioned and General Infrastructure workloads are being colocated (this isn't optimal).
.PARAMETER LogPath
    Optional. Logpath output for all operations. Default path is C:\Logs\PrismCentralVDIAlignment.log
.PARAMETER LogRollover
    Optional. Number of days before logfiles are rolled over. Default is 5.
.PARAMETER pc_source
    Mandatory. The Prism Central Source to target.
.PARAMETER ExcludeClusters
    Optional. Cluster names to exclude from processing.
.PARAMETER AdvancedInfo
    Optional. Outputs Verbose info around the discovery and categorization process
.PARAMETER ShowDetailedVMAlignment
    Optional. Defines which VM types will be shows in the Host tree output (General, MCS, PVS, All, None). Default is All.
.PARAMETER UseCustomCredentialFile
    Optional. Will call the Get-CustomCredentials function which keeps outputs and inputs a secure credential file base on Stephane Bourdeaud from Nutanix functions.
.PARAMETER CredPath
    Optional. Used if using the UseCustomCredentialFile parameter. Defines the location of the credential file. The default is "$Env:USERPROFILE\Documents\WindowsPowerShell\CustomCredentials".
.EXAMPLE
    .\PrismCentralVDIAlignment.ps1 -pc_source 1.1.1.1 -UseCustomCredentialFile
    Will Query Prism Central at 1.1.1.1 using a custom credential file (if it doesn't exist, it will be prompted for and saved for next time). Logs all output to C:\Logs\PrismCentralVDIAlignment.log
    All workloas will be displayed under the the host alignment output.
.EXAMPLE
    .\PrismCentralVDIAlignment.ps1 -pc_source 1.1.1.1 -UseCustomCredentialFile -ShowDetailedVMAlignment None
    Will Query Prism Central at 1.1.1.1 using a custom credential file (if it doesn't exist, it will be prompted for and saved for next time). Logs all output to C:\Logs\PrismCentralVDIAlignment.log. 
    Only VM Summary counts will be shown under the Host alignment output.
.EXAMPLE
    .\PrismCentralVDIAlignment.ps1 -pc_source 1.1.1.1 -UseCustomCredentialFile -ShowDetailedVMAlignment MCS,PVS
    Will Query Prism Central at 1.1.1.1 using a custom credential file (if it doesn't exist, it will be prompted for and saved for next time). Logs all output to C:\Logs\PrismCentralVDIAlignment.log. 
    Both MCS and PVS workloads will be displayed under the Host alignment output.
.EXAMPLE
    .\PrismCentralVDIAlignment.ps1 -pc_source 1.1.1.1 -UseCustomCredentialFile -ShowDetailedVMAlignment MCS,PVS -ExcludeClusters "NaughtyCluster"
    Will Query Prism Central at 1.1.1.1 using a custom credential file (if it doesn't exist, it will be prompted for and saved for next time). Logs all output to C:\Logs\PrismCentralVDIAlignment.log. 
    Both MCS and PVS workloads will be displayed under the Host alignment output.
    The Cluster NaughtCluster will be excluded from processing.
.EXAMPLE
    .\PrismCentralVDIAlignment.ps1 -pc_source 1.1.1.1
    Will Query Prism Central at 1.1.1.1. Credentials will be prompted for. Logs all output to C:\Logs\PrismCentralVDIAlignment.log
    All workloas will be displayed under the the host alignment output.
.EXAMPLE
    .\PrismCentralVDIAlignment.ps1 -pc_source 1.1.1.1 -AdvancedInfo
    Will Query Prism Central at 1.1.1.1. Credentials will be prompted for. Will verbose output Identity Disk info to console and log file. Logs all output to C:\Logs\PrismCentralVDIAlignment.log
    All workloas will be displayed under the the host alignment output.
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs\PrismCentralVDIAlignment.log", # Where we log to

    [Parameter(Mandatory = $false)]
    [int]$LogRollover = 5, # Number of days before logfile rollover occurs

    [Parameter(Mandatory = $true)]
    [string]$pc_source, # The Prism Central Instance hosting the Source VM and associated Protection Policy

    [Parameter(Mandatory = $false)]
    [array]$ExcludeClusters,

    [Parameter(Mandatory = $false)]
    [switch]$UseCustomCredentialFile, # specifies that a credential file should be used

    [Parameter(Mandatory = $false)]
    [String]$CredPath = "$Env:USERPROFILE\Documents\WindowsPowerShell\CustomCredentials", # Default path for custom credential file

    [Parameter(Mandatory = $false)]
    [switch]$AdvancedInfo, #Shows MCS identified machines and associated disk ID

    [Parameter(Mandatory = $false)]
    [ValidateSet("General", "MCS", "PVS", "All", "None")]
    [Array]$ShowDetailedVMAlignment = "All" # Defines which VM types will be shows in the Host tree output (General, MCS, PVS, All). Default is All.

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
        [ValidateSet("Error", "Warn", "Info", "OK", "MCS_Info", "PVS_Info")]
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
            'MCS_Info' {
                Write-Host $Message -ForegroundColor Cyan
                $LevelText = 'INFO:'
            }
            'PVS_Info' {
                Write-Host $Message -ForegroundColor DarkCyan
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

function Set-CustomCredentials {
    #input: path, credname
    #output: saved credentials file
    <#
    .SYNOPSIS
    Creates a saved credential file using DAPI for the current user on the local machine.
    .DESCRIPTION
    This function is used to create a saved credential file using DAPI for the current user on the local machine.
    .NOTES
    Author: Stephane Bourdeaud
    .PARAMETER path
    Specifies the custom path where to save the credential file. By default, this will be %USERPROFILE%\Documents\WindowsPowershell\CustomCredentials.
    .PARAMETER credname
    Specifies the credential file name.
    .EXAMPLE
    .\Set-CustomCredentials -path c:\creds -credname prism-apiuser
    Will prompt for user credentials and create a file called prism-apiuser.txt in c:\creds
    #>
    param
    (
        [parameter(mandatory = $false)]
        [string]$path,
        
        [parameter(mandatory = $true)]
        [string]$credname
    )

    begin {
        if (!$path) {
            if ($IsLinux -or $IsMacOS) {
                $path = $home
            }
            else {
                $path = $CredPath
            }
            Write-Log -Message "[Credentials] Set path to $path" -Level Info
        } 
    }
    process {
        #prompt for credentials
        $credentialsFilePath = "$path\$credname.txt"
        $credentials = Get-Credential -Message "Enter the credentials to save in $path\$credname.txt"
        
        #put details in hashed format
        $user = $credentials.UserName
        $securePassword = $credentials.Password
        
        #convert secureString to text
        try {
            $password = $securePassword | ConvertFrom-SecureString -ErrorAction Stop
        }
        catch {
            Write-Log -Message "[Credentials] Could not convert password : $($_.Exception.Message)" -Level Warn
            StopIteration
            Exit 1
        }

        #create directory to store creds if it does not already exist
        if (!(Test-Path $path)) {
            try {
                $result = New-Item -type Directory $path -ErrorAction Stop
            } 
            catch {
                Write-Log -Message "[Credentials] Could not create directory $path : $($_.Exception.Message)" -Level Warn
                StopIteration
                Exit 1
            }
        }

        #save creds to file
        try {
            Set-Content $credentialsFilePath $user -ErrorAction Stop
        } 
        catch {
            Write-Log -Message "[Credentials] Could not write username to $credentialsFilePath : $($_.Exception.Message)" -Level Warn
            StopIteration
            Exit 1
        }
        try {
            Add-Content $credentialsFilePath $password -ErrorAction Stop
        } 
        catch {
            Write-Log -Message "[Credentials] Could not write password to $credentialsFilePath : $($_.Exception.Message)" -Level Warn
            StopIteration
            Exit 1
        }

        Write-Log -Message "[Credentials] Saved credentials to $credentialsFilePath" -Level Info              
    }
    end
    {}
} #this function is used to create saved credentials for the current user

function Get-CustomCredentials {
    #input: path, credname
    #output: credential object
    <#
    .SYNOPSIS
    Retrieves saved credential file using DAPI for the current user on the local machine.
    .DESCRIPTION
    This function is used to retrieve a saved credential file using DAPI for the current user on the local machine.
    .NOTES
    Author: Stephane Bourdeaud
    .PARAMETER path
    Specifies the custom path where the credential file is. By default, this will be %USERPROFILE%\Documents\WindowsPowershell\CustomCredentials.
    .PARAMETER credname
    Specifies the credential file name.
    .EXAMPLE
    .\Get-CustomCredentials -path c:\creds -credname prism-apiuser
    Will retrieve credentials from the file called prism-apiuser.txt in c:\creds
    #>
    param
    (
        [parameter(mandatory = $false)]
        [string]$path,
        
        [parameter(mandatory = $true)]
        [string]$credname
    )

    begin {
        if (!$path) {
            if ($IsLinux -or $IsMacOS) {
                $path = $home
            }
            else {
                $path = $Credpath
            }
            Write-Log -Message "[Credentials] Retrieving credentials from $path" -Level Info
        } 
    }
    process {
        $credentialsFilePath = "$path\$credname.txt"
        if (!(Test-Path $credentialsFilePath)) {
            Write-Log -Message "[Credentials] Could not access file $credentialsFilePath : $($_.Exception.Message)" -Level Warn
        }

        $credFile = Get-Content $credentialsFilePath
        $user = $credFile[0]
        $securePassword = $credFile[1] | ConvertTo-SecureString

        $customCredentials = New-Object System.Management.Automation.PSCredential -ArgumentList $user, $securePassword

        Write-Log -Message "[Credentials] Returning credentials from $credentialsFilePath" -Level Info
    }
    end {
        return $customCredentials
    }
} #this function is used to retrieve saved credentials for the current user

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

function InvokePrismAPI {
    param (
        [parameter(mandatory = $true)]
        [ValidateSet("POST", "GET", "DELETE", "PUT")]
        [string]$Method,

        [parameter(mandatory = $true)]
        [string]$Url,

        [parameter(mandatory = $false)]
        [string]$Payload,

        [parameter(mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential
    )
    BEGIN {}
    PROCESS {
        if ($APICallVerboseLogging) { 
            Write-Log -Message "[Prism API Call] Making a $method call to $url" -Level Info
        }
        try {
            #check powershell version as PoSH 6 Invoke-RestMethod can natively skip SSL certificates checks and enforce Tls12 as well as use basic authentication with a pscredential object
            if ($PSVersionTable.PSVersion.Major -gt 5) {
                $headers = @{
                    "Content-Type" = "application/json";
                    "Accept"       = "application/json"
                }
                if ($payload) {
                    $resp = Invoke-RestMethod -Method $method -Uri $url -Headers $headers -Body $payload -SkipCertificateCheck -SslProtocol Tls12 -Authentication Basic -Credential $credential -ErrorAction Stop
                }
                else {
                    $resp = Invoke-RestMethod -Method $method -Uri $url -Headers $headers -SkipCertificateCheck -SslProtocol Tls12 -Authentication Basic -Credential $credential -ErrorAction Stop
                }
            }
            else {
                $username = $credential.UserName
                $password = $credential.Password
                $headers = @{
                    "Authorization" = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($username + ":" + ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))) ));
                    "Content-Type"  = "application/json";
                    "Accept"        = "application/json"
                }
                if ($payload) {
                    $resp = Invoke-RestMethod -Method $method -Uri $url -Headers $headers -Body $payload -ErrorAction Stop
                }
                else {
                    $resp = Invoke-RestMethod -Method $method -Uri $url -Headers $headers -ErrorAction Stop
                }
            }
        }
        catch {
            $saved_error = $_.Exception.Message
            # Write-Host "$(Get-Date) [INFO] Headers: $($headers | ConvertTo-Json)"
            #Write-Log -Message "Payload: $payload" -Level Info
            Throw "$(get-date) [ERROR] $saved_error"
        }
        finally {
            #add any last words here; this gets processed no matter what
        }
    }
    END {
        return $resp
    }
}

function GetPCVMIncrements {
    param (
        [parameter(mandatory = $true)]
        [int]$offset
    )
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "POST"
    $RequestUri = "https://$($pc_source):9440/api/nutanix/v3/vms/list"
    $PayloadContent = @{
        kind   = "vm"
        length = 500
        offset = $offset
    }
    $Payload = (ConvertTo-Json $PayloadContent)
    #----------------------------------------------------------------------------------------------------------------------------
    Write-Log -Message "[VM Retrieval] Retrieving machines from offset $($offset) under PC: $($pc_source)" -Level Info
    try {
        $vm_list = InvokePrismAPI -Method $Method -Url $RequestUri -Payload $Payload -Credential $PrismCentralCredentials -ErrorAction Stop
        $vm_list = $vm_list.entities
        Write-Log -Message "[VM Retrieval] Retrieved $($vm_list.Count) from offset $($Offset) virtual machines under PC: $($pc_source)" -Level Info
        #Now we need to add them to the existing $VirtualMachinesArray
        $Global:VirtualMachines = ($Global:VirtualMachines + $vm_list)
        Write-Log -Message "[VM Retrieval] Retrieved VM Count is $($Global:VirtualMachines.Count) under PC: $($pc_source)" -Level Info
    }
    catch {
        Write-Log -Message "[VM Retrieval] Failed to retrieve virtual machines from $($pc_source)" -Level Warn
        StopIteration
        Exit 1
    }
}

#endregion

#Region Execute
# ============================================================================
# Execute
# ============================================================================
StartIteration

#region script parameter reporting
# ============================================================================
# Script processing detailed reporting
# ============================================================================
Write-Log -Message "[Script Params] Logging Script Parameter configurations" -Level Info
Write-Log -Message "[Script Params] Script LogPath = $($LogPath)" -Level Info
Write-Log -Message "[Script Params] Script LogRollover = $($LogRollover)" -Level Info
Write-Log -Message "[Script Params] Nutanix pc_source = $($pc_source)" -Level Info
Write-Log -Message "[Script Params] Nutanix Cluster exclusion list = $($ExcludeClusters)" -Level Info
Write-Log -Message "[Script Params] Script Advanced Info = $($AdvancedInfo)" -Level Info
Write-Log -Message "[Script Params] Script Detailed VM Alignment is = $($ShowDetailedVMAlignment)" -Level Info

#endregion script parameter reporting

#check PoSH version
if ($PSVersionTable.PSVersion.Major -lt 5) { throw "$(get-date) [ERROR] Please upgrade to Powershell v5 or above (https://www.microsoft.com/en-us/download/details.aspx?id=50395)" }

#region Param Validation
if (($ShowDetailedVMAlignment -contains "All") -and ($ShowDetailedVMAlignment -contains "None")) {
    Write-Log -Message "[PARAM ERROR]: You cannot specify both All and None when using ShowDetailedVMAlignment" -Level Warn
    StopIteration
    Exit 0
}
if (($ShowDetailedVMAlignment -contains "None") -and ($ShowDetailedVMAlignment -contains "MCS" -or $ShowDetailedVMAlignment -contains "PVS" -or $ShowDetailedVMAlignment -contains "General")) {
    Write-Log -Message "[PARAM ERROR]: You cannot specify both None and a another filter value when using ShowDetailedVMAlignment" -Level Warn
    StopIteration
    Exit 0
}
if (($ShowDetailedVMAlignment -contains "All") -and ($ShowDetailedVMAlignment -contains "MCS" -or $ShowDetailedVMAlignment -contains "PVS" -or $ShowDetailedVMAlignment -contains "General")) {
    Write-Log -Message "[PARAM ERROR]: You cannot specify both All and a another filter value when using ShowDetailedVMAlignment" -Level Warn
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

#region Authentication
#------------------------------------------------------------
# Handle Authentication
#------------------------------------------------------------
if ($UseCustomCredentialFile.IsPresent) {
    # credentials for PC
    $PrismCentralCreds = "prism-central-creds"
    Write-Log -Message "[Credentials] UseCustomCredentialFile has been selected. Attempting to retrieve credential object" -Level Info
    try {
        $PrismCentralCredentials = Get-CustomCredentials -credname $PrismCentralCreds -ErrorAction Stop
    }
    catch {
        Set-CustomCredentials -credname $PrismCentralCreds
        $PrismCentralCredentials = Get-CustomCredentials -credname $PrismCentralCreds -ErrorAction Stop
    }
}
else {
    # credentials for PC
    Write-Log -Message "[Credentials] Prompting user for Prism Central credentials" -Level Info
    $PrismCentralCredentials = Get-Credential -Message "Enter Credentials for Prism Central Instances"
    if (!$PrismCentralCredentials) {
        Write-Log -Message "[Credentials] Failed to set user credentials" -Level Warn
        StopIteration
        Exit 1
    }
}
#endregion Authentication

#region Get Cluster list
#----------------------------------------------------------------------------------------------------------------------------
# Set API call detail
#----------------------------------------------------------------------------------------------------------------------------
$Method = "POST"
$RequestUri = "https://$($pc_source):9440/api/nutanix/v3/clusters/list"
$PayloadContent = @{
    kind = "cluster"
}
$Payload = (ConvertTo-Json $PayloadContent)
#----------------------------------------------------------------------------------------------------------------------------
try {
    Write-Log -Message "[Cluster Retrieval] Attempting to retrieve Clusters from $($pc_source)" -Level Info
    $Clusters = InvokePrismAPI -Method $Method -Url $RequestUri -Payload $Payload -Credential $PrismCentralCredentials -ErrorAction Stop
    Write-Log -Message "[Cluster Retrieval] Sucessfully retrieved Clusters from $($pc_source)" -Level Info
}
catch {
    Write-Log -Message "[Cluster Retrieval] Failed to retrieve Clusters from $($pc_source)" -Level Warn
    StopIteration
    Exit 1
}

$NtxClusters = $Clusters.entities | Where-Object { $_.status.name -ne "Unnamed" -and $_.status.name -notin $ExcludeClusters }

if ($null -ne $NtxClusters) {
    Write-Log -Message "[Cluster Retrieval] Identified $($NtxClusters.Count) Clusters under PC: $($pc_source)" -Level Info
}
else {
    Write-Log -Message "[Cluster Retrieval] Failed to retrieve Cluster info from $($pc_source)" -Level Error
    StopIteration
    Exit 1
}
#endregion Get Cluster list

#region Get Host list
#----------------------------------------------------------------------------------------------------------------------------
# Set API call detail
#----------------------------------------------------------------------------------------------------------------------------
$Method = "POST"
$RequestUri = "https://$($pc_source):9440/api/nutanix/v3/hosts/list"
$PayloadContent = @{
    kind = "host"
}
$Payload = (ConvertTo-Json $PayloadContent)
#----------------------------------------------------------------------------------------------------------------------------
try {
    Write-Log -Message "[Host Retrieval] Attempting to retrieve Hosts from $($pc_source)" -Level Info
    $Hosts = InvokePrismAPI -Method $Method -Url $RequestUri -Payload $Payload -Credential $PrismCentralCredentials -ErrorAction Stop
    Write-Log -Message "[Host Retrieval] Sucessfully retrieved Hosts from $($pc_source)" -Level Info
}
catch {
    Write-Log -Message "[Host Retrieval] Failed to retrieve Hosts from $($pc_source)" -Level Warn
    StopIteration
    Exit 1
}

$NtxHosts = $Hosts.entities

if ($null -ne $NtxHosts) {
    Write-Log -Message "[Host Retrieval] Identified $($NtxHosts.Count) Hosts under PC: $($pc_source)" -Level Info
}
else {
    Write-Log -Message "[Host Retrieval] Failed to retrieve Hosts info from $($pc_source)" -Level Error
    StopIteration
    Exit 1
}
#endregion Get Host list

#region Get VM list
#---------------------------------------------
## Get the list of VMs
#---------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------
# Set API call detail
#----------------------------------------------------------------------------------------------------------------------------
$Method = "POST"
$RequestUri = "https://$($pc_source):9440/api/nutanix/v3/vms/list"
$PayloadContent = @{
    kind   = "vm"
    length = 500

}
$Payload = (ConvertTo-Json $PayloadContent)
#----------------------------------------------------------------------------------------------------------------------------

try {
    Write-Log -Message "[Host Retrieval] Attempting to retrieve virtual machines from $($pc_source)" -Level Info
    $VirtualMachines = InvokePrismAPI -Method $Method -Url $RequestUri -Payload $Payload -Credential $PrismCentralCredentials -ErrorAction Stop
    # We need to understand if we are above 500 machines, and if we need to loop through incremental pulls
    $vm_total_entity_count = $VirtualMachines.metadata.total_matches
    Write-Log -Message "[VM Retrieval] Sucessfully retrieved virtual machines from $($pc_source)" -Level Info
}
catch {
    Write-Log -Message "[VM Retrieval] Failed to retrieve virtual machines from $($pc_source)" -Level Warn
    StopIteration
    Exit 1
}

$VirtualMachines = $VirtualMachines.entities

if ($null -ne $VirtualMachines) {
    Write-Log -Message "[VM Retrieval] Identified $($VirtualMachines.Count) virtual machines under PC: $($pc_source)" -Level Info
}
else {
    Write-Log -Message "[VM Retrieval] Failed to retrieve virtual machine info from $($pc_source)" -Level Error
    StopIteration
    Exit 1
}

#region bulk machine retrieval from PC

#Configuration Limit reached - bail
if ($vm_total_entity_count -gt 25000) {
    Write-Log -Message "[VM Retrieval] 25K VM limit reached. This is not a supported configuration. Exiting script." -Level Warn
    StopIteration
    Exit 1
}

$api_batch_increment = 500

if ($vm_total_entity_count -gt 500) {
    # Set the variable to Global for this run
    $Global:VirtualMachines = $VirtualMachines
    Write-Log -Message "[VM Retrieval] $($vm_total_entity_count) virtual machines exist under PC: $($pc_source). Looping through batch pulls" -Level Info
    # iterate through increments of 500 until the offset reaches or exceeds the value of $vm_total_entity_count.
    for ($offset = 500; $offset -lt $vm_total_entity_count; $offset += $api_batch_increment) {
        $vm_offset = $offset
        GetPCVMIncrements -offset $vm_offset
    }
}

# Set the variable back to normal
if ($vm_total_entity_count -gt 500) {
    $VirtualMachines = $Global:VirtualMachines
}
#endregion bulk machine retrievale from PC

#endregion Get VM list

#region Categorize Machines
$Citrix_MCS_Machines = @()
$Citrix_PVS_Machines = @()
$General_Workload_Machines = @()

# Attempt to find MCS Machines
foreach ($VM in $VirtualMachines) {
    $IdentityDisk = $VM.spec.resources.disk_list | Where-Object { $_.Device_properties.device_type -eq "DISK" } | Where-Object { $_.disk_size_mib -eq "16" }

    if ($IdentityDisk) {
        if ($AdvancedInfo) {
            Write-Log -Message "[VM Identification] Identified $($VM.status.name) as a Citrix MCS provisioned machine by disk uuid: $($IdentityDisk.uuid) with size $($IdentityDisk.disk_size_mib) mib" -Level Info
        }
        $Citrix_MCS_Machines += $VM
    }
}

# Attempt to find PVS Machines
foreach ($VM in $VirtualMachines) {
    if ($VM -notin $Citrix_MCS_Machines) {
        # Figure out the boot type
        $vm_boot_type = $vm.spec.resources.boot_config.boot_type
        if ($null -ne $vm_boot_type) {
            if ($vm_boot_type -eq "LEGACY") {
                # We are going to be able to figure out the boot order of this guy
                if ($AdvancedInfo) {
                    Write-Log -Message "[VM Identification] $($VM.status.name) has a legacy boot type so we can learn the boot order" -Level Info
                }
                $vm_boot_device = $vm.spec.resources.boot_config.boot_device_order_list | Select-Object -First 1
                if ($null -ne $vm_boot_device) {
                    # We have a list of boot devices now
                    if ($vm_boot_device -eq "CDROM") {
                        #We are booting from a CD ROM
                        $vm_has_iso_attached = ($vm.spec.resources.disk_list | Where-Object { $_.device_properties.device_type -eq "CDROM" } | Where-Object { $_.data_source_reference -ne $null } ).data_source_reference
                        if ($null -ne $vm_has_iso_attached) {
                            #We have some info about boot ISO attached
                            if ($AdvancedInfo) {
                                Write-Log -Message "[VM Identification] $($VM.status.name) is booting from $($vm_boot_device) and has an ISO image attached. This could indicate a Citrix PVS Device" -Level Info
                            }
                            #Add the machine to the array here as a potential PVS machine
                            $Citrix_PVS_Machines += $VM
                        }
                        else {
                            #We have a CD Rom with no ISO attached
                            if ($AdvancedInfo) {
                                Write-Log -Message "[VM Identification] $($VM.status.name) is booting from $($vm_boot_device) but has no ISO image attached. This machine is not using Citrix PVS Boot ISO" -Level Info
                            }
                        }
                    }
                    elseif ($vm_boot_device -eq "NETWORK") {
                        #We are booting from the Network - Could be a PXE booting machine
                        if ($AdvancedInfo) {
                            Write-Log -Message "[VM Identification] $($VM.status.name) is booting from the network. This could indicate a PVS device" -Level Info
                        }
                        #Add the machine to the array here as a potential PVS machine
                        $Citrix_PVS_Machines += $VM
                    }
                }
                else {
                    #we don't have a list of boot devices
                    if ($AdvancedInfo) {
                        Write-Log -Message "[VM Identification] $($VM.status.name) does not return a list of boot devices. Thus we can't identify it's boot order param set with any confidence" -Level Info
                    }
                }
            }
            elseif ($vm_Boot_type -eq "UEFI" -or $vm_Boot_type -eq "SECUREBOOT") {
                if ($AdvancedInfo) {
                    Write-Log -Message "[VM Identification] $($VM.status.name) has a boot type of $($vm_Boot_type). We cannot determine the boot order at the AHV level." -Level Info
                }
                $vm_has_iso_attached = ($vm.spec.resources.disk_list | Where-Object { $_.device_properties.device_type -eq "CDROM" } | Where-Object { $_.data_source_reference -ne $null } ).data_source_reference
                if ($null -ne $vm_has_iso_attached) {
                    if ($AdvancedInfo) {
                        Write-Log -Message "[VM Identification] $($VM.status.name) has an ISO image attached. This could indicate a Citrix PVS Device depending on boot configuration" -Level Info
                    }
                    #Add the machine to the array here as a potential PVS machine
                    $Citrix_PVS_Machines += $VM
                }
            }
        }
        else {
            #We don't know if this is a UEFI or SecureBoot or Legacy Boot VM, so we won't be able to figure out the boot order
            if ($AdvancedInfo) {
                Write-Log -Message "[VM Identification] $($VM.status.name) has an unknown boot type and thus we can't identify it's boot order param set with any confidence" -Level Info
            }
        }
    }
}

# Machines are neither MCS or PVS so stick them into a General Workload Bucket
foreach ($VM in $VirtualMachines) {
    if ($VM -notin $Citrix_MCS_Machines -and $VM -notin $Citrix_PVS_Machines ) {
        if ($AdvancedInfo) {
            Write-Log -Message "[VM Entity Detail] $($VM.status.name) Identified as a General workload Machine" -Level Info
        }
        $General_Workload_Machines += $VM
    }
}

Write-Log -Message "[VM Entity Detail] Identified $($Citrix_MCS_Machines.Count) Citrix MCS provisioned machines" -Level Info
Write-Log -Message "[VM Entity Detail] Identified $($Citrix_PVS_Machines.Count) potential Citrix PVS provisioned machines based on boot configuration" -Level Info
Write-Log -Message "[VM Entity Detail] Identified $($General_Workload_Machines.Count) General workload Machines" -Level Info
#endregion Categorize Machines

#region Report on Layout
$NtxVirtualMachinesOn = ($VirtualMachines | Where-Object { $_.status.resources.power_state -ne "OFF" }).Count
$NtxVirtualMachinesOff = ($VirtualMachines | Where-Object { $_.status.resources.power_state -eq "OFF" }).Count
Write-Log -Message "[Entity Processing] Processing $($NtxVirtualMachinesOn) powered on entities and ignoring $($NtxVirtualMachinesOff) powered off entities" -Level Info
foreach ($Cluster in $NtxClusters) {
    $ClusterName = $Cluster.status.name
    $ClusterUUID = $Cluster.metadata.uuid
    Write-Log -Message "[Cluster] ---------------------------------------------------------------------------------------------------" -Level Info
    Write-Log -Message "[Cluster] Cluster Details for Cluster: $($ClusterName)" -Level Info
    Write-Log -Message "[Cluster] ---------------------------------------------------------------------------------------------------" -Level Info
    foreach ($ntxHost in ($NtxHosts | Where-Object { $_.status.cluster_reference.uuid -eq $ClusterUUID })) {
        $ntx_host_name = $ntxHost.status.name
        $ntx_host_uuid = $ntxHost.metadata.uuid
        $ntx_host_citrix_mcs_machines = @()
        $ntx_host_general_workload_machines = @()
        $ntx_host_citrix_pvs_machines = @()
        Write-Log -Message "---> [Host] ---------------------------------------------------------------------------------------------------" -Level Info
        Write-Log -Message "---> [Host] Processing Host: $($ntx_host_name)" -Level Info
        Write-Log -Message "---> [Host] DISCLAIMER: PVS checks are rudimentary and should be confirmed" -Level Info
        Write-Log -Message "---> [Host] ---------------------------------------------------------------------------------------------------" -Level Info
        foreach ($vm in $VirtualMachines) {
            if ($vm.status.resources.power_state -ne "OFF") {
                $vm_name = $vm.status.name
                $vm_host_uuid = $vm.status.resources.host_reference.uuid
                if ($vm_host_uuid -eq $ntx_host_uuid) {
                    if ($vm_name -in $Citrix_MCS_Machines.status.name) {
                        $ntx_host_citrix_mcs_machines += $vm
                    }
                    elseif ($vm_name -in $Citrix_PVS_Machines.status.name) {
                        $ntx_host_citrix_pvs_machines += $vm
                    }
                    else {
                        $ntx_host_general_workload_machines += $vm
                    }
                }
            }
        }
        # Output Status Messages
        if (($ntx_host_citrix_mcs_machines.count -gt 0 -or $ntx_host_citrix_pvs_machines.count -gt 0) -and $ntx_host_general_workload_machines.Count -lt 1) {
            Write-Log -Message "---> [Host] [$($ntx_host_name)] contains only Citrix Provisioned Workloads" -Level OK
        } 
        if ($ntx_host_general_workload_machines.Count -gt 0 -and $ntx_host_citrix_mcs_machines.count -lt 1 -and $ntx_host_citrix_pvs_machines.count -lt 1) {
            Write-Log -Message "---> [Host] [$($ntx_host_name)] contains only General workload Machines" -Level OK
        } 
        if (($ntx_host_citrix_mcs_machines.count -gt 0 -or $ntx_host_citrix_pvs_machines.count -gt 0) -and $ntx_host_general_workload_machines.Count -gt 0) {
            Write-Log -Message "---> [Host] [$($ntx_host_name)] contains a mix of Citrix provisioned machines and general workload machines" -Level Warn
        }

        # Output General Counts
        Write-Log -Message "---> [Host] [$($ntx_host_name)] contains $($ntx_host_general_workload_machines.count) general workload machines" -Level Info
        Write-Log -Message "---> [Host] [$($ntx_host_name)] contains $($ntx_host_citrix_mcs_machines.count) Citrix MCS provisioned machines" -Level Info
        Write-Log -Message "---> [Host] [$($ntx_host_name)] contains $($ntx_host_citrix_pvs_machines.count) Citrix PVS provisioned machines" -Level Info

        # Output Detailed VM to Host info
        if ($ShowDetailedVMAlignment -contains "None") {
            Write-Log -Message "---> [Host] [$($ntx_host_name)] No VM to host mapping output selected" -Level Info
        }
        if ($ShowDetailedVMAlignment -contains "All") {
            foreach ($vm in $ntx_host_general_workload_machines) {
                $vm_name = $vm.status.name
                Write-Log -Message "------> [VM] [$($vm_name)] is not a Citrix provisioned machine based on available checks" -Level Info
            }
            foreach ($vm in $ntx_host_citrix_mcs_machines) {
                $vm_name = $vm.status.name
                Write-Log -Message "------> [VM] [$($vm_name)] is a Citrix MCS provisioned machine" -Level MCS_Info
            }
            foreach ($vm in $ntx_host_citrix_pvs_machines) {
                $vm_name = $vm.status.name
                Write-Log -Message "------> [VM] [$($vm_name)] is a potentially a Citrix PVS provisioned machine based on boot config (network or cd-rom with iso)" -Level PVS_Info
            }
        }
        if ($ShowDetailedVMAlignment -contains "General") {
            foreach ($vm in $ntx_host_general_workload_machines) {
                $vm_name = $vm.status.name
                Write-Log -Message "------> [VM] [$($vm_name)] is a general workload machine based on available checks" -Level Info
            }
        }
        if ($ShowDetailedVMAlignment -contains "MCS") {
            foreach ($vm in $ntx_host_citrix_mcs_machines) {
                $vm_name = $vm.status.name
                Write-Log -Message "------> [VM] [$($vm_name)] is a Citrix MCS provisioned machine" -Level MCS_Info
            }
        }
        if ($ShowDetailedVMAlignment -contains "PVS") {
            foreach ($vm in $ntx_host_citrix_pvs_machines) {
                $vm_name = $vm.status.name
                Write-Log -Message "------> [VM] [$($vm_name)] is a potentially a Citrix PVS provisioned machine based on boot config (network or cd-rom with iso)" -Level PVS_Info
            }
        }
    }
}

#endregion Report on Layout

StopIteration
Exit 0
#endregion