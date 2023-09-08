<#
.SYNOPSIS
    Sadly this script is written to handle RAS leaving orphaned VM instances throughout Nutanix AHV clusters. The idea is that this script will delete all virtual machines matching the provided naming pattern.
.DESCRIPTION
    RAS provisioning is conistently leaving oprhaned VMs in Nutanix AHV. 
    This script will take a name pattern input, query the Nutanix Cluster specified for any machines matching the target names and will delete the powered instances.
    Once the machine is deleted, RAS provisioner will handle the removal of the vm from it's database if it's still there.
.PARAMETER LogPath
    Optional. Logpath output for all operations. Default is C:\Logs\DeleteRASProvisionedMachines.log
.PARAMETER LogRollover
    Optional. Number of days before logfiles are rolled over. Default is 5.
.PARAMETER UseCustomCredentialFile
    Optional. Will call the Get-CustomCredentials function which keeps outputs and inputs a secure credential file base on Stephane Bourdeaud from Nutanix functions
.PARAMETER CredPath
    Optional. Used if using the UseCustomCredentialFile parameter. Defines the location of the credential file. The default is "$Env:USERPROFILE\Documents\WindowsPowerShell\CustomCredentials"
.PARAMETER SourceCluster
    Mandatory. The target Nutanix Cluster hosting the machines to target.
.PARAMETER NamePattern
    Mandatory. The name pattern to match vms against. Eg. W10-RAS-LC*
.PARAMETER Whatif
    Optional. Will action the script in a whatif processing mode only.
.PARAMETER APICallVerboseLogging
    Optional. Will output all API calls with verbose detail.
.EXAMPLE
    & '.\DeleteRASProvisionedMachines.ps1' -SourceCluster 10.56.68.195 -NamePattern "W10-RAS-LC*" -APICallVerboseLogging -Whatif
    Process the 10.56.68.195 Prism Element, match machines based on W10-RAS-LC* (the RAS naming standard), operating in whatif mode and output all API Calls for the nerds that are interested. It will prompt for credentials.
.EXAMPLE
    & '.\DeleteRASProvisionedMachines.ps1' -SourceCluster 10.56.68.195 -NamePattern "W10-RAS-LC*" -APICallVerboseLogging
    Process the 10.56.68.195 Prism Element, match machines based on W10-RAS-LC* (the RAS naming standard) and output all API Calls for the nerds that are interested. This WILL execute the deletion of duplicated VMs. It will prompt for credentials.
.EXAMPLE
    & '.\DeleteRASProvisionedMachines.ps1' -SourceCluster 10.56.68.195 -NamePattern "W10-RAS-LC*" -APICallVerboseLogging -UseCustomCredentialFile
    Process the 10.56.68.195 Prism Element, match machines based on W10-RAS-LC* (the RAS naming standard) and output all API Calls for the nerds that are interested. This WILL execute the deletion of duplicated VMs. It will use a custom credential file (if not found, will prompt and create)
