
# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on September, 2019

# Connect to HV first, get all powered on VMs, compare that to AD get-adcomputer and run this across that array

# Setting parameters for the connection
[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None") ]
 
Param(
    # Nutanix cluster IP address
    [Parameter(Mandatory = $true)]
    [Alias('IP')] [string] $nxIP,    
    # Nutanix cluster username
    [Parameter(Mandatory = $true)]
    [Alias('User')] [string] $nxUser,
    # Nutanix cluster password
    [Parameter(Mandatory = $true)]
    [Alias('Password')] [String] $nxPassword
)
 
# Converting the password to a secure string which isn't accepted for our API connectivity
$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force
$nxPassword = $null
 
Function write-log {
    <#
       .Synopsis
       Write logs for debugging purposes
       
       .Description
       This function writes logs based on the message including a time stamp for debugging purposes.
    #>
    param (
        $message,
        $sev = "INFO"
    )
    if ($sev -eq "INFO") {
        write-host "$(get-date -format "hh:mm:ss") | INFO | $message"
    }
    elseif ($sev -eq "WARN") {
        write-host "$(get-date -format "hh:mm:ss") | WARN | $message"
    }
    elseif ($sev -eq "ERROR") {
        write-host "$(get-date -format "hh:mm:ss") | ERROR | $message"
    }
    elseif ($sev -eq "CHAPTER") {
        write-host "`n`n### $message`n`n"
    }
} 
 
# Adding PS cmdlets
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}
 
if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
    write-log -message "Nutanix CMDlets are not loaded, aborting the script"
    break
}
 
# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPasswordSec -AcceptInvalidSSLCerts -ForcedConnection
write-log -Message "Connecting to cluster $nxIp"
 
if ($null -eq (get-ntnxclusterinfo)) {
    write-log -message "Cluster connection isn't available, abborting the script"
    break
}
else {
    write-log -message "Connected to Nutanix cluster $nxIP"
}

# Fetching VMs running on AHV
$VMs = get-ntnxvm | Where-Object {$_.controllerVm -Match "False"}
write-log -message "Grabbing VM information and Client OS based Windows AD-objects"
write-log -message "Currently grabbing information on $($VMs.count) VMs"
  
# Check Windows Client OS-based AD Objects
$Clients  = Get-ADComputer -Filter {OperatingSystem -like '*7*' -or OperatingSystem -like '*10*'} -Property *
write-log -message "Currently grabbing information on $($Clients.count) workstations"

# Comparing the VM list with the Windows Client OS-based AD Objects
write-log -message "Comparing the VM list with the AD object list"
$ADVMs = $VMs.vmName | where-object {$clients.Name -contains $_}
write-log -message "The both lists have $($advms.count) machines in common"

# Turning on the VMs that are in both lists
write-log -message "Starting the VMs in the combined list that are turned off"
foreach ($advm in $ADVMs) {
                $vminfo = Get-NTNXVM | Where-Object {$_.vmName -eq $advm}
                If ($vminfo.powerState -eq "Off") {
                # Get the VmID of the VM
                $vmId = ($vminfo.vmid.split(":"))[2]
                # Booting the VM
                Set-NTNXVMPowerOn -Vmid $VMid | out-null
                Write-log -message "Starting $ADVM" 
                }             
}

# Waiting a minute to start all the VMs in the previous action
Start-Sleep 60

# Getting remote registry for each VM that also has a Windows Client OS-based AD object
foreach ($vm in $ADVMs){
            try {
                $RemoteRegistry = Get-CimInstance -Class Win32_Service -ComputerName $vm -Filter 'Name = "RemoteRegistry"' -ErrorAction Stop
                if ($RemoteRegistry.State -eq 'Running') {
                    write-log -Message "$vm : Remote Registry is already Enabled"
                    
                    # Getting Screen saver configuration
                    $result = Invoke-Command -Computername $VM {Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\7516b95f-f776-4464-8c53-06167f40cc99\8EC4B3A5-6868-48c2-BE75-4F3044BE88A7\' -Name 'Attributes'| select-object 'Attributes'}
                    if ($result.Attributes -eq '1'){

                    write-log -message "$VM : Screensaver set"
                    
                    # Collecting current power scheme and changing power options if needed
                    $currentPowerScheme = Invoke-Command -Computername $VM {Powercfg -getactivescheme}
                    $currentPowerScheme = $currentPowerScheme.split("()")
                    Write-log -Message "$VM : Power Scheme set to $($currentPowerScheme[1])"

                    $DisplaySettings = Invoke-Command -Computername $VM {powercfg -query SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e}
                    $DisplaySettings = $DisplaySettings[10].Split(":")[-1]

                    if ($DisplaySettings -like '*0x00000000') {
                        Write-log -Message "$VM : Display Settings: Configured to Never turn off the display"
                        }
                    else {
                        Write-log -Message "$VM : Display Settings: Not configured to Never turn off the display"
                    }
                    }
                }
                } catch {
                # $ErrorMessage = $Computer + " Error: " + $_.Exception.Message
                write-log -message "$vm : Looks like WinRM isn't enabled"
 
            }
          }

# Disconnecting from the Nutanix Cluster
Disconnect-NTNXCluster -Servers *
write-log -message "Closing the connection to the Nutanix cluster $($nxIP)"