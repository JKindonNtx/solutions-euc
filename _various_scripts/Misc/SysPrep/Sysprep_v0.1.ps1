######
# Todo: variable, veiligheid, xml verwijderen, GUI
#
#
######

    Param (
        # Computer name
        [Parameter(ValueFromPipelineByPropertyName=$true)] [ValidateNotNullOrEmpty()] [ValidateLength(1,15)]
        [string] $ComputerName,
        # Local Administrator Password
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)] [ValidateNotNullOrEmpty()] [ValidateLength(6,30)]
        [string] $Password,
         # Active Directory Domain
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)] [ValidateNotNullOrEmpty()] [ValidateLength(6,30)]
        [string] $DomainName,
         # Active Directory Administrator Account
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)] [ValidateNotNullOrEmpty()] [ValidateLength(6,30)]
        [string] $DomainUser,
        # Active Directory Administrator Password
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)] [ValidateNotNullOrEmpty()] [ValidateLength(6,30)]
        [string] $DomainPwd,
        # Registered Owner
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)] [ValidateNotNullOrEmpty()] [ValidateLength(6,30)]
        [string] $FullName,
        # Registered Organisation
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)] [ValidateNotNullOrEmpty()] [ValidateLength(6,30)]
        [string] $Organization,
         # Registered Organisation
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)] [ValidateNotNullOrEmpty()] [ValidateLength(6,30)]
        [string] $LocalUser,
        # Input Locale
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateLength(5,5)] [string] $InputLocale = "en-US",
        # System Locale
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateLength(5,5)] [string] $SystemLocale = "en-US",
        # User Locale
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateLength(5,5)] [string] $UserLocale = "en-US",
        # UI Language
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateLength(5,5)] [string] $UILanguage = "en-US", 
        # Registered Organization
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()] [string] $path = "C:\Windows\Temp\unattend.xml",
        
# $ComputerName = 'kb123'
# $DomainName = 'Contoso.local'
# $DomainUser = 'Contoso\administrator' # in Domain\Username format
# $CitrixDDC = 'CONTMXD001.contoso.local' 
# $path = 'C:\Windows\Temp\unattend.xml'
# $FullName = 'Kees Baggerman'
# $Organization = 'Nutanix'
# $ProductKey
# $Password = 'nutanix/4u'
# $LocalUser = 'Admin'
# $DomainPwd = 'nutanix/4u'
# $LocalUser = 'administrator'
# $Password = 'nutanix/4u'

# create a template XML to hold data
$template = @'

