<#
.SYNOPSIS
    Migrates Dedicated MCS provisioned machines to a manual provisioned catalog and delivery gruop
.DESCRIPTION
    Loops through source catalog, removes the VM from existing delivery group, moves to a new catalog, handles provisioning relics, adds to new delivery group with user assignments retained
.PARAMETER LogPath
    Logpath output for all operations
.PARAMETER LogRollover
    Number of days before logfiles are rolled over. Default is 5
.PARAMETER JSON
    Will consume a JSON import for configuration
.PARAMETER JSONInputPath
    Specifies the JSON input file
.PARAMETER SourceCatalog
    Specifies the source catalog for MCS machines
.PARAMETER TargetCatalog
    Specifies the target catalog for machines migrated from MCS
.PARAMETER TargetDeliveryGroup
    Specifies the target Delivery Group for migrated machines
.PARAMETER OverridePublishedName
    Switch to allow overriding the published desktop name with a new value (-PublishedName) else will consume existing published name
.PARAMETER SetPublishedNameToMachineName
    Switch to force set the published name to the VM name
.PARAMETER PublishedName
    Value for the new published name
.PARAMETER Controller
    Value for the Delivery Controller to Target, Eg, DDC1
.PARAMETER TargetMachineScope
    Specifies how machines are handled, either All, MachineList or CSV. Defaults to All.
        'All', then all machines in source catalog will be targeted
        'MachineList", an array of defined machines to target
        'CSV" a CSV input of machines to target. Used in conjunction with TargetMachineCSVList Param
.PARAMETER TargetMachines
    An array of machines to target
.PARAMETER TargetMachineCSVList
    Target CSV File for machine targets. Used in conjunction with the TargetMachineScope Param when using the CSV value
.EXAMPLE
    .\MigrateMCSToManual -SourceCatalog "Kindon-Azure-SouthEastAsia-Dedicated-MCS" -TargetCatalog "Kindon-Azure-SouthEastAsia-Dedicated" -TargetDeliveryGroup ""Kindon-Azure-ASR-Failover" -SetPublishedNameToMachineName -Controller DDC1
    Migrates vm's from source catalog, moves to target catalog and target delivery group and sets the published name to the VM name using the Controller DDC1
.EXAMPLE
    .\MigrateMCSToManual -JSON -JSONInputPath 'C:\Temp\ASE-MCS.json' -Controller DDC1
    Migrates vm's based on JSON input using the Controller DDC1
.EXAMPLE
    .\MigrateMCSToManual -SourceCatalog "Kindon-Azure-SouthEastAsia-Dedicated-MCS" -TargetCatalog "Kindon-Azure-SouthEastAsia-Dedicated" -TargetDeliveryGroup ""Kindon-Azure-ASR-Failover" -OverridePublishedName -PublishedName "MyVM" -Controller DDC1
    Migrates vm's from source catalog, moves to target catalog and target delivery group and sets the published name to MyVM using the Controller DDC1
.NOTES
    Script has been designed for Citrix Cloud, but should work fine for On-Prem deployments if run on a delivery controller 
