
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
        [int]$Samples
    )
 	
	
	
	Get-Module -Name VMware* -ListAvailable | Import-Module
 
    Write-Host (Get-Date) ": Starting performance data capture on hypervisor."
    
    
    $configESXServer = Get-Content -Path "$PSScriptRoot\config.ESXServer.json" -Raw | ConvertFrom-Json
 
    $delay = 30
    $path = "/tmp/$TestName.csv"
 
    $command = "esxtop -b -d $delay -n 130 > $path"
	
	$password = ConvertTo-SecureString $($configESXServer.rootPassword) -AsPlainText -Force
    $hostCredential = New-Object System.Management.Automation.PSCredential ("root", $password)
  	
    Start-Job -Scriptblock {
        Param(
			$jobUserName,	
            [string]$jobHost,
            [string]$jobCommand
        )
		
        $session = New-SSHSession -ComputerName $jobHost -Credential $jobUserName -AcceptKey
        Invoke-SSHCommand -SessionId $session.SessionId -Command $jobCommand
        Get-SSHSession | Remove-SSHSession | Out-Null
    } -ArgumentList @( $hostCredential, $HostName, $command) | Out-Null
 
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