
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
        [string]$HostName
    )
 
    #Import Nutanix Module
    & "${env:ProgramFiles(x86)}\Nutanix Inc\NutanixCmdlets\powershell\import_modules\ImportModules.PS1"
	
    $configAHVServer = Get-Content -Path "$PSScriptRoot\config.AHV.json" -Raw | ConvertFrom-Json
    $clusterpassword = ConvertTo-SecureString $($configAHVServer.Password) -AsPlainText -Force
	Connect-NutanixCluster -Server $($configAHVServer.Cluster) -UserName $configAHVServer.username  -Password $clusterpassword -AcceptInvalidSSLCerts | Out-Null
    
    $server = Get-NTNXHost | Where-Object {$_.Name -eq $($HostName)}
    Disconnect-NutanixCluster -Servers $($configAHVServer.Cluster)
    Write-Host (Get-Date) ": Entering maintenance mode."
    
    $password = ConvertTo-SecureString $($configAHVServer.CVMPassword) -AsPlainText -Force
    $ControllerCredentials = New-Object System.Management.Automation.PSCredential ("nutanix", $password)

    $session = New-SSHSession -ComputerName $server.controllerVmBackplaneIp -Credential $ControllerCredentials -AcceptKey
    $nodeFullName = $HostName.ToLower() + "." + $env:USERDNSDOMAIN.ToLower()
    $maintenanceModeCommand = '/home/nutanix/bin/acli host.enter_maintenance_mode ' + $nodeFullName +' wait="true"'
    $output = Invoke-SSHCommand -SessionId $session.SessionId -Command $maintenanceModeCommand

    if ($output.ExitStatus -ne 0) {
        Write-Error $output.Output
    }
    
    Write-Host (Get-Date) ": Shutdown controller."
    $sshStream = New-SSHShellStream -SessionId $session.SessionId
    $sshStream.WriteLine('/home/nutanix/cluster/bin/cvm_shutdown -P now')

    #$sshStream.WriteLine('shutdown')

    Start-Sleep -Seconds 180

    Write-Host (Get-Date) ": Rebooting hypervisor."
    $Nodepassword = ConvertTo-SecureString $($configAHVServer.AHVPassword) -AsPlainText -Force
    $NodeCredentials = New-Object System.Management.Automation.PSCredential ("root", $Nodepassword)

    $sessionNode = New-SSHSession -ComputerName $server.hypervisorAddress -Credential $NodeCredentials -AcceptKey
    $reboot = Invoke-SSHCommand -SessionId $sessionNode.SessionId -Command 'reboot'

    if ($reboot.ExitStatus -ne 0) {
        Write-Error $reboot.Output
    }

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
    #Validates if the host is availiable
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

    Write-Host (Get-Date) ": Waiting for Controller to be online."
    & "${env:ProgramFiles(x86)}\Nutanix Inc\NutanixCmdlets\powershell\import_modules\ImportModules.PS1"
	
    $configAHVServer = Get-Content -Path "$PSScriptRoot\config.AHV.json" -Raw | ConvertFrom-Json
	$clusterpassword = ConvertTo-SecureString $($configAHVServer.Password) -AsPlainText -Force
	Connect-NutanixCluster -Server $($configAHVServer.Cluster) -UserName $configAHVServer.username  -Password $clusterpassword -AcceptInvalidSSLCerts | Out-Null

    $server = Get-NTNXHost | Where-Object {$_.Name -eq $($HostName)}

    while ($server.Count -eq 0) {
        $server = Get-NTNXHost | Where-Object {$_.Name -eq $($HostName)}

        if ($server.count -ne 0) {
            break;
        }

        Start-Sleep 15
    }
    Start-Sleep -Seconds 60
    Write-Host (Get-Date) ": Exit maintenance mode."
    $CVMpassword = ConvertTo-SecureString $($configAHVServer.CVMPassword) -AsPlainText -Force
    $ControllerCredentials = New-Object System.Management.Automation.PSCredential ("nutanix", $CVMpassword)
    $sessionCVM = New-SSHSession -ComputerName $server.controllerVmBackplaneIp -Credential $ControllerCredentials -AcceptKey
    $nodeFullName = $HostName.ToLower() + "." + $env:USERDNSDOMAIN.ToLower()
    $maintenanceModeCommand = '/home/nutanix/bin/acli host.exit_maintenance_mode ' + $nodeFullName
    $output = Invoke-SSHCommand -SessionId $sessionCVM.SessionId -Command $maintenanceModeCommand

    if ($output.ExitStatus -ne 0) {
        Write-Error $output.Output
    }

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
	$configAHVServer = Get-Content -Path "$PSScriptRoot\config.AHV.json" -Raw | ConvertFrom-Json

    $clusterpassword = ConvertTo-SecureString $($configAHVServer.Password) -AsPlainText -Force
	Connect-NutanixCluster -Server $($configAHVServer.Cluster) -UserName $configAHVServer.username  -Password $clusterpassword -AcceptInvalidSSLCerts | Out-Null
    $server = Get-NTNXHost | Where-Object {$_.Name -eq $($HostName)}
    Disconnect-NutanixCluster -Servers $($configAHVServer.Cluster)
    Write-Host (Get-Date) ": Starting performance data capture on hypervisor."

    $Username = $configAHVServer.username
    $Password = $configAHVServer.Password
    $header = @{
        Authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Username + ":" + $Password))
    }
    $ipmiuser = $configAHVServer.IPMIuser
    $ipmiPassword = $configAHVServer.IPMIpassword
    $ipmiheader = @{
        Authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ipmiuser + ":" + $ipmipassword))
    }

    $uri = "https://$($configAHVServer.Cluster):9440/PrismGateway/services/rest/v2.0/hosts/$($server.uuid)/stats/?metrics=hypervisor_cpu_usage_ppm&metrics=hypervisor_memory_usage_ppm"
    $ipmiuri = "https://$($configAHVServer.ipmi)/redfish/v1/Chassis/1/Power"

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
        [int]$Duration
    )
 	
	 
    Write-Host (Get-Date) ": Starting NVIDIA performance data capture on hypervisor."
    
    Import-Module Posh-SSH

    #Import Nutanix Module
    & "${env:ProgramFiles(x86)}\Nutanix Inc\NutanixCmdlets\powershell\import_modules\ImportModules.PS1"

    $configAHVServer = Get-Content -Path "$PSScriptRoot\config.AHV.json" -Raw | ConvertFrom-Json
    $clusterpassword = ConvertTo-SecureString $($configAHVServer.Password) -AsPlainText -Force
    Connect-NutanixCluster -Server $($configAHVServer.Cluster) -UserName $configAHVServer.username  -Password $clusterpassword -AcceptInvalidSSLCerts | Out-Null
     
    $server = Get-NTNXHost | Where-Object {$_.Name -eq $($HostName)}
    Disconnect-NutanixCluster -Servers $($configAHVServer.Cluster)
    $HostNode = $server.hypervisorAddress   
    $delay = 30
    $timeout = [math]::Round([int]$Duration - 30)
    $path = "/tmp/$TestName.csv"
 
    $command = "timeout $timeout nvidia-smi -l $delay --format=csv,nounits,noheader --query-gpu=timestamp,index,utilization.gpu,utilization.memory,memory.total,memory.used,memory.free,temperature.gpu,power.draw,clocks.current.graphics,clocks.current.sm,clocks.current.memory,clocks.current.video -f $path"

	$password = ConvertTo-SecureString $($configAHVServer.AHVPassword) -AsPlainText -Force
    $HostCredential = New-Object System.Management.Automation.PSCredential ("root", $password)
  	
    Start-Job -Name NVIDIAjob -Scriptblock {
        Param(
			$jobUserName,	
            [string]$jobHost,
            [string]$jobCommand,
            [int]$jobTimeOut
        )
		
        $session = New-SSHSession -ComputerName $jobHost -Credential $jobUserName -AcceptKey
        Invoke-SSHCommand -Index $session.SessionId -Command $jobCommand -TimeOut $jobTimeOut
    } -ArgumentList @( $hostCredential, $HostNode, $command, $Duration) | Out-Null
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
        Write-Host (Get-Date) ": Collect NVIDIA performance data from hypervisor."
        Import-Module Posh-SSH
        
        #Import Nutanix Module
        & "${env:ProgramFiles(x86)}\Nutanix Inc\NutanixCmdlets\powershell\import_modules\ImportModules.PS1"

        $configAHVServer = Get-Content -Path "$PSScriptRoot\config.AHV.json" -Raw | ConvertFrom-Json
        $clusterpassword = ConvertTo-SecureString $($configAHVServer.Password) -AsPlainText -Force
        Connect-NutanixCluster -Server $($configAHVServer.Cluster) -UserName $configAHVServer.username  -Password $clusterpassword -AcceptInvalidSSLCerts | Out-Null
     
        $server = Get-NTNXHost | Where-Object {$_.Name -eq $($HostName)}
        
        $HostNode = $server.hypervisorAddress
        Disconnect-NutanixCluster -Servers $($configAHVServer.Cluster)
        
        $tempLocation = "$env:Temp\"
        
        $testNameFilter = $TestName
        $testRuns = Get-ChildItem -Path "$Share\_VSI_LogFiles\" | Where-Object {$_.Name.StartsWith($testNameFilter)}
    
        $password = ConvertTo-SecureString $($configAHVServer.AHVPassword) -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ("root", $password)
    
        foreach ($testRun in $testRuns) {       
            $testRunName = $testRun.Name + ".csv"
            $remoteFile = "/tmp/$testRunName"
            $localFile = $tempLocation + $testRunName
            Get-SCPFile -HostName $HostNode -RemoteFile $remoteFile -LocalFile $localFile -Credential $hostCredential -AcceptKey
            
            $data = @()
            $data += "timestamp,index,utilization.gpu,utilization.memory,memory.total,memory.used,memory.free,temperature.gpu,power.draw,clocks.current.graphics,clocks.current.sm,clocks.current.memory,clocks.current.video"
            $data += Get-Content -Path $localFile
            Set-Content -Path $localFile -Value $data
            $GPUcards = Get-Content -Path $localFile | ConvertFrom-CSV | Select-Object -Unique -Property index
            foreach ($GPUcard in $GPUcards) {
                $GPUfilename = $testrunname -split '_run_'
                $newGPUfilename = "$($GPUfilename[0])_GPU$($GPUcard.index)_run_$($GPUfilename[1])"
                Get-Content -Path $localFile | ConvertFrom-CSV | Where-Object index -eq $GPUcard.index | Export-csv -path "$($testRun.FullName)\$newGPUfilename" -NoTypeInformation      
                $File = "$($testRun.FullName)\$newGPUfilename"
                (Get-Content -path $File) | Foreach-Object { $_ -replace "`"", "" } | Set-Content -path $File
                # Delete empty csv
                $EmptyGPUfilename = "$($testRun.FullName)\$($GPUfilename[0])_GPU_run_$($GPUfilename[1])"
                Remove-Item $EmptyGPUfilename -Force -Confirm:$false -ErrorAction Ignore
            }
            Remove-Item -Path $localFile -Confirm:$false
        }	
    }
    catch {
        Write-Host "Failed to get NVIDIA data with reason: $_"
    }
}