.NOTES
    ChangeLog: Nutanix
        [17.04.23, James Kindon] Add Controller Parameter (localhost by default)
        [17.04.23, James Kindon] Add TargetMachineScope, TargetMachines and TargetMachineCSVList Parameters and altered filtering logic for Get VM's
    To do:
        - Add creation of Machine Catalog and Desktop Group
        - Investigate the need for the GetUpdatedCatalogAccountIdentityPool Function. Might not be needed anymore
        - Validate the Published Desktop Name Logic
            - What happens if the PublishedName attribute is blank on the VM (takes it from the DG) and the new DG name is different
            - Should I kill the Switch Param for OverridePublishedName - seems to be silly looking at it now - just use -PublishedName
            - Should we add a parameter to
                - Update the target delivery group published name with the old delivery group (switch) -UpdateDGPublishednameWithSourceDGPublishedName
                - Report in Verbose Fashion that this is going to be a problem if the above switch is not specified
                - Set PublishedName on each Migrated VM to that of the Source Desktop Group - Verbosely yell that new machines are going to be impacted?
        - Validate Catalog Types - We check for manual catalog, but need to validate hosting connection is going to the same cluster as the same as that used on the Source Catalog maybe? What happens if one use IP and one uses name or HTTPS vs HTTP etc? 
            - Maybe an override switch -IgnoreCatalogHostingConnectionDiscrepency? Does this even matter given you could have two hosting connections to the same place and things would work - thoughts....
            - Need to check for "CatalogKind" = PowerManaged
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs\MCSMigration.log", 

    [Parameter(Mandatory = $false)]
    [int]$LogRollover = 5, # number of days before logfile rollover occurs

    [Parameter(Mandatory = $false)]
    [String]$Controller = "localhost", # AdminAddress for the Controller

    [Parameter(Mandatory = $false, ParameterSetName = 'JSON')]
    [Switch]$JSON,

    [Parameter(Mandatory = $true, ParameterSetName = 'JSON')]
    [String]$JSONInputPath,

    [Parameter(Mandatory = $false)] [ValidateSet('All', 'MachineList', 'CSV')]
    [String]$TargetMachineScope = "All", # Target Machine Scopes for Migration

    [Parameter(Mandatory = $false)]
    [Array]$TargetMachines, # Array of machines to target

    [Parameter(Mandatory = $false)]
    [String]$TargetMachineCSVList, # Target CSV File for TargetMachineScope

    [Parameter(Mandatory = $false, ParameterSetName = 'NoJSON')]
    [String]$SourceCatalog,

    [Parameter(Mandatory = $false, ParameterSetName = 'NoJSON')]
    [String]$TargetCatalog,

    [Parameter(Mandatory = $false, ParameterSetName = 'NoJSON')]
    [String]$TargetDeliveryGroup,

    [Parameter(Mandatory = $false, ParameterSetName = 'NoJSON')]
    [Parameter(ParameterSetName = 'JSON')]
    [Parameter(ParameterSetName = 'ReplacePublishedName')]
    [Switch]$SetPublishedNameToMachineName,

    [Parameter(Mandatory = $false, ParameterSetName = 'NoJSON')]
    [Parameter(ParameterSetName = 'ManualPublishedName')]
    [Switch]$OverridePublishedName,

    [Parameter(Mandatory = $false, ParameterSetName = 'NoJSON')]
    [Parameter(ParameterSetName = 'ManualPublishedName')]
    [String]$PublishedName
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

