
# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on March, 2019


# Setting parameters for the connection
[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None") ]
 
Param(
   # Citrix CVAD Specs
  [Parameter(Mandatory = $true)]
  [Alias('CVAD Controller')] [string] $CVADController,                                       # Name of the Citrix Delivery Controller
  [Parameter(Mandatory = $true)]
  [Alias('Machine Catalog Name')] [string] $provSchemeName,                                  # Name of the machine catalog that will be created (Name must be unique.)
    [Parameter(Mandatory = $true)]
  [Alias('Delivery Group Name')] [string] $DeliveryGroupName                                 # Name of the Delivery Group that will be created (Name must be unique.)
)


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
 if ($sev -eq "INFO"){
 write-host "$(get-date -format "hh:mm:ss") | INFO | $message"
 } elseif ($sev -eq "WARN"){
 write-host "$(get-date -format "hh:mm:ss") | WARN | $message"
 } elseif ($sev -eq "ERROR"){
 write-host "$(get-date -format "hh:mm:ss") | ERROR | $message"
 } elseif ($sev -eq "CHAPTER"){
 write-host "`n`n### $message`n`n"
 }
} 

# Adding PS cmdlets for Citrix
$loadedsnapins=(Get-PSSnapin -Registered | Select-Object name).name
if(!($loadedsnapins.Contains("Citrix"))){
 Add-PSSnapin -Name Citrix* 
 write-log -message "Citrix cmdlets are loaded, commencing the script"
}

if ($null -eq (Get-PSSnapin -Name Citrix* -ErrorAction SilentlyContinue))
{
 write-log -message "Citrix cmdlets are not loaded, aborting the script"
 break
}


$AvailableVMs = Get-BrokerMachine -AdminAddress $CVADController | Where-Object {$_.DesktopGroupName -eq $null}
write-log -message "Grabbing all available VMs"

New-BrokerDesktopGroup -AdminAddress $CVADController -ColorDepth "TwentyFourBit" -DeliveryType "DesktopsOnly" -DesktopKind "Private" -InMaintenanceMode $False -IsRemotePC $False -MinimumFunctionalLevel "L7_9" -Name $DeliveryGroupName -OffPeakBufferSizePercent 10 -OffPeakDisconnectAction "Nothing" -OffPeakDisconnectTimeout 0 -OffPeakExtendedDisconnectAction "Nothing" -OffPeakExtendedDisconnectTimeout 0 -OffPeakLogOffAction "Nothing" -OffPeakLogOffTimeout 0 -PeakBufferSizePercent 10 -PeakDisconnectAction "Nothing" -PeakDisconnectTimeout 0 -PeakExtendedDisconnectAction "Nothing" -PeakExtendedDisconnectTimeout 0 -PeakLogOffAction "Nothing" -PeakLogOffTimeout 0 -PublishedName "AHV - Windows - 10 - Delivery Group Name" -Scope @() -SecureIcaRequired $False -SessionSupport "SingleSession" -ShutdownDesktopsAfterUse $True -TimeZone "W. Europe Standard Time" | Out-Null
write-log -message "Creating the delivery group $DeliveryGroupName"

 Foreach ($vm in $AvailableVMs) {
    Add-BrokerMachine -AdminAddress $CVADController -DesktopGroup $DeliveryGroupName -InputObject $vm.UID
 }


write-log -message "Adding $($AvailableVMs.count) VMs to the Delivery Group $DeliveryGroupName"

$DesktopBrokerGroup = Get-BrokerDesktopGroup | Where-Object {$_.Name -eq $DeliveryGroupName}

# Setting up Access Policy rules for the Delivery group
New-BrokerAccessPolicyRule -AdminAddress $CVADController -AllowedConnections "NotViaAG" -AllowedProtocols @("HDX","RDP") -AllowedUsers "AnyAuthenticated" -AllowRestart $True -DesktopGroupUid $DesktopBrokerGroup.Uid -Enabled $True -IncludedSmartAccessFilterEnabled $True -IncludedUserFilterEnabled $True -IncludedUsers @() -Name $DeliveryGroupName+"_Direct" | Out-Null
write-log -message "Creating Access Rule for connections NOT traversing Access Gateway"
New-BrokerAccessPolicyRule -AdminAddress $CVADController -AllowedConnections "ViaAG" -AllowedProtocols @("HDX","RDP") -AllowedUsers "AnyAuthenticated" -AllowRestart $True -DesktopGroupUid $DesktopBrokerGroup.Uid -Enabled $True -IncludedSmartAccessFilterEnabled $True -IncludedSmartAccessTags @() -IncludedUserFilterEnabled $True -IncludedUsers @() -Name $DeliveryGroupName+"_AG" | Out-Null
write-log -message "Creating Access Rule for connections traversing Access Gateway"

# Testing if the access policy rules where created
Test-BrokerAccessPolicyRuleNameAvailable -AdminAddress $CVADController -Name @($DeliveryGroupName+"_Direct") | Out-Null
write-log -message "Testing Broker Access Policies for Direct connections"
Test-BrokerAccessPolicyRuleNameAvailable -AdminAddress $CVADController -Name @($DeliveryGroupName+"_AG") | Out-Null
write-log -message "Testing if the access rule for connections NOT traversing Access Gateway was created"

# Setting up Power schedules

# weekdays
Test-BrokerPowerTimeSchemeNameAvailable -AdminAddress $CVADController -Name @($DeliveryGroupName+"_Weekdays") | Out-Null
write-log -message "Testing if there's a power schedule available during weekdays"
New-BrokerPowerTimeScheme -AdminAddress $CVADController -DaysOfWeek "Weekdays" -DesktopGroupUid $DesktopBrokerGroup.Uid -DisplayName "Weekdays" -Name $DeliveryGroupName+"_Weekdays" -PeakHours @($True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True) -PoolSize @(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0) | Out-Null
write-log -message "Creating a new power schedule during weekdays for the delivery group"

# weekends
Test-BrokerPowerTimeSchemeNameAvailable -AdminAddress $CVADController -Name @($DeliveryGroupName+"_Weekend") | Out-Null
write-log -message "Testing if there's a power schedule available during weekends"
New-BrokerPowerTimeScheme -AdminAddress $CVADController -DaysOfWeek "Weekend" -DesktopGroupUid $DesktopBrokerGroup.Uid -DisplayName "Weekend" -Name $DeliveryGroupName+"_Weekend" -PeakHours @($True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True) -PoolSize @(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)  | Out-Null
write-log -message "Creating a new power schedule during weekends for the delivery group"