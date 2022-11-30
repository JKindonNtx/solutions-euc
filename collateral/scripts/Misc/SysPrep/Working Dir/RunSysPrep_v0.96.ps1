#Requires -Version 2.0
#This File is in Unicode format.  Do not edit in an ASCII editor.

<#
.SYNOPSIS
    Runs an unattended version of Sysprep.
.DESCRIPTION
    This script can be used to run an unattended version of Sysprep, focussed on Acropolis Hypervisor.
    Prerequisites: 
    Windows 7/Windows 2008R2 and up
    WinRM Enabled: https://support.microsoft.com/en-us/kb/555966
    Set WinRM Trusted Hosts: winrm set winrm/config/client @{TrustedHosts="*"}
    Set your execution policy to unrestricted
.PARAMETER ComputerName
    The hostname for this VM
.PARAMETER DomainName
    The Domain name for the domain join
.PARAMETER DomainUser
    Username for the domain join, need to be in domain\username format
.PARAMETER DomainPwd
    Password for domain join
.PARAMETER RegisteredName
    Setting the registered name for this VM
.PARAMETER Organisation
    Setting the registered organisation name for this VM
            .EXAMPLE
    PS C:\PSScript > .\RunSysPrep_vx.x.ps1 -ComputerName "VDI001" -DomainName "contoso.local" -DomainUser "Contoso\administrator" -DomainPwd "*******" -RegisterNamed "Nutanix" -Organization "Nutanix Inc"
.INPUTS
    None.  You cannot pipe objects to this script.
.OUTPUTS
    No objects are output from this script.  
.NOTES
    NAME: RunSysPrep_vx.x.ps1
    VERSION: 1.0
    AUTHOR: Kees Baggerman with help from Iain Brighton
    LASTEDIT: July, 2015
#>



[CmdletBinding()]
param(
      [Parameter(Mandatory = $True)][String]$ComputerName,
      [Parameter(Mandatory = $True)][String]$DomainName,
      [Parameter(Mandatory = $True)][String]$DomainUser,
      [Parameter(Mandatory = $True)][String]$RegisteredName,
      [Parameter(Mandatory = $True)][String]$Organization,
      [Parameter(Mandatory = $True)][Security.SecureString]$DomainPwd
      )
   

# Taking a secure password and converting to plain text
Function ConvertTo-PlainText( [security.securestring]$secure ) {
    $marshal = [Runtime.InteropServices.Marshal]
    $marshal::PtrToStringAuto( $marshal::SecureStringToBSTR($secure) )
}
      
# Set the path variable to the XML file needed for sys prep 
 $path = 'C:\Windows\Temp\unattend.xml'

      
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
            <ComputerName>test</ComputerName>
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
                <PlainText>true</PlainText>
             </Password>
                <Enabled>true</Enabled>
                <Username>administrator</Username>
        </AutoLogon>
        <UserAccounts>
            <LocalAccounts>
                <LocalAccount wcm:action="add">
                <Password>
                <Value>password</Value>
                <PlainText>true</PlainText>
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

# Writing the actual XML file with UTF8 encoding
$template | Out-File $Path -encoding UTF8

# Loading the XML file to modify values
$xml = New-Object XML
$xml.Load($path)

$xml.unattend.settings[0].component[1].UserData.FullName = $RegisteredName
$xml.unattend.settings[0].component[1].UserData.Organization = $Organization
$xml.unattend.settings[2].component[1].ComputerName = $ComputerName
$xml.unattend.settings[2].component[2].identification.JoinDomain = $DomainName
$xml.unattend.settings[2].component[2].identification.credentials.UserName = $DomainUser
$xml.unattend.settings[2].component[2].identification.credentials.Password = ConvertTo-PlainText $DomainPwd
$xml.unattend.settings[2].component[2].identification.credentials.Domain = $DomainName

# Saving the XML
$xml.Save($path)

# Enabling the default administrator account
net user administrator /active:yes

# Running SysPrep adding /mode:vm when running Windows 8 or above to speed up the sysprep process

$Version=(Get-WmiObject win32_operatingsystem).version  
  
if(!($version -eq "6.1"))    
{$argList = "/generalize /oobe /reboot /unattend:$path"}  
else    
{$argList = "/generalize /oobe /reboot /mode:vm /unattend:$path"}

Start-Process -FilePath C:\Windows\System32\Sysprep\Sysprep.exe -ArgumentList $argList