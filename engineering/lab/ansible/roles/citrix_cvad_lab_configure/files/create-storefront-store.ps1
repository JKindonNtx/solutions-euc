<#
 .SYNOPSIS
   Deploy the first member of a remote access StoreFront group with a single XenDesktop farm with one of more servers.
   Wait for a joiner to join to the newly created server and publishes the configuration to it.

 .PARAMETER HostbaseUrl
   The the URL that is used as the root of the URLs for the stores and other StoreFront services hosted on a deployment.

 .PARAMETER SiteId
   The IIS Site that should be used for creating the new StoreFront deployment in.

 .PARAMETER Farmtype
   The type of farm that the resources are published from. Acceptable values are ("XenDesktop","XenApp","AppController","AppController").

 .PARAMETER FarmServers
   The farm servers that applications and/or desktops will be published from

 .PARAMETER StoreVirtualPath
   Optionally specify the IIS virtual path to be used for the Store service.
   Defaults to /Citrix/Store

 .PARAMETER LoadbalanceServers
   If more than one server is used for published resources then loadbalance requests rather than failover.

 .PARAMETER Port
   The port used to communicate with the Xml service on the DDC/Farm.

 .PARAMETER SSLRelayPort
   The port to use for ssl relay.

 .PARAMETER TransportType
   The transport type to use when communicating with the Xml service. Acceptable values are ("HTTP","HTTPS","SSL").

 .PARAMETER GatewayName
   The friendly name for identifying the gateway.

 .PARAMETER GatewayUrl
   The Gateway Url.

 .PARAMETER GatewayCallbackUrl
   The Gateway authentication NetScaler call-back Url.

 .PARAMETER GatewaySTAUrls
   Secure Ticket Authority server Urls. The Secure Ticket Authority (STA) is responsible for issuing session tickets in response to connection requests for published resources on XenApp. These session tickets form the basis of authentication and authorization for access to published resources.

 .PARAMETER GatewaySubnetIP
   IP address.

 .EXAMPLE
   .\MultiServerFirstGroupMember.ps1 -HostbaseUrl "http://storefront.example.com" -SiteId 1 -Farmtype XenApp -FarmServers "XDServer1","XDServer2" -StoreVirtualPath "/Citrix/Store" -LoadbalanceServers $true `
   -GatewayUrl https://mygateway.com -GatewayCallbackUrl https://mygateway.com/CitrixAuthService/AuthService.asmx -GatewaySTAUrls https://xdc01.com/scripts/ctxa.dll -GatewayName "NSG1"

   The example creates a new deployment using the host name of the local server. A single store will be created with resources from XDServer1 and XDServer2.
   The servers will be load balanced and remote access will be enabled via "mygateway.com". The server will start the server group joining process and wait for the second server.
#>

Param(
    [Parameter(Mandatory=$false)][Uri]$HostbaseUrl = ("http://" + [System.Net.Dns]::GetHostByName($env:computerName).HostName),#$env:sf_host_base_url,
    [Parameter(Mandatory=$false)][long]$SiteId = 1,
    [string]$Farmtype = "XenDesktop",
    #[Parameter(Mandatory=$false)][string[]]$FarmServers = @($env:FarmServers),
    [Parameter(Mandatory=$false)][string[]]$FarmServers = [System.Net.Dns]::GetHostByName($env:computerName).HostName,
    [string]$StoreVirtualPath = "/Citrix/Store",
    [bool]$LoadbalanceServers = $true,
    [int]$Port = 80,
    [int]$SSLRelayPort = 443,
    [ValidateSet("HTTP","HTTPS","SSL")][string]$TransportType = $env:sf_transport_type,
    [Parameter(Mandatory=$false)][Uri]$GatewayUrl = $env:sf_gateway_url,
    [Parameter(Mandatory=$false)][Uri]$GatewayCallbackUrl = "$env:sf_host_base_url/CitrixAuthService/AuthService.asmx",
    #[Parameter(Mandatory=$false)][string[]]$GatewaySTAUrls = @($env:GatewaySTAUrls),
    [Parameter(Mandatory=$false)][string[]]$GatewaySTAUrls = ("http://" + [System.Net.Dns]::GetHostByName($env:computerName).HostName + "/scripts/ctxa.dll"),
    [string]$GatewaySubnetIP,
    [Parameter(Mandatory = $false)][string]$GatewayName = $env:sf_gateway_name
)
Start-Transcript -Path "C:\Logs\transcript0.txt"

Set-StrictMode -Version 2.0

# Any failure is a terminating failure.
$ErrorActionPreference = 'Stop'
$ReportErrorShowStackTrace = $true
$ReportErrorShowInnerException = $true

# Import StoreFront modules. Required for versions of PowerShell earlier than 3.0 that do not support autoloading
Import-Module Citrix.StoreFront

# Create a remote access deployment using the RemoteAccessDeployment example
$scriptDirectory = "C:\Program Files\Citrix\Receiver StoreFront\PowerShellSDK\Examples"
$scriptPath = Join-Path $scriptDirectory "RemoteAccessDeployment.ps1"
& $scriptPath -HostbaseUrl $HostbaseUrl -SiteId $SiteId -FarmServers $FarmServers -StoreVirtualPath $StoreVirtualPath -Farmtype $Farmtype `
    -LoadbalanceServers $LoadbalanceServers -Port $Port -SSLRelayPort $SSLRelayPort -TransportType $TransportType -GatewayUrl $GatewayUrl `
    -GatewaySTAUrls $GatewaySTAUrls -GatewayName $GatewayName -GatewayCallbackUrl ("$GatewayUrl/CitrixAuthService/AuthService.asmx")
write-output "Local store configuration complete"

write-output "Starting customizations"
$Rfw = Get-STFWebReceiverService -SiteId $SiteId -VirtualPath "/Citrix/StoreWeb"
write-output "Enabling loopback for SSL offload"
Set-STFWebReceiverCommunication -WebReceiverService $Rfw -Loopback "OnUsingHttp"
write-output "Workspace actions"
Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlLogoffAction "None"
Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlAutoReconnectAtLogon $False
write-output "Sets default IIS page"
Set-STFWebReceiverService -WebReceiverService $Rfw -DefaultIISSite:$True

write-output "Trusted Domain"
$AuthService = Get-STFAuthenticationService -SiteId $SiteId -VirtualPath "/Citrix/StoreAuth"
Set-STFExplicitCommonOptions -AuthenticationService $AuthService -Domains (Get-WmiObject Win32_ComputerSystem).Domain -DefaultDomain (Get-WmiObject Win32_ComputerSystem).Domain -HideDomainField $true -AllowUserPasswordChange "Always"

write-output "Enable Session Reliability"
$gateway = Get-STFRoamingGateway -Name $GatewayName
Set-STFRoamingGateway -Gateway $gateway -SessionReliability $true

Write-output "Change Storefront host base URL"
$scriptDirectory = "C:\Program Files\Citrix\Receiver StoreFront\scripts"
$scriptPath = Join-Path $scriptDirectory "SetHostBaseUrl.ps1"
& $scriptPath $env:sf_host_base_url

Stop-Transcript