function ImportModule {
    Write-Log -Message "Importing $ModuleName Module" -Level Info
    try {
        Import-Module -Name $ModuleName -Force -ErrorAction Stop
    }
    catch {
        Write-Log -Message "Failed to Import $ModuleName Module. Exiting" -Level Warn
        Exit 1
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

function AddVMtoCatalog {
    if ($null -eq (Get-BrokerMachine -MachineName $VM.MachineName -AdminAddress $Controller -ErrorAction SilentlyContinue)) {
        Write-Log -Message "$($VM.MachineName): Adding to Catalog $($NewCatalog.Name)" -Level Info
        try {
            $null = New-BrokerMachine -CatalogUid $NewCatalog.Uid -HostedMachineId $VM.HostedMachineId -HypervisorConnectionUid $VM.HypervisorConnectionUid -MachineName $VM.SID -AdminAddress $Controller -Verbose -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Warn
        }
    }
    else {
        $ExistingCatalog = (Get-BrokerMachine -MachineName $VM.MachineName -AdminAddress $Controller ).CatalogName
        Write-Log -Message "$($VM.MachineName): Already exists in catalog $($ExistingCatalog)" -Level Warn
    }
}

function AddVMtoDeliveryGroup {
    $DG = (Get-BrokerMachine -MachineName $VM.MachineName -AdminAddress $Controller ).DesktopGroupName
    if ($null -eq $DG) {
        Write-Log -Message "$($VM.MachineName): Adding to Delivery Group $($DeliveryGroup.Name)" -Level Info
        try {
            Add-BrokerMachine -MachineName $VM.MachineName -DesktopGroup $DeliveryGroup.Name -AdminAddress $Controller -Verbose -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Warn
        }
    }
    else {
        Write-Log -Message "$($VM.MachineName): Already a member of: $DG" -Level Warn
    } 
}

function AddUsertoVM {
    Write-Log -Message "$($VM.MachineName): Processing User Assignments" -Level Info
    $AssignedUsers = $VM.AssociatedUserNames
    if ($AssignedUsers) {
        foreach ($User in $AssignedUsers) {
            Write-Log -Message "$($VM.MachineName): Adding $($User)" -Level Info
            try {
                Add-BrokerUser $User -PrivateDesktop $VM.MachineName -AdminAddress $Controller -Verbose -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Warn
            }
        }
    }
    else {
        Write-Log -Message "$($VM.MachineName): There are no user assignments defined" -Level Warn
    }
}

function SetVMDisplayName {
    #Need to think about this more and compare with Delivery GroupName
    if ($null -ne $PublishedName) {
        Write-Log -Message "$($VM.MachineName): Setting Published Name to $PublishedName" -Level Info
        try {
            Set-BrokerMachine -MachineName $VM.MachineName -PublishedName $PublishedName -AdminAddress $Controller -Verbose -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -level Warn
        }
    }
    else {
        Write-Log -Message "$($VM.MachineName): No Published name specified" -Level Info
    }
}

function LoadCitrixSnapins {
    try {
        Write-Log -Message "Loading Citrix Snapins" -Level Info
        Add-PSSnapin citrix*
    }
    catch {
        Write-Log -Message $_ -Level Warn
        StopIteration
        Exit 1
    }
}

function TryForAuthentication {
    try {
        Write-Log -Message "Confirming Authentication with Citrix Cloud" -Level Info
        $null = Get-BrokerSite -AdminAddress $Controller -ErrorAction Stop # This should trigger an auth call if session has timed out (else Get-XDAuthentication)
    }
    catch [Citrix.Broker.Admin.SDK.SdkOperationException] {
        try {
            Get-XDAuthentication
        }
        catch {
            Write-Log -Message $_ -Level Warn
            StopIteration
            Exit 1    
        }
    }
    catch {
        Write-Log -Message $_ -Level Warn
        StopIteration
        Exit 1
    }
}

function CheckCatalogIsMCS {
    if ($Catalog.ProvisioningType -eq "MCS" -and $Catalog.PersistUserChanges -eq "OnLocal") {
        Write-Log "Source Catalog: $($Catalog.Name) is an MCS catalog. Proceeding" -Level Info
    }
    elseif ($Catalog.ProvisioningType -eq "MCS" -and $Catalog.PersistUserChanges -eq "Discard") {
        Write-Log "Source Catalog: $($Catalog.Name) is a non persistent MCS catalog. Exiting Script" -Level Warn
        StopIteration
        Exit 1
    }
    elseif ($Catalog.ProvisioningType -ne "MCS") {
        Write-Log "Source Catalog: $($Catalog.Name) is not an MCS catalog. Exiting Script" -Level Warn
        StopIteration
        Exit 1
    }
}

function CheckCatalogisManual {
    if ($NewCatalog.ProvisioningType -eq "Manual") {
        Write-Log -Message "Target Catalog: $($NewCatalog.Name) is a Manual Catalog. Proceeding" -Level Info
    }    
    else {
        Write-Log -Message "Target Catalog: $($NewCatalog.Name) is provisioned catalog and cannot be used in a supported fashion. Exiting Script" -Level Warn
        StopIteration
        Exit 1
    }
}

function RemoveMCSProvisionedMachine {
    Write-Log -Message "Processing $($VM.MachineName)" -Level Info
    # Set Maintenance Mode
    try {
        Write-Log -Message "$($VM.MachineName): Setting Maintenance Mode to On" -Level Info
        Set-BrokerMachine -MachineName $VM.MachineName -InMaintenanceMode $true -AdminAddress $Controller
    }
    catch {
        Write-Log -Message $_ -Level Warn
        $ErrorCount += 1
    }
    # Remove from Desktop Group
    try {
        if ($VM.DesktopGroupName) {
            Write-Log -Message "$($VM.MachineName): Removing from Delivery Group $($VM.DesktopGroupName)" -Level Info
            Remove-BrokerMachine -MachineName $VM.MachineName -DesktopGroup $VM.DesktopGroupName -force -AdminAddress $Controller   
        }
    }
    catch {
        Write-Log -Message $_ -Level Warn
        $ErrorCount += 1
        Break
    }
    # Unlock Account
    $ProvVM = (get-provvm -VMName ($VM.MachineName | Split-Path -Leaf))
    try {
        Write-Log -Message "$($VM.MachineName): Unlocking ProvVM Account" -Level Info
        Unlock-ProvVM -VMID $ProvVM.VMId -ProvisioningSchemeName $VM.CatalogName -AdminAddress $Controller
    }
    catch {
        Write-Log -Message $_ -Level Warn
        $ErrorCount += 1
    }
    # RemoveProvVM
    try {
        Write-Log -Message "$($VM.MachineName): Removing ProvVM but keeping VM" -Level Info
        $null = remove-ProvVM -VMName $ProvVM.VMName -ProvisioningSchemeName $VM.CatalogName -ForgetVM -AdminAddress $Controller
    }
    catch {
        Write-Log -Message $_ -Level Warn
        $ErrorCount += 1
    }
    # remove account from machine catalog
    try {
        Write-Log -Message "$($VM.MachineName): Removing Account from Machine Catalog $($VM.CatalogName)" -Level Info
        $null = Remove-AcctADAccount -IdentityPoolName $VM.CatalogName -ADAccountSid $ProvVM.ADAccountSid -RemovalOption None -AdminAddress $Controller
    }
    catch {
        Write-Log -Message $_ -Level Warn
        $ErrorCount += 1
    }   
    # remove BrokerMachine
    try {
        Write-Log -Message "$($VM.MachineName): Removing VM from Machine Catalog $($VM.CatalogName)" -Level Info
        remove-BrokerMachine -MachineName $VM.MachineName -AdminAddress $Controller
    }
    catch {
        Write-Log -Message $_ -Level Warn
        $ErrorCount += 1
        Break
    }
    GetUpdatedCatalogAccountIdentityPool    
}

function GetCatalogAccountIdentityPool {
    $IdentityPool = try { #get details about the Identity Pool
        Write-Log -Message "Source Catalog: $($SourceCatalog) Getting Identity Pool information" -Level Info
        Get-AcctIdentityPool -IdentityPoolName $SourceCatalog -AdminAddress $Controller -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -Level Warn
        Write-Log -Message "Source Catalog: $($SourceCatalog) Cannot get information about associated Identity Pool. Not proceeding" -Level Warn
        StopIteration
        Exit 1
    }
}

function GetUpdatedCatalogAccountIdentityPool  {
    $UpdatedIdentityPool = try { #get details about the Identity Pool
        Get-AcctIdentityPool -IdentityPoolName $SourceCatalog -AdminAddress $Controller -AdminAddress $Controller -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -Level Warn
        Write-Log -Message "$($SourceCatalog): Cannot get updated associated identity Pool information " -Level Warn
        Break
    }
    
    if (!($UpdatedIdentityPool.OU)) { #incase this is the last machine being removed - reset the OU back to the inital OU
        try {
            Write-Log -Message "Setting OU for Identity Pool: $($IdentityPool.IdentityPoolName) back to Initial OU: $($IdentityPool.OU)" -Level Info
            Set-AcctIdentityPool -IdentityPoolName $IdentityPool.IdentityPoolName -OU $IdentityPool.OU -AdminAddress $Controller -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Warn
        }
    }
}
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

#Region JSON
# ============================================================================
# Handle JSON input
# ============================================================================
if ($JSON.IsPresent) {
    Write-Log -Message "JSON input selected. Importing JSON data from: $JSONInputPath" -Level Info
    try {
        if (!(Test-Path $JSONInputPath)) {
            Write-Log -Message "Cannot find file: $JSONInputPath" -Level Warn
            StopIteration
            Exit 1
        }
        $EnvironmentDetails = Get-Content -Raw -Path $JSONInputPath -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        Write-Log -Message "JSON import failed. Exiting" -Level Warn
        Write-Log -Message $_ -Level Warn
        StopIteration
        Exit 1
    }

    $SourceCatalog = $EnvironmentDetails.SourceCatalog
    $TargetCatalog = $EnvironmentDetails.TargetCatalog
    $TargetDeliveryGroup = $EnvironmentDetails.TargetDeliveryGroup
    $PublishedName = $EnvironmentDetails.PublishedName
}
#endregion

#Region Connection
# ============================================================================
# Connect to Environment
# ============================================================================

LoadCitrixSnapins

TryForAuthentication
#endregion

# ============================================================================
# Get Environment Details
# ============================================================================
Write-Log -Message "Working with Source Catalog: $($SourceCatalog)" -Level Info
Write-Log -Message "Working with Target Catalog: $($TargetCatalog)" -Level Info
Write-Log -Message "Working with Target Delivery Group: $($TargetDeliveryGroup)" -Level Info

#Region Catalog Handling
#GetSourceCatalog
$Catalog = try {
    Write-Log -Message "Source Catalog: Getting details for $SourceCatalog" -Level Info
    Get-BrokerCatalog -Name $SourceCatalog -AdminAddress $Controller -ErrorAction Stop
}
catch {
    Write-Log -Message $_ -level Warn
    StopIteration
    Exit 1
}

CheckCatalogIsMCS

GetCatalogAccountIdentityPool

#GetTargetCatalog
$NewCatalog = try {
    Write-Log -Message "Target Catalog: Getting details for $TargetCatalog" -Level Info
    Get-BrokerCatalog -Name $TargetCatalog -AdminAddress $Controller -ErrorAction Stop
}
catch {
    Write-Log -Message $_ -level Warn
    StopIteration
    Exit 1
}

CheckCatalogisManual

#endregion

#Region Delivery Group Handling
#GetTargetDeliveryGroup
$DeliveryGroup = try {
    Write-Log -Message "Target Delivery Group: Getting Detail for $TargetDeliveryGroup" -Level Info
    Get-BrokerDesktopGroup -name $TargetDeliveryGroup -AdminAddress $Controller -ErrorAction Stop
}
catch {
    Write-Log -Message $_ -level Warn
    StopIteration
    Exit 1
}  
#endregion

#Region VM Handling
#GetVMs
##// Working Section for filtered VMs
if ($TargetMachineScope -eq "All") {
    $VMS = try {
        Write-Log -Message "Source Catalog: Getting VMs from: $SourceCatalog" -Level Info
        Get-BrokerMachine -CatalogName $SourceCatalog -AdminAddress $Controller -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -level Warn
        StopIteration
        Exit 1
    } 
}
elseif ($TargetMachineScope -eq "MachineList") {
    if ($null -ne $MachineList) {
        $VMList = $MachineList ##// Need to get machines now
        Write-Log -Message "Source Machine List: Getting VMs from specified list" -Level Info
        $VMS = try {
            Get-BrokerMachine -CatalogName $SourceCatalog -AdminAddress $Controller | Where-Object { $_.MachineName -in $VMList } ##//Looking for a match...only get machines in $VMList
        }
        catch {
            Write-Log -Message $_ -level Warn
            StopIteration
            Exit 1
        }
    }
    else {
        Write-Log -Message "No Machine Specified in Machine List. Exit Script" -Level Warn
        StopIteration
        Exit 1
    }
}
elseif ($TargetMachineList -eq 'CSV') {
    try {
        Write-Log -Message "Importing VMS from CSV List $($TargetMachineCSVList)" -Level Info
        $VMList = Import-Csv -Path $TargetMachineCSVList -ErrorAction Stop ##// Need to handle headers for multi Value CSV - maybe an export?
        ##// Need to get machines now
        $VMs = try {
            Get-BrokerMachine -CatalogName $SourceCatalog -AdminAddress $Controller | Where-Object { $_.MachineName -in $VMList } ##//Looking for a match...only get machines in $VMList
        }
        catch {
            Write-Log -Message $_ -level Warn
            StopIteration
            Exit 1
        }
    }
    catch {
        Write-Log -Message $_ -level Warn
        Write-Log -Message "Failed to Import CSV File. Exit Script" -level Warn
        StopIteration
        Exit 1
    }
} 
#endregion

# ============================================================================
# Execute the migration
# ============================================================================
$Count = ($VMs | Measure-Object).Count
$StartCount = 1
$ErrorCount = 0

Write-Log -Message "There are $Count machines to process" -Level Info

foreach ($VM in $VMs) {
    if ($VM.ProvisioningType -eq "MCS") {
        Write-Log -Message "Processing machine $StartCount of $Count" -Level Info
        RemoveMCSProvisionedMachine
        AddVMToCatalog
        AddVMtoDeliveryGroup
        AddUsertoVM
        if ($OverridePublishedName.IsPresent) {
            $PublishedName = $PublishedName
            SetVMDisplayName
        }
        if ($SetPublishedNameToMachineName.IsPresent) {
            $PublishedName = ($VM.MachineName | Split-Path -leaf)
            SetVMDisplayName
        }
        else {
            $PublishedName = $VM.PublishedName
            SetVMDisplayName
        }
        $StartCount += 1
    }
    else {
        Write-Log -Message "$($VM.MachineName) is not a MCS provisioned machine. Not proceeding" -Level Warn
        Break
    }
}

# Check error count
if ($ErrorCount -ne "0") {
    Write-Log -Message "There are $ErrorCount errors recorded. Please review logfile $LogPath" -Level Info
}

StopIteration
Exit 0
#endregion
