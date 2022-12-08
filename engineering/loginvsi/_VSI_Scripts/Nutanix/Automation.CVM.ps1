
function Shutdown-CVM {
    ##############################
    #.SYNOPSIS
    #Shuts down the CVM
    #
    #.DESCRIPTION
    #Shuts down the CVM
    #
    #
    #.EXAMPLE
    #Shutdown-CVM
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
 
    #Import Nutanix Module
    & "${env:ProgramFiles(x86)}\Nutanix Inc\NutanixCmdlets\powershell\import_modules\ImportModules.PS1"
    
    $configCVM = Get-Content -Path "$PSScriptRoot\config.AHV.json" -Raw | ConvertFrom-Json
    if (Test-Connection -Computername $($configCVM.CVMaddress) -BufferSize 16 -Count 1 -Quiet) {
        $password = ConvertTo-SecureString $($configCVM.CVMPassword) -AsPlainText -Force
        $ControllerCredentials = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
        $session = New-SSHSession -ComputerName $($configCVM.CVMaddress) -Credential $ControllerCredentials -AcceptKey
        Write-Host (Get-Date) ": Shutdown Nutanix CVM."
        $sshStream = New-SSHShellStream -SessionId $session.SessionId
        $sshStream.WriteLine('/home/nutanix/cluster/bin/cvm_shutdown -P now')
        Start-Sleep -Seconds 180
    }Else {
        Write-Host (Get-Date) ": The Nutanix CVM is already off."
    }
    
}

function Capture-ClusterStats {
    ##############################
    #.SYNOPSIS
    #Captures performance data
    #
    #.DESCRIPTION
    #Captures performance data from the specified Nutanix Cluster
    #	
    #.PARAMETER ClusterName
    #Cluster ip
    #
    #.PARAMETER TestName
    #Name of the active test	
    #
    #.PARAMETER Duration
    #The duration of the test
    #
    #.EXAMPLE
    #Capture-ClusterStats -ClusterName "VAL-TARGET3" -TestName "Win10_TEST_run_1" -Duration 2880
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [string]$TestName,
        [string]$Share,
        [int]$Duration
    )
 	
    Write-Host (Get-Date) ": Starting performance data capture on Nutanix cluster."

    $samples = [math]::Round([int]$Duration / 30) + 4
    $timeout = [math]::Round([int]$Duration + 120)

	$configAHVServer = Get-Content -Path "$PSScriptRoot\config.AHV.json" -Raw | ConvertFrom-Json
    $Username = $configAHVServer.username
    $Password = $configAHVServer.Password
    $header = @{
        Authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Username + ":" + $Password))
    }

    $uri = "https://$($configAHVServer.Cluster):9440/PrismGateway/services/rest/v2.0/cluster/stats/?metrics=hypervisor_cpu_usage_ppm&metrics=hypervisor_cpu_usage_ppm&metrics=hypervisor_memory_usage_ppm&metrics=controller_num_write_iops&metrics=controller_num_read_iops&metrics=controller_num_iops&metrics=controller_avg_io_latency_usecs&metrics=controller_avg_read_io_latency_usecs&metrics=controller_avg_write_io_latency_usecs"

    $clusterfilename = $testname -split '_run_'
    $newclusterfilename = "$($clusterfilename[0])_cluster_run_$($clusterfilename[1])"
    $file = "$($Share)\_VSI_LogFiles\$($testname)\$($newclusterfilename).csv"

    Start-Job -Scriptblock {
        Param(
			$jobHeader,
            [string]$jobUri,
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

            $item | Export-Csv -Path $jobFile -NoTypeInformation -Append

            Start-Sleep -Seconds $delay
            $i++
        } While ($i -ne $jobSamples)
        (Get-Content -path $jobFile) | Foreach-Object { $_ -replace "_ppm", "_cluster" } | Set-Content -path $jobFile
    } -ArgumentList @( $header, $uri, $samples, $file, $timeout) | Out-Null 
}