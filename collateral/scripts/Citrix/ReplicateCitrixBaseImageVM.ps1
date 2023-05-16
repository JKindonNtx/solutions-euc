<#
.SYNOPSIS
    The script is designed to automate the VM restore and snapshot creation of a Citrix Base Image across multiple Nutanix clusters based on Protection Domain methodology
.DESCRIPTION
    The script will query a single Source Cluster and Protection Domain of which your Citrix Base Image should be a member of. 
    It will figure out all target clusters based on protection Domain remote sites and attempt to restore, snapshot, and delete the protected VM instance leaving a Citrix ready snapshot for CS provisioning.
    The script will handle deletion of existing snapshots based on a retention period (effectively a cleanup mode). This is a destructive operation.
    The script assumes that your Protection Domain configurations are setup correctly. It does not alter, moddify, create or delete any form of PD.
    The script by default attempts to use the latest snapshot on the PD. It compares both source and target to ensure these are inline. You can overrid ethis behaviour with SnapShotID parameter.
.PARAMETER LogPath
    Logpath output for all operations
.PARAMETER LogRollover
    Number of days before logfiles are rolled over. Default is 5.
.PARAMETER SourceCluster
    Mandatory. The source Nutanix PE instance which holds the Citrix base image VM.
.PARAMETER pd
    Mandatory. The Protection Domain on the Source Cluster.
.PARAMETER BaseVM
    Mandatory. The name of the Citrix base image VM. This is CASE SENSITIVE.
.PARAMETER VMPrefix
    Optional. The prefix used for both the restored VM (temp) and the associated Snapshot. The default is ctx_
.PARAMETER SnapshotID
    Optional. If you do not want to use the latest snapshot, specify the appropriate Protection Domain Snapshot ID from the Source Clusters.
.PARAMETER ImageSnapsToRetain
    Optional. The number of snapshots to retain on each target Cluster. This is limited only to snaps meeting the BaseVM and VMPrefix naming patterns (Snapshots the script created).
.PARAMETER SleepTime
    Optional. The amount of time to sleep between VM creation and Snapshot creation tasks. Default is 10 seconds.
.PARAMETER UseCustomCredentialFile
    Optional. Will call the Get-CustomCredentials function which keeps outputs and inputs a secure credential file base on Stephane Bourdeaud from Nutanix functions
.PARAMETER CredPath
    Optional. Used if using the UseCustomCredentialFile parameter. Defines the location of the credential file. The default is "$Env:USERPROFILE\Documents\WindowsPowerShell\CustomCredentials"
.EXAMPLE
    .\ReplicateCitrixBaseVM.ps1 -SourceCluster 10.68.68.40 -pd "W10_Migration_Test" -BaseVM "JK-Test-030" -SnapshotID 353902
.EXAMPLE
    .\ReplicateCitrixBaseVM.ps1 -SourceCluster 10.68.68.40 -pd "W10_Migration_Test" -BaseVM "JK-Test-030" -ImageSnapsToRetain 10
.EXAMPLE
    .\ReplicateCitrixBaseVM.ps1 -SourceCluster 10.68.68.40 -pd "W10_Migration_Test" -BaseVM "JK-Test-030" -ImageSnapsToRetain 10 -UseCustomCredentialFile
