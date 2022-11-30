# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on March, 2019

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
     [Alias('Password')] [String] $nxPassword,
     # Citrix CVAD Specs
    [Parameter(Mandatory = $true)]
    [Alias('CVAD Controller')] [string] $CVADController,                                       # Name of the Citrix Delivery Controller
    [Parameter(Mandatory = $true)]
    [Alias('Hosting Connection Name')] [string] $ConnectionName,                               # Hosting Connection (Name must be unique.)
    [Parameter(Mandatory = $true)]
    [Alias('ResourceName')] [string] $VlanName,                                                # Name of the VLAN
        [Parameter(Mandatory = $true)]
    [Alias('HypervisorType')] [string] $hypervisor
)
$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force # Converting the Nutanix Prism password to a secure string to connect to the cluster

# Adding PS cmdlets
$loadedsnapins = (Get-PSSnapin -Registered | Select-Object name).name
if (!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))) {
    Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}
 
if ($null -eq (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
    write-log -message "Nutanix CMDlets are not loaded, aborting the script"
    break
}
if($hypervisor -eq 'AHV'){
# Connecting to the Nutanix Cluster
$nxServerObj = Connect-NTNXCluster -Server $nxIP -UserName $nxUser -Password $nxPasswordsec -AcceptInvalidSSLCerts | out-null
write-log -message "Connecting to the Nutanix Cluster $nxIP"
 
if ($null -eq (get-ntnxclusterinfo)) {
    write-log -message "Cluster connection isn't available, abborting the script"
    break
}
}
# Setting parameters for Machine Catalog properties


$network = $VlanName                                                    # Reusing the name of the network 
$hostingUnitName = $VlanName                                            # Reusing the VLAN Name as ResourceName to avoid multiple connections with the same resource definition
$adContainerDN = "OU=VSI-test,OU=Computers,OU=CORP,DC=contoso,DC=local" # Setting the OU for the desktops

if($hypervisor -eq 'AHV'){
# Grabbing the containerID from the parameter Container
$ContainerInfo = Get-NTNXContainer | Where-Object {$_.name -eq $storage}
$ContainerId = ($Containerinfo.id.split(":"))[2]
}
# End of Global variables
if($hypervisor -eq 'AHV'){
$connectionCustomProperties = "<CustomProperties></CustomProperties>"
$hostingCustomProperties = "<CustomProperties></CustomProperties>"

$provcustomProperties = @"

<CustomProperties xmlns="http://schemas.citrix.com/2014/xd/machinecreation">

  <StringProperty Name="ContainerPath" Value="$containerID.container"/>

  <StringProperty Name="vCPU" Value="$vCPU"/>

  <StringProperty Name="RAM" Value="$RAM"/>

  <StringProperty Name="CPUCores" Value="$coresPerCPU"/>            

</CustomProperties>

"@
}
# Setting variables for the hosting connection(s)

$hypRootPath = "xdhyp:\Connections\"+$hypConnName+"\"
$baseImagePath = "xdhyp:\HostingUnits\" + $hostingUnitName +"\"+ $baseImage+".template"
$networkPath1 = $hypRootPath+$network+".network"
$networkMap = @{ "0" = "XDHyp:\HostingUnits\" + $hostingUnitName +"\"+ $network+".network" }
$storagePath = $hypRootPath+$storage+".storage"

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


#region Setting up the hosting connection

$ExistinghostingConnection = Test-Path -EA Stop -Path @("XDHyp:\Connections\$ConnectionName") -AdminAddress $CVADController
write-log -message "Checking if the hosting connection already exists"

#region Setting up the hosting connection for AHV
if($hypervisor -eq 'AHV'){
if ($ExistinghostingConnection -eq $False){
                                           $Connectionuid = New-Item -ConnectionType "Custom" -CustomProperties "" -HypervisorAddress @("$nxIP") -Path @("XDHyp:\Connections\$ConnectionName") -PluginId "AcropolisFactory" -Scope @() -SecurePassword $nxPasswordSec -UserName $nxUser -persist | Select-Object HypervisorConnectionUid
                                           New-BrokerHypervisorConnection -AdminAddress $CVADController -HypHypervisorConnectionUid $connectionuid.HypervisorConnectionUid | Out-Null
                                           write-log -message "Creating the hosting connection $ConnectionName"

                                           # Create Resources 'NTNX-LAN'  

                                            Set-HypAdminConnection  -AdminAddress $CVADController

                                            $ExistinghostingResource = Test-Path -EA Stop -Path @("XDHyp:\HostingUnits\$VlanName") -AdminAddress $CVADController

                                            if ($ExistinghostingResource -eq $False){
                                                                                       New-Item -HypervisorConnectionName $ConnectionName -NetworkPath @("XDHyp:\Connections\$ConnectionName\VDI-LAN.network") -Path @("XDHyp:\HostingUnits\$VlanName") -PersonalvDiskStoragePath @() -RootPath "XDHyp:\Connections\$ConnectionName" -StoragePath @() | Out-Null
                                                                                       write-log -message "Creating the resources $VlanName for $ConnectionName"
                                                                                    }
                                            Else {
                                                    Write-log -message "This VLAN is already assigned as a resource to the hosting connection, terminating the script"
                                                    break
                                                    }
                                        }
Else {
        write-log -message "This hosting connection already exists"
        }
 }

 #endregion Setting up the hosting connection for AHV

 #region Setting up the hosting connection for ESXi
if($hypervisor -eq 'ESXi'){
if ($ExistinghostingConnection -eq $False){
    #computername = (Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain
    #$URL = "$computername" + ":80"
    $path = $env:TEMP
    $Uri = $nxIP
    $Outputfile = "$path" + "\vmware.cer"
    $Testcertpath = $Outputfile | Test-Path
    if ($Testcertpath -eq "False"){
    # write-host "Certificate already exsist will delete it"
    Remove-Item -Path $Outputfile -Force
    }
    $request = [System.Net.WebRequest]::Create($Uri)
    $Provider = New-Object Microsoft.CSharp.CSharpCodeProvider
    $Compiler = $Provider.CreateCompiler()
    $Params = New-Object System.CodeDom.Compiler.CompilerParameters
    $Params.GenerateExecutable = $False
    $Params.GenerateInMemory = $True
    $Params.IncludeDebugInformation = $False
    $Params.ReferencedAssemblies.Add("System.DLL") > $null
    $TASource = @'
      namespace Local.ToolkitExtensions.Net.CertificatePolicy {
        public class TrustAll : System.Net.ICertificatePolicy {
          public TrustAll() {
          }
          public bool CheckValidationResult(System.Net.ServicePoint sp,
            System.Security.Cryptography.X509Certificates.X509Certificate cert,
            System.Net.WebRequest req, int problem) {
            return true;
          }
        }
      }
'@
    $TAResults = $Provider.CompileAssemblyFromSource($Params, $TASource)
    $TAAssembly = $TAResults.CompiledAssembly
    $TrustAll = $TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
    [System.Net.ServicePointManager]::CertificatePolicy = $TrustAll
    $servicePoint = $request.ServicePoint
    $response = $request.GetResponse()
    $certificate = $servicePoint.Certificate
    $certBytes = $certificate.Export(
    [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    [System.IO.File]::WriteAllBytes($OutputFile, $certBytes)
   
    $certPrint = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $certPrint.Import("$path\vmware.cer")
    $Connectionuid = New-Item -ConnectionType "VCenter" -CustomProperties "" -HypervisorAddress "$nxIp/sdk" -Path @("XDHyp:\Connections\$ConnectionName") -Scope @() -Password $nxPassword -UserName $nxUser -SSLThumbprint $certPrint.Thumbprint -persist | select HypervisorConnectionUid
    New-BrokerHypervisorConnection -AdminAddress $CVADController -HypHypervisorConnectionUid $connectionuid.HypervisorConnectionUid

    $job = [Guid]::NewGuid()
    New-HypStorage  -AdminAddress $CVADController -jobgroup $job -StoragePath @("XDHyp:\Connections\$ConnectionName\NTNX.datacenter\NTNX - Generic.cluster\CTR01.storage") -StorageType "TemporaryStorage"

    Set-HypAdminConnection  -AdminAddress $CVADController 

    New-Item -HypervisorConnectionName $ConnectionName -jobgroup $job -NetworkPath @("XDHyp:\Connections\$ConnectionName\NTNX.datacenter\NTNX - Generic.cluster\VM Network.network") -Path @("XDHyp:\HostingUnits\$vlanname") -PersonalvDiskStoragePath @("XDHyp:\Connections\$ConnectionName\NTNX.datacenter\NTNX - Generic.cluster\CTR01.storage") -RootPath "XDHyp:\Connections\$ConnectionName\NTNX.datacenter\NTNX - Generic.cluster" -StoragePath @("XDHyp:\Connections\$ConnectionName\NTNX.datacenter\NTNX - Generic.cluster\CTR01.storage")

    Set-HypAdminConnection  -AdminAddress $CVADController

    Get-Item  -LiteralPath @("XDHyp:\Connections\$ConnectionName\NTNX.datacenter\NTNX - Generic.cluster")


}
                                        }
Else {
        write-log -message "This hosting connection already exists"
        }
 
 #endregion Setting up the hosting connection for ESXi

$hypHc = get-Item -Path xdhyp:\Connections\$ConnectionName 

#endregion Setting up the hosting connection