
function Reboot-Host {
    ##############################
    #.SYNOPSIS
    #Reboots the host
    #
    #.DESCRIPTION
    #Stops all the running VM's and reboots the hypervisor host
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER TargetPrefix
    #TargetPrefix name used for the delivery group
    #
    #.EXAMPLE
    #Reboot-Host -HostName "VAL-TARGET3" -TargetPrefix "T3"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$HostName,
        [string]$TargetPrefix)


    #Import-Module -Name Vmware*
    Get-Module -Name VMware* -ListAvailable | Import-Module
    Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -confirm:$false
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm:$false
    Set-PowerCLIConfiguration -DefaultVIServerMode single -Confirm:$false
    
    $configESXServer = Get-Content -Path "$PSScriptRoot\config.ESXServer.json" -Raw | ConvertFrom-Json
    
    #Shutdown CVM if present
    if ($($config.CVMPresent)) {
        Shutdown-CVM
       }
    
    #Connect to vCenter server
    $VCPassword = ConvertTo-SecureString $($configESXServer.VCPassword) -AsPlainText -Force
    $VCcredentials = New-Object System.Management.Automation.PSCredential ($($configESXServer.UserName), $VCPassword)
    Connect-VIServer -Server $($configESXServer.vSphereServer) -Credential $VCcredentials | Out-Null
    Write-Host (Get-Date) ": Rebooting hypervisor."
    Get-VMHost | Where-Object {$_.Name.ToLower().StartsWith($hostname.ToLower())} | Restart-VMHost -Force -Confirm:$false

    $startTime = Get-Date
	$date = Get-Date
    $timeout = 10
    while (Test-Connection -ComputerName $HostName -BufferSize 32 -Count 1 -Quiet) {
        Start-Sleep 5
 
        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Error "Host $HostName not responding to reboot." 
            Stop-Transcript
        }
    }
}

 function Validate-Host {
    ##############################
    #.SYNOPSIS
    #Validates if the host is available
    #
    #.DESCRIPTION
    #Validates if the host is available
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.EXAMPLE
    #Reboot-Host -HostName "VAL-TARGET3"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$HostName
        )
	
	$startTime = Get-Date
	$date = Get-Date
    $timeout = 10
    while (!(Test-Connection -ComputerName $HostName -BufferSize 32 -Count 1 -Quiet)) {
        Start-Sleep 5
 
        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Error "Host $HostName not responding to reboot." 
            Stop-Transcript
        }
    }
	
	Write-Host (Get-Date) ": Hypervisor is back online."

 }

 function Capture-HostData {
    ##############################
    #.SYNOPSIS
    #Captures performance data
    #
    #.DESCRIPTION
    #Captures performance data from the specified hypervisor
    #	
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER TestName
    #Name of the active test	
    #
    #.PARAMETER Duration
    #The duration of the test
    #
    #.EXAMPLE
    #Capture-HostData -HostName "VAL-TARGET3" -TestName "Win10_TEST_run_1" -Duration 2880
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$HostName,
        [string]$TestName,
        [string]$Share,
        [int]$Duration
    )
 	
    $samples = [math]::Round([int]$Duration / 30) + 4
    $timeout = [math]::Round([int]$Duration + 150)

	& "${env:ProgramFiles(x86)}\Nutanix Inc\NutanixCmdlets\powershell\import_modules\ImportModules.PS1"
	$configESXiServer = Get-Content -Path "$PSScriptRoot\config.ESXi.json" -Raw | ConvertFrom-Json

    $clusterpassword = ConvertTo-SecureString $($configESXiServer.Password) -AsPlainText -Force
	Connect-NutanixCluster -Server $($configESXiServer.Cluster) -UserName $configESXiServer.username  -Password $clusterpassword -AcceptInvalidSSLCerts | Out-Null
    $server = Get-NTNXHost | Where-Object {$_.Name -eq $($HostName)}
    Disconnect-NutanixCluster -Servers $($configESXiServer.Cluster)
    Write-Host (Get-Date) ": Starting performance data capture on hypervisor."

    $Username = $configESXiServer.username
    $Password = $configESXiServer.Password
    $header = @{
        Authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Username + ":" + $Password))
    }
    $ipmiuser = $configESXiServer.IPMIuser
    $ipmiPassword = $configESXiServer.IPMIpassword
    $ipmiheader = @{
        Authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ipmiuser + ":" + $ipmipassword))
    }

    $uri = "https://$($configESXiServer.Cluster):9440/PrismGateway/services/rest/v2.0/hosts/$($server.uuid)/stats/?metrics=hypervisor_cpu_usage_ppm&metrics=hypervisor_memory_usage_ppm"
    $ipmiuri = "https://$($configESXiServer.ipmi)/redfish/v1/Chassis/1/Power"

    $file = "$($Share)\_VSI_LogFiles\$($testname)\$($testname).csv"

    Start-Job -Scriptblock {
        Param(
			$jobHeader,
            [string]$jobUri,
            $jobheaderipmi,
            [string]$joburiipmi,
            [string]$jobSamples,
            [string]$jobFile,
            [int]$jobTimeOut
        )
#Block to ignore certificate errors
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
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
        
        $delay = 30
        $i = 1
        Do {
            $dateTime = Get-Date

            $results = Invoke-RestMethod -Method GET -Uri $jobUri -Header $jobHeader
            $resultsPower = Invoke-RestMethod -Method GET -Uri $jobUriipmi -Header $jobHeaderipmi

            $item = New-Object PSObject    
            $item | Add-Member Noteproperty DateTime $dateTime.ToString('MM/dd/yyyy HH:mm:ss')
            foreach ($result in $results.stats_specific_responses) {
                if ($result.metric -eq "hypervisor_cpu_usage_ppm" -Or $result.metric -eq "hypervisor_memory_usage_ppm") {
                    $actualvalue = $result.values[0] / 10000
                    $item | Add-Member Noteproperty $result.metric $actualvalue
                }
                else {
                    $item | Add-Member Noteproperty $result.metric $result.values[0]
                }
            }
            $item | Add-Member Noteproperty "PowerConsumedWatts" $resultsPower.PowerControl.PowerConsumedWatts
            $item | Export-Csv -Path $jobFile -NoTypeInformation -Append

            Start-Sleep -Seconds $delay
            $i++
        } While ($i -ne $jobSamples)

    } -ArgumentList @( $header, $uri, $ipmiheader, $ipmiuri, $samples, $file, $timeout) | Out-Null 
}	