<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SetupUILanguage>
                <UILanguage>en-US</UILanguage>
            </SetupUILanguage>
            <InputLocale>1033:00000409</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Diagnostics>
                <OptIn>false</OptIn>
            </Diagnostics>
            <UserData>
                <AcceptEula>true</AcceptEula>
                <FullName>administrator</FullName>
                <Organization>organizationname</Organization>
            </UserData>
            <EnableFirewall>true</EnableFirewall>
          </component>
    </settings>
    <settings pass="generalize">
        <component name="Microsoft-Windows-Security-SPP" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <SkipRearm>1</SkipRearm>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SkipAutoActivation>true</SkipAutoActivation>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>KB</ComputerName>
            <ProductKey>HYF8J-CVRMY-CM74G-RPHKF-PW487</ProductKey>
            <TimeZone>Pacific Standard Time</TimeZone>
        </component>
        <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Identification>
                <Credentials>
                    <Domain>contoso.local</Domain>
                    <Password>nutanix/4u</Password>
                    <Username>administrator</Username>
                </Credentials>
              <JoinDomain>contoso.local</JoinDomain>
              <UnsecureJoin>False</UnsecureJoin>
            </Identification>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>1033:00000409</InputLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RegisteredOwner>administrator</RegisteredOwner>
                <OOBE>
                    <HideEULAPage>true</HideEULAPage>
                    <NetworkLocation>Work</NetworkLocation>
                    <ProtectYourPC>1</ProtectYourPC>
                    <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                    <SkipMachineOOBE>true</SkipMachineOOBE>
                    <SkipUserOOBE>true</SkipUserOOBE>
                </OOBE>
                    <DisableAutoDaylightTimeSet>false</DisableAutoDaylightTimeSet>
                    <FirstLogonCommands>
                    <SynchronousCommand wcm:action="add">
                    <RequiresUserInput>false</RequiresUserInput>
                    <Order>1</Order>
                    <Description>Disable Auto Updates</Description>
                    <CommandLine>reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 1 /f</CommandLine>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Description>Control Panel View</Description>
                    <Order>2</Order>
                    <CommandLine>reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" /v StartupPage /t REG_DWORD /d 1 /f</CommandLine>
                    <RequiresUserInput>true</RequiresUserInput>
                </SynchronousCommand>
                <SynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <Description>Control Panel Icon Size</Description>
                    <RequiresUserInput>false</RequiresUserInput>
                    <CommandLine>reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" /v AllItemsIconView /t REG_DWORD /d 1 /f</CommandLine>
                </SynchronousCommand>
           </FirstLogonCommands>
        <AutoLogon>
            <Password>
                <Value>nutanix/4u</Value>
                <PlainText>false</PlainText>
             </Password>
                <Enabled>true</Enabled>
                <Username>administrator</Username>
        </AutoLogon>
        <UserAccounts>
            <LocalAccounts>
                <LocalAccount wcm:action="add">
                <Password>
                <Value>nutanix/4u</Value>
                <PlainText>false</PlainText>
                </Password>
                <Description></Description>
                <DisplayName>administrator</DisplayName>
                <Group>Administrators</Group>
                <Name>administrator</Name>
            </LocalAccount>
          </LocalAccounts>
        </UserAccounts>
       </component>
        </settings>
    <settings pass="offlineServicing">
        <component name="Microsoft-Windows-LUA-Settings" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <EnableLUA>false</EnableLUA>
        </component>
    </settings>
</unattend>

'@

$template | Out-File $Path -encoding UTF8

# Loading the XML file to modify values
$xml = New-Object XML
$xml.Load($path)

$xml.unattend.settings[0].component[1].UserData.FullName = $FullName
$xml.unattend.settings[0].component[1].UserData.Organization = $Organization
$xml.unattend.settings[2].component[1].ComputerName = $ComputerName
# $xml.unattend.settings[2].component[1].ProductKey = $ProductKey
$xml.unattend.settings[3].component[1].Autologon.password.value = $Password
$xml.unattend.settings[3].component[1].Autologon.Username = $LocalUser
$xml.unattend.settings[2].component[2].identification.JoinDomain = $DomainName
$xml.unattend.settings[2].component[2].identification.credentials.UserName = $DomainUser
$xml.unattend.settings[2].component[2].identification.credentials.Password = $DomainPwd
$xml.unattend.settings[2].component[2].identification.credentials.Domain = $DomainName
$xml.unattend.settings[3].component[1].UserAccounts.LocalAccounts.LocalAccount.Name = $LocalUser
$xml.unattend.settings[3].component[1].UserAccounts.LocalAccounts.LocalAccount.Password.value = $Password

$xml.Save($path)

# Enabling the default administrator account
net user administrator /active:yes

# Running SysPrep
# Start-Process -FilePath C:\Windows\System32\Sysprep\Sysprep.exe -ArgumentList '/generalize /oobe /reboot /unattend:$path'

$argList = "/generalize /oobe /reboot /unattend:$path"
Start-Process -FilePath C:\Windows\System32\Sysprep\Sysprep.exe -ArgumentList $argList

# Installing the XenDesktop VDA and registering the Desktop Delivery COntroller
# .\XenDesktopVdaSetup.exe /components VDA /controllers $CitrixDDC /noreboot /quiet /enable_remote_assistance /enable_real_time_transport /enable_hdx_ports