.NOTES
    Author: James Kindon
    Date: 08.09.2023
    Motivation: Sadness at RAS failure
    Expected Use: Performance Testing Team
    Guidance: RTFM
    Extra Guidance: RTFM again.
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs\DeleteRASProvisionedMachines.log", # Where we log to

    [Parameter(Mandatory = $false)]
    [int]$LogRollover = 5, # Number of days before logfile rollover occurs

    [Parameter(Mandatory = $true)]
    [string]$SourceCluster, # The source cluster holding the VM base image

    [Parameter(Mandatory = $true)]
    [string]$NamePattern, # Pattern Match of machines to kill - Eg. W10-RAS-LC*

    [Parameter(Mandatory = $false)]
    [switch]$UseCustomCredentialFile, # specifies that a credential file should be used

    [Parameter(Mandatory = $false)]
    [String]$CredPath = "$Env:USERPROFILE\Documents\WindowsPowerShell\CustomCredentials", # Default path for custom credential file
    
    [Parameter(Mandatory = $false)]
    [switch]$APICallVerboseLogging, # Show the API calls being made

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
        [ValidateSet("Error", "Warn", "Info")]
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
                Write-Error $Message
                $LevelText = 'ERROR:'
            }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
            }
            'Info' {
                Write-Verbose $Message
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
            #Write-LogOutput -Category INFO -Message "$(get-date) [INFO] Set path to $path"
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
            Write-Log -Message "Payload: $payload" -Level Info
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

function GetPrismv2Task {
    param (
        [parameter(mandatory = $true)]
        [string]$TaskID, #ID of the task to grab

        [parameter(mandatory = $true)]
        [string]$Cluster,

        [parameter(mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential
    )

    $Method = "GET"
    $RequestUri = "https://$($Cluster):9440/PrismGateway/services/rest/v2.0/tasks/$($TaskId)"
    $Payload = $null
    try {
        $TaskStatus = InvokePrismAPI -Method $Method -Url $RequestUri -Payload $Payload -Credential $Credential -ErrorAction Stop
        Write-Log -Message "$($Phase) Monitoring task: $($TaskId)"
        while ($TaskStatus.progress_status -ne "SUCCEEDED") {
            if ($TaskStatus.progress_status -ne "FAILED") {
                Write-Log -Message "$($Phase) Task Status is: $($TaskStatus.progress_status). Waiting for Task completion. Status: $($TaskStatus.percentage_complete)% complete" -Level Info
            }
            elseif ($TaskStatus.progress_status -eq "FAILED") {
                Write-Log -Message "$($Phase) Task Status is: FAILED" -level Warn
                StopIteration
                Exit 1
            }
            Start-Sleep $SleepTime
            $TaskStatus = InvokePrismAPI -Method $Method -Url $RequestUri -Payload $Payload -Credential $Credential -ErrorAction Stop
        }
        if ($TaskStatus.progress_status -eq "SUCCEEDED") {
            Write-Log -Message "$($Phase) Task status is: $($TaskStatus.progress_status). $PhaseSuccessMessage" -Level Info
        }
    }
    catch {
        Write-Log -Message "$($Phase) Failed to get task status for task ID: $($TaskId)" -Level Warn
        StopIteration
        Exit 1
    }     
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

function Write-CustomPrompt {
    <#
    .SYNOPSIS
    Creates a user prompt with a yes/no/skip response. Returns the response.

    .DESCRIPTION
    Creates a user prompt with a yes/no/skip response. Returns the response in lowercase. Valid responses are "y" for yes, "n" for no, "s" for skip.

    .NOTES
    Author: Stephane Bourdeaud (sbourdeaud@nutanix.com)

    .EXAMPLE
    .\Write-CustomPrompt
    Creates the prompt.

    .LINK
    https://github.com/sbourdeaud
    #>
    [CmdletBinding(DefaultParameterSetName = 'None')] #make this function advanced

    param 
    (
        [Switch]$skip
    )

    begin {
        [String]$userChoice = "" #initialize our returned variable
    }
    process {
        if ($skip) {
            do { $userChoice = Read-Host -Prompt "Do you want to continue? (Y[es]/N[o]/S[kip])" } #display the user prompt
            while ($userChoice -notmatch '[ynsYNS]') #loop until the user input is valid
        }
        else {
            do { $userChoice = Read-Host -Prompt "Do you want to continue? (Y[es]/N[o])" } #display the user prompt
            while ($userChoice -notmatch '[ynYN]') #loop until the user input is valid
        }
        $userChoice = $userChoice.ToLower() #change to lowercase
    }
    end {
        return $userChoice
    }

} #this function is used to prompt the user for a yes/no/skip response in order to control the workflow of a script

#endregion

#region Variables
# ============================================================================
# Variables
# ============================================================================

#endregion

#Region Execute
# ============================================================================
# Execute
# ============================================================================
StartIteration

if ($PSVersionTable.PSVersion.Major -lt 5) { throw "$(get-date) [ERROR] Please upgrade to Powershell v5 or above (https://www.microsoft.com/en-us/download/details.aspx?id=50395)" }

#region script parameter reporting
#------------------------------------------------------------
# Script processing detailed reporting
#------------------------------------------------------------
Write-Log -Message "[Script Params] Logging Script Parameter configurations" -Level Info
Write-Log -Message "[Script Params] Script LogPath = $($LogPath)" -Level Info
Write-Log -Message "[Script Params] Script LogRollover = $($LogRollover)" -Level Info
Write-Log -Message "[Script Params] Script Whatif = $($Whatif)" -Level Info
Write-Log -Message "[Script Params] Script APICallVerboseLogging = $($APICallVerboseLogging)" -Level Info
Write-Log -Message "[Script Params] Nutanix Cluster = $($SourceCluster)" -Level Info
Write-Log -Message "[Script Params] Nutanix Custom Credential File = $($UseCustomCredentialFile)" -Level Info
Write-Log -Message "[Script Params] Nutanix Custom Credential Path = $($CredPath)" -Level Info
Write-Log -Message "[Script Params] Nutanix VM Name Pattern Match = $($NamePattern) " -Level Info

#endregion script parameter reporting

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
    $PrismCreds = "prism-creds"
    Write-Log -Message "[Credentials] UseCustomCredentialFile has been selected. Attempting to retrieve credential object" -Level Info
    try {
        $PrismCredentials = Get-CustomCredentials -credname $PrismCreds -ErrorAction Stop
    }
    catch {
        Set-CustomCredentials -credname $PrismCreds
        $PrismCredentials = Get-CustomCredentials -credname $PrismCreds -ErrorAction Stop
    }
} 
else {
    Write-Log -Message "[Credentials] Prompting user for Prism credentials" -Level Info
    $PrismCredentials = Get-Credential -Message "Enter Credentials for Prism Element Instances"
    if (!$PrismCredentials) {
        Write-Log -Message "[Credentials] Failed to set user credentials" -Level Warn
        StopIteration
        Exit 1
    }
}
#endregion Authentication

#region Connect to Source Cluster
#------------------------------------------------------------
# Connect to the Source Cluster
#------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------
# Set API call detail
#----------------------------------------------------------------------------------------------------------------------------
$Method = "GET"
$RequestUri = "https://$($SourceCluster):9440/PrismGateway/services/rest/v2.0/cluster"
$Payload = $null # we are on a get run
#----------------------------------------------------------------------------------------------------------------------------
try {
    Write-Log -Message "[Source Cluster] Connecting to the source Cluster: $($SourceCluster)" -Level Info
    $Cluster = InvokePrismAPI -Method $Method -Url $RequestUri -Payload $Payload -Credential $PrismCredentials -ErrorAction Stop
    Write-Log -Message "[Source Cluster] Successfully connected to the source Cluser: $($SourceCluster)" -Level Info
}
catch {
    Write-Log -Message "[Source Cluster] Could not connect to the source Cluster: $($SourceCluster) " -Level Warn
    Write-Log -Message $_ -Level Warn
    StopIteration
    Exit 1
}
#endregion Connect to Source Cluster

#region Get Virtual Machines
#------------------------------------------------------------
# Get Virtual Machines
#------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------
# Set API call detail
#----------------------------------------------------------------------------------------------------------------------------
$Method = "GET"
$RequestUri = "https://$($SourceCluster):9440/PrismGateway/services/rest/v2.0/vms"
$Payload = $null # we are on a get run
#----------------------------------------------------------------------------------------------------------------------------
try {
    Write-Log -Message "[Source Cluster] Getting a list of Virtual Machines from Source Cluster: $($SourceCluster)" -Level Info
    $VirtualMachines = InvokePrismAPI -Method $Method -Url $RequestUri -Payload $Payload -Credential $PrismCredentials -ErrorAction Stop
}
catch {
    Write-Log -Message "[Source Cluster] Could not list of Virtual Machines from the source Cluster: $($SourceCluster) " -Level Warn
    Write-Log -Message $_ -Level Warn
    StopIteration
    Exit 1
}

if ($VirtualMachines) {
    Write-Log -Message "[Source Cluster] Successfully retreived Virtual machines from the source Cluster: $($SourceCluster)" -Level Info
}
else {
    Write-Log -Message "[Source Cluster] No Virtual machines returned from the source Cluster: $($SourceCluster)" -Level Warn
}

$VirtualMachines = $VirtualMachines.entities

#endregion Get Virtual Machines

#region Sort and Filter Virtual Machines

Write-Log -Message "[VM] Filtering Machines based on name pattern: $($NamePattern)" -Level Info
$ScopedVirtualMachines = $VirtualMachines | Where-Object { $_.name -like $NamePattern }
Write-Log -Message "[VM] There are $($ScopedVirtualMachines.Count) machines matching name pattern: $($NamePattern)" -Level Info

$ScopedVirtualMachines = $ScopedVirtualMachines | Sort-Object -Property name

#endregion Sort and Filter Virtual Machines

#region Delete Virtual Machines
$DeleteInstancesCount = 0

#Add an extra special deletion confirmation check
if ($ScopedVirtualMachines.Count -gt 0) {
    if (!$Whatif) {
        Write-Log -Message "[VM DELETION WARNING] VM deletion Will occur. Are you sure about this?" -Level Info
        $myvar_user_choice = Write-CustomPrompt
        if ($myvar_user_choice -ieq "n") { 
            Write-Log -Message "[VM DELETION WARNING] VM deletion has not been confirmed. Good call." -Level Info
            StopIteration
            Exit 0 
        }
        else {
            Write-Log -Message "[VM DELETION WARNING] VM deletion has been confirmed. It shall be so" -Level Info
        }
    }
}

foreach ($TargetVM in $ScopedVirtualMachines) {
    $vm_name = $TargetVM.name
    $vm_uuid = $TargetVM.uuid
    if (!$Whatif) {
        #we are processing
        Write-Log -Message "[VM: $($vm_name)] With uuid: $($vm_uuid) will be deleted" -Level Info
        #----------------------------------------------------------------------------------------------------------------------------
        # Set API call detail
        #----------------------------------------------------------------------------------------------------------------------------
        $Method = "DELETE"
        $RequestUri = "https://$($SourceCluster):9440/PrismGateway/services/rest/v2.0/vms/$($vm_uuid)?delete_snapshots=true"
        $Payload = $null # we are on a delete run
        #----------------------------------------------------------------------------------------------------------------------------
        try {
            Write-Log -Message "[VM: $($vm_name)] Trying to delete VM on source Cluster: $($SourceCluster)" -Level Info
            $DeleteVM = InvokePrismAPI -Method $Method -Url $RequestUri -Payload $Payload -Credential $PrismCredentials -ErrorAction Stop

            #Get the status of the task above
            $TaskId = $DeleteVM.task_uuid
            $Phase = "[VM: $($vm_name)]"
            $PhaseSuccessMessage = "VM: $($vm_name) has been deleted"

            GetPrismv2Task -TaskID $TaskId -Cluster $SourceCluster -Credential $PrismCredentials

            $DeleteInstancesCount += 1
        }
        catch {
            Write-Log -Message "[VM: $($vm_name)] failed to delete the VM on source Cluster: $($SourceCluster) " -Level Warn
            Write-Log -Message $_ -Level Warn
        }
    }
    else {
        #We are in whatif mode
        Write-Log -Message "[WHATIF: VM: $($vm_name)] With uuid: $($vm_uuid) would be deleted" -Level Info
        $DeleteInstancesCount += 1
    }
}

#endregion Delete Virtual Machines

if (!$Whatif) {
    #we are processing
    Write-Log -Message "[Summary] Deleted $($DeleteInstancesCount) machines from source Cluster $($SourceCluster)" -Level Info
}
else {
    #we are in whatif mode
    Write-Log -Message "[WHATIF: Summary] Would have deleted $($DeleteInstancesCount) machines from source Cluster $($SourceCluster)" -Level Info

}

StopIteration
Exit 0
#endregion