.NOTES
    The script is built on the lowest common version of Nutanix PowerShell capability and doesn't use task validation checks etc available in new PowerShell cmdlets
    The script assumes the same username and password on all PE instances
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs\MCSReplicateBaseImage.log", # Where we log to

    [Parameter(Mandatory = $false)]
    [int]$LogRollover = 5, # Number of days before logfile rollover occurs

    [Parameter(Mandatory = $true)]
    [string]$SourceCluster, # The source cluster holding the VM base image

    [Parameter(Mandatory = $true)]
    [string]$pd, # The protection domain holding the base VM

    [Parameter(Mandatory = $true)]
    [string]$BaseVM, # The VM entity name of the base VM

    [Parameter(Mandatory = $false)]
    [string]$VMPrefix = "ctx_", # The prefix name to create for the restored entity and the created snapshots

    [Parameter(Mandatory = $false)]
    [string]$SnapshotID, # The source ID (numerical) of the snapshot to replicate

    [Parameter(Mandatory = $false)]
    [int]$ImageSnapsToRetain, # The number of snapshots to retain. Effectively a cleanup mode

    [Parameter(Mandatory = $false)]
    [int]$SleepTime = 10, # Sleep time operations for VM and snapshot operations

    [Parameter(Mandatory = $false)]
    [switch]$UseCustomCredentialFile, # specifies that a credential file should be used

    [Parameter(Mandatory = $false)]
    [String]$CredPath = "$Env:USERPROFILE\Documents\WindowsPowerShell\CustomCredentials" # Default path for custom credential file
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

#------------------------------------------------------------
# Import Nutanix PowerShell Modules
#------------------------------------------------------------

try {
    Write-Log -Message "[Nutanix PowerShell] Attempting to import Nutanix PowerShell Module" -Level Info
    & 'C:\Program Files (x86)\Nutanix Inc\NutanixCmdlets\powershell\import_modules\ImportModules.PS1' -ErrorAction Stop
    Write-Log -Message "[Nutanix PowerShell] Successfully imported Nutanix PowerShell Module" -Level Info 
}
catch {
    Write-Log -Message "Failed to import Nutanix PowerShell Module" -Level Warn
    Write-Log -Message $_ -Level Warn
    StopIteration
    Exit 1
}

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

#------------------------------------------------------------
# Connect to the Source Cluster
#------------------------------------------------------------
try {
    Write-Log -Message "[Cluster] Connecting to the source Cluster: $($SourceCluster)" -Level Info
    Connect-NTNXCluster -Server $SourceCluster -UserName $PrismCredentials.Username -Password $PrismCredentials.Password -AcceptInvalidSSLCerts -ErrorAction Stop | Out-null
    Write-Log -Message "[Cluster] Successfully connected to the source Cluser: $($SourceCluster)" -Level Info
}
catch {
    Write-Log -Message "[Cluster] Could not connect to the source Cluster: $($SourceCluster) " -Level Warn
    Write-Log -Message $_ -Level Warn
    StopIteration
    Exit 1
}

#------------------------------------------------------------
# Get the protection domain
#------------------------------------------------------------
try {
    Write-Log -Message "[Protection Domain] Getting Protection Domain details for: $($pd) in the source Cluster: $($SourceCluster)" -Level Info
    $ProtectionDomain = Get-NTNXProtectionDomain -Name $pd -Server $SourceCluster -ErrorAction Stop
    
    if ($ProtectionDomain) {
        # may not respond with an error so capturing empty variable
        Write-Log -Message "[Protection Domain] Sucessfully retrieved Protection Domain details for: $($pd) in the source Cluster: $($SourceCluster)" -Level Info
    }
    else {
        Write-Log -Message "[Protection Domain] Failed to get no Protection Domain named: $($pd) on the source Cluster: $($SourceCluster)" -Level Warn
        StopIteration
        Exit 1
    }
}
catch {
    Write-Log -Message "[Protection Domain] Failed to get Protection Domain details for: $($pd) in the source Cluster: $($SourceCluster)" -Level Warn
    Write-Log -Message $_ -Level Warn
    StopIteration
    Exit 1
}

#------------------------------------------------------------
# Get a list of snapshots from the Source
#------------------------------------------------------------
Write-Log -Message "[PD Snapshot] Getting Snapshots on the source Cluster $($SourceCluster)" -Level Info
try {
    $SourceSnaps = Get-NTNXProtectionDomainSnapshot -Servers $SourceCluster -PdName $pd -ErrorAction Stop | Where-Object {$_.State -ne "EXPIRED"}
    if (!$SourceSnaps) {
        # can't process an empty array
        Write-Log -Message "[PD Snapshot] There are no Snapshots on the specified Protection Domain $($pd) in the source Cluster: $($SourceCluster). Terminating" -Level Warn
        StopIteration
        Exit 1
    }
}
catch {
    Write-Log -Message "[PD Snapshot] Failed to retrieve Snapshots on the source Cluster $($SourceCluster)" -Level Warn
    Write-Log -Message $_ -Level Warn
    StopIteration
    Exit 1
}