function Capture-NvidiaData {
    ##############################
    #.SYNOPSIS
    #Captures nvidia performance data
    #
    #.DESCRIPTION
    #Captures nvidia perfomance data from the specified hypervisor
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER TestName
    #Name of the active test
    #
    #.PARAMETER Duration
    #The duration of the test
    #
    #.EXAMPLE
    #Capture-NvidiaData -HostName "VAL-TARGET3" -TestName "Win10_TEST_run_1" -Duration 2880
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$HostName,
        [string]$TestName,
        [int]$Samples
    )
 	

	
	Get-Module -Name VMware* -ListAvailable | Import-Module
 
    Write-Host (Get-Date) ": Starting performance data capture on hypervisor."
    
    
    $configESXServer = Get-Content -Path "$PSScriptRoot\config.ESXServer.json" -Raw | ConvertFrom-Json
 
    $delay = 30
    $timeout = [math]::Round($Samples * $delay)
    $path = "/tmp/$TestName.csv"
 
    $command = "nvidia-smi -l $delay --format=csv,nounits,noheader --query-gpu=timestamp,index,utilization.gpu,utilization.memory,memory.total,memory.used,memory.free,temperature.gpu,power.draw,clocks.current.graphics,clocks.current.sm,clocks.current.memory,clocks.current.video -f $path"
	
	$password = ConvertTo-SecureString $($configESXServer.rootPassword) -AsPlainText -Force
    $hostCredential = New-Object System.Management.Automation.PSCredential ("root", $password)
  	
    Start-Job -Scriptblock {
        Param(
			$jobUserName,	
            [string]$jobHost,
            [string]$jobCommand,
            [int]$jobTimeOut
        )
        $session = New-SSHSession -ComputerName $jobHost -Credential $jobUserName -AcceptKey
        Invoke-SSHCommand -SessionId $session.SessionId -Command $jobCommand -TimeOut $jobTimeOut
        Get-SSHSession | Remove-SSHSession | Out-Null
    } -ArgumentList @( $hostCredential, $HostName, $command, $timeout) | Out-Null
}	

