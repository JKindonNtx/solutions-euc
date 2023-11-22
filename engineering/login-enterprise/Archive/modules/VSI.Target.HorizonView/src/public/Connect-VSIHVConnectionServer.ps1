function Connect-VSIHVConnectionServer {
    param(
        [string]$Server,
        [string]$Username,
        [string]$Password,
        [string]$vCenterServer,
        [string]$vCenterUsername,
        [string]$vCenterPassword
    )
    import-module VMware.VimAutomation.HorizonView
    import-module VMware.VimAutomation.Core
    $ScriptRoot = if ([string]::IsNullOrEmpty($PSScriptRoot)) { $PWD.Path } else { $PSScriptRoot }
    $incPath = (Get-Item "$PSScriptRoot\..\..\inc\VMware.Hv.Helper").FullName
    import-module $incPath -Force
    Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -InvalidCertificateAction Ignore -ParticipateInCeip $false -DisplayDeprecationWarnings $false -Scope Session -Confirm:$false | Out-Null
    if ($Username.Contains("\")) {
        $global:VSIHV_ConnectionServer = connect-hvserver -Server $Server -User $username.Split("\")[1] -Password $Password -Domain $username.Split("\")[0]
    } else {
        $global:VSIHV_ConnectionServer = connect-hvserver -Server $Server -User $username -Password $Password
    }
    $global:VSIHV_vCenter = Connect-VIServer -Server $vCenterServer -User $vCenterUsername -Password $vCenterPassword

}