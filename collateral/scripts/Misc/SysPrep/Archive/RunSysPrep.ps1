$ComputerName = 'new'
$DomainName = 'Contoso.local'
$Username = 'Contoso\administrator' # in Domain\Username format
$CitrixDDC = 'CONTMXD001.contoso.local'
$pathName = '%temp%'

# Enabling the default administrator account
net user administrator /active:yes

# Building Custom Made XML file
$File ="C:\Windows\Temp\unattend.xml"

'<?xml version="1.0" encoding="utf-8"?>' | Out-File $File
'<unattend xmlns="urn:schemas-microsoft-com:unattend">' | Out-File $File -append
'<settings pass="windowsPE">' | Out-File $File -append
'<component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<SetupUILanguage>' | Out-File $File -append
'<UILanguage>en-US</UILanguage>' | Out-File $File -append
'</SetupUILanguage>' | Out-File $File -append
'<InputLocale>1033:00000409</InputLocale>' | Out-File $File -append
'<SystemLocale>en-US</SystemLocale>' | Out-File $File -append
'<UILanguage>en-US</UILanguage>' | Out-File $File -append
'<UserLocale>en-US</UserLocale>' | Out-File $File -append
'</component>' | Out-File $File -append
'<component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<SetupUILanguage>' | Out-File $File -append
'<UILanguage>en-US</UILanguage>' | Out-File $File -append
'</SetupUILanguage>' | Out-File $File -append
'<InputLocale>1033:00000409</InputLocale>' | Out-File $File -append
'<SystemLocale>en-US</SystemLocale>' | Out-File $File -append
'<UILanguage>en-US</UILanguage>' | Out-File $File -append
'<UserLocale>en-US</UserLocale>' | Out-File $File -append
'</component>' | Out-File $File -append
'<component name="Microsoft-Windows-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<Diagnostics>' | Out-File $File -append
'<OptIn>false</OptIn>' | Out-File $File -append
'</Diagnostics>' | Out-File $File -append
'<DiskConfiguration>' | Out-File $File -append
'<WillShowUI>OnError</WillShowUI>' | Out-File $File -append
'<Disk wcm:action="add">' | Out-File $File -append
'<DiskID>0</DiskID>' | Out-File $File -append
'<WillWipeDisk>false</WillWipeDisk>' | Out-File $File -append
'<CreatePartitions>' | Out-File $File -append
'<CreatePartition wcm:action="add">' | Out-File $File -append
'<Order>1</Order>' | Out-File $File -append
'<Type>Primary</Type>' | Out-File $File -append
'<Size>100</Size>' | Out-File $File -append
'</CreatePartition>' | Out-File $File -append
'<CreatePartition wcm:action="add">' | Out-File $File -append
'<Order>2</Order>' | Out-File $File -append
'<Type>Primary</Type>' | Out-File $File -append
'<Extend>true</Extend>' | Out-File $File -append
'</CreatePartition>' | Out-File $File -append
'</CreatePartitions>' | Out-File $File -append
'<ModifyPartitions>' | Out-File $File -append
'<ModifyPartition wcm:action="add">' | Out-File $File -append
'<Format>NTFS</Format>' | Out-File $File -append
'<Label>System Reserved</Label>' | Out-File $File -append
'<Order>1</Order>' | Out-File $File -append
'<Active>true</Active>' | Out-File $File -append
'<PartitionID>1</PartitionID>' | Out-File $File -append
'<TypeID>0x27</TypeID>' | Out-File $File -append
'</ModifyPartition>' | Out-File $File -append
'<ModifyPartition wcm:action="add">' | Out-File $File -append
'<Active>true</Active>' | Out-File $File -append
'<Format>NTFS</Format>' | Out-File $File -append
'<Label>OS</Label>' | Out-File $File -append
'<Letter>C</Letter>' | Out-File $File -append
'<Order>2</Order>' | Out-File $File -append
'<PartitionID>2</PartitionID>' | Out-File $File -append
'</ModifyPartition>' | Out-File $File -append
'</ModifyPartitions>' | Out-File $File -append
'</Disk>' | Out-File $File -append
'</DiskConfiguration>' | Out-File $File -append
'<ImageInstall>' | Out-File $File -append
'<OSImage>' | Out-File $File -append
'<InstallTo>' | Out-File $File -append
'<DiskID>0</DiskID>' | Out-File $File -append
'<PartitionID>2</PartitionID>' | Out-File $File -append
'</InstallTo>' | Out-File $File -append
'<WillShowUI>OnError</WillShowUI>' | Out-File $File -append
'<InstallToAvailablePartition>false</InstallToAvailablePartition>' | Out-File $File -append
'</OSImage>' | Out-File $File -append
'</ImageInstall>' | Out-File $File -append
'<UserData>' | Out-File $File -append
'<AcceptEula>true</AcceptEula>' | Out-File $File -append
'<FullName>administrator</FullName>' | Out-File $File -append
'<Organization>$organizationname</Organization>' | Out-File $File -append
'</UserData>' | Out-File $File -append
'<EnableFirewall>true</EnableFirewall>' | Out-File $File -append
'</component>' | Out-File $File -append
'<component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<Diagnostics>' | Out-File $File -append
'<OptIn>false</OptIn>' | Out-File $File -append
'</Diagnostics>' | Out-File $File -append
'<DiskConfiguration>' | Out-File $File -append
'<WillShowUI>OnError</WillShowUI>' | Out-File $File -append
'<Disk wcm:action="add">' | Out-File $File -append
'<DiskID>0</DiskID>' | Out-File $File -append
'<WillWipeDisk>false</WillWipeDisk>' | Out-File $File -append
'<CreatePartitions>' | Out-File $File -append
'<CreatePartition wcm:action="add">' | Out-File $File -append
'<Order>1</Order>' | Out-File $File -append
'<Type>Primary</Type>' | Out-File $File -append
'<Size>100</Size>' | Out-File $File -append
'</CreatePartition>' | Out-File $File -append
'<CreatePartition wcm:action="add">' | Out-File $File -append
'<Order>2</Order>' | Out-File $File -append
'<Type>Primary</Type>' | Out-File $File -append
'<Extend>true</Extend>' | Out-File $File -append
'</CreatePartition>' | Out-File $File -append
'</CreatePartitions>' | Out-File $File -append
'<ModifyPartitions>' | Out-File $File -append
'<ModifyPartition wcm:action="add">' | Out-File $File -append
'<Format>NTFS</Format>' | Out-File $File -append
'<Label>System Reserved</Label>' | Out-File $File -append
'<Order>1</Order>' | Out-File $File -append
'<Active>true</Active>' | Out-File $File -append
'<PartitionID>1</PartitionID>' | Out-File $File -append
'<TypeID>0x27</TypeID>' | Out-File $File -append
'</ModifyPartition>' | Out-File $File -append
'<ModifyPartition wcm:action="add">' | Out-File $File -append
'<Active>true</Active>' | Out-File $File -append
'<Format>NTFS</Format>' | Out-File $File -append
'<Label>OS</Label>' | Out-File $File -append
'<Letter>C</Letter>' | Out-File $File -append
'<Order>2</Order>' | Out-File $File -append
'<PartitionID>2</PartitionID>' | Out-File $File -append
'</ModifyPartition>' | Out-File $File -append
'</ModifyPartitions>' | Out-File $File -append
'</Disk>' | Out-File $File -append
'</DiskConfiguration>' | Out-File $File -append
'<ImageInstall>' | Out-File $File -append
'<OSImage>' | Out-File $File -append
'<InstallTo>' | Out-File $File -append
'<DiskID>0</DiskID>' | Out-File $File -append
'<PartitionID>2</PartitionID>' | Out-File $File -append
'</InstallTo>' | Out-File $File -append
'<WillShowUI>OnError</WillShowUI>' | Out-File $File -append
'<InstallToAvailablePartition>false</InstallToAvailablePartition>' | Out-File $File -append
'</OSImage>' | Out-File $File -append
'</ImageInstall>' | Out-File $File -append
'<UserData>' | Out-File $File -append
'<AcceptEula>true</AcceptEula>' | Out-File $File -append
'<FullName>administrator</FullName>' | Out-File $File -append
'<Organization>$organizationname</Organization>' | Out-File $File -append
'</UserData>' | Out-File $File -append
'<EnableFirewall>true</EnableFirewall>' | Out-File $File -append
'</component>' | Out-File $File -append
'</settings>' | Out-File $File -append
'<settings pass="generalize">' | Out-File $File -append
'<component name="Microsoft-Windows-Security-SPP" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<SkipRearm>1</SkipRearm>' | Out-File $File -append
'</component>' | Out-File $File -append
'</settings>' | Out-File $File -append
'<settings pass="generalize">' | Out-File $File -append
'<component name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<SkipRearm>1</SkipRearm>' | Out-File $File -append
'</component>' | Out-File $File -append
'</settings>' | Out-File $File -append
'<settings pass="specialize">' | Out-File $File -append
'<component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<SkipAutoActivation>true</SkipAutoActivation>' | Out-File $File -append
'</component>' | Out-File $File -append
'<component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<SkipAutoActivation>true</SkipAutoActivation>' | Out-File $File -append
'</component>' | Out-File $File -append
'<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<ComputerName>test</ComputerName>' | Out-File $File -append
'<ProductKey>HYF8J-CVRMY-CM74G-RPHKF-PW487</ProductKey>' | Out-File $File -append
'<TimeZone>Pacific Standard Time</TimeZone>' | Out-File $File -append
'</component>' | Out-File $File -append
'<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<ComputerName></ComputerName>' | Out-File $File -append
'<ProductKey>HYF8J-CVRMY-CM74G-RPHKF-PW487</ProductKey>' | Out-File $File -append
'<TimeZone>Pacific Standard Time</TimeZone>' | Out-File $File -append
'</component>' | Out-File $File -append
'</settings>' | Out-File $File -append
'<settings pass="oobeSystem">' | Out-File $File -append
'<component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<InputLocale>1033:00000409</InputLocale>' | Out-File $File -append
'<UILanguage>en-US</UILanguage>' | Out-File $File -append
'<UserLocale>en-US</UserLocale>' | Out-File $File -append
'</component>' | Out-File $File -append
'<component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<InputLocale>1033:00000409</InputLocale>' | Out-File $File -append
'<UILanguage>en-US</UILanguage>' | Out-File $File -append
'<UserLocale>en-US</UserLocale>' | Out-File $File -append
'</component>' | Out-File $File -append
'<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<RegisteredOwner>administrator</RegisteredOwner>' | Out-File $File -append
'<OOBE>' | Out-File $File -append
'<HideEULAPage>true</HideEULAPage>' | Out-File $File -append
'<NetworkLocation>Work</NetworkLocation>' | Out-File $File -append
'<ProtectYourPC>1</ProtectYourPC>' | Out-File $File -append
'<HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>' | Out-File $File -append
'<SkipMachineOOBE>true</SkipMachineOOBE>' | Out-File $File -append
'<SkipUserOOBE>true</SkipUserOOBE>' | Out-File $File -append
'</OOBE>' | Out-File $File -append
'<DisableAutoDaylightTimeSet>false</DisableAutoDaylightTimeSet>' | Out-File $File -append
'<FirstLogonCommands>' | Out-File $File -append
'<SynchronousCommand wcm:action="add">' | Out-File $File -append
'<RequiresUserInput>false</RequiresUserInput>' | Out-File $File -append
'<Order>1</Order>' | Out-File $File -append
'<Description>Disable Auto Updates</Description>' | Out-File $File -append
'<CommandLine>reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 1 /f</CommandLine>' | Out-File $File -append
'</SynchronousCommand>' | Out-File $File -append
'<SynchronousCommand wcm:action="add">' | Out-File $File -append
'<Description>Control Panel View</Description>' | Out-File $File -append
'<Order>2</Order>' | Out-File $File -append
'<CommandLine>reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" /v StartupPage /t REG_DWORD /d 1 /f</CommandLine>' | Out-File $File -append
'<RequiresUserInput>true</RequiresUserInput>' | Out-File $File -append
'</SynchronousCommand>' | Out-File $File -append
'<SynchronousCommand wcm:action="add">' | Out-File $File -append
'<Order>3</Order>' | Out-File $File -append
'<Description>Control Panel Icon Size</Description>' | Out-File $File -append
'<RequiresUserInput>false</RequiresUserInput>' | Out-File $File -append
'<CommandLine>reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" /v AllItemsIconView /t REG_DWORD /d 1 /f</CommandLine>' | Out-File $File -append
'</SynchronousCommand>' | Out-File $File -append
'</FirstLogonCommands>' | Out-File $File -append
'<AutoLogon>' | Out-File $File -append
'<Password>' | Out-File $File -append
'<Value>nutanix/4u</Value>' | Out-File $File -append
'<PlainText>true</PlainText>' | Out-File $File -append
'</Password>' | Out-File $File -append
'<Enabled>true</Enabled>' | Out-File $File -append
'<Username>administrator</Username>' | Out-File $File -append
'</AutoLogon>' | Out-File $File -append
'<UserAccounts>' | Out-File $File -append
'<LocalAccounts>' | Out-File $File -append
'<LocalAccount wcm:action="add">' | Out-File $File -append
'<Password>' | Out-File $File -append
'<Value>nutanix/4u</Value>' | Out-File $File -append
'<PlainText>true</PlainText>' | Out-File $File -append
'</Password>' | Out-File $File -append
'<Description></Description>' | Out-File $File -append
'<DisplayName>administrator</DisplayName>' | Out-File $File -append
'<Group>Administrators</Group>' | Out-File $File -append
'<Name>administrator</Name>' | Out-File $File -append
'</LocalAccount>' | Out-File $File -append
'</LocalAccounts>' | Out-File $File -append
'</UserAccounts>' | Out-File $File -append
'</component>' | Out-File $File -append
'<component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<RegisteredOwner>administrator</RegisteredOwner>' | Out-File $File -append
'<OOBE>' | Out-File $File -append
'<HideEULAPage>true</HideEULAPage>' | Out-File $File -append
'<NetworkLocation>Work</NetworkLocation>' | Out-File $File -append
'<ProtectYourPC>1</ProtectYourPC>' | Out-File $File -append
'<HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>' | Out-File $File -append
'<SkipMachineOOBE>true</SkipMachineOOBE>' | Out-File $File -append
'<SkipUserOOBE>true</SkipUserOOBE>' | Out-File $File -append
'</OOBE>' | Out-File $File -append
'<DisableAutoDaylightTimeSet>false</DisableAutoDaylightTimeSet>' | Out-File $File -append
'<FirstLogonCommands>' | Out-File $File -append
'<SynchronousCommand wcm:action="add">' | Out-File $File -append
'<RequiresUserInput>false</RequiresUserInput>' | Out-File $File -append
'<Order>1</Order>' | Out-File $File -append
'<Description>Disable Auto Updates</Description>' | Out-File $File -append
'<CommandLine>reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 1 /f</CommandLine>' | Out-File $File -append
'</SynchronousCommand>' | Out-File $File -append
'<SynchronousCommand wcm:action="add">' | Out-File $File -append
'<Description>Control Panel View</Description>' | Out-File $File -append
'<Order>2</Order>' | Out-File $File -append
'<CommandLine>reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" /v StartupPage /t REG_DWORD /d 1 /f</CommandLine>' | Out-File $File -append
'<RequiresUserInput>true</RequiresUserInput>' | Out-File $File -append
'</SynchronousCommand>' | Out-File $File -append
'<SynchronousCommand wcm:action="add">' | Out-File $File -append
'<Order>3</Order>' | Out-File $File -append
'<Description>Control Panel Icon Size</Description>' | Out-File $File -append
'<RequiresUserInput>false</RequiresUserInput>' | Out-File $File -append
'<CommandLine>reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel" /v AllItemsIconView /t REG_DWORD /d 1 /f</CommandLine>' | Out-File $File -append
'</SynchronousCommand>' | Out-File $File -append
'</FirstLogonCommands>' | Out-File $File -append
'<AutoLogon>' | Out-File $File -append
'<Password>' | Out-File $File -append
'<Value>nutanix/4u</Value>' | Out-File $File -append
'<PlainText>true</PlainText>' | Out-File $File -append
'</Password>' | Out-File $File -append
'<Enabled>true</Enabled>' | Out-File $File -append
'<Username>administrator</Username>' | Out-File $File -append
'</AutoLogon>' | Out-File $File -append
'<UserAccounts>' | Out-File $File -append
'<LocalAccounts>' | Out-File $File -append
'<LocalAccount wcm:action="add">' | Out-File $File -append
'<Password>' | Out-File $File -append
'<Value>nutanix/4u</Value>' | Out-File $File -append
'<PlainText>true</PlainText>' | Out-File $File -append
'</Password>' | Out-File $File -append
'<Description></Description>' | Out-File $File -append
'<DisplayName>administrator</DisplayName>' | Out-File $File -append
'<Group>Administrators</Group>' | Out-File $File -append
'<Name>administrator</Name>' | Out-File $File -append
'</LocalAccount>' | Out-File $File -append
'</LocalAccounts>' | Out-File $File -append
'</UserAccounts>' | Out-File $File -append
'</component>' | Out-File $File -append
'</settings>' | Out-File $File -append
'<settings pass="offlineServicing">' | Out-File $File -append
'<component name="Microsoft-Windows-LUA-Settings" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<EnableLUA>false</EnableLUA>' | Out-File $File -append
'</component>' | Out-File $File -append
'</settings>' | Out-File $File -append
'<settings pass="offlineServicing">' | Out-File $File -append
'<component name="Microsoft-Windows-LUA-Settings" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' | Out-File $File -append
'<EnableLUA>false</EnableLUA>' | Out-File $File -append
'</component>' | Out-File $File -append
'</settings>' | Out-File $File -append
'</unattend>' | Out-File $File -append
# Running SysPrep
Start-Process -FilePath C:\Windows\System32\Sysprep\Sysprep.exe -ArgumentList '/generalize /oobe /reboot /unattend:c:\Windows\Temp\unattend.xml'



# Adding the VM to the specified domain
# Add-Computer -Domain $DomainName -Credential $UserName
Add-Computer -Domainname $DomainName -credential (New-Object System.Management.Automation.PSCredential ($Username, (ConvertTo-SecureString "nutanix/4u" -AsPlainText -Force)))

# Reboot after domain join
Restart-Computer

# Installing the XenDesktop VDA and registering the Desktop Delivery COntroller
.\XenDesktopVdaSetup.exe /components VDA /controllers $CitrixDDC /noreboot /quiet /enable_remote_assistance /enable_real_time_transport /enable_hdx_ports


