function Get-UnattendFile {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$DomainJoin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$OU,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$AdminPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ProductKey,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$HostName
    )

    try {

        #If a domain is present, add the portion to join to the domain
        if ($DomainJoin -eq $true){
            $JoinDomain = '<component name=\"Microsoft-Windows-UnattendedJoin\" processorArchitecture=\"amd64\" publicKeyToken=\"31bf3856ad364e35\" language=\"neutral\" versionScope=\"nonSxS\" xmlns:wcm=\"http://schemas.microsoft.com/WMIConfig/2002/State\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"> <Identification> <Credentials> <Domain>'
            $JoinDomain += $Domain
            $JoinDomain += '</Domain> <Username>administrator</Username> <Password>'
            $JoinDomain += $AdminPassword
            $JoinDomain += '</Password> </Credentials> <JoinDomain>'
            $JoinDomain += $Domain
            $JoinDomain += '</JoinDomain> <MachineObjectOU>'
            $JoinDomain += $OU
            $JoinDomain += '</MachineObjectOU> </Identification> </component>'
        }

        else {
            $JoinDomain = ""
        }

        #To pass an Unattend.xml as JSON, make sure the XML ends up all on one line and put a \ before any ".  Pass this as "userdata" in the "vm_customization_config"
        $userdata = '<?xml version=\"1.0\" encoding=\"UTF-8\"?> <unattend xmlns=\"urn:schemas-microsoft-com:unattend\"> <settings pass=\"specialize\"> '
        $userdata += $JoinDomain
        $userdata += ' <component xmlns:wcm=\"http://schemas.microsoft.com/WMIConfig/2002/State\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" name=\"Microsoft-Windows-Shell-Setup\" processorArchitecture=\"amd64\" publicKeyToken=\"31bf3856ad364e35\" language=\"neutral\" versionScope=\"nonSxS\"> <ComputerName>'
        $userdata += $Hostname
        $userdata += '</ComputerName> <RegisteredOrganization>Nutanix</RegisteredOrganization> <RegisteredOwner>Nutanix</RegisteredOwner> </component> <component xmlns=\"\" name=\"Microsoft-Windows-TerminalServices-LocalSessionManager\" publicKeyToken=\"31bf3856ad364e35\" language=\"neutral\" versionScope=\"nonSxS\" processorArchitecture=\"amd64\"> <fDenyTSConnections>false</fDenyTSConnections> </component> <component xmlns=\"\" name=\"Microsoft-Windows-TerminalServices-RDP-WinStationExtensions\" publicKeyToken=\"31bf3856ad364e35\" language=\"neutral\" versionScope=\"nonSxS\" processorArchitecture=\"amd64\"> <UserAuthentication>0</UserAuthentication> </component> <component xmlns:wcm=\"http://schemas.microsoft.com/WMIConfig/2002/State\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" name=\"Networking-MPSSVC-Svc\" processorArchitecture=\"amd64\" publicKeyToken=\"31bf3856ad364e35\" language=\"neutral\" versionScope=\"nonSxS\"> </component> </settings> <settings pass=\"oobeSystem\"> <component xmlns:wcm=\"http://schemas.microsoft.com/WMIConfig/2002/State\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" name=\"Microsoft-Windows-Shell-Setup\" processorArchitecture=\"amd64\" publicKeyToken=\"31bf3856ad364e35\" language=\"neutral\" versionScope=\"nonSxS\"> <UserAccounts> <AdministratorPassword> <Value>'
        $userdata += $AdminPassword
        $userdata += '</Value> <PlainText>true</PlainText> </AdministratorPassword> </UserAccounts> <AutoLogon> <Password> <Value>'
        $userdata += $AdminPassword
        $userdata += '</Value> <PlainText>true</PlainText> </Password> <Username>Administrator</Username> <Enabled>true</Enabled> <LogonCount>1</LogonCount> </AutoLogon> <OOBE> <HideEULAPage>true</HideEULAPage> <SkipMachineOOBE>true</SkipMachineOOBE> </OOBE> </component> <component xmlns:wcm=\"http://schemas.microsoft.com/WMIConfig/2002/State\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" name=\"Microsoft-Windows-International-Core\" processorArchitecture=\"amd64\" publicKeyToken=\"31bf3856ad364e35\" language=\"neutral\" versionScope=\"nonSxS\"> <InputLocale>en-US</InputLocale> <SystemLocale>en-US</SystemLocale> <UILanguageFallback>en-us</UILanguageFallback> <UILanguage>en-US</UILanguage> <UserLocale>en-US</UserLocale> </component> </settings> </unattend>'

        #End of Unattend.xml build

    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }
    
    return $userdata
}