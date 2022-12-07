#requires -Modules posh-ssh
#Import-Module -Name Vmware*
Get-Module -Name VMware* -ListAvailable | Import-Module
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -confirm:$false
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm:$false
Set-PowerCLIConfiguration -DefaultVIServerMode single -Confirm:$false

$configESXServer = Get-Content -Path "$PSScriptRoot\config.ESXServer.json" -Raw | ConvertFrom-Json

#Connect to vCenter server
$VCPassword = ConvertTo-SecureString $($configESXServer.VCPassword) -AsPlainText -Force
$VCcredentials = New-Object System.Management.Automation.PSCredential ($($configESXServer.UserName), $VCPassword)
Connect-VIServer -Server $($configESXServer.vSphereServer) -Credential $VCcredentials | Out-Null

$TestName = "CTX71912-W101909-FSLCC-Rem-HDX-8n-960-n"
$delay = 30
$clusterName = 'Desktops'
$user = 'root'
$pswd = 'nutanix/4u'
 
$code = {
        param(
            [string]$EsxName,
            [string]$User,
            [string]$Password,
            [string]$tstname,
            [string]$topdelay,
            [string]$number
        )
 
        $pswdSec = ConvertTo-SecureString -String $Password -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($User,$pswdSec)
 
        $ssh = New-SSHSession -ComputerName $EsxName -Credential $cred -AcceptKey -KeepAliveInterval 5
 
        # Test
        $cmd = "esxtop -b -d $topdelay -n 145 > /vmfs/volumes/VDI/$tstname'_'$number.csv"
        1..2 | %{
            "Loop $_"
            Invoke-SSHCommand -SessionId $ssh.SessionId -Command $cmd -TimeOut 600 | select -ExpandProperty Output
            sleep 10
        }
 
        Remove-SSHSession -SessionId $ssh.SessionId | Out-Null
}
 
$jobs = @()
$n = 1 
Get-Cluster -Name $clusterName | Get-VMHost -PipelineVariable esx |
ForEach-Object -Process {
    Write-Host -ForegroundColor Blue -NoNewline "$($esx.Name)"
    if((Get-VMHostService -VMHost $esx).where({$_.Key -eq 'TSM-SSH'}).Running){
        Write-Host -ForegroundColor Green " SSH running"
        $jobs += Start-Job -ScriptBlock $code -Name "SSH Job" -ArgumentList $esx.Name,$user,$pswd,$TestName,$delay,$n
    }
    $n++
}
 
Wait-Job -Job $jobs
Receive-Job -Job $jobs