#------------------------------------------------------------
# Validate the snapshot exists (if specified)
#------------------------------------------------------------
if ($SnapshotID) {
    $SourceSnapExists = $SourceSnaps | where-Object {$_.SnapshotId -like $SnapshotID}
    if ($SourceSnapExists) {
        Write-Log -Message "[PD Snapshot] Snapshot with ID: $($SnapshotID) has been found on the source Cluster: $($SourceCluster)" -Level Info
    }
    else {
        # the snapshot doesnt exist in the source
        Write-Log -Message "[PD Snapshot] Could not find the defined Snapshot on the source Cluster: $($SourceCluster). Terminating" -Level Warn
    }
}

#------------------------------------------------------------
# Find the remote sites
#------------------------------------------------------------
$RemoteSites = Get-NTNXRemoteSite -Server $SourceCluster | Where-Object {$_.name -eq ($ProtectionDomain).remoteSiteNames}

if (!$RemoteSites) {
    Write-Log -Message "[Remote Sites] There are no Remote Sites defined for: $($pd) in the source Cluster: $($SourceCluster)" -Level Warn
    StopIteration
    Exit 1
}

# get a list of the IP addresses
$RemoteSiteIPS = ($remoteSites.remoteIpPorts).Keys

$TotalClusterCount = $RemoteSiteIPS.Count
Write-Log -Message "[Remote Sites] Remote Clusters to process: $($TotalClusterCount)" -Level Info

#------------------------------------------------------------
# Initialise counts and variables
#------------------------------------------------------------
$CurrentClusterCount = 1
$TotalErrorCount = 0 # start the error count
$TotalSuccessCount = 0 # start the succes count
$RunDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" # we want all snapshots across all clusters to have the same timestamp

