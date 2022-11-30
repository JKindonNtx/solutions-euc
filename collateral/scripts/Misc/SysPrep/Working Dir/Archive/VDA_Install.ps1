# Script name: YesNoPrompt.ps1
# Created on: 2007-01-07
# Used resources: Kent Flinkle and Ed Wilson

#Button Types 

#Value Description 
#0 Show OK button.
#1 Show OK and Cancel buttons.
#2 Show Abort, Retry, and Ignore buttons.
#3 Show Yes, No, and Cancel buttons.
#4 Show Yes and No buttons.
#5 Show Retry and Cancel buttons.


Function Get-FileName($initialDirectory)
{   
 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
 Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = "All files (*.*)| *.*"
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
} #end function Get-FileName

 
$a = new-object -comobject wscript.shell
$intAnswer = $a.popup("Do you want to install the Citrix VDA?", `
0,"Installing Citrix VDA",4)
If ($intAnswer -eq 6) {
  $a.popup("Please provide the location of the VDA installers")
  $Install =  Get-FileName -initialDirectory "c:\"
  $argList = "/components VDA /noreboot /masterimage /optimize /quiet /enable_remote_assistance /enable_real_time_transport /enable_hdx_ports"
  Start-Process $install -Argumentlist $argList
} else {
  $a.popup("The Citrix VDA won't be installed")
}