Function Collect-HostData {	
    ##############################
    #.SYNOPSIS
    #Collects performance data from host
    #
    #.DESCRIPTION
    #Downloads the performance data from the specified hypervisor
    #	
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER TestName
    #Name of the test
    #
    #.PARAMETER Share
    #Location of the Login VSI 	
    #
    #.EXAMPLE
    #Collect-HostData -HostName "VAL-TARGET3" -TestName "WIN10_x64_Test" -Share "\\VAL-FS03\VSIShare"
    #
    #.NOTES	
    #Initial creation of generic function
    ##############################   
    Param(
        [string]$HostName,
        [string]$TestName,
        [string]$Share
    )
    Write-Host (Get-Date) ": Collect all performance data from hypervisor."
    Import-Module Posh-SSH
	
	$configESXServer = Get-Content -Path "$PSScriptRoot\config.ESXServer.json" -Raw | ConvertFrom-Json
 
    $tempLocation = "$env:Temp\"
 	
    $testNameFilter = $TestName
    $testRuns = Get-ChildItem -Path "$Share\_VSI_LogFiles\" | Where-Object {$_.Name.StartsWith($testNameFilter)}
 
    $password = ConvertTo-SecureString $($configESXServer.rootPassword) -AsPlainText -Force
    $hostCredential = New-Object System.Management.Automation.PSCredential ("root", $password)
 
    foreach ($testRun in $testRuns) {       
        $testRunName = $testRun.Name + ".csv"
        $remoteFile = "/tmp/$testRunName"
        $localFile = $tempLocation + $testRunName
        Get-SCPFile -HostName $HostName -RemoteFile $remoteFile -LocalFile $localFile -Credential $hostCredential -AcceptKey
        
        Copy-Item -Path $localFile -Destination $testRun.FullName
        Remove-Item -Path $localFile -Confirm:$false
    }	
}

Function Collect-NvidiaData {	
    ##############################
    #.SYNOPSIS
    #Collects nvidia performance data from host
    #
    #.DESCRIPTION
    #Downloads the nvidia perfomance data from the specified hypervisor
    #
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER TestName
    #Name of the test
    #
    #.PARAMETER Share
    #Location of the Login VSI share
    #
    #.EXAMPLE
    #Collect-NvidiaData -HostName "VAL-TARGET3" -TestName "WIN10_x64_Test" -Share "\\VAL-FS03\VSIShare"
    #
    #.NOTES
    #Initial creation of generic function
    ##############################   
    Param(
        [string]$HostName,
        [string]$TestName,
        [string]$Share
    )

    try {
        Write-Host (Get-Date) ": Collect all performance data from hypervisor."
        Import-Module Posh-SSH
        
        $configESXServer = Get-Content -Path "$PSScriptRoot\config.ESXServer.json" -Raw | ConvertFrom-Json
    
        $tempLocation = "$env:Temp\"
        
        $testNameFilter = $TestName
        $testRuns = Get-ChildItem -Path "$Share\_VSI_LogFiles\" | Where-Object {$_.Name.StartsWith($testNameFilter)}
    
        $password = ConvertTo-SecureString $($configESXServer.rootPassword) -AsPlainText -Force
        $hostCredential = New-Object System.Management.Automation.PSCredential ("root", $password)
    
        foreach ($testRun in $testRuns) {       
            $testRunName = $testRun.Name + ".csv"
            $remoteFile = "/tmp/$testRunName"
            $localFile = $tempLocation + $testRunName
            Get-SCPFile -HostName $HostName -RemoteFile $remoteFile -LocalFile $localFile -Credential $hostCredential -AcceptKey
            
            $data = @()
            $data += "timestamp,index,utilization.gpu,utilization.memory,memory.total,memory.used,memory.free,temperature.gpu,power.draw,clocks.current.graphics,clocks.current.sm,clocks.current.memory,clocks.current.video"
            $data += Get-Content -Path $localFile
            Set-Content -Path $localFile -Value $data

            Copy-Item -Path $localFile -Destination $testRun.FullName
            Remove-Item -Path $localFile -Confirm:$false
        }	
    }
    catch {
        Write-Host "Failed to get NVIDIA data with reason: $_"
    }
}