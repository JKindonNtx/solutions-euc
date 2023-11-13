Install-Module -Name Evergreen -RequiredVersion 2301.787

$VMwareTools =  Get-EvergreenApp -Name VMwareTools

if ((Get-WmiObject win32_operatingsystem | select osarchitecture).osarchitecture -eq "64-bit")
{
    #64 bit logic here
    Write "64-bit OS"
    WGET $VmwareTools[0].uri -OutFile C:\Install\VMwareTools.exe
    C:\Install\VMwareTools_x64.exe /S /v "/qn REBOOT=R ADDLOCAL=ALL REMOVE=Hgfs,CBHelper,FileIntrospection,NetworkIntrospection,ServiceDiscovery,DeviceHelper"
}
else
{
    #32 bit logic here
    Write "32-bit OS"
    WGET $VmwareTools[1].uri -OutFile C:\Install\VMwareTools.exe
    C:\Install\VMwareTools_x86.exe /S /v "/qn REBOOT=R ADDLOCAL=ALL REMOVE=Hgfs,CBHelper,FileIntrospection,NetworkIntrospection,ServiceDiscovery,DeviceHelper"
}

