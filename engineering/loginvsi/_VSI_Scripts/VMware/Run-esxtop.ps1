
	Get-Module -Name VMware* -ListAvailable | Import-Module
 
    Write-Host (Get-Date) ": Starting performance data capture on hypervisor."
    
    $TestName = "ESX-Hor-FSLr"
    $configESXServer = Get-Content -Path "$PSScriptRoot\config.ESXServer.json" -Raw | ConvertFrom-Json
    $Hosts = @("rtp-test83-1", "rtp-test83-2", "rtp-test83-3", "rtp-test83-4", "rtp-test84-1", "rtp-test84-2", "rtp-test84-3", "rtp-test84-4")
    $delay = 30
	$password = ConvertTo-SecureString $($configESXServer.rootPassword) -AsPlainText -Force
    $hostCredential = New-Object System.Management.Automation.PSCredential ("root", $password)
      
    Foreach ($ESXhost in $hosts) {
		$command = "esxtop -b -d $delay -n 150 > /vmfs/volumes/VDI/$ESXhost.$TestName.csv"
        $session = New-SSHSession -ComputerName $ESXhost -Credential $hostCredential -AcceptKey
        Invoke-SSHCommand -SessionId $session.SessionId -Command $command -TimeOut 1
        Get-SSHSession | Remove-SSHSession | Out-Null
    }