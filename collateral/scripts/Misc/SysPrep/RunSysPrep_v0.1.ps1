$ComputerName = 'new'
$DomainName = 'Contoso.local'
$Username = 'Contoso\administrator' # in Domain\Username format
$CitrixDDC = 'CONTMXD001.contoso.local'
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
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
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
            <DiskConfiguration>
                <WillShowUI>OnError</WillShowUI>
                <Disk wcm:action="add">
                <DiskID>0</DiskID>
                <WillWipeDisk>false</WillWipeDisk>
                <CreatePartitions>
                <CreatePartition wcm:action="add">
                <Order>1</Order>
                <Type>Primary</Type>
                <Size>100</Size>
            </CreatePartition>
            <CreatePartition wcm:action="add">
                    <Order>2</Order>
                    <Type>Primary</Type>
                    <Extend>true</Extend>
                </CreatePartition>
            </CreatePartitions>
            <ModifyPartitions>
            <ModifyPartition wcm:action="add">
                <Format>NTFS</Format>
                <Label>System Reserved</Label>
                <Order>1</Order>
                <Active>true</Active>
                <PartitionID>1</PartitionID>
                <TypeID>0x27</TypeID>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
                    <Active>true</Active>
                    <Format>NTFS</Format>
                    <Label>OS</Label>
                    <Letter>C</Letter>
                    <Order>2</Order>
                  <PartitionID>2</PartitionID>
                </ModifyPartition>
              </ModifyPartitions>
             </Disk>
            </DiskConfiguration>
            <ImageInstall>
             <OSImage>
              <InstallTo>
               <DiskID>0</DiskID>
                 <PartitionID>2</PartitionID>
               </InstallTo>
             <WillShowUI>OnError</WillShowUI>
             <InstallToAvailablePartition>false</InstallToAvailablePartition>
            </OSImage>
            </ImageInstall>
            <UserData>
                <AcceptEula>true</AcceptEula>
                <FullName>administrator</FullName>
                <Organization>$organizationname</Organization>
            </UserData>
            <EnableFirewall>true</EnableFirewall>
          </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <Diagnostics>
                    <OptIn>false</OptIn>
                </Diagnostics>
                    <DiskConfiguration>
                        <WillShowUI>OnError</WillShowUI>
                        <Disk wcm:action="add">
                        <DiskID>0</DiskID>
                        <WillWipeDisk>false</WillWipeDisk>
                        <CreatePartitions>
                        <CreatePartition wcm:action="add">
                        <Order>1</Order>
                        <Type>Primary</Type>
                        <Size>100</Size>
                    </CreatePartition>
                <CreatePartition wcm:action="add">
                    <Order>2</Order>
                    <Type>Primary</Type>
                    <Extend>true</Extend>
                </CreatePartition>
               </CreatePartitions>
            <ModifyPartitions>
                <ModifyPartition wcm:action="add">
                <Format>NTFS</Format>
                <Label>System Reserved</Label>
                <Order>1</Order>
                <Active>true</Active>
                <PartitionID>1</PartitionID>
                <TypeID>0x27</TypeID>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
                <Active>true</Active>
                <Format>NTFS</Format>
                <Label>OS</Label>
                <Letter>C</Letter>
                <Order>2</Order>
                <PartitionID>2</PartitionID>
            </ModifyPartition>
           </ModifyPartitions>
          </Disk>
         </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>2</PartitionID>
                    </InstallTo>
                    <WillShowUI>OnError</WillShowUI>
                    <InstallToAvailablePartition>false</InstallToAvailablePartition>
                </OSImage>
            </ImageInstall>
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
    <settings pass="generalize">
        <component name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SkipRearm>1</SkipRearm>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SkipAutoActivation>true</SkipAutoActivation>
        </component>
        <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SkipAutoActivation>true</SkipAutoActivation>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>test</ComputerName>
            <ProductKey>HYF8J-CVRMY-CM74G-RPHKF-PW487</ProductKey>
            <TimeZone>Pacific Standard Time</TimeZone>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName></ComputerName>
            <ProductKey>HYF8J-CVRMY-CM74G-RPHKF-PW487</ProductKey>
            <TimeZone>Pacific Standard Time</TimeZone>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>1033:00000409</InputLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
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
                <PlainText>true</PlainText>
             </Password>
                <Enabled>true</Enabled>
                <Username>administrator</Username>
        </AutoLogon>
        <UserAccounts>
            <LocalAccounts>
                <LocalAccount wcm:action="add">
                <Password>
                <Value>nutanix/4u</Value>
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
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
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
                <PlainText>true</PlainText>
            </Password>
                <Enabled>true</Enabled>
                <Username>administrator</Username>
        </AutoLogon>
                <UserAccounts>
                <LocalAccounts>
                <LocalAccount wcm:action="add">
            <Password>
                <Value>nutanix/4u</Value>
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
    <settings pass="offlineServicing">
           <component name="Microsoft-Windows-LUA-Settings" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <EnableLUA>false</EnableLUA>
            </component>
     </settings>
</unattend>

'@

$template | Out-File .\desktop\unattend.xml -encoding UTF8


# Loading the XML file to modify values
$xml = New-Object XML
$xml.Load(".\desktop\unattend.xml")

# Enabling the default administrator account
net user administrator /active:yes

# Running SysPrep
Start-Process -FilePath C:\Windows\System32\Sysprep\Sysprep.exe -ArgumentList '/generalize /oobe /reboot /unattend:c:\Windows\Temp\unattend.xml'



# Adding the VM to the specified domain
# Add-Computer -Domain $DomainName -Credential $UserName
Add-Computer -Domainname $DomainName -credential (New-Object System.Management.Automation.PSCredential ($Username, (ConvertTo-SecureString "nutanix/4u" -AsPlainText -Force)))

# Reboot after domain join
Restart-Computer

# Installing the XenDesktop VDA and registering the Desktop Delivery COntroller
.\XenDesktopVdaSetup.exe /components VDA /controllers $CitrixDDC /noreboot /quiet /enable_remote_assistance /enable_real_time_transport /enable_hdx_ports


