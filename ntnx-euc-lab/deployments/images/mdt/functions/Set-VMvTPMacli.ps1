Function Set-VMvTPMacli {
    <#
    .Synopsis
        This function will add a virtual TPM on the VM using the SSH to CVM connection.
    .Description
        This function will add a virtual TPM on the VM using the SSH to CVM connection.
    #>

    Param (
        [string] $ClusterIP,
        [string] $CVMsshpassword,
        [string] $VMname
    )
    #Remove existing SSH keys.
    Get-SSHTrustedHost | Remove-SSHTrustedHost
    $command = "acli vm.update $($VMname) virtual_tpm=true"
    $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
    $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
    $session = New-SSHSession -ComputerName "$($ClusterIP)" -Credential $HostCredential -AcceptKey -KeepAliveInterval 5
    $SSHOutput = (Invoke-SSHCommand -Index $session.SessionId -Command $command -Timeout 7200).output
    Remove-SSHSession -Name $Session | Out-Null 
    Write-Host (Get-Date)": vTPM added to VM $($VMname)."
}