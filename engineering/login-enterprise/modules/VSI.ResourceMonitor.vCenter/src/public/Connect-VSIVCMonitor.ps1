function Connect-VSIVCMonitor {
    param(
        $vCenterServer,
        $vCenterUsername,
        $vCenterPassword
    )
    Import-Module VMware.VimAutomation.Core
    Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -InvalidCertificateAction Ignore -ParticipateInCeip $false -DisplayDeprecationWarnings $false -Scope Session -Confirm:$false | Out-Null
    Connect-VIServer -Server $vCenterServer -User $vCenterUsername -Password $vCenterPassword
}