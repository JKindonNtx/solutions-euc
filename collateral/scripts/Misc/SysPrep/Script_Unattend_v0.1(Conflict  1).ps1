######
# Todo: variable, veiligheid, xml verwijderen, GUI
#
#
######
$ComputerName = 'new'
$DomainName = 'Contoso.local'
$Username = 'Contoso\administrator' # in Domain\Username format
$pathName = '%temp%'



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
                <Organization>$organizationname</Organization>
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
                    <Password>password</Password>
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
                <Value>password</Value>
                <PlainText>false</PlainText>
             </Password>
                <Enabled>true</Enabled>
                <Username>administrator</Username>
        </AutoLogon>
        <UserAccounts>
            <LocalAccounts>
                <LocalAccount wcm:action="add">
                <Password>
                <Value>password</Value>
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

$template | Out-File .\desktop\unattend.xml -encoding UTF8


# Loading the XML file to modify values
$xml = New-Object XML
$xml.Load(".\desktop\unattend.xml")

# Changing the XML values here

# Enabling the default administrator account
net user administrator /active:yes

# Running SysPrep
Start-Process -FilePath C:\Windows\System32\Sysprep\Sysprep.exe -ArgumentList '/generalize /oobe /reboot /unattend:c:\users\admin\desktop\unattend.xml'