#------------------------------------------------------------
# Process each Cluster
#------------------------------------------------------------
foreach ($Site in $RemoteSiteIPS){
    $IterationErrorCount = 0 # start the iteration error count

    #------------------------------------------------------------
    # Process the cluster
    #------------------------------------------------------------
    Write-Log -Message "[Cluster] Processing Cluster $($CurrentClusterCount) of $($TotalClusterCount)" -Level Info
    $TargetCluster = $Site
    Write-Log -Message "[Cluster] Connecting to the target Cluster: $($TargetCluster)" -Level Info
    try {
        Connect-NTNXCluster -Server $TargetCluster -UserName $PrismCredentials.Username -Password $PrismCredentials.Password -AcceptInvalidSSLCerts -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Log -Message "[Cluster] Could not connect to the target Cluster: $($TargetCluster) " -Level Warn
        Write-Log -Message $_ -Level Warn
        $IterationErrorCount += 1
        $TotalErrorCount += 1
        Break
    }
    
    # start count for snapshots (how many currently exist)
    Write-Log -Message "[VM Snapshot] There are $((Get-NTNXSnapshot -Server $TargetCluster | Where-Object {$_.snapshotName -like ($VMPrefix + "$BaseVM*")}).Count) Snapshots matching: $($VMPrefix + $BaseVM) on the target Cluster: $($TargetCluster)" -Level Info
    
    #------------------------------------------------------------
    # Get PD snapshots
    #------------------------------------------------------------
    Write-Log -Message "[PD Snapshot] Getting Snapshots on the target Cluster $($TargetCluster)" -Level Info
    try {
        $TargetSnaps = Get-NTNXProtectionDomainSnapshot -Servers $TargetCluster -PdName $pd -ErrorAction Stop | Where-Object {$_.State -ne "EXPIRED"}
        if (!$TargetSnaps) {
            # can't process an empty array
            Write-Log -Message "[PD Snapshot] There are no Snapshots on the specified Protection Domain $($pd) in the target Cluster: $($TargetCluster)" -Level Warn
            $IterationErrorCount += 1
            $TotalErrorCount += 1
            Break
        }
    }
    catch {
        Write-Log -Message "[PD Snapshot] Failed to retrieve Snapshots on the target Cluster: $($TargetCluster)" -Level Warn
        $IterationErrorCount += 1
        $TotalErrorCount += 1
        Break
    }
        
    if ($SnapshotID) {
        # we specified a specific Snapshot ID - Validate Destination Snaps
        $TargetSnapExists = $TargetSnaps | where-Object {$_.SnapshotId -like "*:$SnapshotID"}
        if ($TargetSnapExists) {
            Write-Log -Message "[PD Snapshot] Snapshot with ID: $($SnapshotID) has been found on the target Cluster: $($TargetCluster)" -Level Info
            $SelectedSnapshot = $TargetSnapExists.snapshotId
        }
        else {
            # the snapshot doesnt exist in the target
            Write-Log -Message "[PD Snapshot] Could not find defined Snapshot on the target Cluster: $($TargetCluster). Terminating" -Level Warn
            $IterationErrorCount += 1
            $TotalErrorCount += 1
            Disconnect-NTNXCluster -Server $TargetCluster
            Break
        }
    }
    else {
        # we are using the most recent snapshot matching the name pattern
        Write-Log -Message "[PD Snapshot] Comparing latest PD Snapshot ID in the source: $($SourceCluster) and target: $($TargetCluster) Clusters" -Level Info
        $LatestSourceSnap = $SourceSnaps[0].snapshotId 
        $LatestTargetSnap = ($TargetSnaps[0].snapshotId -split ":")[1]

        if ($LatestTargetSnap -eq $LatestSourceSnap) {
            Write-Log -Message "[PD Snapshot] The latest PD Snapshot ID: $($LatestTargetSnap) on the target Cluster: $($TargetCluster) matches the latest PD Snapshot ID: $($LatestSourceSnap) on the source cluster: $($SourceCluster)" -Level Info
            $SelectedSnapshot = $TargetSnaps[0].snapshotId
        }
        else {
            # snapshots exist in both source and target
            Write-Log -Message "[PD Snapshot] The latest PD Snapshot ID: $($LatestTargetSnap) on the target Cluster: $($TargetCluster) does not match the latest PD Snapshot ID: $($LatestSourceSnap) on the source cluster: $($SourceCluster)" -Level Warn
            Write-Log -Message "[PD Snapshot] Please check Protection Domain replication status for Snapshot consistency. Terminating PD: $($pd) processing on target Cluster $($TargetCluster)" -Level Warn
            $IterationErrorCount += 1
            $TotalErrorCount += 1
            Disconnect-NTNXCluster -Server $TargetCluster
            Break
        }
    }

    #------------------------------------------------------------
    # Restore the instance
    #------------------------------------------------------------
    Write-Log -Message "[VM] Restoring VM: $($BaseVM) from Protection Domain: $($pd) on target Cluster: $($TargetCluster) from Snapshot ID: $($SelectedSnapshot)" -Level Info
    try {
        Restore-NTNXEntity -VmNames $BaseVM -pdName $pd -SnapshotId $SelectedSnapshot -VmNamePrefix $VMPrefix -Server $TargetCluster -ErrorAction Stop | Out-Null
        # wait due to delay
        Write-Log -Message "[VM] Waiting $($SleepTime) seconds for VM creation of: $($VMPrefix + $BaseVM) to finalise on target Cluster: $($TargetCluster)" -Level Info
        Start-Sleep $SleepTime
        Write-Log -Message "[VM] Successfully restored VM: $($VMPrefix + $BaseVM) on target Cluster: $($TargetCluster)" -Level Info
    }
    catch {
        Write-Log -Message "[VM] Failed to restore VM: $($BaseVM) from Protection Domain: $($pd) on target Cluster: $($TargetCluster) from Snapshot ID: $($SelectedSnapshot)" -Level Warn
        Write-Log -Message $_ -level Warn
        $IterationErrorCount += 1
        $TotalErrorCount += 1
        Disconnect-NTNXCluster -Server $TargetCluster
        Break
    }

    #------------------------------------------------------------
    # Take a snaphot
    #------------------------------------------------------------
    $vm = Get-NTNXVM -SearchString ($VMPrefix + $BaseVM) -Server $TargetCluster
    if (!$vm) {
        #couldn't find the VM
        Write-Log -Message "[VM] Could not find the VM: $($VMPrefix + $BaseVM) on the target Cluster: $($TargetCluster)" -Level Warn
        $IterationErrorCount += 1
        $TotalErrorCount += 1
        Disconnect-NTNXCluster -Server $TargetCluster
        Break
    }

    # handle multiple vm match
    if ($vm.count -gt 1) {
        Write-Log -Message "[VM] There are $($vm.Count) vm entities found. Doing a direct name match to identify VM" -Level Info
        $vm = $vm | where-Object {$_.vmName -eq $VMPrefix + $BaseVM}
    }

    # create snapshot config
    Write-Log -Message "[VM Snapshot] Creating Snapshot spec and creating Snapshot on the target Cluster: $($TargetCluster)" -Level Info
    $snapshotName = $vm.vmName + "_" + $RunDate
    $newSnapshot = New-NTNXObject -Name SnapshotSpecDTO
    $newSnapshot.vmuuid = $vm.uuid
    $newSnapshot.snapshotname = $snapshotName
    # take the snapshot
    try {
        New-NTNXSnapshot -SnapshotSpecs $newSnapshot -Server $TargetCluster -ErrorAction Stop | Out-Null
        Write-Log -Message "[VM Snapshot] Waiting $($SleepTime) seconds for Snapshot creation of: $($snapshotName) to finalise on the target Cluster: $($TargetCluster)" -Level Info
        Start-Sleep $SleepTime
        Write-Log -Message "[VM Snapshot] Sucessfully created Snapshot: $($snapshotName) on the target Cluster: $($TargetCluster)" -Level Info
    }
    catch {
        Write-Log -Message "[VM Snapshot] Failed to create Snapshot: $($snapshotName) on the target Cluster: $($TargetCluster) " -Level Warn
        Write-Log -Message $_ -level Warn
        $IterationErrorCount += 1
        $TotalErrorCount += 1
        Disconnect-NTNXCluster -Server $TargetCluster
        Break
    }
    
    #------------------------------------------------------------    
    # Remove the VM
    #------------------------------------------------------------
    Write-Log -Message "[VM] Removing Temp VM: $($vm.vmName) on the target Cluster: $($TargetCluster)" -Level Info
    try {
        Remove-NTNXVirtualMachine -Vmid $vm.uuid -Server $TargetCluster -ErrorAction Stop | Out-Null
        Write-Log -Message "[VM] Successfully removed Temp VM: $($vm.vmName) on the target Cluster: $($TargetCluster)" -Level Info
    }
    catch {
        Write-Log -Message "[VM] Failed to remove Temp VM: $($vm.vmName) on the target Cluster: $($TargetCluster)" -Level Warn
        Write-Log -Message $_ -level Warn
        $IterationErrorCount += 1
        $TotalErrorCount += 1
        Disconnect-NTNXCluster -Server $TargetCluster
        Break
    }

    # end count for snapshots (how many currently exist)
    Write-Log -Message "[VM Snapshot] There are now: $((Get-NTNXSnapshot -Server $TargetCluster | Where-Object {$_.snapshotName -like ($VMPrefix + "$BaseVM*")}).Count) Snapshots matching $($VMPrefix + $BaseVM) on cluster $($TargetCluster)" -Level Info
    
    #------------------------------------------------------------
    # Handle the deletion of snapshot retention if set
    #------------------------------------------------------------
    if ($ImageSnapsToRetain) {
        Write-Log -Message "[VM Snapshot] Removing Snapshots that do not meet the retention value: $($ImageSnapsToRetain) on the target Cluster: $($TargetCluster)" -Level Info

        $ImageSnapsOnTarget = Get-NTNXSnapshot -Server $TargetCluster | Where-Object { $_.snapshotName -like ($VMPrefix + "$BaseVM*") }
        $ImageSnapsOnTargetToRetain = $ImageSnapsOnTarget | Sort-Object -Property createdTime -Descending | Select-Object -First $ImageSnapsToRetain

        $ImageSnapsOnTargetToDelete = @() #Initialise the delete array
        foreach ($snap in $ImageSnapsOnTarget) {
            # loop through each snapshot and add to delete array if not in the ImageSnapsOnTargetToRetain array
            if ($snap -notin $ImageSnapsOnTargetToRetain) {
                Write-Log -Message "[VM Snapshot] Adding Snapshot: $($snap.snapshotName) to the delete list" -Level Info
                $ImageSnapsOnTargetToDelete += $snap
            }
        }

        Write-Log -Message "[VM Snapshot] There are $($ImageSnapsOnTargetToDelete.Count) Snapshots to delete based on a retention value of $($ImageSnapsToRetain) on the target Cluster: $($TargetCluster)" -Level Info
        $SnapShotsDeletedOnTarget = 0
        $SnapShotsFailedToDeleteOnTarget = 0
        if ($ImageSnapsOnTargetToDelete.Count -gt 0) {
            foreach ($Snap in $ImageSnapsOnTargetToDelete) {
                # process the snapshot deletion
                Write-Log -Message "[VM Snapshot] Processing deletion of Snapshot: $($snap.snapshotName) on the target Cluster: $($TargetCluster)" -Level Info
                try {
                    Remove-NTNXSnapshot -Uuid $snap.uuid -Server $TargetCluster -ErrorAction Stop | Out-Null
                    Write-Log -Message "[VM Snapshot] Successfully deleted Snapshot: $($snap.snapshotName) on the target Cluster: $($TargetCluster)" -Level Info
                    $SnapShotsDeletedOnTarget += 1
                }
                catch {
                    Write-Log -Message "[VM Snapshot] Failed to delete vm Snapshot: $($snap.snapshotName) on the target Cluster: $($TargetCluster)" -Level Warn
                    Write-Log -Message $_ -level Warn
                    $SnapShotsFailedToDeleteOnTarget += 1
                    Break
                }
            }
        }
        else {
            Write-Log -Message "[VM Snapshot] There are no Snapshots to delete based on the retention value of: $($ImageSnapsToRetain) on the target Cluster: $($TargetCluster)" -Level Info
        }

        Write-Log "[Data] Sucessfully deleted: $($SnapShotsDeletedOnTarget) Snapshots on the target Cluster: $($TargetCluster)" -Level Info
        if ($SnapShotsFailedToDeleteOnTarget -gt 0) {
            Write-Log -Message "[Data] Encountered $($SnapShotsFailedToDeleteOnTarget.Count) VM Snapshot deletion errors. Please review log file $($LogPath) for failures" -Level Info
        }
    }
    else {
        Write-Log -Message "[VM Snapshot] Cleanup (ImageSnapsToRetain) not specified. Nothing to process." -Level Info
    }
    
    #------------------------------------------------------------
    # Disconnect from the cluster
    #------------------------------------------------------------
    Write-Log -Message "[Cluster] Disconnecting from the target Cluster: $($TargetCluster)" -Level Info
    Disconnect-NTNXCluster -Server $TargetCluster

    #------------------------------------------------------------
    # Update the processed cluster counts
    #------------------------------------------------------------
    if ($IterationErrorCount -eq 0) {
        $TotalSuccessCount += 1
    }
    $CurrentClusterCount += 1
}

Write-Log -Message "[Data] Successfully processed $($TotalSuccessCount) Clusters" -Level Info
Write-Log -Message "[Data] Encountered $($TotalErrorCount) errors. Please review log file $($LogPath) for failures" -Level Info

StopIteration
#endregion
