#Requires -Version 3.0
#This File is in Unicode format.  Do not edit in an ASCII editor.

#region help text

<#
.SYNOPSIS
	Creates an inventory of a Citrix PVS 7.x Farm.
.DESCRIPTION
	Creates an inventory of a Citrix PVS 7.x Farm using Microsoft PowerShell, Word,
	plain text or HTML.

	Word is NOT needed to run the script. This script will output in Text and HTML.
	
	You do NOT have to run this script on a PVS Server. This script was developed and run 
	from a Windows 8.1 VM.
	
	You can run this script remotely using the –AdminAddress (AA) parameter.
	
	Creates an output file named after the PVS farm.
	
	Word and PDF Document includes a Cover Page, Table of Contents and Footer.
	
	Includes support for the following language versions of Microsoft Word:
		Catalan
		Danish
		Dutch
		English
		Finnish
		French
		German
		Norwegian
		Portuguese
		Spanish
		Swedish

.PARAMETER CompanyName
	Company Name to use for the Cover Page.  
	Default value is contained in HKCU:\Software\Microsoft\Office\Common\UserInfo\CompanyName or
	HKCU:\Software\Microsoft\Office\Common\UserInfo\Company, whichever is populated on the 
	computer running the script.
	This parameter has an alias of CN.
	If either registry key does not exist and this parameter is not specified, the report will
	not contain a Company Name on the cover page.
	This parameter is only valid with the MSWORD and PDF output parameters.
.PARAMETER CoverPage
	What Microsoft Word Cover Page to use.
	Only Word 2010, 2013 and 2016 are supported.
	(default cover pages in Word en-US)
	
	Valid input is:
		Alphabet (Word 2010. Works)
		Annual (Word 2010. Doesn't work well for this report)
		Austere (Word 2010. Works)
		Austin (Word 2010/2013/2016. Doesn't work in 2013 or 2016, mostly works in 2010 but 
						Subtitle/Subject & Author fields need to be moved 
						after title box is moved up)
		Banded (Word 2013/2016. Works)
		Conservative (Word 2010. Works)
		Contrast (Word 2010. Works)
		Cubicles (Word 2010. Works)
		Exposure (Word 2010. Works if you like looking sideways)
		Facet (Word 2013/2016. Works)
		Filigree (Word 2013/2016. Works)
		Grid (Word 2010/2013/2016. Works in 2010)
		Integral (Word 2013/2016. Works)
		Ion (Dark) (Word 2013/2016. Top date doesn't fit, box needs to be manually resized or font 
						changed to 8 point)
		Ion (Light) (Word 2013/2016. Top date doesn't fit, box needs to be manually resized or font 
						changed to 8 point)
		Mod (Word 2010. Works)
		Motion (Word 2010/2013/2016. Works if top date is manually changed to 36 point)
		Newsprint (Word 2010. Works but date is not populated)
		Perspective (Word 2010. Works)
		Pinstripes (Word 2010. Works)
		Puzzle (Word 2010. Top date doesn't fit, box needs to be manually resized or font 
					changed to 14 point)
		Retrospect (Word 2013/2016. Works)
		Semaphore (Word 2013/2016. Works)
		Sideline (Word 2010/2013/2016. Doesn't work in 2013 or 2016, works in 2010)
		Slice (Dark) (Word 2013/2016. Doesn't work)
		Slice (Light) (Word 2013/2016. Doesn't work)
		Stacks (Word 2010. Works)
		Tiles (Word 2010. Date doesn't fit unless changed to 26 point)
		Transcend (Word 2010. Works)
		ViewMaster (Word 2013/2016. Works)
		Whisp (Word 2013/2016. Works)
		
	Default value is Sideline.
	This parameter has an alias of CP.
	This parameter is only valid with the MSWORD and PDF output parameters.
.PARAMETER UserName
	User name to use for the Cover Page and Footer.
	Default value is contained in $env:username
	This parameter has an alias of UN.
	This parameter is only valid with the MSWORD and PDF output parameters.
.PARAMETER PDF
	SaveAs PDF file instead of DOCX file.
	This parameter is disabled by default.
	The PDF file is roughly 5X to 10X larger than the DOCX file.
	This parameter requires Microsoft Word to be installed.
	This parameter uses the Word SaveAs PDF capability.
.PARAMETER Text
	Creates a formatted text file with a .txt extension.
	This parameter is disabled by default.
	This parameter is reserved for a future update and no useable output is created at this time.
.PARAMETER MSWord
	SaveAs DOCX file
	This parameter is set True if no other output format is selected.
.PARAMETER HTML
	Creates an HTML file with an .html extension.
	This parameter is disabled by default.
	This parameter is reserved for a future update and no output is created at this time.
.PARAMETER Hardware
	Use WMI to gather hardware information on: Computer System, Disks, Processor and Network Interface Cards
	This parameter is disabled by default.
	This parameter has an alias of HW.
.PARAMETER AdminAddress
	Specifies the name of a PVS server that the PowerShell script will connect to. 
	This parameter has an alias of AA.
.PARAMETER User
	Specifies the user used for the AdminAddress connection. 
.PARAMETER Domain
	Specifies the domain used for the AdminAddress connection. 
.PARAMETER Password
	Specifies the password used for the AdminAddress connection. 
.PARAMETER StartDate
	Start date for the Audit Trail report.

	Format for date only is MM/DD/YYYY.
	
	Format to include a specific time range is "MM/DD/YYYY HH:MM:SS" in 24 hour format.
	The double quotes are needed.
	
	Default is today's date minus seven days.
	This parameter has an alias of SD.
.PARAMETER EndDate
	End date for the Audit Trail report.

	Format for date only is MM/DD/YYYY.
	
	Format to include a specific time range is "MM/DD/YYYY HH:MM:SS" in 24 hour format.
	The double quotes are needed.
	
	Default is today's date.
	This parameter has an alias of ED.
.PARAMETER AddDateTime
	Adds a date time stamp to the end of the file name.
	Time stamp is in the format of yyyy-MM-dd_HHmm.
	June 1, 2015 at 6PM is 2015-06-01_1800.
	Output filename will be ReportName_2015-06-01_1800.docx (or .pdf).
	This parameter is disabled by default.
	This parameter has an alias of ADT.
.EXAMPLE
	PS C:\PSScript > .\PVS_Inventory_V5.ps1
	
	Will use all Default values.
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\Company="Carl Webster"
	$env:username = Administrator
	AdminAddress = LocalHost

	Carl Webster for the Company Name.
	Sideline for the Cover Page format.
	Administrator for the User Name.
	LocalHost for AdminAddress.
.EXAMPLE
	PS C:\PSScript > .\PVS_Inventory_V5.ps1 -PDF 
	
	Will use all Default values and save the document as a PDF file.
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\Company="Carl Webster"
	$env:username = Administrator
	AdminAddress = LocalHost

	Carl Webster for the Company Name.
	Sideline for the Cover Page format.
	Administrator for the User Name.
	LocalHost for AdminAddress.
.EXAMPLE
	PS C:\PSScript > .\PVS_Inventory_V5.ps1 -TEXT

	This parameter is reserved for a future update and no output is created at this time.
	
	Will use all default values and save the document as a formatted text file.
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\CompanyName="Carl Webster" or
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\Company="Carl Webster"
	$env:username = Administrator

	Carl Webster for the Company Name.
	Sideline for the Cover Page format.
	Administrator for the User Name.
	LocalHost for AdminAddress.
.EXAMPLE
	PS C:\PSScript > .\PVS_Inventory_V5.ps1 -HTML

	This parameter is reserved for a future update and no output is created at this time.
	
	Will use all default values and save the document as an HTML file.
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\CompanyName="Carl Webster" or
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\Company="Carl Webster"
	$env:username = Administrator

	Carl Webster for the Company Name.
	Sideline for the Cover Page format.
	Administrator for the User Name.
	LocalHost for AdminAddress.
.EXAMPLE
	PS C:\PSScript > .\PVS_Inventory_V5.ps1 -Hardware 
	
	Will use all Default values and add additional information for each server about its hardware.
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\CompanyName="Carl Webster" or
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\Company="Carl Webster"
	$env:username = Administrator

	Carl Webster for the Company Name.
	Sideline for the Cover Page format.
	Administrator for the User Name.
.EXAMPLE
	PS C:\PSScript .\PVS_Inventory_V5.ps1 -CompanyName "Carl Webster Consulting" -CoverPage "Mod" -UserName "Carl Webster"

	Will use:
		Carl Webster Consulting for the Company Name.
		Mod for the Cover Page format.
		Carl Webster for the User Name.
.EXAMPLE
	PS C:\PSScript .\PVS_Inventory_V5.ps1 -CN "Carl Webster Consulting" -CP "Mod" -UN "Carl Webster" -AdminAddress PVS1

	Will use:
		Carl Webster Consulting for the Company Name (alias CN).
		Mod for the Cover Page format (alias CP).
		Carl Webster for the User Name (alias UN).
		PVS1 for AdminAddress.
.EXAMPLE
	PS C:\PSScript .\PVS_Inventory_V5.ps1 -CN "Carl Webster Consulting" -CP "Mod" -UN "Carl Webster" -AdminAddress PVS1 -User cwebster -Domain WebstersLab -Password Abc123!@#

	Will use:
		Carl Webster Consulting for the Company Name (alias CN).
		Mod for the Cover Page format (alias CP).
		Carl Webster for the User Name (alias UN).
		PVS1 for AdminAddress.
		cwebster for User.
		WebstersLab for Domain.
		Abc123!@# for Password.
.EXAMPLE
	PS C:\PSScript .\PVS_Inventory_V5.ps1 -CN "Carl Webster Consulting" -CP "Mod" -UN "Carl Webster" -AdminAddress PVS1 -User cwebster

	Will use:
		Carl Webster Consulting for the Company Name (alias CN).
		Mod for the Cover Page format (alias CP).
		Carl Webster for the User Name (alias UN).
		PVS1 for AdminAddress.
		cwebster for User.
		Script will prompt for the Domain and Password
.EXAMPLE
	PS C:\PSScript > .\PVS_Inventory_V5.ps1 -StartDate "01/01/2015" -EndDate "01/31/2015" 
	
	Will use all Default values.
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\Company="Carl Webster"
	$env:username = Administrator
	AdminAddress = LocalHost

	Carl Webster for the Company Name.
	Sideline for the Cover Page format.
	Administrator for the User Name.
	LocalHost for AdminAddress.
	Will return all Audit Trail entries from "01/01/2015" through "01/31/2015".
.EXAMPLE
	PS C:\PSScript > .\PVS_Inventory_V5.ps1 -StartDate "01/01/2015 10:00:00" -EndDate "01/31/2015 14:00:00" 
	
	Will use all Default values.
	HKEY_CURRENT_USER\Software\Microsoft\Office\Common\UserInfo\Company="Carl Webster"
	$env:username = Administrator
	AdminAddress = LocalHost

	Carl Webster for the Company Name.
	Sideline for the Cover Page format.
	Administrator for the User Name.
	LocalHost for AdminAddress.
	Will return all Audit Trail entries from 01/01/2015 10:100AM through 01/31/2015 2:00PM.
.INPUTS
	None.  You cannot pipe objects to this script.
.OUTPUTS
	No objects are output from this script.  This script creates a Word or PDF document.
.NOTES
	NAME: PVS_Inventory_V5.ps1
	VERSION: 5.0
	AUTHOR: Carl Webster
	LASTEDIT: December 28, 2015
#>

#endregion

#region script parameters
#thanks to @jeffwouters and Michael B. Smith for helping me with these parameters
[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None", DefaultParameterSetName = "Word") ]

Param(
	[parameter(ParameterSetName="Word",Mandatory=$False)] 
	[Switch]$MSWord=$False,

	[parameter(ParameterSetName="PDF",Mandatory=$False)] 
	[Switch]$PDF=$False,

	[parameter(ParameterSetName="Text",Mandatory=$False)] 
	[Switch]$Text=$False,

	[parameter(ParameterSetName="HTML",Mandatory=$False)] 
	[Switch]$HTML=$False,

	[parameter(Mandatory=$False)] 
	[Alias("HW")]
	[Switch]$Hardware=$False, 

	[parameter(Mandatory=$False)] 
	[Alias("SD")]
	[Datetime]$StartDate = ((Get-Date -displayhint date).AddDays(-7)),

	[parameter(Mandatory=$False)] 
	[Alias("ED")]
	[Datetime]$EndDate = (Get-Date -displayhint date),
	
	[parameter(Mandatory=$False)] 
	[Alias("ADT")]
	[Switch]$AddDateTime=$False,
	
	[parameter(Mandatory=$False)] 
	[Alias("AA")]
	[string]$AdminAddress="",

	[parameter(Mandatory=$False)] 
	[string]$Domain="",

	[parameter(Mandatory=$False)] 
	[string]$User="",

	[parameter(Mandatory=$False)] 
	[string]$Password="",
	
	[parameter(ParameterSetName="Word",Mandatory=$False)] 
	[parameter(ParameterSetName="PDF",Mandatory=$False)] 
	[Alias("CN")]
	[ValidateNotNullOrEmpty()]
	[string]$CompanyName="",
    
	[parameter(ParameterSetName="Word",Mandatory=$False)] 
	[parameter(ParameterSetName="PDF",Mandatory=$False)] 
	[Alias("CP")]
	[ValidateNotNullOrEmpty()]
	[string]$CoverPage="Sideline", 

	[parameter(ParameterSetName="Word",Mandatory=$False)] 
	[parameter(ParameterSetName="PDF",Mandatory=$False)] 
	[Alias("UN")]
	[ValidateNotNullOrEmpty()]
	[string]$UserName=$env:username

	)
#endregion

#region script change log	
#webster@carlwebster.com
#@carlwebster on Twitter
#http://www.CarlWebster.com
#Created on April 30, 2015

#HTML functions and sample text contributed by Ken Avram October 2014
#endregion

#region initial variable testing and setup
Set-StrictMode -Version 2

#force  on
$PSDefaultParameterValues = @{"*:Verbose"=$True}
$SaveEAPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'

If($PDF -eq $Null)
{
	$PDF = $False
}
If($Text -eq $Null)
{
	$Text = $False
}
If($MSWord -eq $Null)
{
	$MSWord = $False
}
If($HTML -eq $Null)
{
	$HTML = $False
}
If($StartDate -eq $Null)
{
	$StartDate = ((Get-Date -displayhint date).AddDays(-7))
}
If($EndDate -eq $Null)
{
	$EndDate = ((Get-Date -displayhint date))
}
If($AddDateTime -eq $Null)
{
	$AddDateTime = $False
}
If($Hardware -eq $Null)
{
	$Hardware = $False
}
If($ComputerName -eq $Null)
{
	$ComputerName = "LocalHost"
}

If(!(Test-Path Variable:PDF))
{
	$PDF = $False
}
If(!(Test-Path Variable:Text))
{
	$Text = $False
}
If(!(Test-Path Variable:MSWord))
{
	$MSWord = $False
}
If(!(Test-Path Variable:HTML))
{
	$HTML = $False
}
If(!(Test-Path Variable:StartDate))
{
	$StartDate = ((Get-Date -displayhint date).AddDays(-7))
}
If(!(Test-Path Variable:EndDate))
{
	$EndDate = ((Get-Date -displayhint date))
}
If(!(Test-Path Variable:AddDateTime))
{
	$AddDateTime = $False
}
If(!(Test-Path Variable:Hardware))
{
	$Hardware = $False
}
If(!(Test-Path Variable:AdminAddress))
{
	$AdminAddress = ""
}

If($MSWord -eq $Null)
{
	If($Text -or $HTML -or $PDF)
	{
		$MSWord = $False
	}
	Else
	{
		$MSWord = $True
	}
}

If($MSWord -eq $False -and $PDF -eq $False -and $Text -eq $False -and $HTML -eq $False)
{
	$MSWord = $True
}

Write-Verbose "$(Get-Date): Testing output parameters"

If($MSWord)
{
	Write-Verbose "$(Get-Date): MSWord is set"
}
ElseIf($PDF)
{
	Write-Verbose "$(Get-Date): PDF is set"
}
ElseIf($Text)
{
	Write-Verbose "$(Get-Date): Text is set"
}
ElseIf($HTML)
{
	Write-Verbose "$(Get-Date): HTML is set"
}
Else
{
	$ErrorActionPreference = $SaveEAPreference
	Write-Verbose "$(Get-Date): Unable to determine output parameter"
	If($MSWord -eq $Null)
	{
		Write-Verbose "$(Get-Date): MSWord is Null"
	}
	ElseIf($PDF -eq $Null)
	{
		Write-Verbose "$(Get-Date): PDF is Null"
	}
	ElseIf($Text -eq $Null)
	{
		Write-Verbose "$(Get-Date): Text is Null"
	}
	ElseIf($HTML -eq $Null)
	{
		Write-Verbose "$(Get-Date): HTML is Null"
	}
	Else
	{
		Write-Verbose "$(Get-Date): MSWord is $($MSWord)"
		Write-Verbose "$(Get-Date): PDF is $($PDF)"
		Write-Verbose "$(Get-Date): Text is $($Text)"
		Write-Verbose "$(Get-Date): HTML is $($HTML)"
	}
	Write-Error "Unable to determine output parameter.  Script cannot continue"
	Exit
}
#endregion

#region initialize variables for word html and text
If($MSWord -or $PDF)
{
	#try and fix the issue with the $CompanyName variable
	$Script:CoName = $CompanyName
	Write-Verbose "$(Get-Date): CoName is $($Script:CoName)"
	
	#the following values were attained from 
	#http://groovy.codehaus.org/modules/scriptom/1.6.0/scriptom-office-2K3-tlb/apidocs/
	#http://msdn.microsoft.com/en-us/library/office/aa211923(v=office.11).aspx
	[int]$wdAlignPageNumberRight = 2
	[long]$wdColorGray15 = 14277081
	[long]$wdColorGray05 = 15987699 
	[int]$wdMove = 0
	[int]$wdSeekMainDocument = 0
	[int]$wdSeekPrimaryFooter = 4
	[int]$wdStory = 6
	[int]$wdColorRed = 255
	[int]$wdColorBlack = 0
	[int]$wdWord2007 = 12
	[int]$wdWord2010 = 14
	[int]$wdWord2013 = 15
	[int]$wdWord2016 = 16
	[int]$wdFormatDocumentDefault = 16
	[int]$wdFormatPDF = 17
	#http://blogs.technet.com/b/heyscriptingguy/archive/2006/03/01/how-can-i-right-align-a-single-column-in-a-word-table.aspx
	#http://msdn.microsoft.com/en-us/library/office/ff835817%28v=office.15%29.aspx
	[int]$wdAlignParagraphLeft = 0
	[int]$wdAlignParagraphCenter = 1
	[int]$wdAlignParagraphRight = 2
	#http://msdn.microsoft.com/en-us/library/office/ff193345%28v=office.15%29.aspx
	[int]$wdCellAlignVerticalTop = 0
	[int]$wdCellAlignVerticalCenter = 1
	[int]$wdCellAlignVerticalBottom = 2
	#http://msdn.microsoft.com/en-us/library/office/ff844856%28v=office.15%29.aspx
	[int]$wdAutoFitFixed = 0
	[int]$wdAutoFitContent = 1
	[int]$wdAutoFitWindow = 2
	#http://msdn.microsoft.com/en-us/library/office/ff821928%28v=office.15%29.aspx
	[int]$wdAdjustNone = 0
	[int]$wdAdjustProportional = 1
	[int]$wdAdjustFirstColumn = 2
	[int]$wdAdjustSameWidth = 3

	[int]$PointsPerTabStop = 36
	[int]$Indent0TabStops = 0 * $PointsPerTabStop
	[int]$Indent1TabStops = 1 * $PointsPerTabStop
	[int]$Indent2TabStops = 2 * $PointsPerTabStop
	[int]$Indent3TabStops = 3 * $PointsPerTabStop
	[int]$Indent4TabStops = 4 * $PointsPerTabStop

	# http://www.thedoctools.com/index.php?show=wt_style_names_english_danish_german_french
	[int]$wdStyleHeading1 = -2
	[int]$wdStyleHeading2 = -3
	[int]$wdStyleHeading3 = -4
	[int]$wdStyleHeading4 = -5
	[int]$wdStyleNoSpacing = -158
	[int]$wdTableGrid = -155

	#http://groovy.codehaus.org/modules/scriptom/1.6.0/scriptom-office-2K3-tlb/apidocs/org/codehaus/groovy/scriptom/tlb/office/word/WdLineStyle.html
	[int]$wdLineStyleNone = 0
	[int]$wdLineStyleSingle = 1

	[int]$wdHeadingFormatTrue = -1
	[int]$wdHeadingFormatFalse = 0 

	[string]$RunningOS = (Get-WmiObject -class Win32_OperatingSystem -EA 0).Caption
}

If($HTML)
{
    Set htmlredmask         -Option AllScope -Value "#FF0000" 4>$Null
    Set htmlcyanmask        -Option AllScope -Value "#00FFFF" 4>$Null
    Set htmlbluemask        -Option AllScope -Value "#0000FF" 4>$Null
    Set htmldarkbluemask    -Option AllScope -Value "#0000A0" 4>$Null
    Set htmllightbluemask   -Option AllScope -Value "#ADD8E6" 4>$Null
    Set htmlpurplemask      -Option AllScope -Value "#800080" 4>$Null
    Set htmlyellowmask      -Option AllScope -Value "#FFFF00" 4>$Null
    Set htmllimemask        -Option AllScope -Value "#00FF00" 4>$Null
    Set htmlmagentamask     -Option AllScope -Value "#FF00FF" 4>$Null
    Set htmlwhitemask       -Option AllScope -Value "#FFFFFF" 4>$Null
    Set htmlsilvermask      -Option AllScope -Value "#C0C0C0" 4>$Null
    Set htmlgraymask        -Option AllScope -Value "#808080" 4>$Null
    Set htmlblackmask       -Option AllScope -Value "#000000" 4>$Null
    Set htmlorangemask      -Option AllScope -Value "#FFA500" 4>$Null
    Set htmlmaroonmask      -Option AllScope -Value "#800000" 4>$Null
    Set htmlgreenmask       -Option AllScope -Value "#008000" 4>$Null
    Set htmlolivemask       -Option AllScope -Value "#808000" 4>$Null

    Set htmlbold        -Option AllScope -Value 1 4>$Null
    Set htmlitalics     -Option AllScope -Value 2 4>$Null
    Set htmlred         -Option AllScope -Value 4 4>$Null
    Set htmlcyan        -Option AllScope -Value 8 4>$Null
    Set htmlblue        -Option AllScope -Value 16 4>$Null
    Set htmldarkblue    -Option AllScope -Value 32 4>$Null
    Set htmllightblue   -Option AllScope -Value 64 4>$Null
    Set htmlpurple      -Option AllScope -Value 128 4>$Null
    Set htmlyellow      -Option AllScope -Value 256 4>$Null
    Set htmllime        -Option AllScope -Value 512 4>$Null
    Set htmlmagenta     -Option AllScope -Value 1024 4>$Null
    Set htmlwhite       -Option AllScope -Value 2048 4>$Null
    Set htmlsilver      -Option AllScope -Value 4096 4>$Null
    Set htmlgray        -Option AllScope -Value 8192 4>$Null
    Set htmlolive       -Option AllScope -Value 16384 4>$Null
    Set htmlorange      -Option AllScope -Value 32768 4>$Null
    Set htmlmaroon      -Option AllScope -Value 65536 4>$Null
    Set htmlgreen       -Option AllScope -Value 131072 4>$Null
    Set htmlblack       -Option AllScope -Value 262144 4>$Null
}

If($TEXT)
{
	$global:output = ""
}
#endregion

#region code for -hardware switch
Function GetComputerWMIInfo
{
	Param([string]$RemoteComputerName)
	
	# original work by Kees Baggerman, 
	# Senior Technical Consultant @ Inter Access
	# k.baggerman@myvirtualvision.com
	# @kbaggerman on Twitter
	# http://blog.myvirtualvision.com
	# modified 1-May-2014 to work in trusted AD Forests and using different domain admin credentials	

	#Get Computer info
	Write-Verbose "$(Get-Date): `t`tProcessing WMI Computer information"
	Write-Verbose "$(Get-Date): `t`t`tHardware information"
	If($MSWord -or $PDF)
	{
		WriteWordLine 3 0 "Computer Information: $($RemoteComputerName)"
		WriteWordLine 4 0 "General Computer"
	}
	ElseIf($Text)
	{
		Line 0 "Computer Information: $($RemoteComputerName)"
		Line 1 "General Computer"
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 3 0 "Computer Information: $($RemoteComputerName)"
	}
	
	[bool]$GotComputerItems = $True
	
	Try
	{
		$Results = Get-WmiObject -computername $RemoteComputerName win32_computersystem
	}
	
	Catch
	{
		$Results = $Null
	}
	
	If($? -and $Results -ne $Null)
	{
		$ComputerItems = $Results | Select Manufacturer, Model, Domain, `
		@{N="TotalPhysicalRam"; E={[math]::round(($_.TotalPhysicalMemory / 1GB),0)}}, `
		NumberOfProcessors, NumberOfLogicalProcessors
		$Results = $Null

		ForEach($Item in $ComputerItems)
		{
			OutputComputerItem $Item
		}
	}
	ElseIf(!$?)
	{
		Write-Verbose "$(Get-Date): Get-WmiObject win32_computersystem failed for $($RemoteComputerName)"
		Write-Warning "Get-WmiObject win32_computersystem failed for $($RemoteComputerName)"
		If($MSWORD -or $PDF)
		{
			WriteWordLine 0 2 "Get-WmiObject win32_computersystem failed for $($RemoteComputerName)" "" $Null 0 $False $True
			WriteWordLine 0 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository" "" $Null 0 $False $True
			WriteWordLine 0 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may" "" $Null 0 $False $True
			WriteWordLine 0 2 "need to rerun the script with Domain Admin credentials from the trusted Forest." "" $Null 0 $False $True
		}
		ElseIf($Text)
		{
			Line 2 "Get-WmiObject win32_computersystem failed for $($RemoteComputerName)"
			Line 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository"
			Line 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may"
			Line 2 "need to rerun the script with Domain Admin credentials from the trusted Forest."
			Line 2 ""
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 0 2 "Get-WmiObject win32_computersystem failed for $($RemoteComputerName)" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "need to rerun the script with Domain Admin credentials from the trusted Forest." "" $Null 0 $False $True
		}
	}
	Else
	{
		Write-Verbose "$(Get-Date): No results Returned for Computer information"
		If($MSWORD -or $PDF)
		{
			WriteWordLine 0 2 "No results Returned for Computer information" "" $Null 0 $False $True
		}
		ElseIf($Text)
		{
			Line 2 "No results Returned for Computer information"
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 0 2 "No results Returned for Computer information" "" $Null 0 $False $True
		}
	}
	
	#Get Disk info
	Write-Verbose "$(Get-Date): `t`t`tDrive information"

	If($MSWord -or $PDF)
	{
		WriteWordLine 4 0 "Drive(s)"
	}
	ElseIf($Text)
	{
		Line 1 "Drive(s)"
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 "Drive(s)"
	}

	[bool]$GotDrives = $True
	
	Try
	{
		$Results = Get-WmiObject -computername $RemoteComputerName Win32_LogicalDisk
	}
	
	Catch
	{
		$Results = $Null
	}

	If($? -and $Results -ne $Null)
	{
		$drives = $Results | Select caption, @{N="drivesize"; E={[math]::round(($_.size / 1GB),0)}}, 
		filesystem, @{N="drivefreespace"; E={[math]::round(($_.freespace / 1GB),0)}}, 
		volumename, drivetype, volumedirty, volumeserialnumber
		$Results = $Null
		ForEach($drive in $drives)
		{
			If($drive.caption -ne "A:" -and $drive.caption -ne "B:")
			{
				OutputDriveItem $drive
			}
		}
	}
	ElseIf(!$?)
	{
		Write-Verbose "$(Get-Date): Get-WmiObject Win32_LogicalDisk failed for $($RemoteComputerName)"
		Write-Warning "Get-WmiObject Win32_LogicalDisk failed for $($RemoteComputerName)"
		If($MSWORD -or $PDF)
		{
			WriteWordLine 0 2 "Get-WmiObject Win32_LogicalDisk failed for $($RemoteComputerName)" "" $Null 0 $False $True
			WriteWordLine 0 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository" "" $Null 0 $False $True
			WriteWordLine 0 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may" "" $Null 0 $False $True
			WriteWordLine 0 2 "need to rerun the script with Domain Admin credentials from the trusted Forest." "" $Null 0 $False $True
		}
		ElseIf($Text)
		{
			Line 2 "Get-WmiObject Win32_LogicalDisk failed for $($RemoteComputerName)"
			Line 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository"
			Line 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may"
			Line 2 "need to rerun the script with Domain Admin credentials from the trusted Forest."
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 0 2 "Get-WmiObject Win32_LogicalDisk failed for $($RemoteComputerName)" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "need to rerun the script with Domain Admin credentials from the trusted Forest." "" $Null 0 $False $True
		}
	}
	Else
	{
		Write-Verbose "$(Get-Date): No results Returned for Drive information"
		If($MSWORD -or $PDF)
		{
			WriteWordLine 0 2 "No results Returned for Drive information" "" $Null 0 $False $True
		}
		ElseIf($Text)
		{
			Line 2 "No results Returned for Drive information"
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 0 2 "No results Returned for Drive information" "" $Null 0 $False $True
		}
	}
	

	#Get CPU's and stepping
	Write-Verbose "$(Get-Date): `t`t`tProcessor information"

	If($MSWord -or $PDF)
	{
		WriteWordLine 4 0 "Processor(s)"
	}
	ElseIf($Text)
	{
		Line 1 "Processor(s)"
	}
	ElseIf($HTML)
	{
	}

	[bool]$GotProcessors = $True
	
	Try
	{
		$Results = Get-WmiObject -computername $RemoteComputerName win32_Processor
	}
	
	Catch
	{
		$Results = $Null
	}

	If($? -and $Results -ne $Null)
	{
		$Processors = $Results | Select availability, name, description, maxclockspeed, 
		l2cachesize, l3cachesize, numberofcores, numberoflogicalprocessors
		$Results = $Null
		ForEach($processor in $processors)
		{
			OutputProcessorItem $processor
		}
	}
	ElseIf(!$?)
	{
		Write-Verbose "$(Get-Date): Get-WmiObject win32_Processor failed for $($RemoteComputerName)"
		Write-Warning "Get-WmiObject win32_Processor failed for $($RemoteComputerName)"
		If($MSWORD -or $PDF)
		{
			WriteWordLine 0 2 "Get-WmiObject win32_Processor failed for $($RemoteComputerName)" "" $Null 0 $False $True
			WriteWordLine 0 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository" "" $Null 0 $False $True
			WriteWordLine 0 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may" "" $Null 0 $False $True
			WriteWordLine 0 2 "need to rerun the script with Domain Admin credentials from the trusted Forest." "" $Null 0 $False $True
		}
		ElseIf($Text)
		{
			Line 2 "Get-WmiObject win32_Processor failed for $($RemoteComputerName)"
			Line 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository"
			Line 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may"
			Line 2 "need to rerun the script with Domain Admin credentials from the trusted Forest."
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 0 2 "Get-WmiObject win32_Processor failed for $($RemoteComputerName)" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "need to rerun the script with Domain Admin credentials from the trusted Forest." "" $Null 0 $False $True
		}
	}
	Else
	{
		Write-Verbose "$(Get-Date): No results Returned for Processor information"
		If($MSWORD -or $PDF)
		{
			WriteWordLine 0 2 "No results Returned for Processor information" "" $Null 0 $False $True
		}
		ElseIf($Text)
		{
			Line 2 "No results Returned for Processor information"
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 0 2 "No results Returned for Processor information" "" $Null 0 $False $True
		}
	}

	#Get Nics
	Write-Verbose "$(Get-Date): `t`t`tNIC information"

	If($MSWord -or $PDF)
	{
		WriteWordLine 4 0 "Network Interface(s)"
	}
	ElseIf($Text)
	{
		Line 1 "Network Interface(s)"
	}
	ElseIf($HTML)
	{
	}

	[bool]$GotNics = $True
	
	Try
	{
		$Results = Get-WmiObject -computername $RemoteComputerName win32_networkadapterconfiguration
	}
	
	Catch
	{
		$Results
	}

	If($? -and $Results -ne $Null)
	{
		$Nics = $Results | Where {$_.ipaddress -ne $Null}
		$Results = $Null

		If($Nics -eq $Null ) 
		{ 
			$GotNics = $False 
		} 
		Else 
		{ 
			$GotNics = !($Nics.__PROPERTY_COUNT -eq 0) 
		} 
	
		If($GotNics)
		{
			ForEach($nic in $nics)
			{
				Try
				{
					$ThisNic = Get-WmiObject -computername $RemoteComputerName win32_networkadapter | Where {$_.index -eq $nic.index}
				}
				
				Catch 
				{
					$ThisNic = $Null
				}
				
				If($? -and $ThisNic -ne $Null)
				{
					OutputNicItem $Nic $ThisNic
				}
				ElseIf(!$?)
				{
					Write-Warning "$(Get-Date): Error retrieving NIC information"
					Write-Verbose "$(Get-Date): Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)"
					Write-Warning "Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)"
					If($MSWORD -or $PDF)
					{
						WriteWordLine 0 2 "Error retrieving NIC information" "" $Null 0 $False $True
						WriteWordLine 0 2 "Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)" "" $Null 0 $False $True
						WriteWordLine 0 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository" "" $Null 0 $False $True
						WriteWordLine 0 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may" "" $Null 0 $False $True
						WriteWordLine 0 2 "need to rerun the script with Domain Admin credentials from the trusted Forest." "" $Null 0 $False $True
					}
					ElseIf($Text)
					{
						Line 2 "Error retrieving NIC information"
						Line 2 "Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)"
						Line 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository"
						Line 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may"
						Line 2 "need to rerun the script with Domain Admin credentials from the trusted Forest."
					}
					ElseIf($HTML)
					{
						WriteHTMLLine 0 2 "Error retrieving NIC information" "" $Null 0 $False $True
						WriteHTMLLine 0 2 "Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)" "" $Null 0 $False $True
						WriteHTMLLine 0 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository" "" $Null 0 $False $True
						WriteHTMLLine 0 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may" "" $Null 0 $False $True
						WriteHTMLLine 0 2 "need to rerun the script with Domain Admin credentials from the trusted Forest." "" $Null 0 $False $True
					}
				}
				Else
				{
					Write-Verbose "$(Get-Date): No results Returned for NIC information"
					If($MSWORD -or $PDF)
					{
						WriteWordLine 0 2 "No results Returned for NIC information" "" $Null 0 $False $True
					}
					ElseIf($Text)
					{
						Line 2 "No results Returned for NIC information"
					}
					ElseIf($HTML)
					{
						WriteHTMLLine 0 2 "No results Returned for NIC information" "" $Null 0 $False $True
					}
				}
			}
		}	
	}
	ElseIf(!$?)
	{
		Write-Warning "$(Get-Date): Error retrieving NIC configuration information"
		Write-Verbose "$(Get-Date): Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)"
		Write-Warning "Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)"
		If($MSWORD -or $PDF)
		{
			WriteWordLine 0 2 "Error retrieving NIC configuration information" "" $Null 0 $False $True
			WriteWordLine 0 2 "Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)" "" $Null 0 $False $True
			WriteWordLine 0 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository" "" $Null 0 $False $True
			WriteWordLine 0 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may" "" $Null 0 $False $True
			WriteWordLine 0 2 "need to rerun the script with Domain Admin credentials from the trusted Forest." "" $Null 0 $False $True
		}
		ElseIf($Text)
		{
			Line 2 "Error retrieving NIC configuration information"
			Line 2 "Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)"
			Line 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository"
			Line 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may"
			Line 2 "need to rerun the script with Domain Admin credentials from the trusted Forest."
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 0 2 "Error retrieving NIC configuration information" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "Get-WmiObject win32_networkadapterconfiguration failed for $($RemoteComputerName)" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "On $($RemoteComputerName) you may need to run winmgmt /verifyrepository" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "and winmgmt /salvagerepository.  If this is a trusted Forest, you may" "" $Null 0 $False $True
			WriteHTMLLine 0 2 "need to rerun the script with Domain Admin credentials from the trusted Forest." "" $Null 0 $False $True
		}
	}
	Else
	{
		Write-Verbose "$(Get-Date): No results Returned for NIC configuration information"
		If($MSWORD -or $PDF)
		{
			WriteWordLine 0 2 "No results Returned for NIC configuration information" "" $Null 0 $False $True
		}
		ElseIf($Text)
		{
			Line 2 "No results Returned for NIC configuration information"
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 0 2 "No results Returned for NIC configuration information" "" $Null 0 $False $True
		}
	}
	
	If($MSWORD -or $PDF)
	{
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 0 ""
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 0 0 ""
	}

	$Results = $Null
	$ComputerItems = $Null
	$Drives = $Null
	$Processors = $Null
	$Nics = $Null
}

Function OutputComputerItem
{
	Param([object]$Item)
	If($MSWord -or $PDF)
	{
		[System.Collections.Hashtable[]] $ItemInformation = @()
		$ItemInformation += @{ Data = "Manufacturer"; Value = $Item.manufacturer; }
		$ItemInformation += @{ Data = "Model"; Value = $Item.model; }
		$ItemInformation += @{ Data = "Domain"; Value = $Item.domain; }
		$ItemInformation += @{ Data = "Total Ram"; Value = "$($Item.totalphysicalram) GB"; }
		$ItemInformation += @{ Data = "Physical Processors (sockets)"; Value = $Item.NumberOfProcessors; }
		$ItemInformation += @{ Data = "Logical Processors (cores w/HT)"; Value = $Item.NumberOfLogicalProcessors; }
		$Table = AddWordTable -Hashtable $ItemInformation `
		-Columns Data,Value `
		-List `
		-AutoFit $wdAutoFitFixed;

		## Set first column format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		## IB - set column widths without recursion
		$Table.Columns.Item(1).Width = 150;
		$Table.Columns.Item(2).Width = 200;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustNone)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 2 ""
	}
	ElseIf($Text)
	{
		Line 2 "Manufacturer`t: " $Item.manufacturer
		Line 2 "Model`t`t: " $Item.model
		Line 2 "Domain`t`t: " $Item.domain
		Line 2 "Total Ram`t: $($Item.totalphysicalram) GB"
		Line 2 "Physical Processors (sockets): " $Item.NumberOfProcessors
		Line 2 "Logical Processors (cores w/HT): " $Item.NumberOfLogicalProcessors
		Line 2 ""
	}
	ElseIf($HTML)
	{
		$rowdata = @()
		$columnHeaders = @("Manufacturer",($htmlsilver -bor $htmlbold),$Item.manufacturer,$htmlwhite)
		$rowdata += @(,('Model',($htmlsilver -bor $htmlbold),$Item.model,$htmlwhite))
		$rowdata += @(,('Domain',($htmlsilver -bor $htmlbold),$Item.domain,$htmlwhite))
		$rowdata += @(,('Total Ram',($htmlsilver -bor $htmlbold),"$($Item.totalphysicalram) GB",$htmlwhite))
		$rowdata += @(,('Physical Processors (sockets)',($htmlsilver -bor $htmlbold),$Item.NumberOfProcessors,$htmlwhite))
		$rowdata += @(,('Logical Processors (cores w/HT)',($htmlsilver -bor $htmlbold),$Item.NumberOfLogicalProcessors,$htmlwhite))

		$msg = "General Computer"
		$columnWidths = @("150px","200px")
		FormatHTMLTable $msg -rowarray $rowdata -columnArray $columnheaders -fixedWidth $columnWidths
		WriteHTMLLine 0 0 ""
	}
}

Function OutputDriveItem
{
	Param([object]$Drive)
	
	$xDriveType = ""
	Switch ($drive.drivetype)
	{
		0	{$xDriveType = "Unknown"}
		1	{$xDriveType = "No Root Directory"}
		2	{$xDriveType = "Removable Disk"}
		3	{$xDriveType = "Local Disk"}
		4	{$xDriveType = "Network Drive"}
		5	{$xDriveType = "Compact Disc"}
		6	{$xDriveType = "RAM Disk"}
		Default {$xDriveType = "Unknown"}
	}
	
	$xVolumeDirty = ""
	If(![String]::IsNullOrEmpty($drive.volumedirty))
	{
		If($drive.volumedirty)
		{
			$xVolumeDirty = "Yes"
		}
		Else
		{
			$xVolumeDirty = "No"
		}
	}

	If($MSWORD -or $PDF)
	{
		[System.Collections.Hashtable[]] $DriveInformation = @()
		$DriveInformation += @{ Data = "Caption"; Value = $Drive.caption; }
		$DriveInformation += @{ Data = "Size"; Value = "$($drive.drivesize) GB"; }
		If(![String]::IsNullOrEmpty($drive.filesystem))
		{
			$DriveInformation += @{ Data = "File System"; Value = $Drive.filesystem; }
		}
		$DriveInformation += @{ Data = "Free Space"; Value = "$($drive.drivefreespace) GB"; }
		If(![String]::IsNullOrEmpty($drive.volumename))
		{
			$DriveInformation += @{ Data = "Volume Name"; Value = $Drive.volumename; }
		}
		If(![String]::IsNullOrEmpty($drive.volumedirty))
		{
			$DriveInformation += @{ Data = "Volume is Dirty"; Value = $xVolumeDirty; }
		}
		If(![String]::IsNullOrEmpty($drive.volumeserialnumber))
		{
			$DriveInformation += @{ Data = "Volume Serial Number"; Value = $Drive.volumeserialnumber; }
		}
		$DriveInformation += @{ Data = "Drive Type"; Value = $xDriveType; }
		$Table = AddWordTable -Hashtable $DriveInformation `
		-Columns Data,Value `
		-List `
		-AutoFit $wdAutoFitFixed;

		## Set first column format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells `
		-Bold `
		-BackgroundColor $wdColorGray15;

		## IB - set column widths without recursion
		$Table.Columns.Item(1).Width = 150;
		$Table.Columns.Item(2).Width = 200;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 2 ""
	}
	ElseIf($Text)
	{
		Line 2 "Caption`t`t: " $drive.caption
		Line 2 "Size`t`t: $($drive.drivesize) GB"
		If(![String]::IsNullOrEmpty($drive.filesystem))
		{
			Line 2 "File System`t: " $drive.filesystem
		}
		Line 2 "Free Space`t: $($drive.drivefreespace) GB"
		If(![String]::IsNullOrEmpty($drive.volumename))
		{
			Line 2 "Volume Name`t: " $drive.volumename
		}
		If(![String]::IsNullOrEmpty($drive.volumedirty))
		{
			Line 2 "Volume is Dirty`t: " $xVolumeDirty
		}
		If(![String]::IsNullOrEmpty($drive.volumeserialnumber))
		{
			Line 2 "Volume Serial #`t: " $drive.volumeserialnumber
		}
		Line 2 "Drive Type`t: " $xDriveType
		Line 2 ""
	}
	ElseIf($HTML)
	{
		$rowdata = @()
		$columnHeaders = @("Caption",($htmlsilver -bor $htmlbold),$Drive.caption,$htmlwhite)
		$rowdata += @(,('Size',($htmlsilver -bor $htmlbold),"$($drive.drivesize) GB",$htmlwhite))

		If(![String]::IsNullOrEmpty($drive.filesystem))
		{
			$rowdata += @(,('File System',($htmlsilver -bor $htmlbold),$Drive.filesystem,$htmlwhite))
		}
		$rowdata += @(,('Free Space',($htmlsilver -bor $htmlbold),"$($drive.drivefreespace) GB",$htmlwhite))
		If(![String]::IsNullOrEmpty($drive.volumename))
		{
			$rowdata += @(,('Volume Name',($htmlsilver -bor $htmlbold),$Drive.volumename,$htmlwhite))
		}
		If(![String]::IsNullOrEmpty($drive.volumedirty))
		{
			$rowdata += @(,('Volume is Dirty',($htmlsilver -bor $htmlbold),$xVolumeDirty,$htmlwhite))
		}
		If(![String]::IsNullOrEmpty($drive.volumeserialnumber))
		{
			$rowdata += @(,('Volume Serial Number',($htmlsilver -bor $htmlbold),$Drive.volumeserialnumber,$htmlwhite))
		}
		$rowdata += @(,('Drive Type',($htmlsilver -bor $htmlbold),$xDriveType,$htmlwhite))

		$msg = ""
		$columnWidths = @("150px","200px")
		FormatHTMLTable $msg -rowarray $rowdata -columnArray $columnheaders -fixedWidth $columnWidths
		WriteHTMLLine 0 0 ""
	}
}

Function OutputProcessorItem
{
	Param([object]$Processor)
	
	$xAvailability = ""
	Switch ($processor.availability)
	{
		1	{$xAvailability = "Other"}
		2	{$xAvailability = "Unknown"}
		3	{$xAvailability = "Running or Full Power"}
		4	{$xAvailability = "Warning"}
		5	{$xAvailability = "In Test"}
		6	{$xAvailability = "Not Applicable"}
		7	{$xAvailability = "Power Off"}
		8	{$xAvailability = "Off Line"}
		9	{$xAvailability = "Off Duty"}
		10	{$xAvailability = "Degraded"}
		11	{$xAvailability = "Not Installed"}
		12	{$xAvailability = "Install Error"}
		13	{$xAvailability = "Power Save - Unknown"}
		14	{$xAvailability = "Power Save - Low Power Mode"}
		15	{$xAvailability = "Power Save - Standby"}
		16	{$xAvailability = "Power Cycle"}
		17	{$xAvailability = "Power Save - Warning"}
		Default	{$xAvailability = "Unknown"}
	}

	If($MSWORD -or $PDF)
	{
		[System.Collections.Hashtable[]] $ProcessorInformation = @()
		$ProcessorInformation += @{ Data = "Name"; Value = $Processor.name; }
		$ProcessorInformation += @{ Data = "Description"; Value = $Processor.description; }
		$ProcessorInformation += @{ Data = "Max Clock Speed"; Value = "$($processor.maxclockspeed) MHz"; }
		If($processor.l2cachesize -gt 0)
		{
			$ProcessorInformation += @{ Data = "L2 Cache Size"; Value = "$($processor.l2cachesize) KB"; }
		}
		If($processor.l3cachesize -gt 0)
		{
			$ProcessorInformation += @{ Data = "L3 Cache Size"; Value = "$($processor.l3cachesize) KB"; }
		}
		If($processor.numberofcores -gt 0)
		{
			$ProcessorInformation += @{ Data = "Number of Cores"; Value = $Processor.numberofcores; }
		}
		If($processor.numberoflogicalprocessors -gt 0)
		{
			$ProcessorInformation += @{ Data = "Number of Logical Processors (cores w/HT)"; Value = $Processor.numberoflogicalprocessors; }
		}
		$ProcessorInformation += @{ Data = "Availability"; Value = $xAvailability; }
		$Table = AddWordTable -Hashtable $ProcessorInformation `
		-Columns Data,Value `
		-List `
		-AutoFit $wdAutoFitFixed;

		## Set first column format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		## IB - set column widths without recursion
		$Table.Columns.Item(1).Width = 150;
		$Table.Columns.Item(2).Width = 200;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 2 "Name`t`t`t: " $processor.name
		Line 2 "Description`t`t: " $processor.description
		Line 2 "Max Clock Speed`t`t: $($processor.maxclockspeed) MHz"
		If($processor.l2cachesize -gt 0)
		{
			Line 2 "L2 Cache Size`t`t: $($processor.l2cachesize) KB"
		}
		If($processor.l3cachesize -gt 0)
		{
			Line 2 "L3 Cache Size`t`t: $($processor.l3cachesize) KB"
		}
		If($processor.numberofcores -gt 0)
		{
			Line 2 "# of Cores`t`t: " $processor.numberofcores
		}
		If($processor.numberoflogicalprocessors -gt 0)
		{
			Line 2 "# of Logical Procs (cores w/HT)`t: " $processor.numberoflogicalprocessors
		}
		Line 2 "Availability`t`t: " $xAvailability
		Line 2 ""
	}
	ElseIf($HTML)
	{
		$rowdata = @()
		$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$Processor.name,$htmlwhite)
		$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$Processor.description,$htmlwhite))

		$rowdata += @(,('Max Clock Speed',($htmlsilver -bor $htmlbold),"$($processor.maxclockspeed) MHz",$htmlwhite))
		If($processor.l2cachesize -gt 0)
		{
			$rowdata += @(,('L2 Cache Size',($htmlsilver -bor $htmlbold),"$($processor.l2cachesize) KB",$htmlwhite))
		}
		If($processor.l3cachesize -gt 0)
		{
			$rowdata += @(,('L3 Cache Size',($htmlsilver -bor $htmlbold),"$($processor.l3cachesize) KB",$htmlwhite))
		}
		If($processor.numberofcores -gt 0)
		{
			$rowdata += @(,('Number of Cores',($htmlsilver -bor $htmlbold),$Processor.numberofcores,$htmlwhite))
		}
		If($processor.numberoflogicalprocessors -gt 0)
		{
			$rowdata += @(,('Number of Logical Processors (cores w/HT)',($htmlsilver -bor $htmlbold),$Processor.numberoflogicalprocessors,$htmlwhite))
		}
		$rowdata += @(,('Availability',($htmlsilver -bor $htmlbold),$xAvailability,$htmlwhite))

		$msg = "Processor(s)"
		$columnWidths = @("150px","200px")
		FormatHTMLTable $msg -rowarray $rowdata -columnArray $columnheaders -fixedWidth $columnWidths
		WriteHTMLLine 0 0 ""
	}
}

Function OutputNicItem
{
	Param([object]$Nic, [object]$ThisNic)
	
	$xAvailability = ""
	Switch ($processor.availability)
	{
		1	{$xAvailability = "Other"}
		2	{$xAvailability = "Unknown"}
		3	{$xAvailability = "Running or Full Power"}
		4	{$xAvailability = "Warning"}
		5	{$xAvailability = "In Test"}
		6	{$xAvailability = "Not Applicable"}
		7	{$xAvailability = "Power Off"}
		8	{$xAvailability = "Off Line"}
		9	{$xAvailability = "Off Duty"}
		10	{$xAvailability = "Degraded"}
		11	{$xAvailability = "Not Installed"}
		12	{$xAvailability = "Install Error"}
		13	{$xAvailability = "Power Save - Unknown"}
		14	{$xAvailability = "Power Save - Low Power Mode"}
		15	{$xAvailability = "Power Save - Standby"}
		16	{$xAvailability = "Power Cycle"}
		17	{$xAvailability = "Power Save - Warning"}
		Default	{$xAvailability = "Unknown"}
	}

	$xIPAddress = @()
	ForEach($IPAddress in $Nic.ipaddress)
	{
		$xIPAddress += "$($IPAddress)"
	}

	$xIPSubnet = @()
	ForEach($IPSubnet in $Nic.ipsubnet)
	{
		$xIPSubnet += "$($IPSubnet)"
	}

	If($nic.dnsdomainsuffixsearchorder -ne $Null -and $nic.dnsdomainsuffixsearchorder.length -gt 0)
	{
		$nicdnsdomainsuffixsearchorder = $nic.dnsdomainsuffixsearchorder
		$xnicdnsdomainsuffixsearchorder = @()
		ForEach($DNSDomain in $nicdnsdomainsuffixsearchorder)
		{
			$xnicdnsdomainsuffixsearchorder += "$($DNSDomain)"
		}
	}
	
	If($nic.dnsserversearchorder -ne $Null -and $nic.dnsserversearchorder.length -gt 0)
	{
		$nicdnsserversearchorder = $nic.dnsserversearchorder
		$xnicdnsserversearchorder = @()
		ForEach($DNSServer in $nicdnsserversearchorder)
		{
			$xnicdnsserversearchorder += "$($DNSServer)"
		}
	}

	$xdnsenabledforwinsresolution = ""
	If($nic.dnsenabledforwinsresolution)
	{
		$xdnsenabledforwinsresolution = "Yes"
	}
	Else
	{
		$xdnsenabledforwinsresolution = "No"
	}
	
	$xTcpipNetbiosOptions = ""
	Switch ($nic.TcpipNetbiosOptions)
	{
		0	{$xTcpipNetbiosOptions = "Use NetBIOS setting from DHCP Server"}
		1	{$xTcpipNetbiosOptions = "Enable NetBIOS"}
		2	{$xTcpipNetbiosOptions = "Disable NetBIOS"}
		Default	{$xTcpipNetbiosOptions = "Unknown"}
	}
	
	$xwinsenablelmhostslookup = ""
	If($nic.winsenablelmhostslookup)
	{
		$xwinsenablelmhostslookup = "Yes"
	}
	Else
	{
		$xwinsenablelmhostslookup = "No"
	}

	If($MSWORD -or $PDF)
	{
		[System.Collections.Hashtable[]] $NicInformation = @()
		$NicInformation += @{ Data = "Name"; Value = $ThisNic.Name; }
		If($ThisNic.Name -ne $nic.description)
		{
			$NicInformation += @{ Data = "Description"; Value = $Nic.description; }
		}
		$NicInformation += @{ Data = "Connection ID"; Value = $ThisNic.NetConnectionID; }
		$NicInformation += @{ Data = "Manufacturer"; Value = $Nic.manufacturer; }
		$NicInformation += @{ Data = "Availability"; Value = $xAvailability; }
		$NicInformation += @{ Data = "Physical Address"; Value = $Nic.macaddress; }
		If($xIPAddress.Count -gt 1)
		{
			$NicInformation += @{ Data = "IP Address"; Value = $xIPAddress[0]; }
			$NicInformation += @{ Data = "Default Gateway"; Value = $Nic.Defaultipgateway; }
			$NicInformation += @{ Data = "Subnet Mask"; Value = $xIPSubnet[0]; }
			$cnt = -1
			ForEach($tmp in $xIPAddress)
			{
				$cnt++
				If($cnt -gt 0)
				{
					$NicInformation += @{ Data = "IP Address"; Value = $tmp; }
					$NicInformation += @{ Data = "Subnet Mask"; Value = $xIPSubnet[$cnt]; }
				}
			}
		}
		Else
		{
			$NicInformation += @{ Data = "IP Address"; Value = $xIPAddress; }
			$NicInformation += @{ Data = "Default Gateway"; Value = $Nic.Defaultipgateway; }
			$NicInformation += @{ Data = "Subnet Mask"; Value = $xIPSubnet; }
		}
		If($nic.dhcpenabled)
		{
			$DHCPLeaseObtainedDate = $nic.ConvertToDateTime($nic.dhcpleaseobtained)
			$DHCPLeaseExpiresDate = $nic.ConvertToDateTime($nic.dhcpleaseexpires)
			$NicInformation += @{ Data = "DHCP Enabled"; Value = $Nic.dhcpenabled; }
			$NicInformation += @{ Data = "DHCP Lease Obtained"; Value = $dhcpleaseobtaineddate; }
			$NicInformation += @{ Data = "DHCP Lease Expires"; Value = $dhcpleaseexpiresdate; }
			$NicInformation += @{ Data = "DHCP Server"; Value = $Nic.dhcpserver; }
		}
		If(![String]::IsNullOrEmpty($nic.dnsdomain))
		{
			$NicInformation += @{ Data = "DNS Domain"; Value = $Nic.dnsdomain; }
		}
		If($nic.dnsdomainsuffixsearchorder -ne $Null -and $nic.dnsdomainsuffixsearchorder.length -gt 0)
		{
			$NicInformation += @{ Data = "DNS Search Suffixes"; Value = $xnicdnsdomainsuffixsearchorder[0]; }
			$cnt = -1
			ForEach($tmp in $xnicdnsdomainsuffixsearchorder)
			{
				$cnt++
				If($cnt -gt 0)
				{
					$NicInformation += @{ Data = ""; Value = $tmp; }
				}
			}
		}
		$NicInformation += @{ Data = "DNS WINS Enabled"; Value = $xdnsenabledforwinsresolution; }
		If($nic.dnsserversearchorder -ne $Null -and $nic.dnsserversearchorder.length -gt 0)
		{
			$NicInformation += @{ Data = "DNS Servers"; Value = $xnicdnsserversearchorder[0]; }
			$cnt = -1
			ForEach($tmp in $xnicdnsserversearchorder)
			{
				$cnt++
				If($cnt -gt 0)
				{
					$NicInformation += @{ Data = ""; Value = $tmp; }
				}
			}
		}
		$NicInformation += @{ Data = "NetBIOS Setting"; Value = $xTcpipNetbiosOptions; }
		$NicInformation += @{ Data = "WINS: Enabled LMHosts"; Value = $xwinsenablelmhostslookup; }
		If(![String]::IsNullOrEmpty($nic.winshostlookupfile))
		{
			$NicInformation += @{ Data = "Host Lookup File"; Value = $Nic.winshostlookupfile; }
		}
		If(![String]::IsNullOrEmpty($nic.winsprimaryserver))
		{
			$NicInformation += @{ Data = "Primary Server"; Value = $Nic.winsprimaryserver; }
		}
		If(![String]::IsNullOrEmpty($nic.winssecondaryserver))
		{
			$NicInformation += @{ Data = "Secondary Server"; Value = $Nic.winssecondaryserver; }
		}
		If(![String]::IsNullOrEmpty($nic.winsscopeid))
		{
			$NicInformation += @{ Data = "Scope ID"; Value = $Nic.winsscopeid; }
		}
		$Table = AddWordTable -Hashtable $NicInformation -Columns Data,Value -List -AutoFit $wdAutoFitFixed;

		## Set first column format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		## IB - set column widths without recursion
		$Table.Columns.Item(1).Width = 150;
		$Table.Columns.Item(2).Width = 200;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
	}
	ElseIf($Text)
	{
		Line 2 "Name`t`t`t: " $ThisNic.Name
		If($ThisNic.Name -ne $nic.description)
		{
			Line 2 "Description`t`t: " $nic.description
		}
		Line 2 "Connection ID`t`t: " $ThisNic.NetConnectionID
		Line 2 "Manufacturer`t`t: " $ThisNic.manufacturer
		Line 2 "Availability`t`t: " $xAvailability
		Line 2 "Physical Address`t: " $nic.macaddress
		Line 2 "IP Address`t`t: " $xIPAddress[0]
		$cnt = -1
		ForEach($tmp in $xIPAddress)
		{
			$cnt++
			If($cnt -gt 0)
			{
				Line 5 "" $tmp
			}
		}
		Line 2 "Default Gateway`t`t: " $Nic.Defaultipgateway
		Line 2 "Subnet Mask`t`t: " $xIPSubnet[0]
		$cnt = -1
		ForEach($tmp in $xIPSubnet)
		{
			$cnt++
			If($cnt -gt 0)
			{
				Line 5 "" $tmp
			}
		}
		If($nic.dhcpenabled)
		{
			$DHCPLeaseObtainedDate = $nic.ConvertToDateTime($nic.dhcpleaseobtained)
			$DHCPLeaseExpiresDate = $nic.ConvertToDateTime($nic.dhcpleaseexpires)
			Line 2 "DHCP Enabled`t`t: " $nic.dhcpenabled
			Line 2 "DHCP Lease Obtained`t: " $dhcpleaseobtaineddate
			Line 2 "DHCP Lease Expires`t: " $dhcpleaseexpiresdate
			Line 2 "DHCP Server`t`t:" $nic.dhcpserver
		}
		If(![String]::IsNullOrEmpty($nic.dnsdomain))
		{
			Line 2 "DNS Domain`t`t: " $nic.dnsdomain
		}
		If($nic.dnsdomainsuffixsearchorder -ne $Null -and $nic.dnsdomainsuffixsearchorder.length -gt 0)
		{
			[int]$x = 1
			Line 2 "DNS Search Suffixes`t:" $xnicdnsdomainsuffixsearchorder[0]
			$cnt = -1
			ForEach($tmp in $xnicdnsdomainsuffixsearchorder)
			{
				$cnt++
				If($cnt -gt 0)
				{
					$ScriptInformation += @{ Data = ""; Value = $tmp; }
				}
			}
		}
		Line 2 "DNS WINS Enabled`t: " $xdnsenabledforwinsresolution
		If($nic.dnsserversearchorder -ne $Null -and $nic.dnsserversearchorder.length -gt 0)
		{
			[int]$x = 1
			Line 2 "DNS Servers`t`t:" $xnicdnsserversearchorder[0]
			$cnt = -1
			ForEach($tmp in $xnicdnsserversearchorder)
			{
				$cnt++
				If($cnt -gt 0)
				{
					$ScriptInformation += @{ Data = ""; Value = $tmp; }
				}
			}
		}
		Line 2 "NetBIOS Setting`t`t: " $xTcpipNetbiosOptions
		Line 2 "WINS:"
		Line 3 "Enabled LMHosts`t: " $xwinsenablelmhostslookup
		If(![String]::IsNullOrEmpty($nic.winshostlookupfile))
		{
			Line 3 "Host Lookup File`t: " $nic.winshostlookupfile
		}
		If(![String]::IsNullOrEmpty($nic.winsprimaryserver))
		{
			Line 3 "Primary Server`t`t: " $nic.winsprimaryserver
		}
		If(![String]::IsNullOrEmpty($nic.winssecondaryserver))
		{
			Line 3 "Secondary Server`t: " $nic.winssecondaryserver
		}
		If(![String]::IsNullOrEmpty($nic.winsscopeid))
		{
			Line 3 "Scope ID`t`t: " $nic.winsscopeid
		}
	}
	ElseIf($HTML)
	{
		$rowdata = @()
		$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$ThisNic.Name,$htmlwhite)
		If($ThisNic.Name -ne $nic.description)
		{
			$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$Nic.description,$htmlwhite))
		}
		$rowdata += @(,('Connection ID',($htmlsilver -bor $htmlbold),$ThisNic.NetConnectionID,$htmlwhite))
		$rowdata += @(,('Manufacturer',($htmlsilver -bor $htmlbold),$Nic.manufacturer,$htmlwhite))
		$rowdata += @(,('Availability',($htmlsilver -bor $htmlbold),$xAvailability,$htmlwhite))
		$rowdata += @(,('Physical Address',($htmlsilver -bor $htmlbold),$Nic.macaddress,$htmlwhite))
		$rowdata += @(,('IP Address',($htmlsilver -bor $htmlbold),$xIPAddress[0],$htmlwhite))
		$cnt = -1
		ForEach($tmp in $xIPAddress)
		{
			$cnt++
			If($cnt -gt 0)
			{
				$rowdata += @(,('IP Address',($htmlsilver -bor $htmlbold),$tmp,$htmlwhite))
			}
		}
		$rowdata += @(,('Default Gateway',($htmlsilver -bor $htmlbold),$Nic.Defaultipgateway,$htmlwhite))
		$rowdata += @(,('Subnet Mask',($htmlsilver -bor $htmlbold),$xIPSubnet[0],$htmlwhite))
		$cnt = -1
		ForEach($tmp in $xIPSubnet)
		{
			$cnt++
			If($cnt -gt 0)
			{
				$rowdata += @(,('Subnet Mask',($htmlsilver -bor $htmlbold),$tmp,$htmlwhite))
			}
		}
		If($nic.dhcpenabled)
		{
			$DHCPLeaseObtainedDate = $nic.ConvertToDateTime($nic.dhcpleaseobtained)
			$DHCPLeaseExpiresDate = $nic.ConvertToDateTime($nic.dhcpleaseexpires)
			$rowdata += @(,('DHCP Enabled',($htmlsilver -bor $htmlbold),$Nic.dhcpenabled,$htmlwhite))
			$rowdata += @(,('DHCP Lease Obtained',($htmlsilver -bor $htmlbold),$dhcpleaseobtaineddate,$htmlwhite))
			$rowdata += @(,('DHCP Lease Expires',($htmlsilver -bor $htmlbold),$dhcpleaseexpiresdate,$htmlwhite))
			$rowdata += @(,('DHCP Server',($htmlsilver -bor $htmlbold),$Nic.dhcpserver,$htmlwhite))
		}
		If(![String]::IsNullOrEmpty($nic.dnsdomain))
		{
			$rowdata += @(,('DNS Domain',($htmlsilver -bor $htmlbold),$Nic.dnsdomain,$htmlwhite))
		}
		If($nic.dnsdomainsuffixsearchorder -ne $Null -and $nic.dnsdomainsuffixsearchorder.length -gt 0)
		{
			$rowdata += @(,('DNS Search Suffixes',($htmlsilver -bor $htmlbold),$xnicdnsdomainsuffixsearchorder[0],$htmlwhite))
			$cnt = -1
			ForEach($tmp in $xnicdnsdomainsuffixsearchorder)
			{
				$cnt++
				If($cnt -gt 0)
				{
					$rowdata += @(,('',($htmlsilver -bor $htmlbold),$tmp,$htmlwhite))
				}
			}
		}
		$rowdata += @(,('DNS WINS Enabled',($htmlsilver -bor $htmlbold),$xdnsenabledforwinsresolution,$htmlwhite))
		If($nic.dnsserversearchorder -ne $Null -and $nic.dnsserversearchorder.length -gt 0)
		{
			$rowdata += @(,('DNS Servers',($htmlsilver -bor $htmlbold),$xnicdnsserversearchorder[0],$htmlwhite))
			$cnt = -1
			ForEach($tmp in $xnicdnsserversearchorder)
			{
				$cnt++
				If($cnt -gt 0)
				{
					$rowdata += @(,('',($htmlsilver -bor $htmlbold),$tmp,$htmlwhite))
				}
			}
		}
		$rowdata += @(,('NetBIOS Setting',($htmlsilver -bor $htmlbold),$xTcpipNetbiosOptions,$htmlwhite))
		$rowdata += @(,('WINS: Enabled LMHosts',($htmlsilver -bor $htmlbold),$xwinsenablelmhostslookup,$htmlwhite))
		If(![String]::IsNullOrEmpty($nic.winshostlookupfile))
		{
			$rowdata += @(,('Host Lookup File',($htmlsilver -bor $htmlbold),$Nic.winshostlookupfile,$htmlwhite))
		}
		If(![String]::IsNullOrEmpty($nic.winsprimaryserver))
		{
			$rowdata += @(,('Primary Server',($htmlsilver -bor $htmlbold),$Nic.winsprimaryserver,$htmlwhite))
		}
		If(![String]::IsNullOrEmpty($nic.winssecondaryserver))
		{
			$rowdata += @(,('Secondary Server',($htmlsilver -bor $htmlbold),$Nic.winssecondaryserver,$htmlwhite))
		}
		If(![String]::IsNullOrEmpty($nic.winsscopeid))
		{
			$rowdata += @(,('Scope ID',($htmlsilver -bor $htmlbold),$Nic.winsscopeid,$htmlwhite))
		}

		$msg = "Network Interface(s)"
		$columnWidths = @("150px","200px")
		FormatHTMLTable $msg -rowarray $rowdata -columnArray $columnheaders -fixedWidth $columnWidths
		WriteHTMLLine 0 0 ""
	}
}
#endregion

#region word specific functions
Function SetWordHashTable
{
	Param([string]$CultureCode)

	#optimized by Michael B. SMith
	
	# DE and FR translations for Word 2010 by Vladimir Radojevic
	# Vladimir.Radojevic@Commerzreal.com

	# DA translations for Word 2010 by Thomas Daugaard
	# Citrix Infrastructure Specialist at edgemo A/S

	# CA translations by Javier Sanchez 
	# CEO & Founder 101 Consulting

	#ca - Catalan
	#da - Danish
	#de - German
	#en - English
	#es - Spanish
	#fi - Finnish
	#fr - French
	#nb - Norwegian
	#nl - Dutch
	#pt - Portuguese
	#sv - Swedish

	[string]$toc = $(
		Switch ($CultureCode)
		{
			'ca-'	{ 'Taula automática 2' }

			'da-'	{ 'Automatisk tabel 2' }

			'de-'	{ 'Automatische Tabelle 2' }

			'en-'	{ 'Automatic Table 2' }

			'es-'	{ 'Tabla automática 2' }

			'fi-'	{ 'Automaattinen taulukko 2' }

			'fr-'	{ 'Sommaire Automatique 2' }

			'nb-'	{ 'Automatisk tabell 2' }

			'nl-'	{ 'Automatische inhoudsopgave 2' }

			'pt-'	{ 'Sumário Automático 2' }

			'sv-'	{ 'Automatisk innehållsförteckning2' }
		}
	)

	$Script:myHash                      = @{}
	$Script:myHash.Word_TableOfContents = $toc
	$Script:myHash.Word_NoSpacing       = $wdStyleNoSpacing
	$Script:myHash.Word_Heading1        = $wdStyleheading1
	$Script:myHash.Word_Heading2        = $wdStyleheading2
	$Script:myHash.Word_Heading3        = $wdStyleheading3
	$Script:myHash.Word_Heading4        = $wdStyleheading4
	$Script:myHash.Word_TableGrid       = $wdTableGrid
}

Function GetCulture
{
	Param([int]$WordValue)
	
	#codes obtained from http://support.microsoft.com/kb/221435
	#http://msdn.microsoft.com/en-us/library/bb213877(v=office.12).aspx
	$CatalanArray = 1027
	$DanishArray = 1030
	$DutchArray = 2067, 1043
	$EnglishArray = 3081, 10249, 4105, 9225, 6153, 8201, 5129, 13321, 7177, 11273, 2057, 1033, 12297
	$FinnishArray = 1035
	$FrenchArray = 2060, 1036, 11276, 3084, 12300, 5132, 13324, 6156, 8204, 10252, 7180, 9228, 4108
	$GermanArray = 1031, 3079, 5127, 4103, 2055
	$NorwegianArray = 1044, 2068
	$PortugueseArray = 1046, 2070
	$SpanishArray = 1034, 11274, 16394, 13322, 9226, 5130, 7178, 12298, 17418, 4106, 18442, 19466, 6154, 15370, 10250, 20490, 3082, 14346, 8202
	$SwedishArray = 1053, 2077

	#ca - Catalan
	#da - Danish
	#de - German
	#en - English
	#es - Spanish
	#fi - Finnish
	#fr - French
	#nb - Norwegian
	#nl - Dutch
	#pt - Portuguese
	#sv - Swedish

	Switch ($WordValue)
	{
		{$CatalanArray -contains $_} {$CultureCode = "ca-"}
		{$DanishArray -contains $_} {$CultureCode = "da-"}
		{$DutchArray -contains $_} {$CultureCode = "nl-"}
		{$EnglishArray -contains $_} {$CultureCode = "en-"}
		{$FinnishArray -contains $_} {$CultureCode = "fi-"}
		{$FrenchArray -contains $_} {$CultureCode = "fr-"}
		{$GermanArray -contains $_} {$CultureCode = "de-"}
		{$NorwegianArray -contains $_} {$CultureCode = "nb-"}
		{$PortugueseArray -contains $_} {$CultureCode = "pt-"}
		{$SpanishArray -contains $_} {$CultureCode = "es-"}
		{$SwedishArray -contains $_} {$CultureCode = "sv-"}
		Default {$CultureCode = "en-"}
	}
	
	Return $CultureCode
}

Function ValidateCoverPage
{
	Param([int]$xWordVersion, [string]$xCP, [string]$CultureCode)
	
	$xArray = ""
	
	Switch ($CultureCode)
	{
		'ca-'	{
				If($xWordVersion -eq $wdWord2016)
				{
					$xArray = ("Austin", "En bandes", "Faceta", "Filigrana",
					"Integral", "Ió (clar)", "Ió (fosc)", "Línia lateral",
					"Moviment", "Quadrícula", "Retrospectiu", "Sector (clar)",
					"Sector (fosc)", "Semàfor", "Visualització principal", "Whisp")
				}
				ElseIf($xWordVersion -eq $wdWord2013)
				{
					$xArray = ("Austin", "En bandes", "Faceta", "Filigrana",
					"Integral", "Ió (clar)", "Ió (fosc)", "Línia lateral",
					"Moviment", "Quadrícula", "Retrospectiu", "Sector (clar)",
					"Sector (fosc)", "Semàfor", "Visualització", "Whisp")
				}
				ElseIf($xWordVersion -eq $wdWord2010)
				{
					$xArray = ("Alfabet", "Anual", "Austin", "Conservador",
					"Contrast", "Cubicles", "Diplomàtic", "Exposició",
					"Línia lateral", "Mod", "Mosiac", "Moviment", "Paper de diari",
					"Perspectiva", "Piles", "Quadrícula", "Sobri",
					"Transcendir", "Trencaclosques")
				}
			}

		'da-'	{
				If($xWordVersion -eq $wdWord2016)
				{
					$xArray = ("Austin", "BevægElse", "Brusen", "Facet", "Filigran", 
					"Gitter", "Integral", "Ion (lys)", "Ion (mørk)", 
					"Retro", "Semafor", "Sidelinje", "Stribet", 
					"Udsnit (lys)", "Udsnit (mørk)", "Visningsmaster")
				}
				ElseIf($xWordVersion -eq $wdWord2013)
				{
					$xArray = ("BevægElse", "Brusen", "Ion (lys)", "Filigran",
					"Retro", "Semafor", "Visningsmaster", "Integral",
					"Facet", "Gitter", "Stribet", "Sidelinje", "Udsnit (lys)",
					"Udsnit (mørk)", "Ion (mørk)", "Austin")
				}
				ElseIf($xWordVersion -eq $wdWord2010)
				{
					$xArray = ("BevægElse", "Moderat", "Perspektiv", "Firkanter",
					"Overskrid", "Alfabet", "Kontrast", "Stakke", "Fliser", "Gåde",
					"Gitter", "Austin", "Eksponering", "Sidelinje", "Enkel",
					"Nålestribet", "Årlig", "Avispapir", "Tradionel")
				}
			}

		'de-'	{
				If($xWordVersion -eq $wdWord2016)
				{
					$xArray = ("Austin", "Bewegung", "Facette", "Filigran", 
					"Gebändert", "Integral", "Ion (dunkel)", "Ion (hell)", 
					"Pfiff", "Randlinie", "Raster", "Rückblick", 
					"Segment (dunkel)", "Segment (hell)", "Semaphor", 
					"ViewMaster")
				}
				ElseIf($xWordVersion -eq $wdWord2013)
				{
					$xArray = ("Semaphor", "Segment (hell)", "Ion (hell)",
					"Raster", "Ion (dunkel)", "Filigran", "Rückblick", "Pfiff",
					"ViewMaster", "Segment (dunkel)", "Verbunden", "Bewegung",
					"Randlinie", "Austin", "Integral", "Facette")
				}
				ElseIf($xWordVersion -eq $wdWord2010)
				{
					$xArray = ("Alphabet", "Austin", "Bewegung", "Durchscheinend",
					"Herausgestellt", "Jährlich", "Kacheln", "Kontrast", "Kubistisch",
					"Modern", "Nadelstreifen", "Perspektive", "Puzzle", "Randlinie",
					"Raster", "Schlicht", "Stapel", "Traditionell", "Zeitungspapier")
				}
			}

		'en-'	{
				If($xWordVersion -eq $wdWord2013 -or $xWordVersion -eq $wdWord2016)
				{
					$xArray = ("Austin", "Banded", "Facet", "Filigree", "Grid",
					"Integral", "Ion (Dark)", "Ion (Light)", "Motion", "Retrospect",
					"Semaphore", "Sideline", "Slice (Dark)", "Slice (Light)", "ViewMaster",
					"Whisp")
				}
				ElseIf($xWordVersion -eq $wdWord2010)
				{
					$xArray = ("Alphabet", "Annual", "Austere", "Austin", "Conservative",
					"Contrast", "Cubicles", "Exposure", "Grid", "Mod", "Motion", "Newsprint",
					"Perspective", "Pinstripes", "Puzzle", "Sideline", "Stacks", "Tiles", "Transcend")
				}
			}

		'es-'	{
				If($xWordVersion -eq $wdWord2016)
				{
					$xArray = ("Austin", "Con bandas", "Cortar (oscuro)", "Cuadrícula", 
					"Whisp", "Faceta", "Filigrana", "Integral", "Ion (claro)", 
					"Ion (oscuro)", "Línea lateral", "Movimiento", "Retrospectiva", 
					"Semáforo", "Slice (luz)", "Vista principal", "Whisp")
				}
				ElseIf($xWordVersion -eq $wdWord2013)
				{
					$xArray = ("Whisp", "Vista principal", "Filigrana", "Austin",
					"Slice (luz)", "Faceta", "Semáforo", "Retrospectiva", "Cuadrícula",
					"Movimiento", "Cortar (oscuro)", "Línea lateral", "Ion (oscuro)",
					"Ion (claro)", "Integral", "Con bandas")
				}
				ElseIf($xWordVersion -eq $wdWord2010)
				{
					$xArray = ("Alfabeto", "Anual", "Austero", "Austin", "Conservador",
					"Contraste", "Cuadrícula", "Cubículos", "Exposición", "Línea lateral",
					"Moderno", "Mosaicos", "Movimiento", "Papel periódico",
					"Perspectiva", "Pilas", "Puzzle", "Rayas", "Sobrepasar")
				}
			}

		'fi-'	{
				If($xWordVersion -eq $wdWord2016)
				{
					$xArray = ("Filigraani", "Integraali", "Ioni (tumma)",
					"Ioni (vaalea)", "Opastin", "Pinta", "Retro", "Sektori (tumma)",
					"Sektori (vaalea)", "Vaihtuvavärinen", "ViewMaster", "Austin",
					"Kuiskaus", "Liike", "Ruudukko", "Sivussa")
				}
				ElseIf($xWordVersion -eq $wdWord2013)
				{
					$xArray = ("Filigraani", "Integraali", "Ioni (tumma)",
					"Ioni (vaalea)", "Opastin", "Pinta", "Retro", "Sektori (tumma)",
					"Sektori (vaalea)", "Vaihtuvavärinen", "ViewMaster", "Austin",
					"Kiehkura", "Liike", "Ruudukko", "Sivussa")
				}
				ElseIf($xWordVersion -eq $wdWord2010)
				{
					$xArray = ("Aakkoset", "Askeettinen", "Austin", "Kontrasti",
					"Laatikot", "Liike", "Liituraita", "Mod", "Osittain peitossa",
					"Palapeli", "Perinteinen", "Perspektiivi", "Pinot", "Ruudukko",
					"Ruudut", "Sanomalehtipaperi", "Sivussa", "Vuotuinen", "Ylitys")
				}
			}

		'fr-'	{
				If($xWordVersion -eq $wdWord2013 -or $xWordVersion -eq $wdWord2016)
				{
					$xArray = ("À bandes", "Austin", "Facette", "Filigrane", 
					"Guide", "Intégrale", "Ion (clair)", "Ion (foncé)", 
					"Lignes latérales", "Quadrillage", "Rétrospective", "Secteur (clair)", 
					"Secteur (foncé)", "Sémaphore", "ViewMaster", "Whisp")
				}
				ElseIf($xWordVersion -eq $wdWord2010)
				{
					$xArray = ("Alphabet", "Annuel", "Austère", "Austin", 
					"Blocs empilés", "Classique", "Contraste", "Emplacements de bureau", 
					"Exposition", "Guide", "Ligne latérale", "Moderne", 
					"Mosaïques", "Mots croisés", "Papier journal", "Perspective",
					"Quadrillage", "Rayures fines", "Transcendant")
				}
			}

		'nb-'	{
				If($xWordVersion -eq $wdWord2013 -or $xWordVersion -eq $wdWord2016)
				{
					$xArray = ("Austin", "BevegElse", "Dempet", "Fasett", "Filigran",
					"Integral", "Ion (lys)", "Ion (mørk)", "Retrospekt", "Rutenett",
					"Sektor (lys)", "Sektor (mørk)", "Semafor", "Sidelinje", "Stripet",
					"ViewMaster")
				}
				ElseIf($xWordVersion -eq $wdWord2010)
				{
					$xArray = ("Alfabet", "Årlig", "Avistrykk", "Austin", "Avlukker",
					"BevegElse", "Engasjement", "Enkel", "Fliser", "Konservativ",
					"Kontrast", "Mod", "Perspektiv", "Puslespill", "Rutenett", "Sidelinje",
					"Smale striper", "Stabler", "Transcenderende")
				}
			}

		'nl-'	{
				If($xWordVersion -eq $wdWord2013 -or $xWordVersion -eq $wdWord2016)
				{
					$xArray = ("Austin", "Beweging", "Facet", "Filigraan", "Gestreept",
					"Integraal", "Ion (donker)", "Ion (licht)", "Raster",
					"Segment (Light)", "Semafoor", "Slice (donker)", "Spriet",
					"Terugblik", "Terzijde", "ViewMaster")
				}
				ElseIf($xWordVersion -eq $wdWord2010)
				{
					$xArray = ("Aantrekkelijk", "Alfabet", "Austin", "Bescheiden",
					"Beweging", "Blikvanger", "Contrast", "Eenvoudig", "Jaarlijks",
					"Krantenpapier", "Krijtstreep", "Kubussen", "Mod", "Perspectief",
					"Puzzel", "Raster", "Stapels",
					"Tegels", "Terzijde")
				}
			}

		'pt-'	{
				If($xWordVersion -eq $wdWord2013 -or $xWordVersion -eq $wdWord2016)
				{
					$xArray = ("Animação", "Austin", "Em Tiras", "Exibição Mestra",
					"Faceta", "Fatia (Clara)", "Fatia (Escura)", "Filete", "Filigrana", 
					"Grade", "Integral", "Íon (Claro)", "Íon (Escuro)", "Linha Lateral",
					"Retrospectiva", "Semáforo")
				}
				ElseIf($xWordVersion -eq $wdWord2010)
				{
					$xArray = ("Alfabeto", "Animação", "Anual", "Austero", "Austin", "Baias",
					"Conservador", "Contraste", "Exposição", "Grade", "Ladrilhos",
					"Linha Lateral", "Listras", "Mod", "Papel Jornal", "Perspectiva", "Pilhas",
					"Quebra-cabeça", "Transcend")
				}
			}

		'sv-'	{
				If($xWordVersion -eq $wdWord2013 -or $xWordVersion -eq $wdWord2016)
				{
					$xArray = ("Austin", "Band", "Fasett", "Filigran", "Integrerad", "Jon (ljust)",
					"Jon (mörkt)", "Knippe", "Rutnät", "RörElse", "Sektor (ljus)", "Sektor (mörk)",
					"Semafor", "Sidlinje", "VisaHuvudsida", "Återblick")
				}
				ElseIf($xWordVersion -eq $wdWord2010)
				{
					$xArray = ("Alfabetmönster", "Austin", "Enkelt", "Exponering", "Konservativt",
					"Kontrast", "Kritstreck", "Kuber", "Perspektiv", "Plattor", "Pussel", "Rutnät",
					"RörElse", "Sidlinje", "Sobert", "Staplat", "Tidningspapper", "Årligt",
					"Övergående")
				}
			}

		Default	{
					If($xWordVersion -eq $wdWord2013 -or $xWordVersion -eq $wdWord2016)
					{
						$xArray = ("Austin", "Banded", "Facet", "Filigree", "Grid",
						"Integral", "Ion (Dark)", "Ion (Light)", "Motion", "Retrospect",
						"Semaphore", "Sideline", "Slice (Dark)", "Slice (Light)", "ViewMaster",
						"Whisp")
					}
					ElseIf($xWordVersion -eq $wdWord2010)
					{
						$xArray = ("Alphabet", "Annual", "Austere", "Austin", "Conservative",
						"Contrast", "Cubicles", "Exposure", "Grid", "Mod", "Motion", "Newsprint",
						"Perspective", "Pinstripes", "Puzzle", "Sideline", "Stacks", "Tiles", "Transcend")
					}
				}
	}
	
	If($xArray -contains $xCP)
	{
		$xArray = $Null
		Return $True
	}
	Else
	{
		$xArray = $Null
		Return $False
	}
}

Function CheckWordPrereq
{
	If((Test-Path  REGISTRY::HKEY_CLASSES_ROOT\Word.Application) -eq $False)
	{
		$ErrorActionPreference = $SaveEAPreference
		Write-Host "`n`n`t`tThis script directly outputs to Microsoft Word, please install Microsoft Word`n`n"
		Exit
	}

	#find out our session (usually "1" except on TS/RDC or Citrix)
	$SessionID = (Get-Process -PID $PID).SessionId
	
	#Find out if winword is running in our session
	[bool]$wordrunning = ((Get-Process 'WinWord' -ea 0)|?{$_.SessionId -eq $SessionID}) -ne $Null
	If($wordrunning)
	{
		$ErrorActionPreference = $SaveEAPreference
		Write-Host "`n`n`tPlease close all instances of Microsoft Word before running this report.`n`n"
		Exit
	}
}

Function ValidateCompanyName
{
	[bool]$xResult = Test-RegistryValue "HKCU:\Software\Microsoft\Office\Common\UserInfo" "CompanyName"
	If($xResult)
	{
		Return Get-RegistryValue "HKCU:\Software\Microsoft\Office\Common\UserInfo" "CompanyName"
	}
	Else
	{
		$xResult = Test-RegistryValue "HKCU:\Software\Microsoft\Office\Common\UserInfo" "Company"
		If($xResult)
		{
			Return Get-RegistryValue "HKCU:\Software\Microsoft\Office\Common\UserInfo" "Company"
		}
		Else
		{
			Return ""
		}
	}
}

Function _SetDocumentProperty 
{
	#jeff hicks
	Param([object]$Properties,[string]$Name,[string]$Value)
	#get the property object
	$prop = $properties | ForEach { 
		$propname=$_.GetType().InvokeMember("Name","GetProperty",$Null,$_,$Null)
		If($propname -eq $Name) 
		{
			Return $_
		}
	} #ForEach

	#set the value
	$Prop.GetType().InvokeMember("Value","SetProperty",$Null,$prop,$Value)
}

Function FindWordDocumentEnd
{
	#return focus to main document    
	$Script:Doc.ActiveWindow.ActivePane.view.SeekView = $wdSeekMainDocument
	#move to the end of the current document
	$Script:Selection.EndKey($wdStory,$wdMove) | Out-Null
}

Function SetupWord
{
	Write-Verbose "$(Get-Date): Setting up Word"
    
	# Setup word for output
	Write-Verbose "$(Get-Date): Create Word comObject."
	$Script:Word = New-Object -comobject "Word.Application" -EA 0 4>$Null
	
	If(!$? -or $Script:Word -eq $Null)
	{
		Write-Warning "The Word object could not be created.  You may need to repair your Word installation."
		$ErrorActionPreference = $SaveEAPreference
		Write-Error "`n`n`t`tThe Word object could not be created.  You may need to repair your Word installation.`n`n`t`tScript cannot continue.`n`n"
		Exit
	}

	Write-Verbose "$(Get-Date): Determine Word language value"
	If( ( validStateProp $Script:Word Language Value__ ) )
	{
		[int]$Script:WordLanguageValue = [int]$Script:Word.Language.Value__
	}
	Else
	{
		[int]$Script:WordLanguageValue = [int]$Script:Word.Language
	}

	If(!($Script:WordLanguageValue -gt -1))
	{
		$ErrorActionPreference = $SaveEAPreference
		Write-Error "`n`n`t`tUnable to determine the Word language value.`n`n`t`tScript cannot continue.`n`n"
		AbortScript
	}
	Write-Verbose "$(Get-Date): Word language value is $($Script:WordLanguageValue)"
	
	$Script:WordCultureCode = GetCulture $Script:WordLanguageValue
	
	SetWordHashTable $Script:WordCultureCode
	
	[int]$Script:WordVersion = [int]$Script:Word.Version
	If($Script:WordVersion -eq $wdWord2016)
	{
		$Script:WordProduct = "Word 2016"
	}
	ElseIf($Script:WordVersion -eq $wdWord2013)
	{
		$Script:WordProduct = "Word 2013"
	}
	ElseIf($Script:WordVersion -eq $wdWord2010)
	{
		$Script:WordProduct = "Word 2010"
	}
	ElseIf($Script:WordVersion -eq $wdWord2007)
	{
		$ErrorActionPreference = $SaveEAPreference
		Write-Error "`n`n`t`tMicrosoft Word 2007 is no longer supported.`n`n`t`tScript will end.`n`n"
		AbortScript
	}
	Else
	{
		$ErrorActionPreference = $SaveEAPreference
		Write-Error "`n`n`t`tYou are running an untested or unsupported version of Microsoft Word.`n`n`t`tScript will end.`n`n`t`tPlease send info on your version of Word to webster@carlwebster.com`n`n"
		AbortScript
	}

	#only validate CompanyName if the field is blank
	If([String]::IsNullOrEmpty($Script:CoName))
	{
		Write-Verbose "$(Get-Date): Company name is blank.  Retrieve company name from registry."
		$TmpName = ValidateCompanyName
		
		If([String]::IsNullOrEmpty($TmpName))
		{
			Write-Warning "`n`n`t`tCompany Name is blank so Cover Page will not show a Company Name."
			Write-Warning "`n`t`tCheck HKCU:\Software\Microsoft\Office\Common\UserInfo for Company or CompanyName value."
			Write-Warning "`n`t`tYou may want to use the -CompanyName parameter if you need a Company Name on the cover page.`n`n"
		}
		Else
		{
			$Script:CoName = $TmpName
			Write-Verbose "$(Get-Date): Updated company name to $($Script:CoName)"
		}
	}

	If($Script:WordCultureCode -ne "en-")
	{
		Write-Verbose "$(Get-Date): Check Default Cover Page for $($WordCultureCode)"
		[bool]$CPChanged = $False
		Switch ($Script:WordCultureCode)
		{
			'ca-'	{
					If($CoverPage -eq "Sideline")
					{
						$CoverPage = "Línia lateral"
						$CPChanged = $True
					}
				}

			'da-'	{
					If($CoverPage -eq "Sideline")
					{
						$CoverPage = "Sidelinje"
						$CPChanged = $True
					}
				}

			'de-'	{
					If($CoverPage -eq "Sideline")
					{
						$CoverPage = "Randlinie"
						$CPChanged = $True
					}
				}

			'es-'	{
					If($CoverPage -eq "Sideline")
					{
						$CoverPage = "Línea lateral"
						$CPChanged = $True
					}
				}

			'fi-'	{
					If($CoverPage -eq "Sideline")
					{
						$CoverPage = "Sivussa"
						$CPChanged = $True
					}
				}

			'fr-'	{
					If($CoverPage -eq "Sideline")
					{
						If($Script:WordVersion -eq $wdWord2013 -or $Script:WordVersion -eq $wdWord2016)
						{
							$CoverPage = "Lignes latérales"
							$CPChanged = $True
						}
						Else
						{
							$CoverPage = "Ligne latérale"
							$CPChanged = $True
						}
					}
				}

			'nb-'	{
					If($CoverPage -eq "Sideline")
					{
						$CoverPage = "Sidelinje"
						$CPChanged = $True
					}
				}

			'nl-'	{
					If($CoverPage -eq "Sideline")
					{
						$CoverPage = "Terzijde"
						$CPChanged = $True
					}
				}

			'pt-'	{
					If($CoverPage -eq "Sideline")
					{
						$CoverPage = "Linha Lateral"
						$CPChanged = $True
					}
				}

			'sv-'	{
					If($CoverPage -eq "Sideline")
					{
						$CoverPage = "Sidlinje"
						$CPChanged = $True
					}
				}
		}

		If($CPChanged)
		{
			Write-Verbose "$(Get-Date): Changed Default Cover Page from Sideline to $($CoverPage)"
		}
	}

	Write-Verbose "$(Get-Date): Validate cover page $($CoverPage) for culture code $($Script:WordCultureCode)"
	[bool]$ValidCP = $False
	
	$ValidCP = ValidateCoverPage $Script:WordVersion $CoverPage $Script:WordCultureCode
	
	If(!$ValidCP)
	{
		$ErrorActionPreference = $SaveEAPreference
		Write-Verbose "$(Get-Date): Word language value $($Script:WordLanguageValue)"
		Write-Verbose "$(Get-Date): Culture code $($Script:WordCultureCode)"
		Write-Error "`n`n`t`tFor $($Script:WordProduct), $($CoverPage) is not a valid Cover Page option.`n`n`t`tScript cannot continue.`n`n"
		AbortScript
	}

	ShowScriptOptions

	$Script:Word.Visible = $False

	#http://jdhitsolutions.com/blog/2012/05/san-diego-2012-powershell-deep-dive-slides-and-demos/
	#using Jeff's Demo-WordReport.ps1 file for examples
	Write-Verbose "$(Get-Date): Load Word Templates"

	[bool]$Script:CoverPagesExist = $False
	[bool]$BuildingBlocksExist = $False

	$Script:Word.Templates.LoadBuildingBlocks()
	#word 2010/2013
	$BuildingBlocksCollection = $Script:Word.Templates | Where {$_.name -eq "Built-In Building Blocks.dotx"}

	Write-Verbose "$(Get-Date): Attempt to load cover page $($CoverPage)"
	$part = $Null

	$BuildingBlocksCollection | 
	ForEach{
		If ($_.BuildingBlockEntries.Item($CoverPage).Name -eq $CoverPage) 
		{
			$BuildingBlocks = $_
		}
	}        

	If($BuildingBlocks -ne $Null)
	{
		$BuildingBlocksExist = $True

		Try 
		{
			$part = $BuildingBlocks.BuildingBlockEntries.Item($CoverPage)
		}

		Catch
		{
			$part = $Null
		}

		If($part -ne $Null)
		{
			$Script:CoverPagesExist = $True
		}
	}

	If(!$Script:CoverPagesExist)
	{
		Write-Verbose "$(Get-Date): Cover Pages are not installed or the Cover Page $($CoverPage) does not exist."
		Write-Warning "Cover Pages are not installed or the Cover Page $($CoverPage) does not exist."
		Write-Warning "This report will not have a Cover Page."
	}

	Write-Verbose "$(Get-Date): Create empty word doc"
	$Script:Doc = $Script:Word.Documents.Add()
	If($Script:Doc -eq $Null)
	{
		Write-Verbose "$(Get-Date): "
		$ErrorActionPreference = $SaveEAPreference
		Write-Error "`n`n`t`tAn empty Word document could not be created.`n`n`t`tScript cannot continue.`n`n"
		AbortScript
	}

	$Script:Selection = $Script:Word.Selection
	If($Script:Selection -eq $Null)
	{
		Write-Verbose "$(Get-Date): "
		$ErrorActionPreference = $SaveEAPreference
		Write-Error "`n`n`t`tAn unknown error happened selecting the entire Word document for default formatting options.`n`n`t`tScript cannot continue.`n`n"
		AbortScript
	}

	#set Default tab stops to 1/2 inch (this line is not from Jeff Hicks)
	#36 = .50"
	$Script:Word.ActiveDocument.DefaultTabStop = 36

	#Disable Spell and Grammar Check to resolve issue and improve performance (from Pat Coughlin)
	Write-Verbose "$(Get-Date): Disable grammar and spell checking"
	#bug reported 1-Apr-2015 by Tim Mangan
	#save current options first before turning them off
	$Script:CurrentGrammarOption = $Script:Word.Options.CheckGrammarAsYouType
	$Script:CurrentSpellingOption = $Script:Word.Options.CheckSpellingAsYouType
	$Script:Word.Options.CheckGrammarAsYouType = $False
	$Script:Word.Options.CheckSpellingAsYouType = $False

	If($BuildingBlocksExist)
	{
		#insert new page, getting ready for table of contents
		Write-Verbose "$(Get-Date): Insert new page, getting ready for table of contents"
		$part.Insert($Script:Selection.Range,$True) | Out-Null
		$Script:Selection.InsertNewPage()

		#table of contents
		Write-Verbose "$(Get-Date): Table of Contents - $($Script:MyHash.Word_TableOfContents)"
		$toc = $BuildingBlocks.BuildingBlockEntries.Item($Script:MyHash.Word_TableOfContents)
		If($toc -eq $Null)
		{
			Write-Verbose "$(Get-Date): "
			Write-Verbose "$(Get-Date): Table of Content - $($Script:MyHash.Word_TableOfContents) could not be retrieved."
			Write-Warning "This report will not have a Table of Contents."
		}
		Else
		{
			$toc.insert($Script:Selection.Range,$True) | Out-Null
		}
	}
	Else
	{
		Write-Verbose "$(Get-Date): Table of Contents are not installed."
		Write-Warning "Table of Contents are not installed so this report will not have a Table of Contents."
	}

	#set the footer
	Write-Verbose "$(Get-Date): Set the footer"
	[string]$footertext = "Report created by $username"

	#get the footer
	Write-Verbose "$(Get-Date): Get the footer and format font"
	$Script:Doc.ActiveWindow.ActivePane.view.SeekView = $wdSeekPrimaryFooter
	#get the footer and format font
	$footers = $Script:Doc.Sections.Last.Footers
	ForEach ($footer in $footers) 
	{
		If($footer.exists) 
		{
			$footer.range.Font.name = "Calibri"
			$footer.range.Font.size = 8
			$footer.range.Font.Italic = $True
			$footer.range.Font.Bold = $True
		}
	} #end ForEach
	Write-Verbose "$(Get-Date): Footer text"
	$Script:Selection.HeaderFooter.Range.Text = $footerText

	#add page numbering
	Write-Verbose "$(Get-Date): Add page numbering"
	$Script:Selection.HeaderFooter.PageNumbers.Add($wdAlignPageNumberRight) | Out-Null

	FindWordDocumentEnd
	Write-Verbose "$(Get-Date):"
	#end of Jeff Hicks 
}

Function UpdateDocumentProperties
{
	Param([string]$AbstractTitle, [string]$SubjectTitle)
	#Update document properties
	If($MSWORD -or $PDF)
	{
		If($Script:CoverPagesExist)
		{
			Write-Verbose "$(Get-Date): Set Cover Page Properties"
			_SetDocumentProperty $Script:Doc.BuiltInDocumentProperties "Company" $Script:CoName
			_SetDocumentProperty $Script:Doc.BuiltInDocumentProperties "Title" $Script:title
			_SetDocumentProperty $Script:Doc.BuiltInDocumentProperties "Author" $username

			_SetDocumentProperty $Script:Doc.BuiltInDocumentProperties "Subject" $SubjectTitle

			#Get the Coverpage XML part
			$cp = $Script:Doc.CustomXMLParts | Where {$_.NamespaceURI -match "coverPageProps$"}

			#get the abstract XML part
			$ab = $cp.documentelement.ChildNodes | Where {$_.basename -eq "Abstract"}

			#set the text
			If([String]::IsNullOrEmpty($Script:CoName))
			{
				[string]$abstract = $AbstractTitle
			}
			Else
			{
				[string]$abstract = "$($AbstractTitle) for $($Script:CoName)"
			}

			$ab.Text = $abstract

			$ab = $cp.documentelement.ChildNodes | Where {$_.basename -eq "PublishDate"}
			#set the text
			[string]$abstract = (Get-Date -Format d).ToString()
			$ab.Text = $abstract

			Write-Verbose "$(Get-Date): Update the Table of Contents"
			#update the Table of Contents
			$Script:Doc.TablesOfContents.item(1).Update()
			$cp = $Null
			$ab = $Null
			$abstract = $Null
		}
	}
}
#endregion

#region registry functions
#http://stackoverflow.com/questions/5648931/test-if-registry-value-exists
# This Function just gets $True or $False
Function Test-RegistryValue($path, $name)
{
	$key = Get-Item -LiteralPath $path -EA 0
	$key -and $Null -ne $key.GetValue($name, $Null)
}

# Gets the specified registry value or $Null if it is missing
Function Get-RegistryValue($path, $name)
{
	$key = Get-Item -LiteralPath $path -EA 0
	If($key)
	{
		$key.GetValue($name, $Null)
	}
	Else
	{
		$Null
	}
}
#endregion

#region word, text and html line output functions
Function line
#function created by Michael B. Smith, Exchange MVP
#@essentialexchange on Twitter
#http://TheEssentialExchange.com
#for creating the formatted text report
#created March 2011
#updated March 2015
{
	Param( [int]$tabs = 0, [string]$name = '', [string]$value = '', [string]$newline = "`r`n", [switch]$nonewline )
	While( $tabs -gt 0 ) { $Global:Output += "`t"; $tabs--; }
	If( $nonewline )
	{
		$Global:Output += $name + $value
	}
	Else
	{
		$Global:Output += $name + $value + $newline
	}
}
	
Function WriteWordLine
#Function created by Ryan Revord
#@rsrevord on Twitter
#Function created to make output to Word easy in this script
#updated 27-Mar-2015 to include font name, font size, italics and bold options
{
	Param([int]$style=0, 
	[int]$tabs = 0, 
	[string]$name = '', 
	[string]$value = '', 
	[string]$fontName=$Null,
	[int]$fontSize=0,
	[bool]$italics=$False,
	[bool]$boldface=$False,
	[Switch]$nonewline)
	
	#Build output style
	[string]$output = ""
	Switch ($style)
	{
		0 {$Script:Selection.Style = $Script:MyHash.Word_NoSpacing}
		1 {$Script:Selection.Style = $Script:MyHash.Word_Heading1}
		2 {$Script:Selection.Style = $Script:MyHash.Word_Heading2}
		3 {$Script:Selection.Style = $Script:MyHash.Word_Heading3}
		4 {$Script:Selection.Style = $Script:MyHash.Word_Heading4}
		Default {$Script:Selection.Style = $Script:MyHash.Word_NoSpacing}
	}
	
	#build # of tabs
	While($tabs -gt 0)
	{ 
		$output += "`t"; $tabs--; 
	}
 
	If(![String]::IsNullOrEmpty($fontName)) 
	{
		$Script:Selection.Font.name = $fontName
	} 

	If($fontSize -ne 0) 
	{
		$Script:Selection.Font.size = $fontSize
	} 
 
	If($italics -eq $True) 
	{
		$Script:Selection.Font.Italic = $True
	} 
 
	If($boldface -eq $True) 
	{
		$Script:Selection.Font.Bold = $True
	} 

	#output the rest of the parameters.
	$output += $name + $value
	$Script:Selection.TypeText($output)
 
	#test for new WriteWordLine 0.
	If($nonewline)
	{
		# Do nothing.
	} 
	Else 
	{
		$Script:Selection.TypeParagraph()
	}
}

#***********************************************************************************************************
# WriteHTMLLine
#***********************************************************************************************************

<#
.Synopsis
	Writes a line of output for HTML output
.DESCRIPTION
	This function formats an HTML line
.USAGE
	WriteHTMLLine <Style> <Tabs> <Name> <Value> <Font Name> <Font Size> <Options>

	0 for Font Size denotes using the default font size of 2 or 10 point

.EXAMPLE
	WriteHTMLLine 0 0 ""

	Writes a blank line with no style or tab stops, obviously none needed.

.EXAMPLE
	WriteHTMLLine 0 1 "This is a regular line of text indented 1 tab stops"

	Writes a line with 1 tab stop.

.EXAMPLE
	WriteHTMLLine 0 0 "This is a regular line of text in the default font in italics" "" $null 0 $htmlitalics

	Writes a line omitting font and font size and setting the italics attribute

.EXAMPLE
	WriteHTMLLine 0 0 "This is a regular line of text in the default font in bold" "" $null 0 $htmlbold

	Writes a line omitting font and font size and setting the bold attribute

.EXAMPLE
	WriteHTMLLine 0 0 "This is a regular line of text in the default font in bold italics" "" $null 0 ($htmlbold -bor $htmlitalics)

	Writes a line omitting font and font size and setting both italics and bold options

.EXAMPLE	
	WriteHTMLLine 0 0 "This is a regular line of text in the default font in 10 point" "" $null 2  # 10 point font

	Writes a line using 10 point font

.EXAMPLE
	WriteHTMLLine 0 0 "This is a regular line of text in Courier New font" "" "Courier New" 0 

	Writes a line using Courier New Font and 0 font point size (default = 2 if set to 0)

.EXAMPLE	
	WriteHTMLLine 0 0 "This is a regular line of RED text indented 0 tab stops with the computer name as data in 10 point Courier New bold italics: " $env:computername "Courier New" 2 ($htmlbold -bor $htmlred -bor $htmlitalics)

	Writes a line using Courier New Font with first and second string values to be used, also uses 10 point font with bold, italics and red color options set.

.NOTES

	Font Size - Unlike word, there is a limited set of font sizes that can be used in HTML.  They are:
		0 - default which actually gives it a 2 or 10 point.
		1 - 7.5 point font size
		2 - 10 point
		3 - 13.5 point
		4 - 15 point
		5 - 18 point
		6 - 24 point
		7 - 36 point
	Any number larger than 7 defaults to 7

	Style - Refers to the headers that are used with output and resemble the headers in word, 
	HTML supports headers h1-h6 and h1-h4 are more commonly used.  Unlike word, H1 will not 
	give you a blue colored font, you will have to set that yourself.

	Colors and Bold/Italics Flags are:

		htmlbold       
		htmlitalics    
		htmlred        
		htmlcyan        
		htmlblue       
		htmldarkblue   
		htmllightblue   
		htmlpurple      
		htmlyellow      
		htmllime       
		htmlmagenta     
		htmlwhite       
		htmlsilver      
		htmlgray       
		htmlolive       
		htmlorange      
		htmlmaroon      
		htmlgreen       
		htmlblack       
#>

Function WriteHTMLLine
#Function created by Ken Avram
#Function created to make output to HTML easy in this script
{
	Param([int]$style=0, 
	[int]$tabs = 0, 
	[string]$name = '', 
	[string]$value = '', 
	[string]$fontName="Calibri",
	[int]$fontSize=1,
	[int]$options=$htmlblack)


	#Build output style
	[string]$output = ""

	If([String]::IsNullOrEmpty($Name))	
	{
		$HTMLBody = "<p></p>"
	}
	Else
	{
		$color = CheckHTMLColor $options

		#build # of tabs

		While($tabs -gt 0)
		{ 
			$output += "&nbsp;&nbsp;&nbsp;&nbsp;"; $tabs--; 
		}

		$HTMLFontName = $fontName		

		$HTMLBody = ""

		If($options -band $htmlitalics) 
		{
			$HTMLBody += "<i>"
		} 

		If($options -band $htmlbold) 
		{
			$HTMLBody += "<b>"
		} 

		#output the rest of the parameters.
		$output += $name + $value

		$HTMLBody += "<br><font face='" + $HTMLFontName + "' " + "color='" + $color + "' size='"  + $fontsize + "'>"
		
		Switch ($style)
		{
			1 {$HTMLStyle = "<h1>"}
			2 {$HTMLStyle = "<h2>"}
			3 {$HTMLStyle = "<h3>"}
			4 {$HTMLStyle = "<h4>"}
			Default {$HTMLStyle = ""}
		}

		$HTMLBody += $HTMLStyle + $output

		Switch ($style)
		{
			1 {$HTMLStyle = "</h1>"}
			2 {$HTMLStyle = "</h2>"}
			3 {$HTMLStyle = "</h3>"}
			4 {$HTMLStyle = "</h4>"}
			Default {$HTMLStyle = ""}
		}

		$HTMLBody += $HTMLStyle +  "</font>"

		If($options -band $htmlitalics) 
		{
			$HTMLBody += "</i>"
		} 

		If($options -band $htmlbold) 
		{
			$HTMLBody += "</b>"
		} 
	}
	$HTMLBody += <br />

	out-file -FilePath $Script:FileName1 -Append -InputObject $HTMLBody 4>$Null
}
#endregion

#region HTML table functions
#***********************************************************************************************************
# AddHTMLTable - Called from FormatHTMLTable function
# Created by Ken Avram
# modified by Jake Rutski
#***********************************************************************************************************
Function AddHTMLTable
{
	Param([string]$fontName="Calibri",
	[int]$fontSize=2,
	[int]$colCount=0,
	[int]$rowCount=0,
	[object[]]$rowInfo=@(),
	[object[]]$fixedInfo=@())

	For($rowidx = $RowIndex;$rowidx -le $rowCount;$rowidx++)
	{
		$rd = @($rowInfo[$rowidx - 2])
		$htmlbody = $htmlbody + "<tr>"
		For($columnIndex = 0; $columnIndex -lt $colCount; $columnindex+=2)
		{
			$fontitalics = $False
			$fontbold = $false
			$tmp = CheckHTMLColor $rd[$columnIndex+1]

			If($fixedInfo.Length -eq 0)
			{
				$htmlbody += "<td style=""background-color:$($tmp)""><font face='$($fontName)' size='$($fontSize)'>"
			}
			Else
			{
				$htmlbody += "<td style=""width:$($fixedInfo[$columnIndex/2]); background-color:$($tmp)""><font face='$($fontName)' size='$($fontSize)'>"
			}

			If($rd[$columnIndex+1] -band $htmlbold)
			{
				$htmlbody += "<b>"
			}
			If($rd[$columnIndex+1] -band $htmlitalics)
			{
				$htmlbody += "<i>"
			}
			If($rd[$columnIndex] -ne $null)
			{
				$cell = $rd[$columnIndex].tostring()
				If($cell -eq " " -or $cell.length -eq 0)
				{
					$htmlbody += "&nbsp;&nbsp;&nbsp;"
				}
				Else
				{
					For($i=0;$i -lt $cell.length;$i++)
					{
						If($cell[$i] -eq " ")
						{
							$htmlbody += "&nbsp;"
						}
						If($cell[$i] -ne " ")
						{
							Break
						}
					}
					$htmlbody += $cell
				}
			}
			Else
			{
				$htmlbody += "&nbsp;&nbsp;&nbsp;"
			}
			If($rd[$columnIndex+1] -band $htmlbold)
			{
				$htmlbody += "</b>"
			}
			If($rd[$columnIndex+1] -band $htmlitalics)
			{
				$htmlbody += "</i>"
			}
			$htmlbody += "</font></td>"
		}
		$htmlbody += "</tr>"
	}
	out-file -FilePath $Script:FileName1 -Append -InputObject $HTMLBody 4>$Null 
}

#***********************************************************************************************************
# FormatHTMLTable 
# Created by Ken Avram
# modified by Jake Rutski
#***********************************************************************************************************

<#
.Synopsis
	Format table for HTML output document
.DESCRIPTION
	This function formats a table for HTML from an array of strings
.PARAMETER noBorder
	If set to $true, a table will be generated without a border (border='0')
.PARAMETER noHeadCols
	This parameter should be used when generating tables without column headers
	Set this parameter equal to the number of columns in the table
.PARAMETER rowArray
	This parameter contains the row data array for the table
.PARAMETER columnArray
	This parameter contains column header data for the table
.PARAMETER fixedWidth
	This parameter contains widths for columns in pixel format ("100px") to override auto column widths
	The variable should contain a width for each column you wish to override the auto-size setting
	For example: $columnWidths = @("100px","110px","120px","130px","140px")

.USAGE
	FormatHTMLTable <Table Header> <Table Format> <Font Name> <Font Size>

.EXAMPLE
	FormatHTMLTable "Table Heading" "auto" "Calibri" 3

	This example formats a table and writes it out into an html file.  All of the parameters are optional
	defaults are used if not supplied.

	for <Table format>, the default is auto which will autofit the text into the columns and adjust to the longest text in that column.  You can also use percentage i.e. 25%
	which will take only 25% of the line and will auto word wrap the text to the next line in the column.  Also, instead of using a percentage, you can use pixels i.e. 400px.

	FormatHTMLTable "Table Heading" "auto" -rowArray $rowData -columnArray $columnData

	This example creates an HTML table with a heading of 'Table Heading', auto column spacing, column header data from $columnData and row data from $rowData

	FormatHTMLTable "Table Heading" -rowArray $rowData -noHeadCols 3

	This example creates an HTML table with a heading of 'Table Heading', auto column spacing, no header, and row data from $rowData

	FormatHTMLTable "Table Heading" -rowArray $rowData -fixedWidth $fixedColumns

	This example creates an HTML table with a heading of 'Table Heading, no header, row data from $rowData, and fixed columns defined by $fixedColumns

.NOTES
	In order to use the formatted table it first has to be loaded with data.  Examples below will show how to load the table:

	First, initialize the table array

	$rowdata = @()

	Then Load the array.  If you are using column headers then load those into the column headers array, otherwise the first line of the table goes into the column headers array
	and the second and subsequent lines go into the $rowdata table as shown below:

	$columnHeaders = @('Display Name',($htmlsilver -bor $htmlbold),'Status',($htmlsilver -bor $htmlbold),'Startup Type',($htmlsilver -bor $htmlbold))

	The first column is the actual name to display, the second are the attributes of the column i.e. color anded with bold or italics.  For the anding, parens are required or it will
	not format correctly.

	This is following by adding rowdata as shown below.  As more columns are added the columns will auto adjust to fit the size of the page.

	$rowdata = @()
	$columnHeaders = @("User Name",($htmlsilver -bor $htmlbold),$UserName,$htmlwhite)
	$rowdata += @(,('Save as PDF',($htmlsilver -bor $htmlbold),$PDF.ToString(),$htmlwhite))
	$rowdata += @(,('Save as TEXT',($htmlsilver -bor $htmlbold),$TEXT.ToString(),$htmlwhite))
	$rowdata += @(,('Save as WORD',($htmlsilver -bor $htmlbold),$MSWORD.ToString(),$htmlwhite))
	$rowdata += @(,('Save as HTML',($htmlsilver -bor $htmlbold),$HTML.ToString(),$htmlwhite))
	$rowdata += @(,('Add DateTime',($htmlsilver -bor $htmlbold),$AddDateTime.ToString(),$htmlwhite))
	$rowdata += @(,('Hardware Inventory',($htmlsilver -bor $htmlbold),$Hardware.ToString(),$htmlwhite))
	$rowdata += @(,('Computer Name',($htmlsilver -bor $htmlbold),$ComputerName,$htmlwhite))
	$rowdata += @(,('Filename1',($htmlsilver -bor $htmlbold),$Script:FileName1,$htmlwhite))
	$rowdata += @(,('OS Detected',($htmlsilver -bor $htmlbold),$RunningOS,$htmlwhite))
	$rowdata += @(,('PSUICulture',($htmlsilver -bor $htmlbold),$PSCulture,$htmlwhite))
	$rowdata += @(,('PoSH version',($htmlsilver -bor $htmlbold),$Host.Version.ToString(),$htmlwhite))
	FormatHTMLTable "Example of Horizontal AutoFitContents HTML Table" -rowArray $rowdata

	The 'rowArray' paramater is mandatory to build the table, but it is not set as such in the function - if nothing is passed, the table will be empty.

	Colors and Bold/Italics Flags are shown below:

		htmlbold       
		htmlitalics    
		htmlred        
		htmlcyan        
		htmlblue       
		htmldarkblue   
		htmllightblue   
		htmlpurple      
		htmlyellow      
		htmllime       
		htmlmagenta     
		htmlwhite       
		htmlsilver      
		htmlgray       
		htmlolive       
		htmlorange      
		htmlmaroon      
		htmlgreen       
		htmlblack     

#>

Function FormatHTMLTable
{
	Param([string]$tableheader,
	[string]$tablewidth="auto",
	[string]$fontName="Calibri",
	[int]$fontSize=2,
	[switch]$noBorder=$false,
	[int]$noHeadCols=1,
	[object[]]$rowArray=@(),
	[object[]]$fixedWidth=@(),
	[object[]]$columnArray=@())

	$HTMLBody = "<b><font face='" + $fontname + "' size='" + ($fontsize + 1) + "'>" + $tableheader + "</font></b>"

	If($columnArray.Length -eq 0)
	{
		$NumCols = $noHeadCols + 1
	}  # means we have no column headers, just a table
	Else
	{
		$NumCols = $columnArray.Length
	}  # need to add one for the color attrib

	If($rowArray -ne $null)
	{
		$NumRows = $rowArray.length + 1
	}
	Else
	{
		$NumRows = 1
	}

	If($noBorder)
	{
		$htmlbody += "<table border='0' width='" + $tablewidth + "'>"
	}
	Else
	{
		$htmlbody += "<table border='1' width='" + $tablewidth + "'>"
	}

	If(!($columnArray.Length -eq 0))
	{
		$htmlbody += "<tr>"

		For($columnIndex = 0; $columnIndex -lt $NumCols; $columnindex+=2)
		{
			$tmp = CheckHTMLColor $columnArray[$columnIndex+1]
			If($fixedWidth.Length -eq 0)
			{
				$htmlbody += "<td style=""background-color:$($tmp)""><font face='$($fontName)' size='$($fontSize)'>"
			}
			Else
			{
				$htmlbody += "<td style=""width:$($fixedWidth[$columnIndex/2]); background-color:$($tmp)""><font face='$($fontName)' size='$($fontSize)'>"
			}

			If($columnArray[$columnIndex+1] -band $htmlbold)
			{
				$htmlbody += "<b>"
			}
			If($columnArray[$columnIndex+1] -band $htmlitalics)
			{
				$htmlbody += "<i>"
			}
			If($columnArray[$columnIndex] -ne $null)
			{
				If($columnArray[$columnIndex] -eq " " -or $columnArray[$columnIndex].length -eq 0)
				{
					$htmlbody += "&nbsp;&nbsp;&nbsp;"
				}
				Else
				{
					$found = $false
					For($i=0;$i -lt $columnArray[$columnIndex].length;$i+=2)
					{
						If($columnArray[$columnIndex][$i] -eq " ")
						{
							$htmlbody += "&nbsp;"
						}
						If($columnArray[$columnIndex][$i] -ne " ")
						{
							Break
						}
					}
					$htmlbody += $columnArray[$columnIndex]
				}
			}
			Else
			{
				$htmlbody += "&nbsp;&nbsp;&nbsp;"
			}
			If($columnArray[$columnIndex+1] -band $htmlbold)
			{
				$htmlbody += "</b>"
			}
			If($columnArray[$columnIndex+1] -band $htmlitalics)
			{
				$htmlbody += "</i>"
			}
			$htmlbody += "</font></td>"
		}
		$htmlbody += "</tr>"
	}
	$rowindex = 2
	If($rowArray -ne $null)
	{
		AddHTMLTable $fontName $fontSize -colCount $numCols -rowCount $NumRows -rowInfo $rowArray -fixedInfo $fixedWidth
		$rowArray = @()
		$htmlbody = "</table>"
	}
	Else
	{
		$HTMLBody += "</table>"
	}	
	out-file -FilePath $Script:FileName1 -Append -InputObject $HTMLBody 4>$Null 
}
#endregion

#region other HTML functions
#***********************************************************************************************************
# CheckHTMLColor - Called from AddHTMLTable WriteHTMLLine and FormatHTMLTable
#***********************************************************************************************************
Function CheckHTMLColor
{
	Param($hash)

	If($hash -band $htmlwhite)
	{
		Return $htmlwhitemask
	}
	If($hash -band $htmlred)
	{
		Return $htmlredmask
	}
	If($hash -band $htmlcyan)
	{
		Return $htmlcyanmask
	}
	If($hash -band $htmlblue)
	{
		Return $htmlbluemask
	}
	If($hash -band $htmldarkblue)
	{
		Return $htmldarkbluemask
	}
	If($hash -band $htmllightblue)
	{
		Return $htmllightbluemask
	}
	If($hash -band $htmlpurple)
	{
		Return $htmlpurplemask
	}
	If($hash -band $htmlyellow)
	{
		Return $htmlyellowmask
	}
	If($hash -band $htmllime)
	{
		Return $htmllimemask
	}
	If($hash -band $htmlmagenta)
	{
		Return $htmlmagentamask
	}
	If($hash -band $htmlsilver)
	{
		Return $htmlsilvermask
	}
	If($hash -band $htmlgray)
	{
		Return $htmlgraymask
	}
	If($hash -band $htmlblack)
	{
		Return $htmlblackmask
	}
	If($hash -band $htmlorange)
	{
		Return $htmlorangemask
	}
	If($hash -band $htmlmaroon)
	{
		Return $htmlmaroonmask
	}
	If($hash -band $htmlgreen)
	{
		Return $htmlgreenmask
	}
	If($hash -band $htmlolive)
	{
		Return $htmlolivemask
	}
}

Function SetupHTML
{
	Write-Verbose "$(Get-Date): Setting up HTML"
    If($AddDateTime)
    {
		$Script:FileName1 += "_$(Get-Date -f yyyy-MM-dd_HHmm).html"
    }

    $htmlhead = "<html><head><meta http-equiv='Content-Language' content='da'><title>" + $Script:Title + "</title></head><body>"
    #echo $htmlhead > $FileName1
	out-file -FilePath $Script:FileName1 -Force -InputObject $HTMLHead 4>$Null
}
#endregion

#region Iain's Word table functions

<#
.Synopsis
	Add a table to a Microsoft Word document
.DESCRIPTION
	This function adds a table to a Microsoft Word document from either an array of
	Hashtables or an array of PSCustomObjects.

	Using this function is quicker than setting each table cell individually but can
	only utilise the built-in MS Word table autoformats. Individual tables cells can
	be altered after the table has been appended to the document (a table reference
	is returned).
.EXAMPLE
	AddWordTable -Hashtable $HashtableArray

	This example adds table to the MS Word document, utilising all key/value pairs in
	the array of hashtables. Column headers will display the key names as defined.
	Note: the columns might not be displayed in the order that they were defined. To
	ensure columns are displayed in the required order utilise the -Columns parameter.
.EXAMPLE
	AddWordTable -Hashtable $HashtableArray -List

	This example adds table to the MS Word document, utilising all key/value pairs in
	the array of hashtables. No column headers will be added, in a ListView format.
	Note: the columns might not be displayed in the order that they were defined. To
	ensure columns are displayed in the required order utilise the -Columns parameter.
.EXAMPLE
	AddWordTable -CustomObject $PSCustomObjectArray

	This example adds table to the MS Word document, utilising all note property names
	the array of PSCustomObjects. Column headers will display the note property names.
	Note: the columns might not be displayed in the order that they were defined. To
	ensure columns are displayed in the required order utilise the -Columns parameter.
.EXAMPLE
	AddWordTable -Hashtable $HashtableArray -Columns FirstName,LastName,EmailAddress

	This example adds a table to the MS Word document, but only using the specified
	key names: FirstName, LastName and EmailAddress. If other keys are present in the
	array of Hashtables they will be ignored.
.EXAMPLE
	AddWordTable -CustomObject $PSCustomObjectArray -Columns FirstName,LastName,EmailAddress -Headers "First Name","Last Name","Email Address"

	This example adds a table to the MS Word document, but only using the specified
	PSCustomObject note properties: FirstName, LastName and EmailAddress. If other note
	properties are present in the array of PSCustomObjects they will be ignored. The
	display names for each specified column header has been overridden to display a
	custom header. Note: the order of the header names must match the specified columns.
#>

Function AddWordTable
{
	[CmdletBinding()]
	Param
	(
		# Array of Hashtable (including table headers)
		[Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True, ParameterSetName='Hashtable', Position=0)]
		[ValidateNotNullOrEmpty()] [System.Collections.Hashtable[]] $Hashtable,
		# Array of PSCustomObjects
		[Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True, ParameterSetName='CustomObject', Position=0)]
		[ValidateNotNullOrEmpty()] [PSCustomObject[]] $CustomObject,
		# Array of Hashtable key names or PSCustomObject property names to include, in display order.
		# If not supplied then all Hashtable keys or all PSCustomObject properties will be displayed.
		[Parameter(ValueFromPipelineByPropertyName=$True)] [AllowNull()] [string[]] $Columns = $Null,
		# Array of custom table header strings in display order.
		[Parameter(ValueFromPipelineByPropertyName=$True)] [AllowNull()] [string[]] $Headers = $Null,
		# AutoFit table behavior.
		[Parameter(ValueFromPipelineByPropertyName=$True)] [AllowNull()] [int] $AutoFit = -1,
		# List view (no headers)
		[Switch] $List,
		# Grid lines
		[Switch] $NoGridLines,
		[Switch] $NoInternalGridLines,
		# Built-in Word table formatting style constant
		# Would recommend only $wdTableFormatContempory for normal usage (possibly $wdTableFormatList5 for List view)
		[Parameter(ValueFromPipelineByPropertyName=$True)] [int] $Format = 0
	)

	Begin 
	{
		Write-Debug ("Using parameter set '{0}'" -f $PSCmdlet.ParameterSetName);
		## Check if -Columns wasn't specified but -Headers were (saves some additional parameter sets!)
		If(($Columns -eq $Null) -and ($Headers -ne $Null)) 
		{
			Write-Warning "No columns specified and therefore, specified headers will be ignored.";
			$Columns = $Null;
		}
		ElseIf(($Columns -ne $Null) -and ($Headers -ne $Null)) 
		{
			## Check if number of specified -Columns matches number of specified -Headers
			If($Columns.Length -ne $Headers.Length) 
			{
				Write-Error "The specified number of columns does not match the specified number of headers.";
			}
		} ## end elseif
	} ## end Begin

	Process
	{
		## Build the Word table data string to be converted to a range and then a table later.
		[System.Text.StringBuilder] $WordRangeString = New-Object System.Text.StringBuilder;

		Switch ($PSCmdlet.ParameterSetName) 
		{
			'CustomObject' 
			{
				If($Columns -eq $Null) 
				{
					## Build the available columns from all availble PSCustomObject note properties
					[string[]] $Columns = @();
					## Add each NoteProperty name to the array
					ForEach($Property in ($CustomObject | Get-Member -MemberType NoteProperty)) 
					{ 
						$Columns += $Property.Name; 
					}
				}

				## Add the table headers from -Headers or -Columns (except when in -List(view)
				If(-not $List) 
				{
					Write-Debug ("$(Get-Date): `t`tBuilding table headers");
					If($Headers -ne $Null) 
					{
                        [ref] $Null = $WordRangeString.AppendFormat("{0}`n", [string]::Join("`t", $Headers));
					}
					Else 
					{ 
                        [ref] $Null = $WordRangeString.AppendFormat("{0}`n", [string]::Join("`t", $Columns));
					}
				}

				## Iterate through each PSCustomObject
				Write-Debug ("$(Get-Date): `t`tBuilding table rows");
				ForEach($Object in $CustomObject) 
				{
					$OrderedValues = @();
					## Add each row item in the specified order
					ForEach($Column in $Columns) 
					{ 
						$OrderedValues += $Object.$Column; 
					}
					## Use the ordered list to add each column in specified order
					[ref] $Null = $WordRangeString.AppendFormat("{0}`n", [string]::Join("`t", $OrderedValues));
				} ## end foreach
				Write-Debug ("$(Get-Date): `t`t`tAdded '{0}' table rows" -f ($CustomObject.Count));
			} ## end CustomObject

			Default 
			{   ## Hashtable
				If($Columns -eq $Null) 
				{
					## Build the available columns from all available hashtable keys. Hopefully
					## all Hashtables have the same keys (they should for a table).
					$Columns = $Hashtable[0].Keys;
				}

				## Add the table headers from -Headers or -Columns (except when in -List(view)
				If(-not $List) 
				{
					Write-Debug ("$(Get-Date): `t`tBuilding table headers");
					If($Headers -ne $Null) 
					{ 
						[ref] $Null = $WordRangeString.AppendFormat("{0}`n", [string]::Join("`t", $Headers));
					}
					Else 
					{
						[ref] $Null = $WordRangeString.AppendFormat("{0}`n", [string]::Join("`t", $Columns));
					}
				}
                
				## Iterate through each Hashtable
				Write-Debug ("$(Get-Date): `t`tBuilding table rows");
				ForEach($Hash in $Hashtable) 
				{
					$OrderedValues = @();
					## Add each row item in the specified order
					ForEach($Column in $Columns) 
					{ 
						$OrderedValues += $Hash.$Column; 
					}
					## Use the ordered list to add each column in specified order
					[ref] $Null = $WordRangeString.AppendFormat("{0}`n", [string]::Join("`t", $OrderedValues));
				} ## end foreach

				Write-Debug ("$(Get-Date): `t`t`tAdded '{0}' table rows" -f $Hashtable.Count);
			} ## end default
		} ## end switch

		## Create a MS Word range and set its text to our tab-delimited, concatenated string
		Write-Debug ("$(Get-Date): `t`tBuilding table range");
		$WordRange = $Script:Doc.Application.Selection.Range;
		$WordRange.Text = $WordRangeString.ToString();

		## Create hash table of named arguments to pass to the ConvertToTable method
		$ConvertToTableArguments = @{ Separator = [Microsoft.Office.Interop.Word.WdTableFieldSeparator]::wdSeparateByTabs; }

		## Negative built-in styles are not supported by the ConvertToTable method
		If($Format -ge 0) 
		{
			$ConvertToTableArguments.Add("Format", $Format);
			$ConvertToTableArguments.Add("ApplyBorders", $True);
			$ConvertToTableArguments.Add("ApplyShading", $True);
			$ConvertToTableArguments.Add("ApplyFont", $True);
			$ConvertToTableArguments.Add("ApplyColor", $True);
			If(!$List) 
			{ 
				$ConvertToTableArguments.Add("ApplyHeadingRows", $True); 
			}
			$ConvertToTableArguments.Add("ApplyLastRow", $True);
			$ConvertToTableArguments.Add("ApplyFirstColumn", $True);
			$ConvertToTableArguments.Add("ApplyLastColumn", $True);
		}

		## Invoke ConvertToTable method - with named arguments - to convert Word range to a table
		## See http://msdn.microsoft.com/en-us/library/office/aa171893(v=office.11).aspx
		Write-Debug ("$(Get-Date): `t`tConverting range to table");
		## Store the table reference just in case we need to set alternate row coloring
		$WordTable = $WordRange.GetType().InvokeMember(
			"ConvertToTable",                               # Method name
			[System.Reflection.BindingFlags]::InvokeMethod, # Flags
			$Null,                                          # Binder
			$WordRange,                                     # Target (self!)
			([Object[]]($ConvertToTableArguments.Values)),  ## Named argument values
			$Null,                                          # Modifiers
			$Null,                                          # Culture
			([String[]]($ConvertToTableArguments.Keys))     ## Named argument names
		);

		## Implement grid lines (will wipe out any existing formatting
		If($Format -lt 0) 
		{
			Write-Debug ("$(Get-Date): `t`tSetting table format");
			$WordTable.Style = $Format;
		}

		## Set the table autofit behavior
		If($AutoFit -ne -1) 
		{ 
			$WordTable.AutoFitBehavior($AutoFit); 
		}

		If(!$List)
		{
			#the next line causes the heading row to flow across page breaks
			$WordTable.Rows.First.Headingformat = $wdHeadingFormatTrue;
		}

		If(!$NoGridLines) 
		{
			$WordTable.Borders.InsideLineStyle = $wdLineStyleSingle;
			$WordTable.Borders.OutsideLineStyle = $wdLineStyleSingle;
		}
		If($NoGridLines) 
		{
			$WordTable.Borders.InsideLineStyle = $wdLineStyleNone;
			$WordTable.Borders.OutsideLineStyle = $wdLineStyleNone;
		}
		If($NoInternalGridLines) 
		{
			$WordTable.Borders.InsideLineStyle = $wdLineStyleNone;
			$WordTable.Borders.OutsideLineStyle = $wdLineStyleSingle;
		}

		Return $WordTable;

	} ## end Process
}

<#
.Synopsis
	Sets the format of one or more Word table cells
.DESCRIPTION
	This function sets the format of one or more table cells, either from a collection
	of Word COM object cell references, an individual Word COM object cell reference or
	a hashtable containing Row and Column information.

	The font name, font size, bold, italic , underline and shading values can be used.
.EXAMPLE
	SetWordCellFormat -Hashtable $Coordinates -Table $TableReference -Bold

	This example sets all text to bold that is contained within the $TableReference
	Word table, using an array of hashtables. Each hashtable contain a pair of co-
	ordinates that is used to select the required cells. Note: the hashtable must
	contain the .Row and .Column key names. For example:
	@ { Row = 7; Column = 3 } to set the cell at row 7 and column 3 to bold.
.EXAMPLE
	$RowCollection = $Table.Rows.First.Cells
	SetWordCellFormat -Collection $RowCollection -Bold -Size 10

	This example sets all text to size 8 and bold for all cells that are contained
	within the first row of the table.
	Note: the $Table.Rows.First.Cells returns a collection of Word COM cells objects
	that are in the first table row.
.EXAMPLE
	$ColumnCollection = $Table.Columns.Item(2).Cells
	SetWordCellFormat -Collection $ColumnCollection -BackgroundColor 255

	This example sets the background (shading) of all cells in the table's second
	column to red.
	Note: the $Table.Columns.Item(2).Cells returns a collection of Word COM cells objects
	that are in the table's second column.
.EXAMPLE
	SetWordCellFormat -Cell $Table.Cell(17,3) -Font "Tahoma" -Color 16711680

	This example sets the font to Tahoma and the text color to blue for the cell located
	in the table's 17th row and 3rd column.
	Note: the $Table.Cell(17,3) returns a single Word COM cells object.
#>

Function SetWordCellFormat 
{
	[CmdletBinding(DefaultParameterSetName='Collection')]
	Param (
		# Word COM object cell collection reference
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='Collection', Position=0)] [ValidateNotNullOrEmpty()] $Collection,
		# Word COM object individual cell reference
		[Parameter(Mandatory=$true, ParameterSetName='Cell', Position=0)] [ValidateNotNullOrEmpty()] $Cell,
		# Hashtable of cell co-ordinates
		[Parameter(Mandatory=$true, ParameterSetName='Hashtable', Position=0)] [ValidateNotNullOrEmpty()] [System.Collections.Hashtable[]] $Coordinates,
		# Word COM object table reference
		[Parameter(Mandatory=$true, ParameterSetName='Hashtable', Position=1)] [ValidateNotNullOrEmpty()] $Table,
		# Font name
		[Parameter()] [AllowNull()] [string] $Font = $null,
		# Font color
		[Parameter()] [AllowNull()] $Color = $null,
		# Font size
		[Parameter()] [ValidateNotNullOrEmpty()] [int] $Size = 0,
		# Cell background color
		[Parameter()] [AllowNull()] $BackgroundColor = $null,
		# Force solid background color
		[Switch] $Solid,
		[Switch] $Bold,
		[Switch] $Italic,
		[Switch] $Underline
	)

	Begin 
	{
		Write-Debug ("Using parameter set '{0}'." -f $PSCmdlet.ParameterSetName);
	}

	Process 
	{
		Switch ($PSCmdlet.ParameterSetName) 
		{
			'Collection' {
				ForEach($Cell in $Collection) 
				{
					If($BackgroundColor -ne $null) { $Cell.Shading.BackgroundPatternColor = $BackgroundColor; }
					If($Bold) { $Cell.Range.Font.Bold = $true; }
					If($Italic) { $Cell.Range.Font.Italic = $true; }
					If($Underline) { $Cell.Range.Font.Underline = 1; }
					If($Font -ne $null) { $Cell.Range.Font.Name = $Font; }
					If($Color -ne $null) { $Cell.Range.Font.Color = $Color; }
					If($Size -ne 0) { $Cell.Range.Font.Size = $Size; }
					If($Solid) { $Cell.Shading.Texture = 0; } ## wdTextureNone
				} # end foreach
			} # end Collection
			'Cell' 
			{
				If($Bold) { $Cell.Range.Font.Bold = $true; }
				If($Italic) { $Cell.Range.Font.Italic = $true; }
				If($Underline) { $Cell.Range.Font.Underline = 1; }
				If($Font -ne $null) { $Cell.Range.Font.Name = $Font; }
				If($Color -ne $null) { $Cell.Range.Font.Color = $Color; }
				If($Size -ne 0) { $Cell.Range.Font.Size = $Size; }
				If($BackgroundColor -ne $null) { $Cell.Shading.BackgroundPatternColor = $BackgroundColor; }
				If($Solid) { $Cell.Shading.Texture = 0; } ## wdTextureNone
			} # end Cell
			'Hashtable' 
			{
				ForEach($Coordinate in $Coordinates) 
				{
					$Cell = $Table.Cell($Coordinate.Row, $Coordinate.Column);
					If($Bold) { $Cell.Range.Font.Bold = $true; }
					If($Italic) { $Cell.Range.Font.Italic = $true; }
					If($Underline) { $Cell.Range.Font.Underline = 1; }
					If($Font -ne $null) { $Cell.Range.Font.Name = $Font; }
					If($Color -ne $null) { $Cell.Range.Font.Color = $Color; }
					If($Size -ne 0) { $Cell.Range.Font.Size = $Size; }
					If($BackgroundColor -ne $null) { $Cell.Shading.BackgroundPatternColor = $BackgroundColor; }
					If($Solid) { $Cell.Shading.Texture = 0; } ## wdTextureNone
				}
			} # end Hashtable
		} # end switch
	} # end process
}

<#
.Synopsis
	Sets alternate row colors in a Word table
.DESCRIPTION
	This function sets the format of alternate rows within a Word table using the
	specified $BackgroundColor. This function is expensive (in performance terms) as
	it recursively sets the format on alternate rows. It would be better to pick one
	of the predefined table formats (if one exists)? Obviously the more rows, the
	longer it takes :'(

	Note: this function is called by the AddWordTable function if an alternate row
	format is specified.
.EXAMPLE
	SetWordTableAlternateRowColor -Table $TableReference -BackgroundColor 255

	This example sets every-other table (starting with the first) row and sets the
	background color to red (wdColorRed).
.EXAMPLE
	SetWordTableAlternateRowColor -Table $TableReference -BackgroundColor 39423 -Seed Second

	This example sets every other table (starting with the second) row and sets the
	background color to light orange (weColorLightOrange).
#>

Function SetWordTableAlternateRowColor 
{
	[CmdletBinding()]
	Param (
		# Word COM object table reference
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)] [ValidateNotNullOrEmpty()] $Table,
		# Alternate row background color
		[Parameter(Mandatory=$true, Position=1)] [ValidateNotNull()] [int] $BackgroundColor,
		# Alternate row starting seed
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=2)] [ValidateSet('First','Second')] [string] $Seed = 'First'
	)

	Process 
	{
		$StartDateTime = Get-Date;
		Write-Debug ("{0}: `t`tSetting alternate table row colors.." -f $StartDateTime);

		## Determine the row seed (only really need to check for 'Second' and default to 'First' otherwise
		If($Seed.ToLower() -eq 'second') 
		{ 
			$StartRowIndex = 2; 
		}
		Else 
		{ 
			$StartRowIndex = 1; 
		}

		For($AlternateRowIndex = $StartRowIndex; $AlternateRowIndex -lt $Table.Rows.Count; $AlternateRowIndex += 2) 
		{ 
			$Table.Rows.Item($AlternateRowIndex).Shading.BackgroundPatternColor = $BackgroundColor;
		}

		## I've put verbose calls in here we can see how expensive this functionality actually is.
		$EndDateTime = Get-Date;
		$ExecutionTime = New-TimeSpan -Start $StartDateTime -End $EndDateTime;
		Write-Debug ("{0}: `t`tDone setting alternate row style color in '{1}' seconds" -f $EndDateTime, $ExecutionTime.TotalSeconds);
	}
}
#endregion

#region general script functions
Function ShowScriptOptions
{
	Write-Verbose "$(Get-Date): "
	Write-Verbose "$(Get-Date): "
	Write-Verbose "$(Get-Date): Company Name : $($Script:CoName)"
	Write-Verbose "$(Get-Date): Cover Page   : $($CoverPage)"
	Write-Verbose "$(Get-Date): User Name    : $($UserName)"
	Write-Verbose "$(Get-Date): Save As PDF  : $($PDF)"
	Write-Verbose "$(Get-Date): Save As TEXT : $($TEXT)"
	Write-Verbose "$(Get-Date): Save As WORD : $($MSWORD)"
	Write-Verbose "$(Get-Date): Save As HTML : $($HTML)"
	Write-Verbose "$(Get-Date): Add DateTime : $($AddDateTime)"
	Write-Verbose "$(Get-Date): HW Inventory : $($Hardware)"
	Write-Verbose "$(Get-Date): Filename1    : $($Script:FileName1)"
	If($PDF)
	{
		Write-Verbose "$(Get-Date): Filename2    : $($Script:FileName2)"
	}
	Write-Verbose "$(Get-Date): OS Detected  : $($RunningOS)"
	Write-Verbose "$(Get-Date): PSUICulture  : $($PSUICulture)"
	Write-Verbose "$(Get-Date): PSCulture    : $($PSCulture)"
	If($MSWord -or $PDF)
	{
		Write-Verbose "$(Get-Date): Word version : $($Script:WordProduct)"
		Write-Verbose "$(Get-Date): Word language: $($Script:WordLanguageValue)"
	}
	Write-Verbose "$(Get-Date): PoSH version : $($Host.Version)"
	Write-Verbose "$(Get-Date): "
	Write-Verbose "$(Get-Date): Script start : $($Script:StartTime)"
	Write-Verbose "$(Get-Date): "
	Write-Verbose "$(Get-Date): "
}

Function validStateProp( [object] $object, [string] $topLevel, [string] $secondLevel )
{
	#function created 8-jan-2015 by Michael B. Smith
	if( $object )
	{
		If( ( gm -Name $topLevel -InputObject $object ) )
		{
			If( ( gm -Name $secondLevel -InputObject $object.$topLevel ) )
			{
				Return $True
			}
		}
	}
	Return $False
}

Function SaveandCloseDocumentandShutdownWord
{
	#bug fix 1-Apr-2015
	#reset Grammar and Spelling options back to their original settings
	$Script:Word.Options.CheckGrammarAsYouType = $Script:CurrentGrammarOption
	$Script:Word.Options.CheckSpellingAsYouType = $Script:CurrentSpellingOption

	Write-Verbose "$(Get-Date): Save and Close document and Shutdown Word"
	If($Script:WordVersion -eq $wdWord2010)
	{
		#the $saveFormat below passes StrictMode 2
		#I found this at the following two links
		#http://blogs.technet.com/b/bshukla/archive/2011/09/27/3347395.aspx
		#http://msdn.microsoft.com/en-us/library/microsoft.office.interop.word.wdsaveformat(v=office.14).aspx
		If($PDF)
		{
			Write-Verbose "$(Get-Date): Saving as DOCX file first before saving to PDF"
		}
		Else
		{
			Write-Verbose "$(Get-Date): Saving DOCX file"
		}
		If($AddDateTime)
		{
			$Script:FileName1 += "_$(Get-Date -f yyyy-MM-dd_HHmm).docx"
			If($PDF)
			{
				$Script:FileName2 += "_$(Get-Date -f yyyy-MM-dd_HHmm).pdf"
			}
		}
		Write-Verbose "$(Get-Date): Running Word 2010 and detected operating system $($RunningOS)"
		$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatDocumentDefault")
		$Script:Doc.SaveAs([REF]$Script:FileName1, [ref]$SaveFormat)
		If($PDF)
		{
			Write-Verbose "$(Get-Date): Now saving as PDF"
			$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatPDF")
			$Script:Doc.SaveAs([REF]$Script:FileName2, [ref]$saveFormat)
		}
	}
	ElseIf($Script:WordVersion -eq $wdWord2013 -or $Script:WordVersion -eq $wdWord2016)
	{
		If($PDF)
		{
			Write-Verbose "$(Get-Date): Saving as DOCX file first before saving to PDF"
		}
		Else
		{
			Write-Verbose "$(Get-Date): Saving DOCX file"
		}
		If($AddDateTime)
		{
			$Script:FileName1 += "_$(Get-Date -f yyyy-MM-dd_HHmm).docx"
			If($PDF)
			{
				$Script:FileName2 += "_$(Get-Date -f yyyy-MM-dd_HHmm).pdf"
			}
		}
		Write-Verbose "$(Get-Date): Running Word 2013 and detected operating system $($RunningOS)"
		$Script:Doc.SaveAs2([REF]$Script:FileName1, [ref]$wdFormatDocumentDefault)
		If($PDF)
		{
			Write-Verbose "$(Get-Date): Now saving as PDF"
			$Script:Doc.SaveAs([REF]$Script:FileName2, [ref]$wdFormatPDF)
		}
	}

	Write-Verbose "$(Get-Date): Closing Word"
	$Script:Doc.Close()
	Write-Verbose "$(Get-Date): Waiting 10 seconds to allow Word to save file"
	Start-Sleep -Seconds 10
	$Script:Word.Quit()
	Write-Verbose "$(Get-Date): Waiting 10 seconds to allow Word to fully close"
	Start-Sleep -Seconds 10
	If($PDF)
	{
		[int]$cnt = 0
		While(Test-Path $Script:FileName1)
		{
			$cnt++
			If($cnt -gt 1)
			{
				Write-Verbose "$(Get-Date): Waiting another 10 seconds to allow Word to fully close (try # $($cnt))"
				Start-Sleep -Seconds 10
				$Script:Word.Quit()
				If($cnt -gt 2)
				{
					#kill the winword process

					#find out our session (usually "1" except on TS/RDC or Citrix)
					$SessionID = (Get-Process -PID $PID).SessionId
					
					#Find out if winword is running in our session
					$wordprocess = ((Get-Process 'WinWord' -ea 0)|?{$_.SessionId -eq $SessionID}).Id
					If($wordprocess -gt 0)
					{
						Write-Verbose "$(Get-Date): Attempting to stop WinWord process # $($wordprocess)"
						Stop-Process $wordprocess -EA 0
					}
				}
			}
			Write-Verbose "$(Get-Date): Attempting to delete $($Script:FileName1) since only $($Script:FileName2) is needed (try # $($cnt))"
			Remove-Item $Script:FileName1 -EA 0 4>$Null
		}
	}
	Write-Verbose "$(Get-Date): System Cleanup"
	[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Script:Word) | Out-Null
	If(Test-Path variable:global:word)
	{
		Remove-Variable -Name word -Scope Global 4>$Null
	}
	$SaveFormat = $Null
	[gc]::collect() 
	[gc]::WaitForPendingFinalizers()
	
	#is the winword process still running? kill it

	#find out our session (usually "1" except on TS/RDC or Citrix)
	$SessionID = (Get-Process -PID $PID).SessionId

	#Find out if winword is running in our session
	$wordprocess = ((Get-Process 'WinWord' -ea 0)|?{$_.SessionId -eq $SessionID}).Id
	If($wordprocess -gt 0)
	{
		Write-Verbose "$(Get-Date): WinWord process is still running. Attempting to stop WinWord process # $($wordprocess)"
		Stop-Process $wordprocess -EA 0
	}
}

Function SaveandCloseTextDocument
{
	If($AddDateTime)
	{
		$Script:FileName1 += "_$(Get-Date -f yyyy-MM-dd_HHmm).txt"
	}

	Write-Output $Global:Output | Out-File $Script:Filename1 4>$Null
}

Function SaveandCloseHTMLDocument
{
    #echo "<p></p></body></html>" >> $FileName1
	out-file -FilePath $Script:FileName1 -Append -InputObject "<p></p></body></html>" 4>$Null
}

Function SetFileName1andFileName2
{
	Param([string]$OutputFileName)
	$pwdpath = $pwd.Path

	If($pwdpath.EndsWith("\"))
	{
		#remove the trailing \
		$pwdpath = $pwdpath.SubString(0, ($pwdpath.Length - 1))
	}

	#set $filename1 and $filename2 with no file extension
	If($AddDateTime)
	{
		[string]$Script:FileName1 = "$($pwdpath)\$($OutputFileName)"
		If($PDF)
		{
			[string]$Script:FileName2 = "$($pwdpath)\$($OutputFileName)"
		}
	}

	If($MSWord -or $PDF)
	{
		CheckWordPreReq

		If(!$AddDateTime)
		{
			[string]$Script:FileName1 = "$($pwdpath)\$($OutputFileName).docx"
			If($PDF)
			{
				[string]$Script:FileName2 = "$($pwdpath)\$($OutputFileName).pdf"
			}
		}

		SetupWord
	}
	ElseIf($Text)
	{
		If(!$AddDateTime)
		{
			[string]$Script:FileName1 = "$($pwdpath)\$($OutputFileName).txt"
		}
	}
	ElseIf($HTML)
	{
		If(!$AddDateTime)
		{
			[string]$Script:FileName1 = "$($pwdpath)\$($OutputFileName).html"
		}
       SetupHTML
	}
}

Function TestComputerName
{
	Param([string]$Cname)
	If(![String]::IsNullOrEmpty($CName)) 
	{
		#get computer name
		#first test to make sure the computer is reachable
		Write-Verbose "$(Get-Date): Testing to see if $($CName) is online and reachable"
		If(Test-Connection -ComputerName $CName -quiet)
		{
			Write-Verbose "$(Get-Date): Server $($CName) is online."
		}
		Else
		{
			Write-Verbose "$(Get-Date): Computer $($CName) is offline"
			$ErrorActionPreference = $SaveEAPreference
			Write-Error "`n`n`t`tComputer $($CName) is offline.`nScript cannot continue.`n`n"
			Exit
		}
	}

	#if computer name is localhost, get actual computer name
	If($CName -eq "localhost")
	{
		$CName = $env:ComputerName
		Write-Verbose "$(Get-Date): Computer name has been renamed from localhost to $($CName)"
		Return $CName
	}

	#if computer name is an IP address, get host name from DNS
	#http://blogs.technet.com/b/gary/archive/2009/08/29/resolve-ip-addresses-to-hostname-using-powershell.aspx
	#help from Michael B. Smith
	$ip = $CName -as [System.Net.IpAddress]
	If($ip)
	{
		$Result = [System.Net.Dns]::gethostentry($ip)
		
		If($? -and $Result -ne $Null)
		{
			$CName = $Result.HostName
			Write-Verbose "$(Get-Date): Computer name has been renamed from $($ip) to $($CName)"
			Return $CName
		}
		Else
		{
			Write-Warning "Unable to resolve $($CName) to a hostname"
		}
	}
	Else
	{
		#computer is online but for some reason $ComputerName cannot be converted to a System.Net.IpAddress
	}
	Return $CName
}

Function ProcessDocumentOutput
{
	If($MSWORD -or $PDF)
	{
		SaveandCloseDocumentandShutdownWord
	}
	ElseIf($Text)
	{
		SaveandCloseTextDocument
	}
	ElseIf($HTML)
	{
		SaveandCloseHTMLDocument
	}

	If($PDF)
	{
		If(Test-Path "$($Script:FileName2)")
		{
			Write-Verbose "$(Get-Date): $($Script:FileName2) is ready for use"
		}
		Else
		{
			Write-Warning "$(Get-Date): Unable to save the output file, $($Script:FileName2)"
			Write-Error "Unable to save the output file, $($Script:FileName2)"
		}
	}
	Else
	{
		If(Test-Path "$($Script:FileName1)")
		{
			Write-Verbose "$(Get-Date): $($Script:FileName1) is ready for use"
		}
		Else
		{
			Write-Warning "$(Get-Date): Unable to save the output file, $($Script:FileName1)"
			Write-Error "Unable to save the output file, $($Script:FileName1)"
		}
	}
}

Function AbortScript
{
	If($MSWord -or $PDF)
	{
		$Script:Word.quit()
		Write-Verbose "$(Get-Date): System Cleanup"
		[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Script:Word) | Out-Null
		If(Test-Path variable:global:word)
		{
			Remove-Variable -Name word -Scope Global
		}
	}
	[gc]::collect() 
	[gc]::WaitForPendingFinalizers()
	Write-Verbose "$(Get-Date): Script has been aborted"
	$ErrorActionPreference = $SaveEAPreference
	Exit
}

Function OutputWarning
{
	Param([string] $txt)
	Write-Warning $txt
	If($MSWord -or $PDF)
	{
		WriteWordLine 0 1 $txt
	}
	ElseIf($Text)
	{
		Line 1 $txt
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 0 1 $txt
	}
}

Function SecondsToMinutes
{
	Param($xVal)
	
	If([int]$xVal -lt 60)
	{
		Return "0:$xVal"
	}
	$xMinutes = ([int]($xVal / 60)).ToString()
	$xSeconds = ([int]($xVal % 60)).ToString().PadLeft(2, "0")
	Return "$xMinutes`:$xSeconds"
}

Function Check-NeededPSSnapins
{
	Param([parameter(Mandatory = $True)][alias("Snapin")][string[]]$Snapins)

	#Function specifics
	$MissingSnapins = @()
	[bool]$FoundMissingSnapin = $False
	$LoadedSnapins = @()
	$RegisteredSnapins = @()

	#Creates arrays of strings, rather than objects, we're passing strings so this will be more robust.
	$loadedSnapins += Get-Pssnapin | % {$_.name}
	$registeredSnapins += Get-Pssnapin -Registered | % {$_.name}

	ForEach($Snapin in $Snapins)
	{
		#check if the snapin is loaded
		If(!($LoadedSnapins -like $snapin))
		{
			#Check if the snapin is missing
			If(!($RegisteredSnapins -like $Snapin))
			{
				#set the flag if it's not already
				If(!($FoundMissingSnapin))
				{
					$FoundMissingSnapin = $True
				}
				#add the entry to the list
				$MissingSnapins += $Snapin
			}
			Else
			{
				#Snapin is registered, but not loaded, loading it now:
				Add-PSSnapin -Name $snapin -EA 0 *>$Null
			}
		}
	}

	If($FoundMissingSnapin)
	{
		Write-Warning "Missing Windows PowerShell snap-ins Detected:"
		$missingSnapins | % {Write-Warning "($_)"}
		Return $False
	}
	Else
	{
		Return $True
	}
}

Function OutputViewMembers
{		 
	Param([object] $Members)
	
	If($MSWord -or $PDF)
	{
		## Create an array of hashtables to store our admins
		[System.Collections.Hashtable[]] $MembersWordTable = @();
		## Seed the row index from the second row
		[int] $CurrentServiceIndex = 1;
	}
	ElseIf($HTML)
	{
		$rowdata = @()
	}

	ForEach($Member in $Members)
	{
		If($MSWord -or $PDF)
		{
			$WordTableRowHash = @{Name = $Member.deviceName;}
			$MembersWordTable += $WordTableRowHash;
			$CurrentServiceIndex++;
		}
		ElseIf($Text)
		{
			Line 3 $Member.deviceName
		}
		ElseIf($HTML)
		{
			$rowdata += @(,(
			$Member.deviceName,$htmlwhite))
		}
	}
	If($MSword -or $PDF)
	{
		## Add the table to the document, using the hashtable (-Alt is short for -AlternateBackgroundColor!)
		$Table = AddWordTable -Hashtable $MembersWordTable `
		-Columns Name `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format
		SetWordCellFormat -Collection $Table.Rows.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($HTML)
	{
		$columnHeaders = @(
		'Name',($htmlsilver -bor $htmlbold))
		
		$msg = "Members"
		FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
		WriteHTMLLine 0 0 ""
	}
}

Function DeviceStatus
{
	Param($xDevice)

	If($xDevice -eq $Null -or $xDevice.status -eq "" -or $xDevice.status -eq "0")
	{
		If($MSWord -or $PDF)
		{
			WriteWordLine 0 0 "Target device inactive"
		}
		ElseIf($Text)
		{
			Line 3 "Target device inactive"
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 0 3 "Target device inactive"
		}
	}
	Else
	{
		Switch ($xDevice.diskVersionAccess)
		{
			0 {$xDevicediskVersionAccess = "Production"}
			1 {$xDevicediskVersionAccess = "Test"}
			2 {$xDevicediskVersionAccess = "Maintenance"}
			3 {$xDevicediskVersionAccess = "Personal vDisk"}
			Default {$xDevicediskVersionAccess = "vDisk access type could not be determined: $($xDevice.diskVersionAccess)"}
		}

		Switch($xDevice.bdmBoot)
		{
			0 {$xDevicebdmBoot = "PXE boot"}
			1 {$xDevicebdmBoot = "BDM disk"}
			Default {$xDevicebdmBoot = "Boot mode could not be determined: $($xDevice.bdmBoot)"}
		}

		Switch($xDevice.licenseType)
		{
			0 {$xDevicelicenseType = "No License"}
			1 {$xDevicelicenseType = "Desktop License"}
			2 {$xDevicelicenseType = "Server License"}
			5 {$xDevicelicenseType = "OEM SmartClient License"}
			6 {$xDevicelicenseType = "XenApp License"}
			7 {$xDevicelicenseType = "XenDesktop License"}
			Default {$xDevicelicenseType = "Device license type could not be determined: $($xDevice.licenseType)"}
		}

		Switch ($xDevice.logLevel)
		{
			0   {$xDevicelogLevel = "Off"    }
			1   {$xDevicelogLevel = "Fatal"  }
			2   {$xDevicelogLevel = "Error"  }
			3   {$xDevicelogLevel = "Warning"}
			4   {$xDevicelogLevel = "Info"   }
			5   {$xDevicelogLevel = "Debug"  }
			6   {$xDevicelogLevel = "Trace"  }
			Default {$xDevicelogLevel = "Logging level could not be determined: $($xDevice.logLevel)"}
		}

		If($MSWord -or $PDF)
		{
			[System.Collections.Hashtable[]] $ScriptInformation = @()
			$ScriptInformation += @{ Data = "Target device active"; Value = ""; }
			$ScriptInformation += @{ Data = "IP Address"; Value = $xDevice.ip; }
			$ScriptInformation += @{ Data = "Server"; Value = "$($xDevice.serverName) `($($xDevice.serverIpConnection)`: $($xDevice.serverPortConnection)`)"; }
			$ScriptInformation += @{ Data = "Retries"; Value = $xDevice.status; }
			$ScriptInformation += @{ Data = "vDisk"; Value = $xDevice.diskLocatorName; }
			$ScriptInformation += @{ Data = "vDisk version"; Value = $xDevice.diskVersion; }
			$ScriptInformation += @{ Data = "vDisk name"; Value = $xDevice.diskFileName; }
			$ScriptInformation += @{ Data = "vDisk access"; Value = $xDevicediskVersionAccess; }
			$ScriptInformation += @{ Data = "Local write cache disk"; Value = "$($xDevice.localWriteCacheDiskSize)GB"; }
			$ScriptInformation += @{ Data = "Boot mode"; Value = $xDevicebdmBoot; }
			$ScriptInformation += @{ Data = $xDevicelicenseType; Value = ""; }
			$Table = AddWordTable -Hashtable $ScriptInformation `
			-Columns Data,Value `
			-List `
			-Format $wdTableGrid `
			-AutoFit $wdAutoFitContent;

			SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

			#$Table.Columns.Item(1).Width = 250;
			#$Table.Columns.Item(2).Width = 250;

			$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

			FindWordDocumentEnd
			$Table = $Null
			WriteWordLine 0 0 ""
			
			WriteWordLine 4 0 "Logging"
			
			[System.Collections.Hashtable[]] $ScriptInformation = @()
			$ScriptInformation += @{ Data = "Logging level"; Value = $xDevicelogLevel; }

			$Table = AddWordTable -Hashtable $ScriptInformation `
			-Columns Data,Value `
			-List `
			-Format $wdTableGrid `
			-AutoFit $wdAutoFitContent;

			SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

			#$Table.Columns.Item(1).Width = 250;
			#$Table.Columns.Item(2).Width = 250;

			$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

			FindWordDocumentEnd
			$Table = $Null
			WriteWordLine 0 0 ""
		}
		ElseIf($Text)
		{
			Line 3 "Target device active"
			Line 3 "IP Address`t`t: " $xDevice.ip
			Line 3 "Server`t`t`t: " "$($xDevice.serverName) `($($xDevice.serverIpConnection)`: $($xDevice.serverPortConnection)`)"
			Line 3 "Retries`t`t`t: " $xDevice.status
			Line 3 "vDisk`t`t`t: " $xDevice.diskLocatorName
			Line 3 "vDisk version`t`t: " $xDevice.diskVersion
			Line 3 "vDisk name`t`t: " $xDevice.diskFileName
			Line 3 "vDisk access`t`t: " $xDevicediskVersionAccess
			Line 3 "Local write cache disk`t:$($xDevice.localWriteCacheDiskSize)GB"
			Line 3 "Boot mode`t`t:" $xDevicebdmBoot
			Line 3 $xDevicelicenseType
			
			Line 2 "Logging"
			Line 3 "Logging level`t`t: " $xDevicelogLevel
			
			Line 0 ""
		}
		ElseIf($HTML)
		{
			$rowdata = @()
			$columnHeaders = @("Target device active",($htmlsilver -bor $htmlbold),"",$htmlwhite)
			$rowdata += @(,('IP Address',($htmlsilver -bor $htmlbold),$xDevice.ip,$htmlwhite))
			$rowdata += @(,('Server',($htmlsilver -bor $htmlbold),"$($xDevice.serverName) `($($xDevice.serverIpConnection)`: $($xDevice.serverPortConnection)`)",$htmlwhite))
			$rowdata += @(,('Retries',($htmlsilver -bor $htmlbold),$xDevice.status,$htmlwhite))
			$rowdata += @(,('vDisk',($htmlsilver -bor $htmlbold),$xDevice.diskLocatorName,$htmlwhite))
			$rowdata += @(,('vDisk version',($htmlsilver -bor $htmlbold),$xDevice.diskVersion,$htmlwhite))
			$rowdata += @(,('vDisk name',($htmlsilver -bor $htmlbold),$xDevice.diskFileName,$htmlwhite))
			$rowdata += @(,('vDisk access',($htmlsilver -bor $htmlbold),$xDevicediskVersionAccess,$htmlwhite))
			$rowdata += @(,('Local write cache disk',($htmlsilver -bor $htmlbold),"$($xDevice.localWriteCacheDiskSize)GB",$htmlwhite))
			$rowdata += @(,('Boot mode',($htmlsilver -bor $htmlbold),$xDevicebdmBoot,$htmlwhite))
			$rowdata += @(,($xDevicelicenseType,($htmlsilver -bor $htmlbold),"",$htmlwhite))

			$msg = ""
			FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
			WriteHTMLLine 0 0 ""
			
			$rowdata = @()
			$columnHeaders = @("Logging level",($htmlsilver -bor $htmlbold),$xDevicelogLevel,$htmlwhite)

			$msg = "Logging"
			FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
			WriteHTMLLine 0 0 ""
		}
	}
}
#endregion

#region script setup function
Function ProcessScriptSetup
{
	$script:startTime = Get-Date

	Write-Verbose "$(Get-Date): Checking for PVS PSSnapin"
	If(!(Check-NeededPSSnapins "Citrix.PVS.SnapIn")){
		#We're missing Citrix Snapins that we need
		$ErrorActionPreference = $SaveEAPreference
		Write-Error "Missing Citrix PowerShell Snap-ins Detected, check the console above for more information. Script will now close."
		Exit
	}
	Else
	{
		Write-Verbose "$(Get-Date): PVS PSSnapin loaded"
	}
	
	#setup remoting if $AdminAddress is not empty
	[bool]$Script:Remoting = $False
	If(![System.String]::IsNullOrEmpty($AdminAddress))
	{
		Write-Verbose "$(Get-Date): Creating connection to PVS Server $($AdminAddress)"
		If(![System.String]::IsNullOrEmpty($User))
		{
			If([System.String]::IsNullOrEmpty($Domain))
			{
				$Domain = Read-Host "Domain name for user is required.  Enter Domain name for user"
			}		

			If([System.String]::IsNullOrEmpty($Password))
			{
				$Password = Read-Host "Password for user is required.  Enter password for user"
			}		
			Set-PVSConnection -server $AdminAddress -user $User -domain $Domain -password $Password -EA 0 4>$Null
		}
		Else
		{
			Set-PVSConnection -server $AdminAddress -EA 0 4>$Null
		}

		#If($? -and (Get-PVSConnection).Server -eq $AdminAddress 4>$Null)
		If($?)
		{
			$Script:Remoting = $True
			Write-Verbose "$(Get-Date): This script is being run remotely against server $($AdminAddress)"
			If(![System.String]::IsNullOrEmpty($User))
			{
				Write-Verbose "$(Get-Date): User=$($User)"
				Write-Verbose "$(Get-Date): Domain=$($Domain)"
			}
		}
		Else 
		{
			$ErrorActionPreference = $SaveEAPreference
			Write-Warning "Remoting could not be setup to server $($AdminAddress)"
			Write-Warning "Check the Citrix PVS Soap Server Service on $($AdminAddress)"
			Write-Warning "Script cannot continue"
			Exit
		}
	}

	Write-Verbose "$(Get-Date): Verifying PVS SOAP and Stream Services are running"
	$soapserver = $Null
	$StreamService = $Null

	If($Script:Remoting)
	{
		$soapserver = Get-Service -ComputerName $AdminAddress -EA 0 | Where-Object {$_.DisplayName -like "*Citrix PVS Soap Server*"}
		$StreamService = Get-Service -ComputerName $AdminAddress -EA 0 | Where-Object {$_.DisplayName -like "*Citrix PVS Stream Service*"}
	}
	Else
	{
		$soapserver = Get-Service -EA 0 | Where-Object {$_.DisplayName -like "*Citrix PVS Soap Server*"}
		$StreamService = Get-Service -EA 0 | Where-Object {$_.DisplayName -like "*Citrix PVS Stream Service*"}
	}

	If($soapserver.Status -ne "Running")
	{
		$ErrorActionPreference = $SaveEAPreference
		If($Script:Remoting)
		{
			Write-Warning "The Citrix PVS Soap Server service is not Started on server $($AdminAddress)"
		}
		Else
		{
			Write-Warning "The Citrix PVS Soap Server service is not Started"
		}
		Write-Error "Script cannot continue.  See message above."
		Exit
	}

	If($StreamService.Status -ne "Running")
	{
		$ErrorActionPreference = $SaveEAPreference
		If($Script:Remoting)
		{
			Write-Warning "The Citrix PVS Stream Service service is not Started on server $($AdminAddress)"
		}
		Else
		{
			Write-Warning "The Citrix PVS Stream Service service is not Started"
		}
		Write-Error "Script cannot continue.  See message above."
		Exit
	}

	#get PVS major version
	Write-Verbose "$(Get-Date): Getting PVS version info"

	$Results = Get-PVSVersion -EA 0 4>$Null
	If($? -and $Results -ne $Null)
	{
		#build PVS version values
		$Script:version = $Results.MapiVersion 
		$Script:PVSVersion = $Version.SubString(0,1)	
		$Script:PVSFullVersion = $Version.SubString(0,3)	} 
	Else 
	{
		$ErrorActionPreference = $SaveEAPreference
		Write-Warning "PVS version information could not be retrieved"
		Write-Error "Script is terminating"
		#without version info, script should not proceed
		Exit
	}
}
#endregion

#region audit trail function
Function OutputAuditTrail
{

	Param([object] $Audits, [string] $Level)
		
	If($Audits -ne $Null)
	{
		If($MSWord -or $PDF)
		{
			$selection.InsertNewPage()
			WriteWordLine 2 0 "$($Level) Audit Trail"
			WriteWordLine 0 0 "Audit Trail for dates $($StartDate) through $($EndDate)"
		}
		ElseIf($Text)
		{
			Line 0 ""
			Line 0 "$($Level) Audit Trail"
			Line 0 "Audit Trail for dates $($StartDate) through $($EndDate)"
			Line 0 ""
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 2 0 "$($Level) Audit Trail"
			WriteHTMLLine 4 0 "Audit Trail for dates $($StartDate) through $($EndDate)"
			WriteHTMLLine 0 0 ""
		}

		If($MSWord -or $PDF)
		{
			## Create an array of hashtables to store our services
			[System.Collections.Hashtable[]] $AuditWordTable = @();
			## Create an array of hashtables to store references of cells that we wish to highlight after the table has been added
			[System.Collections.Hashtable[]] $HighlightedCells = @();
			## Seed the $Services row index from the second row
			[int] $CurrentServiceIndex = 2;
		}
		ElseIf($HTML)
		{
			$rowdata = @()
		}
		
		ForEach($Audit in $Audits)
		{
			$xAction = ""
			Switch([int]$Audit.action)
			{
				1 { $xAction = "Add AuthGroup"}
				2 { $xAction = "Add Collection"}
				3 { $xAction = "Add Device"}
				4 { $xAction = "Add DiskLocator"}
				5 { $xAction = "Add FarmView"}
				6 { $xAction = "Add Server"}
				7 { $xAction = "Add Site"}
				8 { $xAction = "Add SiteView"}
				9 { $xAction = "Add Store"}
				10 { $xAction = "Add UserGroup"}
				11 { $xAction = "Add VirtualHostingPool"}
				12 { $xAction = "Add UpdateTask"}
				13 { $xAction = "Add DiskUpdateDevice"}
				1001 { $xAction = "Delete AuthGroup"}
				1002 { $xAction = "Delete Collection"}
				1003 { $xAction = "Delete Device"}
				1004 { $xAction = "Delete DeviceDiskCacheFile"}
				1005 { $xAction = "Delete DiskLocator"}
				1006 { $xAction = "Delete FarmView"}
				1007 { $xAction = "Delete Server"}
				1008 { $xAction = "Delete ServerStore"}
				1009 { $xAction = "Delete Site"}
				1010 { $xAction = "Delete SiteView"}
				1011 { $xAction = "Delete Store"}
				1012 { $xAction = "Delete UserGroup"}
				1013 { $xAction = "Delete VirtualHostingPool"}
				1014 { $xAction = "Delete UpdateTask"}
				1015 { $xAction = "Delete DiskUpdateDevice"}
				1016 { $xAction = "Delete DiskVersion"}
				2001 { $xAction = "Run AddDeviceToDomain"}
				2002 { $xAction = "Run ApplyAutoUpdate"}
				2003 { $xAction = "Run ApplyIncrementalUpdate"}
				2004 { $xAction = "Run ArchiveAuditTrail"}
				2005 { $xAction = "Run AssignAuthGroup"}
				2006 { $xAction = "Run AssignDevice"}
				2007 { $xAction = "Run AssignDiskLocator"}
				2008 { $xAction = "Run AssignServer"}
				2009 { $xAction = "Run Boot"}
				2010 { $xAction = "Run CopyPasteDevice"}
				2011 { $xAction = "Run CopyPasteDisk"}
				2012 { $xAction = "Run CopyPasteServer"}
				2013 { $xAction = "Run CreateDirectory"}
				2014 { $xAction = "Run CreateDiskCancel"}
				2015 { $xAction = "Run DisableCollection"}
				2016 { $xAction = "Run DisableDevice"}
				2017 { $xAction = "Run DisableDeviceDiskLocator"}
				2018 { $xAction = "Run DisableDiskLocator"}
				2019 { $xAction = "Run DisableUserGroup"}
				2020 { $xAction = "Run DisableUserGroupDiskLocator"}
				2021 { $xAction = "Run DisplayMessage"}
				2022 { $xAction = "Run EnableCollection"}
				2023 { $xAction = "Run EnableDevice"}
				2024 { $xAction = "Run EnableDeviceDiskLocator"}
				2025 { $xAction = "Run EnableDiskLocator"}
				2026 { $xAction = "Run EnableUserGroup"}
				2027 { $xAction = "Run EnableUserGroupDiskLocator"}
				2028 { $xAction = "Run ExportOemLicenses"}
				2029 { $xAction = "Run ImportDatabase"}
				2030 { $xAction = "Run ImportDevices"}
				2031 { $xAction = "Run ImportOemLicenses"}
				2032 { $xAction = "Run MarkDown"}
				2033 { $xAction = "Run Reboot"}
				2034 { $xAction = "Run RemoveAuthGroup"}
				2035 { $xAction = "Run RemoveDevice"}
				2036 { $xAction = "Run RemoveDeviceFromDomain"}
				2037 { $xAction = "Run RemoveDirectory"}
				2038 { $xAction = "Run RemoveDiskLocator"}
				2039 { $xAction = "Run ResetDeviceForDomain"}
				2040 { $xAction = "Run ResetDatabaseConnection"}
				2041 { $xAction = "Run Restart StreamingService"}
				2042 { $xAction = "Run Shutdown"}
				2043 { $xAction = "Run StartStreamingService"}
				2044 { $xAction = "Run StopStreamingService"}
				2045 { $xAction = "Run UnlockAllDisk"}
				2046 { $xAction = "Run UnlockDisk"}
				2047 { $xAction = "Run ServerStoreVolumeAccess"}
				2048 { $xAction = "Run ServerStoreVolumeMode"}
				2049 { $xAction = "Run MergeDisk"}
				2050 { $xAction = "Run RevertDiskVersion"}
				2051 { $xAction = "Run PromoteDiskVersion"}
				2052 { $xAction = "Run CancelDiskMaintenance"}
				2053 { $xAction = "Run ActivateDevice"}
				2054 { $xAction = "Run AddDiskVersion"}
				2055 { $xAction = "Run ExportDisk"}
				2056 { $xAction = "Run AssignDisk"}
				2057 { $xAction = "Run RemoveDisk"}
				2057 { $xAction = "Run DiskUpdateStart"}
				2057 { $xAction = "Run DiskUpdateCancel"}
				2058 { $xAction = "Run SetOverrideVersion"}
				2059 { $xAction = "Run CancelTask"}
				2060 { $xAction = "Run ClearTask"}
				3001 { $xAction = "Run WithReturnCreateDisk"}
				3002 { $xAction = "Run WithReturnCreateDiskStatus"}
				3003 { $xAction = "Run WithReturnMapDisk"}
				3004 { $xAction = "Run WithReturnRebalanceDevices"}
				3005 { $xAction = "Run WithReturnCreateMaintenanceVersion"}
				3006 { $xAction = "Run WithReturnImportDisk"}
				4001 { $xAction = "Run ByteArrayInputImportDevices"}
				4002 { $xAction = "Run ByteArrayInputImportOemLicenses"}
				5001 { $xAction = "Run ByteArrayOutputArchiveAuditTrail"}
				5002 { $xAction = "Run ByteArrayOutputExportOemLicenses"}
				6001 { $xAction = "Set AuthGroup"}
				6002 { $xAction = "Set Collection"}
				6003 { $xAction = "Set Device"}
				6004 { $xAction = "Set Disk"}
				6005 { $xAction = "Set DiskLocator"}
				6006 { $xAction = "Set Farm"}
				6007 { $xAction = "Set FarmView"}
				6008 { $xAction = "Set Server"}
				6009 { $xAction = "Set ServerBiosBootstrap"}
				6010 { $xAction = "Set ServerBootstrap"}
				6011 { $xAction = "Set ServerStore"}
				6012 { $xAction = "Set Site"}
				6013 { $xAction = "Set SiteView"}
				6014 { $xAction = "Set Store"}
				6015 { $xAction = "Set UserGroup"}
				6016 { $xAction = "Set VirtualHostingPool"}
				6017 { $xAction = "Set UpdateTask"}
				6018 { $xAction = "Set DiskUpdateDevice"}
				7001 { $xAction = "Set ListDeviceBootstraps"}
				7002 { $xAction = "Set ListDeviceBootstraps Delete"}
				7003 { $xAction = "Set ListDeviceBootstraps Add"}
				7004 { $xAction = "Set ListDeviceCustomProperty"}
				7005 { $xAction = "Set ListDeviceCustomPropertyDelete"}
				7006 { $xAction = "Set ListDeviceCustomPropertyAdd"}
				7007 { $xAction = "Set ListDeviceDiskPrinters"}
				7008 { $xAction = "Set ListDeviceDiskPrintersDelete"}
				7009 { $xAction = "Set ListDeviceDiskPrintersAdd"}
				7010 { $xAction = "Set ListDevicePersonality"}
				7011 { $xAction = "Set ListDevicePersonalityDelete"}
				7012 { $xAction = "Set ListDevicePersonalityAdd"}
				7013 { $xAction = "Set ListDevicePortBlockerCategories"}
				7014 { $xAction = "Set ListDevicePortBlockerCategoriesDelete"}
				7015 { $xAction = "Set ListDevicePortBlockerCategoriesAdd"}
				7016 { $xAction = "Set ListDevicePortBlockerOverrides"}
				7017 { $xAction = "Set ListDevicePortBlockerOverridesDelete"}
				7018 { $xAction = "Set ListDevicePortBlockerOverridesAdd"}
				7019 { $xAction = "Set ListDiskLocatorCustomProperty"}
				7020 { $xAction = "Set ListDiskLocatorCustomPropertyDelete"}
				7021 { $xAction = "Set ListDiskLocatorCustomPropertyAdd"}
				7022 { $xAction = "Set ListDiskLocatorPortBlockerCategories"}
				7023 { $xAction = "Set ListDiskLocatorPortBlockerCategoriesDelete"}
				7024 { $xAction = "Set ListDiskLocatorPortBlockerCategoriesAdd"}
				7025 { $xAction = "Set ListDiskLocatorPortBlockerOverrides"}
				7026 { $xAction = "Set ListDiskLocatorPortBlockerOverridesDelete"}
				7027 { $xAction = "Set ListDiskLocatorPortBlockerOverridesAdd"}
				7028 { $xAction = "Set ListServerCustomProperty"}
				7029 { $xAction = "Set ListServerCustomPropertyDelete"}
				7030 { $xAction = "Set ListServerCustomPropertyAdd"}
				7031 { $xAction = "Set ListUserGroupCustomProperty"}
				7032 { $xAction = "Set ListUserGroupCustomPropertyDelete"}
				7033 { $xAction = "Set ListUserGroupCustomPropertyAdd"}				
				Default {$xAction = "Unknown"}
			}
			$xType = ""
			Switch ($Audit.type)
			{
				0 {$xType = "Many"}
				1 {$xType = "AuthGroup"}
				2 {$xType = "Collection"}
				3 {$xType = "Device"}
				4 {$xType = "Disk"}
				5 {$xType = "DiskLocator"}
				6 {$xType = "Farm"}
				7 {$xType = "FarmView"}
				8 {$xType = "Server"}
				9 {$xType = "Site"}
				10 {$xType = "SiteView"}
				11 {$xType = "Store"}
				12 {$xType = "System"}
				13 {$xType = "UserGroup"}
				Default { {$xType = "Undefined"}}
			}
			If($MSWord -or $PDF)
			{
				## Add the required key/values to the hashtable
				$WordTableRowHash = @{ DateTime=$Audit.time; `
				Action=$xAction; `
				Type=$xType; `
				Name=$Audit.objectName; `
				User=$Audit.userName; `
				Domain=$Audit.domain; `
				Path=$Audit.path;  }

				## Add the hash to the array
				$AuditWordTable += $WordTableRowHash;

				$CurrentServiceIndex++;
			}
			ElseIf($Text)
			{
				Line 1 "Date/Time`t: " $Audit.time
				Line 1 "Action`t`t: " $xAction
				Line 1 "Type`t`t: " $xType
				Line 1 "Name`t`t: " $Audit.objectName
				Line 1 "User`t`t: " $Audit.userName
				Line 1 "Domain`t`t: " $Audit.domain
				Line 1 "Path`t`t: " $Audit.path
				Line 0 ""
			}
			ElseIf($HTML)
			{
				$rowdata += @(,(
				$Audit.time,$htmlwhite,
				$xAction,$htmlwhite,
				$xType,$htmlwhite,
				$Audit.objectName,$htmlwhite,
				$Audit.userName,$htmlwhite,
				$Audit.domain,$htmlwhite,
				$Audit.path,$htmlwhite))
			}
		}

		If($MSWord -or $PDF)
		{
			## Add the table to the document, using the hashtable (-Alt is short for -AlternateBackgroundColor!)
			$Table = AddWordTable -Hashtable $AuditWordTable `
			-Columns DateTime,Action,Type,Name,User,Domain,Path `
			-Headers "Date/Time","Action","Type","Name","User","Domain","Path" `
			-AutoFit $wdAutoFitFixed;

			#set table to 9 point
			SetWordCellFormat -Collection $Table -Size 9
			## IB - Set the header row format after the SetWordTableAlternateRowColor function as it will paint the header row!
			SetWordCellFormat -Collection $Table.Rows.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

			## IB - set column widths without recursion
			$Table.Columns.Item(1).Width = 65;
			$Table.Columns.Item(2).Width = 95;
			$Table.Columns.Item(3).Width = 50;
			$Table.Columns.Item(4).Width = 65;
			$Table.Columns.Item(5).Width = 65;
			$Table.Columns.Item(6).Width = 80;
			$Table.Columns.Item(7).Width = 80;

			$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

			FindWordDocumentEnd
			$TableRange = $Null
			$Table = $Null
		}
		ElseIf($HTML)
		{
			$columnHeaders = @(
			'Date/Time',($htmlsilver -bor $htmlbold),
			'Action',($htmlsilver -bor $htmlbold),
			'Type',($htmlsilver -bor $htmlbold),
			'Name',($htmlsilver -bor $htmlbold),
			'User',($htmlsilver -bor $htmlbold),
			'Domain',($htmlsilver -bor $htmlbold),
			'Path',($htmlsilver -bor $htmlbold))
			
			$msg = ""
			FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
			WriteHTMLLine 0 0 ""
		}
	}
}

Function OutputauthGroups
{
	Param([object] $authGroups)
	
	If($MSWord -or $PDF)
	{
		## Create an array of hashtables to store our admins
		[System.Collections.Hashtable[]] $AuthWordTable = @();
		## Seed the row index from the second row
		[int] $CurrentServiceIndex = 1;
	}
	ElseIf($HTML)
	{
		$rowdata = @()
	}

	ForEach($Group in $authgroups)
	{
		If($Group.authGroupName)
		{
			If($MSword -or $PDF)
			{
				$WordTableRowHash = @{Name = $Group.authGroupName;}
				$AuthWordTable += $WordTableRowHash;
				$CurrentServiceIndex++;
			}
			ElseIf($Text)
			{
				Line 2 $Group.authGroupName
			}
			ElseIf($HTML)
			{
				$rowdata += @(,(
				$Group.authGroupName,$htmlwhite))
			}
		}
	}
	
	If($MSword -or $PDF)
	{
		## Add the table to the document, using the hashtable (-Alt is short for -AlternateBackgroundColor!)
		$Table = AddWordTable -Hashtable $AuthWordTable `
		-Columns Name `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		SetWordCellFormat -Collection $Table.Rows.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($HTML)
	{
		$columnHeaders = @(
		'Name',($htmlsilver -bor $htmlbold))
		
		$msg = ""
		FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
	}
}

Function OutputauthGroupUsages
{
	Param([object] $authGroups)
	
	If($MSWord -or $PDF)
	{
		## Create an array of hashtables to store our admins
		[System.Collections.Hashtable[]] $AuthWordTable = @();
		## Seed the row index from the second row
		[int] $CurrentServiceIndex = 1;
	}
	ElseIf($HTML)
	{
		$rowdata = @()
	}

	ForEach($Group in $authgroups)
	{
		If($Group.Name)
		{
			If($MSword -or $PDF)
			{
				$WordTableRowHash = @{Name = $Group.Name;}
				$AuthWordTable += $WordTableRowHash;
				$CurrentServiceIndex++;
			}
			ElseIf($Text)
			{
				Line 2 $Group.Name
			}
			ElseIf($HTML)
			{
				$rowdata += @(,(
				$Group.Name,$htmlwhite))
			}
		}
	}
	
	If($MSword -or $PDF)
	{
		## Add the table to the document, using the hashtable (-Alt is short for -AlternateBackgroundColor!)
		$Table = AddWordTable -Hashtable $AuthWordTable `
		-Columns Name `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		SetWordCellFormat -Collection $Table.Rows.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($HTML)
	{
		$columnHeaders = @(
		'Name',($htmlsilver -bor $htmlbold))
		
		$msg = ""
		FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
	}
}
#endregion

#region pvs farm data

Function ProcessFarm
{
	[bool]$Script:FarmAutoAddEnabled = $False

	#build PVS farm values
	Write-Verbose "$(Get-Date): Processing PVS Farm Information"
	$farm = Get-PVSFarm -EA 0 4>$Null

	If($? -and $farm -ne $Null)
	{
		[string]$FarmName = $farm.FarmName
		[string]$Script:Title="Inventory Report for the $($FarmName) Farm"
		SetFileName1andFileName2 "$($FarmName)"	
		If($farm.autoAddEnabled)
		{
			$Script:FarmAutoAddEnabled = $True
		}
		Else
		{
			$Script:FarmAutoAddEnabled = $False
		}
	}
	Else
	{
		#without farm info, script should not proceed
		$ErrorActionPreference = $SaveEAPreference
		Write-Error "PVS Farm information could not be retrieved.  Script is terminating."
		Exit
	}

	OutputFarm $farm
}

Function OutputFarm
{
	Param([object]$farm)
	
	Write-Verbose "$(Get-Date): Processing PVS Farm Information"
	
	$xautoAddEnabled = "No"
	If($farm.autoAddEnabled)
	{
		$xautoAddEnabled = "Yes"
	}
	$xauditingEnabled = "No"
	If($farm.auditingEnabled)
	{
		$xauditingEnabled = "Yes"
	}
	$xofflineDatabaseSupportEnabled = "No"
	If($farm.offlineDatabaseSupportEnabled)
	{
		$xofflineDatabaseSupportEnabled = "Yes"	
	}
	$xautomaticMergeEnabled = "No"
	If($farm.automaticMergeEnabled)
	{
		$xautomaticMergeEnabled = "Yes"
	}
	$xmergeMode = ""
	Switch ($Farm.mergeMode)
	{
		0   {$xmergeMode = "Production" }
		1   {$xmergeMode = "Test"       }
		2   {$xmergeMode = "Maintenance"}
		Default {$xmergeMode = "Default access mode could not be determined: $($Farm.mergeMode)"}
	}
	$xadGroupsEnabled = ""
	If($Farm.adGroupsEnabled)
	{
		$xadGroupsEnabled = "Active Directory groups are used for access rights"
	}
	Else
	{
		$xadGroupsEnabled = "Active Directory groups are not used for access rights"
	}

	If($MSWord -or $PDF)
	{
		$selection.InsertNewPage()
		WriteWordLine 1 0 "PVS Farm Information"
		#general tab
		WriteWordLine 2 0 "General"
		[System.Collections.Hashtable[]] $ScriptInformation = @()
		$ScriptInformation += @{ Data = "Name"; Value = $farm.farmName; }
		If(![String]::IsNullOrEmpty($farm.description))
		{
			$ScriptInformation += @{ Data = "Description"; Value = $farm.description; }
		}
		$Table = AddWordTable -Hashtable $ScriptInformation `
		-Columns Data,Value `
		-List `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 0 "PVS Farm Information"
		#general tab
		Line 0 "General"
		Line 1 "Name`t`t: " $farm.farmName
		If(![String]::IsNullOrEmpty($farm.description))
		{
			Line 1 "Description`t: " $farm.description
		}
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 1 0 "PVS Farm Information"
		#general tab
		$rowdata = @()
		$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$farm.farmName,$htmlwhite)
		If(![String]::IsNullOrEmpty($farm.description))
		{
			$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$farm.description,$htmlwhite))
		}
		
		$msg = "General"
		FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
	}

	#security tab
	Write-Verbose "$(Get-Date): `tProcessing Security Tab"
	
	If($MSWord -or $PDF)
	{
		WriteWordLine 2 0 "Security"
		WriteWordLine 0 0 "Groups with 'Farm Administrator' access"
	}
	ElseIf($Text)
	{
		Line 0 "Security"
		Line 1 "Groups with Farm Administrator access:"
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 "Security"
		WriteHTMLLine 3 0 "Groups with Farm Administrator access:"
	}
	
	#build security tab values
	$authgroups = Get-PVSAuthGroup -Farm -EA 0 4>$Null

	If($? -and $AuthGroups -ne $Null)
	{
		OutputauthGroups $authGroups
	}
	ElseIf($? -and $AuthGroups -eq $Null)
	{
		$txt = "There are no Farm authorization group"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Farm authorization group"
		OutputWarning $txt
	}

	#groups tab
	Write-Verbose "$(Get-Date): `tProcessing Groups Tab"
	If($MSword -or $PDF)
	{
		WriteWordLine 2 0 "Groups"
		WriteWordLine 0 0 "All the Security Groups that can be assigned access rights"
	}
	ElseIf($Text)
	{
		Line 0 "Groups"
		Line 1 "All the Security Groups that can be assigned access rights:"
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 "Groups"
		WriteHTMLLine 3 0 "All the Security Groups that can be assigned access rights:"
	}
	$authgroups = Get-PVSAuthGroup -EA 0 4>$Null

	If($? -and $AuthGroups -ne $Null)
	{
		OutputauthGroups $authGroups
	}
	ElseIf($? -and $AuthGroups -eq $Null)
	{
		$txt = "There are no authorization groups"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve authorization groups"
		OutputWarning $txt
	}

	#licensing tab
	Write-Verbose "$(Get-Date): `tProcessing Licensing Tab"
	If($MSword -or $PDF)
	{
		WriteWordLine 2 0 "Licensing"
		[System.Collections.Hashtable[]] $ScriptInformation = @()
		$ScriptInformation += @{ Data = "License server name"; Value = $farm.licenseServer; }
		$ScriptInformation += @{ Data = "License server port"; Value = $farm.licenseServerPort; }
		$Table = AddWordTable -Hashtable $ScriptInformation `
		-Columns Data,Value `
		-List `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 0 "Licensing"
		Line 1 "License server name`t: " $farm.licenseServer
		Line 1 "License server port`t: " $farm.licenseServerPort
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 "Licensing"
		$rowdata = @()
		$columnHeaders = @("License server name",($htmlsilver -bor $htmlbold),$farm.licenseServer,$htmlwhite)
		$rowdata += @(,('License server port',($htmlsilver -bor $htmlbold),$farm.licenseServerPort,$htmlwhite))
		FormatHTMLTable "" "auto" -rowArray $rowdata -columnArray $columnHeaders
	}

	#options tab
	Write-Verbose "$(Get-Date): `tProcessing Options Tab"
	If($MSword -or $PDF)
	{
		WriteWordLine 2 0 "Options"
		[System.Collections.Hashtable[]] $ScriptInformation = @()
		$ScriptInformation += @{ Data = "Enable auto-add"; Value = $xautoAddEnabled; }
		If($farm.autoAddEnabled)
		{
			$ScriptInformation += @{ Data = "Add new devices to this site"; Value = $farm.DefaultSiteName; }
		}
		$ScriptInformation += @{ Data = "Enable auditing"; Value = $xauditingEnabled; }
		$ScriptInformation += @{ Data = "Enable offline database support"; Value = $xofflineDatabaseSupportEnabled; }
		$Table = AddWordTable -Hashtable $ScriptInformation `
		-Columns Data,Value `
		-List `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 0 "Options"
		Line 1 "Auto-Add"
		Line 2 "Enable auto-add: " $autoAddEnabled
		If($farm.autoAddEnabled)
		{
			Line 3 "Add new devices to this site: " $farm.DefaultSiteName
		}
		Line 1 "Auditing"
		Line 2 "Enable auditing: " $xauditingEnabled
		Line 1 "Offline database support"
		Line 2 "Enable offline database support: " $xofflineDatabaseSupportEnabled
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 "Options"
		$rowdata = @()
		$columnHeaders = @("Enable auto-add",($htmlsilver -bor $htmlbold),$xautoAddEnabled,$htmlwhite)
		If($farm.autoAddEnabled)
		{
			$rowdata += @(,('Add new devices to this site',($htmlsilver -bor $htmlbold),$farm.DefaultSiteName,$htmlwhite))
		}
		$rowdata += @(,('Enable auditing',($htmlsilver -bor $htmlbold),$xauditingEnabled,$htmlwhite))
		$rowdata += @(,('Enable offline database support',($htmlsilver -bor $htmlbold),$xofflineDatabaseSupportEnabled,$htmlwhite))
		FormatHTMLTable "" "auto" -rowArray $rowdata -columnArray $columnHeaders
	}

	#vDisk Version tab
	Write-Verbose "$(Get-Date): `tProcessing vDisk Version Tab"
	If($MSword -or $PDF)
	{
		WriteWordLine 2 0 "vDisk Version"
		[System.Collections.Hashtable[]] $ScriptInformation = @()
		$ScriptInformation += @{ Data = "Alert if number of versions from base image exceeds"; Value = $farm.maxVersions; }
		$ScriptInformation += @{ Data = "Merge after automated vDisk update, if over alert threshold"; Value = $xautomaticMergeEnabled; }
		$ScriptInformation += @{ Data = "Default access mode for new merge versions"; Value = $xmergeMode; }
		$Table = AddWordTable -Hashtable $ScriptInformation `
		-Columns Data,Value `
		-List `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 0 "vDisk Version"
		Line 1 "Alert if number of versions from base image exceeds`t`t: " $farm.maxVersions
		Line 1 "Merge after automated vDisk update, if over alert threshold`t: " $xautomaticMergeEnabled
		Line 1 "Default access mode for new merge versions`t`t`t: " $xmergeMode
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 "vDisk Version"
		$rowdata = @()
		$columnHeaders = @("Alert if number of versions from base image exceeds",($htmlsilver -bor $htmlbold),$farm.maxVersions,$htmlwhite)
		$rowdata += @(,('Merge after automated vDisk update, if over alert threshold',($htmlsilver -bor $htmlbold),$xautomaticMergeEnabled,$htmlwhite))
		$rowdata += @(,('Default access mode for new merge versions',($htmlsilver -bor $htmlbold),$xmergeMode,$htmlwhite))
		FormatHTMLTable "" "auto" -rowArray $rowdata -columnArray $columnHeaders
	}

	#status tab
	Write-Verbose "$(Get-Date): `tProcessing Status Tab"
	If($MSword -or $PDF)
	{
		WriteWordLine 2 0 "Status"
		WriteWordLine 0 0 "Current status of the farm:"
		[System.Collections.Hashtable[]] $ScriptInformation = @()
		$ScriptInformation += @{ Data = "Database server"; Value = $farm.databaseServerName; }
		$ScriptInformation += @{ Data = "Database instance"; Value = $farm.databaseInstanceName; }
		$ScriptInformation += @{ Data = "Database"; Value = $farm.databaseName; }
		$ScriptInformation += @{ Data = "Failover Partner Server"; Value = $farm.failoverPartnerServerName; }
		$ScriptInformation += @{ Data = "Failover Partner Instance"; Value = $farm.failoverPartnerServerName; }
		$ScriptInformation += @{ Data = $xadGroupsEnabled; Value = ""; }
		$Table = AddWordTable -Hashtable $ScriptInformation `
		-Columns Data,Value `
		-List `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 0 "Status"
		Line 1 "Current status of the farm:"
		Line 2 "Database server`t: " $farm.databaseServerName
		If(![String]::IsNullOrEmpty($farm.databaseInstanceName))
		{
			Line 2 "Database instance`t: " $farm.databaseInstanceName
		}
		Line 2 "Database`t: " $farm.databaseName
		If(![String]::IsNullOrEmpty($farm.failoverPartnerServerName))
		{
			Line 2 "Failover Partner Server: " $farm.failoverPartnerServerName
		}
		If(![String]::IsNullOrEmpty($farm.failoverPartnerInstanceName))
		{
			Line 2 "Failover Partner Instance: " $farm.failoverPartnerInstanceName
		}
		Line 2 "" $xadGroupsEnabled
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 "Status"
		$rowdata = @()
		$columnHeaders = @("Database server",($htmlsilver -bor $htmlbold),$farm.databaseServerName,$htmlwhite)
		If(![String]::IsNullOrEmpty($farm.databaseInstanceName))
		{
			$rowdata += @(,('Database instance',($htmlsilver -bor $htmlbold),$farm.databaseInstanceName,$htmlwhite))
		}
		$rowdata += @(,('Database',($htmlsilver -bor $htmlbold),$farm.databaseName,$htmlwhite))
		If(![String]::IsNullOrEmpty($farm.failoverPartnerServerName))
		{
			$rowdata += @(,('Failover Partner Server',($htmlsilver -bor $htmlbold),$farm.failoverPartnerServerName,$htmlwhite))
		}
		If(![String]::IsNullOrEmpty($farm.failoverPartnerInstanceName))
		{
			$rowdata += @(,('Failover Partner Instance',($htmlsilver -bor $htmlbold),$farm.failoverPartnerInstanceName,$htmlwhite))
		}
		$rowdata += @(,('',($htmlsilver -bor $htmlbold),$xadGroupsEnabled,$htmlwhite))
		
		$msg = "Current status of the farm:"
		FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
	}
	
	#add Audit Trail
	Write-Verbose "$(Get-Date): `tProcessing Audit Trail"
	
	$Audits = Get-PVSAuditTrail -BeginDate $StartDate -EndDate $EndDate -EA 0 4>$Null
	
	If($? -and $Audits -ne $Null)
	{
		OutputAuditTrail $Audits "Farm"
	}
	ElseIf($? -and $Audits -eq $Null)
	{
		$txt = "There are no Farm Audit Trail items"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Farm Audit Trail items"
		OutputWarning $txt
	}
	Write-Verbose "$(Get-Date): "
}
#endregion

#region Site
Function ProcessSites
{
	#build site values
	Write-Verbose "$(Get-Date): Processing Sites"
	$PVSSites = Get-PVSSite -EA 0 4>$Null
	
	If($? -and $PVSSites -ne $Null)
	{
		ForEach($PVSSite in $PVSSites)
		{
			OutputSite $PVSSite
		}
	}
	ElseIf($? -and $PVSSites -eq $Null)
	{
		$txt = "There are no Sites"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Sites"
		OutputWarning $txt
	}
}

Function OutputSite
{
	Param([object] $PVSSite)
	Write-Verbose "$(Get-Date): `tProcessing Site $($PVSSite.siteName)"
	
	$Script:AdvancedItems1 = @()
	$Script:AdvancedItems2 = @()

	$selection.InsertNewPage()
	#general tab
	If($MSWord -or $PDF)
	{
		WriteWordLine 1 0 "Site properties"
		WriteWordLine 2 0 "General"
		[System.Collections.Hashtable[]] $ScriptInformation = @()
		$ScriptInformation += @{ Data = "Name"; Value = $PVSSite.siteName; }
		If(![String]::IsNullOrEmpty($PVSSite.description))
		{
			$ScriptInformation += @{ Data = "Description"; Value = $PVSSite.description; }
		}
		$Table = AddWordTable -Hashtable $ScriptInformation `
		-Columns Data,Value `
		-List `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 0 "Site properties"
		Line 0 "General"
		Line 1 "Name`t`t: " $PVSSite.siteName
		If(![String]::IsNullOrEmpty($PVSSite.description))
		{
			Line 1 "Description`t: " $PVSSite.description
		}
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 1 0 "Site properties"
		WriteHTMLLine 2 0 "General"
		$rowdata = @()
		$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$PVSSite.siteName,$htmlwhite)
		If(![String]::IsNullOrEmpty($PVSSite.description))
		{
			$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$PVSSite.description,$htmlwhite))
		}
		FormatHTMLTable "" "auto" -rowArray $rowdata -columnArray $columnHeaders
	}

	#security tab
	Write-Verbose "$(Get-Date): `t`tProcessing Security Tab"
	If($MSWord -or $PDF)
	{
		WriteWordLine 2 0 "Security"
		WriteWordLine 0 0 "Groups with Site Administrator access"
	}
	ElseIf($Text)
	{
		Line 0 "Security"
		Line 1 "Groups with Site Administrator access:"
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 "Security"
		WriteHTMLLine 3 0 "Groups with Site Administrator access:"
	}
	$authgroups = Get-PVSAuthGroup -SiteName $PVSSite.SiteName -EA 0 4>$Null

	If($? -and $AuthGroups -ne $Null)
	{
		OutputauthGroups $authGroups
	}
	ElseIf($? -and $AuthGroups -eq $Null)
	{
		$txt = "There are no Site Administrators defined"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Site Administrators"
		OutputWarning $txt
	}

	#options tab
	Write-Verbose "$(Get-Date): `t`tProcessing Options Tab"
	$xAutoAdd = ""
	If($Script:FarmAutoAddEnabled)
	{
		If($PVSSite.DefaultCollectionName)
		{
			$xAutoAdd = $PVSSite.DefaultCollectionName
		}
		Else
		{
			$xAutoAdd = "<No Default collection>"
		}
	}
	Else
	{
		$xAutoAdd = "Not enabled at the Farm level"
	}
	If($MSWord -or $PDF)
	{
		WriteWordLine 2 0 "Options"
		WriteWordLine 0 0 "Auto-Add"
		[System.Collections.Hashtable[]] $ScriptInformation = @()
		$ScriptInformation += @{ Data = "Add new devices to this collection"; Value = $xAutoAdd; }
		$Table = AddWordTable -Hashtable $ScriptInformation `
		-Columns Data,Value `
		-List `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 0 "Options"
		Line 1 "Auto-Add"
		Line 2 "Add new devices to this collection: " $xAutoAdd
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 "Options"
		$rowdata = @()
		$columnHeaders = @("Add new devices to this collection",($htmlsilver -bor $htmlbold),$xAutoAdd,$htmlwhite)
		
		$msg = "Auto-Add"
		FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
	}
	
	#vDisk Update
	Write-Verbose "$(Get-Date): `t`tProcessing vDisk Update Tab"
	If($PVSSite.enableDiskUpdate)
	{
		If($MSWord -or $PDF)
		{
			WriteWordLine 2 0 "vDisk Update"
			[System.Collections.Hashtable[]] $ScriptInformation = @()
			$ScriptInformation += @{ Data = "Enable automatic vDisk updates on this site"; Value = "Yes"; }
			$ScriptInformation += @{ Data = "Server to run vDisk updates for this site"; Value = $PVSSite.diskUpdateServerName; }
			$Table = AddWordTable -Hashtable $ScriptInformation `
			-Columns Data,Value `
			-List `
			-Format $wdTableGrid `
			-AutoFit $wdAutoFitContent;

			## IB - Set the header row format
			SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

			$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

			FindWordDocumentEnd
			$Table = $Null
			WriteWordLine 0 0 ""
		}
		ElseIf($Text)
		{
			Line 0 "vDisk Update"
			Line 1 "Enable automatic vDisk updates on this site`t: Yes"
			Line 1 "Server to run vDisk updates for this site`t`t: " $PVSSite.diskUpdateServerName
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 2 0 "vDisk Update"
			$rowdata = @()
			$columnHeaders = @("Enable automatic vDisk updates on this site",($htmlsilver -bor $htmlbold),"Yes",$htmlwhite)
			$rowdata += @(,('Server to run vDisk updates for this site',($htmlsilver -bor $htmlbold),$PVSSite.diskUpdateServerName,$htmlwhite))
			FormatHTMLTable "" "auto" -rowArray $rowdata -columnArray $columnHeaders
		}
	}
	Else
	{
		If($MSWord -or $PDF)
		{
			WriteWordLine 2 0 "vDisk Update"
			[System.Collections.Hashtable[]] $ScriptInformation = @()
			$ScriptInformation += @{ Data = "Enable automatic vDisk updates on this site"; Value = "No"; }
			$Table = AddWordTable -Hashtable $ScriptInformation `
			-Columns Data,Value `
			-List `
			-Format $wdTableGrid `
			-AutoFit $wdAutoFitContent;

			## IB - Set the header row format
			SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

			$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

			FindWordDocumentEnd
			$Table = $Null
			WriteWordLine 0 0 ""
		}
		ElseIf($Text)
		{
			Line 0 "vDisk Update"
			Line 1 "Enable automatic vDisk updates on this site: No"
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 2 0 "vDisk Update"
			$rowdata = @()
			$columnHeaders = @("Enable automatic vDisk updates on this site",($htmlsilver -bor $htmlbold),"No",$htmlwhite)
			FormatHTMLTable "" "auto" -rowArray $rowdata -columnArray $columnHeaders
		}
	}

	#process all servers in site
	Write-Verbose "$(Get-Date): `t`tProcessing Servers in Site $($PVSSite.siteName)"
	$Servers = Get-PVSServer -SiteName $PVSSite.SiteName -EA 0 4>$Null
	
	If($? -and $Servers -ne $Null)
	{
		OutputServers $Servers
	}
	ElseIf($? -and $Servers -eq $Null)
	{
		$txt = "There are no Servers"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Servers"
		OutputWarning $txt
	}

	#the properties for the servers have been processed. 
	#now to process the stuff available via a right-click on each server

	#Configure Bootstrap is first
	Write-Verbose "$(Get-Date): `t`t`tProcessing Bootstrap files"
	If($MSWord -or $PDF)
	{
		WriteWordLine 2 0 "Configure Bootstrap settings"
	}
	ElseIf($Text)
	{
		Line 0 ""
		Line 0 "Configure Bootstrap settings"
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 "Configure Bootstrap settings"
	}

	ForEach($Server in $Servers)
	{
		Write-Verbose "$(Get-Date): `t`t`tTesting to see if $($server.ServerName) is online and reachable"
		If(Test-Connection -ComputerName $server.servername -quiet -EA 0)
		{
			Write-Verbose "$(Get-Date): `t`t`t`tProcessing Bootstrap files for Server $($server.servername)"
			#first get all bootstrap files for the server
			If($MSWord -or $PDF)
			{
				WriteWordLine 3 0 $Server.serverName
			}
			ElseIf($Text)
			{
				Line 0 $Server.serverName
			}
			ElseIf($HTML)
			{
				WriteHTMLLine 3 0 $Server.serverName
			}
			$BootstrapNames = Get-PvsServerBootstrapName -ServerName $server.serverName -EA 0 4>$Null

			#Now that the list of bootstrap names has been gathered
			#We have the mandatory parameter to get the bootstrap info
			#there should be at least one bootstrap filename
			If($? -and $BootstrapNames -ne $Null)
			{
				$serverbootstraps = @()
				ForEach($Bootstrapname in $Bootstrapnames)
				{
					#get serverbootstrap info
					$serverbootstrap = Get-PvsServerBootstrap -Name $Bootstrapname.name -ServerName $server.serverName 4>$Null
					If($? -and $serverbootstrap -ne $Null)
					{
						If($ServerBootstrap.bootserver1_Ip -eq "0.0.0.0" -and `
						$ServerBootstrap.bootserver2_Ip -eq "0.0.0.0" -and `
						$ServerBootstrap.bootserver3_Ip -eq "0.0.0.0" -and `
						$ServerBootstrap.bootserver4_Ip -eq "0.0.0.0")
						{
							#do nothing
						}
						Else
						{
							$serverbootstraps +=  $serverbootstrap
						}
					}
					ElseIf($? -and $serverbootstrap -eq $Null)
					{
						$txt = "There are no Server bootstrap fields"
						OutputWarning $txt
					}
					Else
					{
						$txt = "Unable to retrieve Server bootstrap fields"
						OutputWarning $txt
					}
				}
				If($ServerBootstraps.Count -gt 0)
				{
					ForEach($ServerBootstrap in $ServerBootstraps)
					{
					    Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Bootstrap file $($ServerBootstrap.name)"
					    Write-Verbose "$(Get-Date): `t`t`t`t`t`tProcessing General Tab"
					    If($MSWord -or $PDF)
					    {
						    WriteWordLine 0 0 "General"	
					    }
					    ElseIf($Text)
					    {
						    Line 1 "General"	
					    }
					    ElseIf($HTML)
					    {
					    }
						If($MSWord -or $PDF)
						{
							WriteWordLine 0 0 "Bootstrap file: " $ServerBootstrap.name
							## Create an array of hashtables to store our services
							[System.Collections.Hashtable[]] $ItemsWordTable = @();
							## Seed the row index from the second row
							[int] $CurrentServiceIndex = 2;
							If($ServerBootstrap.bootserver1_Ip -ne "0.0.0.0")
							{
								$NetMask = ""
								$Gateway = ""
								If($ServerBootstrap.bootserver1_Netmask -ne "0.0.0.0")
								{
									$Netmask = $ServerBootstrap.bootserver1_Netmask
								}
								Else
								{
									$Netmask = "Use settings from DHCP"
								}
								If($ServerBootstrap.bootserver1_Gateway -ne "0.0.0.0")
								{
									$Gateway = $ServerBootstrap.bootserver1_Gateway
								}
								Else
								{
									$Gateway = "Use settings from DHCP"
								}
								$WordTableRowHash = @{ 
								IPAddress = $ServerBootstrap.bootserver1_Ip; 
								Port = $ServerBootstrap.bootserver1_Port; 
								SubnetMask = $Netmask; 
								Gateway = $Gateway;}

								## Add the hash to the array
								$ItemsWordTable += $WordTableRowHash;

								$CurrentServiceIndex++;
							}
							If($ServerBootstrap.bootserver2_Ip -ne "0.0.0.0")
							{
								$NetMask = ""
								$Gateway = ""
								If($ServerBootstrap.bootserver2_Netmask -ne "0.0.0.0")
								{
									$Netmask = $ServerBootstrap.bootserver2_Netmask
								}
								Else
								{
									$Netmask = "Use settings from DHCP"
								}
								If($ServerBootstrap.bootserver2_Gateway -ne "0.0.0.0")
								{
									$Gateway = $ServerBootstrap.bootserver2_Gateway
								}
								Else
								{
									$Gateway = "Use settings from DHCP"
								}
								$WordTableRowHash = @{ 
								IPAddress = $ServerBootstrap.bootserver2_Ip; 
								Port = $ServerBootstrap.bootserver2_Port; 
								SubnetMask = $Netmask; 
								Gateway = $Gateway;}

								## Add the hash to the array
								$ItemsWordTable += $WordTableRowHash;

								$CurrentServiceIndex++;
							}
							If($ServerBootstrap.bootserver3_Ip -ne "0.0.0.0")
							{
								$NetMask = ""
								$Gateway = ""
								If($ServerBootstrap.bootserver3_Netmask -ne "0.0.0.0")
								{
									$Netmask = $ServerBootstrap.bootserver3_Netmask
								}
								Else
								{
									$Netmask = "Use settings from DHCP"
								}
								If($ServerBootstrap.bootserver3_Gateway -ne "0.0.0.0")
								{
									$Gateway = $ServerBootstrap.bootserver3_Gateway
								}
								Else
								{
									$Gateway = "Use settings from DHCP"
								}
								$WordTableRowHash = @{ 
								IPAddress = $ServerBootstrap.bootserver3_Ip; 
								Port = $ServerBootstrap.bootserver3_Port; 
								SubnetMask = $Netmask; 
								Gateway = $Gateway;}

								## Add the hash to the array
								$ItemsWordTable += $WordTableRowHash;

								$CurrentServiceIndex++;
							}
							If($ServerBootstrap.bootserver4_Ip -ne "0.0.0.0")
							{
								$NetMask = ""
								$Gateway = ""
								If($ServerBootstrap.bootserver4_Netmask -ne "0.0.0.0")
								{
									$Netmask = $ServerBootstrap.bootserver4_Netmask
								}
								Else
								{
									$Netmask = "Use settings from DHCP"
								}
								If($ServerBootstrap.bootserver4_Gateway -ne "0.0.0.0")
								{
									$Gateway = $ServerBootstrap.bootserver4_Gateway
								}
								Else
								{
									$Gateway = "Use settings from DHCP"
								}
								$WordTableRowHash = @{ 
								IPAddress = $ServerBootstrap.bootserver4_Ip; 
								Port = $ServerBootstrap.bootserver4_Port; 
								SubnetMask = $Netmask; 
								Gateway = $Gateway;}

								## Add the hash to the array
								$ItemsWordTable += $WordTableRowHash;

								$CurrentServiceIndex++;
							}
							## Add the table to the document, using the hashtable (-Alt is short for -AlternateBackgroundColor!)
							$Table = AddWordTable -Hashtable $ItemsWordTable `
							-Columns IPAddress, Port, SubnetMask, Gateway `
							-Headers "IP Address", "Port", "Subnet Mask", "Gateway" `
							-AutoFit $wdAutoFitContent;

							## IB - Set the header row format after the SetWordTableAlternateRowColor function as it will paint the header row!
							SetWordCellFormat -Collection $Table.Rows.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

							$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

							FindWordDocumentEnd
							$TableRange = $Null
							$Table = $Null
							WriteWordLine 0 0 ""
						}
						ElseIf($Text)
						{
							Line 1 "Bootstrap file: " $ServerBootstrap.name
							If($ServerBootstrap.bootserver1_Ip -ne "0.0.0.0")
							{
								$rowdata = @()
								Line 2 "IP Address`t: " $ServerBootstrap.bootserver1_Ip
								Line 2 "Port`t`t: " $ServerBootstrap.bootserver1_Port
								If($ServerBootstrap.bootserver1_Netmask -ne "0.0.0.0")
								{
									Line 2 "Subnet Mask`t: " $ServerBootstrap.bootserver1_Netmask
								}
								Else
								{
									Line 2 "Subnet Mask`t: " "Use settings from DHCP"
								}
								If($ServerBootstrap.bootserver1_Gateway -ne "0.0.0.0")
								{
									Line 2 "Gateway`t`t: " $ServerBootstrap.bootserver1_Gateway
								}
								Else
								{
									Line 2 "Gateway`t`t: " "Use settings from DHCP"
								}
								Line 0 ""
							}
							If($ServerBootstrap.bootserver2_Ip -ne "0.0.0.0")
							{
								Line 2 "IP Address`t: " $ServerBootstrap.bootserver2_Ip
								Line 2 "Port`t`t: " $ServerBootstrap.bootserver2_Port
								If($ServerBootstrap.bootserver2_Netmask -ne "0.0.0.0")
								{
									Line 2 "Subnet Mask`t: " $ServerBootstrap.bootserver2_Netmask
								}
								Else
								{
									Line 2 "Subnet Mask`t: " "Use settings from DHCP"
								}
								If($ServerBootstrap.bootserver2_Gateway -ne "0.0.0.0")
								{
									Line 2 "Gateway`t`t: " $ServerBootstrap.bootserver2_Gateway
								}
								Else
								{
									Line 2 "Gateway`t`t: " "Use settings from DHCP"
								}
								Line 0 ""
							}
							If($ServerBootstrap.bootserver3_Ip -ne "0.0.0.0")
							{
								Line 2 "IP Address`t: " $ServerBootstrap.bootserver3_Ip
								Line 2 "Port`t`t: " $ServerBootstrap.bootserver3_Port
								If($ServerBootstrap.bootserver3_Netmask -ne "0.0.0.0")
								{
									Line 2 "Subnet Mask`t: " $ServerBootstrap.bootserver3_Netmask
								}
								Else
								{
									Line 2 "Subnet Mask`t: " "Use settings from DHCP"
								}
								If($ServerBootstrap.bootserver3_Gateway -ne "0.0.0.0")
								{
									Line 2 "Gateway`t`t: " $ServerBootstrap.bootserver3_Gateway
								}
								Else
								{
									Line 2 "Gateway`t`t: " "Use settings from DHCP"
								}
								Line 0 ""
							}
							If($ServerBootstrap.bootserver4_Ip -ne "0.0.0.0")
							{
								Line 2 "IP Address`t: " $ServerBootstrap.bootserver4_Ip
								Line 2 "Port`t`t: " $ServerBootstrap.bootserver4_Port
								If($ServerBootstrap.bootserver4_Netmask -ne "0.0.0.0")
								{
									Line 2 "Subnet Mask`t: " $ServerBootstrap.bootserver4_Netmask
								}
								Else
								{
									Line 2 "Subnet Mask`t: " "Use settings from DHCP"
								}
								If($ServerBootstrap.bootserver4_Gateway -ne "0.0.0.0")
								{
									Line 2 "Gateway`t`t: " $ServerBootstrap.bootserver4_Gateway
								}
								Else
								{
									Line 2 "Gateway`t`t: " "Use settings from DHCP"
								}
								Line 0 ""
							}
						}
						ElseIf($HTML)
						{
							WriteHTMLLine 4 0 "Bootstrap file: " $ServerBootstrap.name
							$rowdata = @()
							If($ServerBootstrap.bootserver1_Ip -ne "0.0.0.0")
							{
								$NetMask = ""
								$Gateway = ""
								If($ServerBootstrap.bootserver1_Netmask -ne "0.0.0.0")
								{
									$Netmask = $ServerBootstrap.bootserver1_Netmask
								}
								Else
								{
									$Netmask = "Use settings from DHCP"
								}
								If($ServerBootstrap.bootserver1_Gateway -ne "0.0.0.0")
								{
									$Gateway = $ServerBootstrap.bootserver1_Gateway
								}
								Else
								{
									$Gateway = "Use settings from DHCP"
								}
								$rowdata += @(,(
								$ServerBootstrap.bootserver1_Ip,$htmlwhite,
								$ServerBootstrap.bootserver1_Port,$htmlwhite,
								$ServerBootstrap.bootserver1_Netmask,$htmlwhite,
								$ServerBootstrap.bootserver1_Gateway,$htmlwhite))
							}
							If($ServerBootstrap.bootserver2_Ip -ne "0.0.0.0")
							{
								$NetMask = ""
								$Gateway = ""
								If($ServerBootstrap.bootserver2_Netmask -ne "0.0.0.0")
								{
									$Netmask = $ServerBootstrap.bootserver2_Netmask
								}
								Else
								{
									$Netmask = "Use settings from DHCP"
								}
								If($ServerBootstrap.bootserver2_Gateway -ne "0.0.0.0")
								{
									$Gateway = $ServerBootstrap.bootserver2_Gateway
								}
								Else
								{
									$Gateway = "Use settings from DHCP"
								}
								$rowdata += @(,(
								$ServerBootstrap.bootserver2_Ip,$htmlwhite,
								$ServerBootstrap.bootserver2_Port,$htmlwhite,
								$ServerBootstrap.bootserver2_Netmask,$htmlwhite,
								$ServerBootstrap.bootserver2_Gateway,$htmlwhite))
							}
							If($ServerBootstrap.bootserver3_Ip -ne "0.0.0.0")
							{
								$NetMask = ""
								$Gateway = ""
								If($ServerBootstrap.bootserver3_Netmask -ne "0.0.0.0")
								{
									$Netmask = $ServerBootstrap.bootserver3_Netmask
								}
								Else
								{
									$Netmask = "Use settings from DHCP"
								}
								If($ServerBootstrap.bootserver3_Gateway -ne "0.0.0.0")
								{
									$Gateway = $ServerBootstrap.bootserver3_Gateway
								}
								Else
								{
									$Gateway = "Use settings from DHCP"
								}
								$rowdata += @(,(
								$ServerBootstrap.bootserver3_Ip,$htmlwhite,
								$ServerBootstrap.bootserver3_Port,$htmlwhite,
								$ServerBootstrap.bootserver3_Netmask,$htmlwhite,
								$ServerBootstrap.bootserver3_Gateway,$htmlwhite))
							}
							If($ServerBootstrap.bootserver4_Ip -ne "0.0.0.0")
							{
								$NetMask = ""
								$Gateway = ""
								If($ServerBootstrap.bootserver4_Netmask -ne "0.0.0.0")
								{
									$Netmask = $ServerBootstrap.bootserver4_Netmask
								}
								Else
								{
									$Netmask = "Use settings from DHCP"
								}
								If($ServerBootstrap.bootserver4_Gateway -ne "0.0.0.0")
								{
									$Gateway = $ServerBootstrap.bootserver4_Gateway
								}
								Else
								{
									$Gateway = "Use settings from DHCP"
								}
								$rowdata += @(,(
								$ServerBootstrap.bootserver4_Ip,$htmlwhite,
								$ServerBootstrap.bootserver4_Port,$htmlwhite,
								$ServerBootstrap.bootserver4_Netmask,$htmlwhite,
								$ServerBootstrap.bootserver4_Gateway,$htmlwhite))
							}
							$columnHeaders = @(
							'IP Address',($htmlsilver -bor $htmlbold),
							'Port',($htmlsilver -bor $htmlbold),
							'Subnet Mask',($htmlsilver -bor $htmlbold),
							'Gateway',($htmlsilver -bor $htmlbold))
							
							$msg = "General"
							FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
							WriteHTMLLine 0 0 ""
						}
						Write-Verbose "$(Get-Date): `t`t`t`t`t`tProcessing Options Tab"
						
						If($ServerBootstrap.verboseMode)
						{
							$verboseMode = "Yes"
						}
						Else
						{
							$verboseMode = "No"
						}
						If($ServerBootstrap.interruptSafeMode)
						{
							$interruptSafeMode = "Yes"
						}
						Else
						{
							$interruptSafeMode = "No"
						}
						If($ServerBootstrap.paeMode)
						{
							$paeMode = "Yes"
						}
						Else
						{
							$paeMode = "No"
						}
						If($ServerBootstrap.bootFromHdOnFail)
						{
							$bootFromHdOnFail = "Reboot to Hard Drive after $($ServerBootstrap.recoveryTime) seconds"
						}
						Else
						{
							$bootFromHdOnFail = "Restore network connection"
						}
						If($MSWord -or $PDF)
						{
							WriteWordLine 0 0 "Options"
							[System.Collections.Hashtable[]] $ScriptInformation = @()
							$ScriptInformation += @{ Data = "Verbose mode"; Value = $verboseMode; }
							$ScriptInformation += @{ Data = "Interrupt safe mode"; Value = $interruptSafeMode; }
							$ScriptInformation += @{ Data = "Advanced Memory Support"; Value = $paeMode; }
							$ScriptInformation += @{ Data = "Network recovery method"; Value = $bootFromHdOnFail; }
							$ScriptInformation += @{ Data = "Timeouts"; Value = ""; }
							$ScriptInformation += @{ Data = "     Login polling timeout"; Value = "$($ServerBootstrap.pollingTimeout) (milliseconds)"; }
							$ScriptInformation += @{ Data = "     Login general timeout"; Value = "$($ServerBootstrap.generalTimeout) (milliseconds)"; }
							$Table = AddWordTable -Hashtable $ScriptInformation `
							-Columns Data,Value `
							-List `
							-Format $wdTableGrid `
							-AutoFit $wdAutoFitContent;

							## IB - Set the header row format
							SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

							$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

							FindWordDocumentEnd
							$Table = $Null
							WriteWordLine 0 0 ""
						}
						ElseIf($Text)
						{
							Line 1 "Options"
							Line 2 "Verbose mode`t`t`t: " $verboseMode
							Line 2 "Interrupt safe mode`t`t: " $interruptSafeMode
							Line 2 "Advanced Memory Support`t`t: " $paeMode
							Line 2 "Network recovery method`t`t: " $bootFromHdOnFail
							Line 2 "Timeouts"
							Line 3 "Login polling timeout`t: " "$($ServerBootstrap.pollingTimeout) (milliseconds)"
							Line 3 "Login general timeout`t: " "$($ServerBootstrap.generalTimeout) (milliseconds)"
							Line 0 ""
						}
						ElseIf($HTML)
						{
							$rowdata = @()
							$columnHeaders = @("Verbose mode",($htmlsilver -bor $htmlbold),$verboseMode,$htmlwhite)
							$rowdata += @(,('Interrupt safe mode',($htmlsilver -bor $htmlbold),$interruptSafeMode,$htmlwhite))
							$rowdata += @(,('Advanced Memory Support',($htmlsilver -bor $htmlbold),$paeMode,$htmlwhite))
							$rowdata += @(,('Network recovery method',($htmlsilver -bor $htmlbold),$bootFromHdOnFail,$htmlwhite))
							$rowdata += @(,('Timeouts',($htmlsilver -bor $htmlbold),"",$htmlwhite))
							$rowdata += @(,('     Login polling timeout',($htmlsilver -bor $htmlbold),"$($ServerBootstrap.pollingTimeout) (milliseconds)",$htmlwhite))
							$rowdata += @(,('     Login general timeout',($htmlsilver -bor $htmlbold),"$($ServerBootstrap.generalTimeout) (milliseconds)",$htmlwhite))
							
							$msg = "Options"
							FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
						}
					}
				}
			}
			ElseIf($? -and $BootstrapNames -eq $Null)
			{
				$txt = "There are no Bootstrap Names"
				OutputWarning $txt
			}
			Else
			{
				$txt = "Unable to retrieve Bootstrao Names"
				OutputWarning $txt
			}
		}
		Else
		{
			Write-Verbose "$(Get-Date): `t`t`t`tServer $($server.servername) is offline"
		}
	}		

	#process all vDisks in site
	Write-Verbose "$(Get-Date): `t`tProcessing all vDisks in site"
	$Disks = Get-PVSDiskInfo -SiteName $PVSSite.SiteName -EA 0 4>$Null

	WriteWordLine 2 0 "vDisk Pool"
	If($? -and $Disks -ne $Null)
	{
		ForEach($Disk in $Disks)
		{
			Write-Verbose "$(Get-Date): `t`t`tProcessing vDisk $($Disk.diskLocatorName)"
			Write-Verbose "$(Get-Date): `t`t`tProcessing vDisk Properties"
			Write-Verbose "$(Get-Date): `t`t`t`tProcessing General Tab"

			If($Disk.writeCacheType -eq 0)
			{
				$accessMode = "Private Image (single device, read/write access)"
			}
			Else
			{
				$accessMode = "Standard Image (multi-device, read-only access)"
				Switch ($Disk.writeCacheType)
				{
					0   {$writeCacheType = "Private Image"}
					1   {$writeCacheType = "Cache on server"}
					3   {$writeCacheType = "Cache in device RAM"}
					4   {$writeCacheType = "Cache on device hard disk"}
					7   {$writeCacheType = "Cache on server persisted"}
					8   {$writeCacheType = "Cache on device hard drive persisted (NT 6.1 and later)"}
					9   {$writeCacheType = "Cache in device RAM with overflow on hard disk"}
					Default {$writeCacheType = "Cache type could not be determined: $($Disk.writeCacheType)"}
				}
			}
			If($Disk.adPasswordEnabled)
			{
				$adPasswordEnabled = "Yes"
			}
			Else
			{
				$adPasswordEnabled = "No"
			}
			If($Disk.printerManagementEnabled)
			{
				$printerManagementEnabled = "Yes"
			}
			Else
			{
				$printerManagementEnabled = "No"
			}
			If($Disk.Enabled)
			{
				$Enabled = "Yes"
			}
			Else
			{
				$Enabled = "No"
			}
			Switch ($Disk.licenseMode)
			{
				0 {$licenseMode = "None"                          }
				1 {$licenseMode = "Multiple Activation Key (MAK)" }
				2 {$licenseMode = "Key Management Service (KMS)"  }
				Default {$licenseMode = "Volume License Mode could not be determined: $($Disk.licenseMode)"}
			}
			If($Disk.autoUpdateEnabled)
			{
				$autoUpdateEnabled = "Yes"
			}
			Else
			{
				$autoUpdateEnabled = "No"
			}
			$DiskSize = ((($Disk.diskSize/1024)/1024)/1024)
			If($MSWord -or $PDF)
			{
				WriteWordLine 3 0 $Disk.diskLocatorName
				WriteWordLine 4 0 "vDisk Properties"
				WriteWordLine 0 0 "General"
				[System.Collections.Hashtable[]] $ScriptInformation = @()
				$ScriptInformation += @{ Data = "Site"; Value = $Disk.siteName; }
				$ScriptInformation += @{ Data = "Store"; Value = $Disk.storeName; }
				$ScriptInformation += @{ Data = "Filename"; Value = $Disk.diskLocatorName; }
				$ScriptInformation += @{ Data = "Size"; Value = "$($diskSize) MB"; }
				$ScriptInformation += @{ Data = "VHD block size"; Value = "$($Disk.vhdBlockSize) KB"; }
				$ScriptInformation += @{ Data = "Access mode"; Value = $accessMode; }
				If($Disk.writeCacheType -ne 0)
				{
					$ScriptInformation += @{ Data = "Cache type"; Value = $writeCacheType; }
				}
				If($Disk.writeCacheType -ne 0 -and $Disk.writeCacheType -eq 3)
				{
					$ScriptInformation += @{ Data = "Cache size"; Value = "$($Disk.writeCacheSize) MB"; }
				}
				If($Disk.writeCacheType -ne 0 -and $Disk.writeCacheType -eq 9)
				{
					$ScriptInformation += @{ Data = "Maximum RAM size"; Value = "$($Disk.writeCacheSize) MBs"; }
				}
				If(![String]::IsNullOrEmpty($Disk.menuText))
				{
					$ScriptInformation += @{ Data = "BIOS boot menu text"; Value = $Disk.menuText; }
				}
				$ScriptInformation += @{ Data = "Enable AD machine account password management"; Value = $adPasswordEnabled; }
				$ScriptInformation += @{ Data = "Enable printer management"; Value = $printerManagementEnabled; }
				$ScriptInformation += @{ Data = "Enable streaming of this vDisk"; Value = $Enabled; }
				$Table = AddWordTable -Hashtable $ScriptInformation `
				-Columns Data,Value `
				-List `
				-Format $wdTableGrid `
				-AutoFit $wdAutoFitContent;

				## IB - Set the header row format
				SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

				$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

				FindWordDocumentEnd
				$Table = $Null
				WriteWordLine 0 0 ""
			}
			ElseIf($Text)
			{
				WriteWordLine 3 0 $Disk.diskLocatorName
				Line 1 "vDisk Properties"
				Line 2 "General"
				Line 3 "Site`t`t: " $Disk.siteName
				Line 3 "Store`t`t: " $Disk.storeName
				Line 3 "Filename`t: " $Disk.diskLocatorName
				Line 3 "Size`t`t: " "$($diskSize) MB"
				Line 3 "VHD block size`t: " "$($Disk.vhdBlockSize) KB"
				Line 3 "Access mode`t: " $accessMode
				If($Disk.writeCacheType -ne 0)
				{
					Line 3 "Cache type`t: " $writeCacheType
				}
				If($Disk.writeCacheType -ne 0 -and $Disk.writeCacheType -eq 3)
				{
					Line 3 "Cache size`t: " "$($Disk.writeCacheSize) MB"
				}
				If($Disk.writeCacheType -ne 0 -and $Disk.writeCacheType -eq 9)
				{
					Line 3 "Maximum RAM size: " "$($Disk.writeCacheSize) MBs"
				}
				If(![String]::IsNullOrEmpty($Disk.menuText))
				{
					Line 3 "BIOS boot menu text`t`t`t: " $Disk.menuText
				}
				Line 3 "Enable AD machine acct pwd mgmt`t: " $adPasswordEnabled
				Line 3 "Enable printer management`t: " $printerManagementEnabled
				Line 3 "Enable streaming of this vDisk`t: " $Enabled
				Line 0 ""
			}
			ElseIf($HTML)
			{
				WriteHTMLLine 3 0 $Disk.diskLocatorName
				WriteHTMLLine 4 0 "vDisk Properties"
				$rowdata = @()
				$columnHeaders = @("Site",($htmlsilver -bor $htmlbold),$Disk.siteName,$htmlwhite)
				$rowdata += @(,('Store',($htmlsilver -bor $htmlbold),$Disk.storeName,$htmlwhite))
				$rowdata += @(,('Filename',($htmlsilver -bor $htmlbold),$Disk.diskLocatorName,$htmlwhite))
				$rowdata += @(,('Size',($htmlsilver -bor $htmlbold),"$($diskSize) MB",$htmlwhite))
				$rowdata += @(,('VHD block size',($htmlsilver -bor $htmlbold),"$($Disk.vhdBlockSize) KB",$htmlwhite))
				$rowdata += @(,('Access mode',($htmlsilver -bor $htmlbold),$accessMode,$htmlwhite))
				If($Disk.writeCacheType -ne 0)
				{
					$rowdata += @(,('Cache type',($htmlsilver -bor $htmlbold),$writeCacheType,$htmlwhite))
				}
				If($Disk.writeCacheType -ne 0 -and $Disk.writeCacheType -eq 3)
				{
					$rowdata += @(,('Cache size',($htmlsilver -bor $htmlbold),"$($Disk.writeCacheSize) MB",$htmlwhite))
				}
				If($Disk.writeCacheType -ne 0 -and $Disk.writeCacheType -eq 9)
				{
					$rowdata += @(,('Maximum RAM size',($htmlsilver -bor $htmlbold),"$($Disk.writeCacheSize) MBs",$htmlwhite))
				}
				If(![String]::IsNullOrEmpty($Disk.menuText))
				{
					$rowdata += @(,('BIOS boot menu text',($htmlsilver -bor $htmlbold),$Disk.menuText,$htmlwhite))
				}
				$rowdata += @(,('Enable AD machine account password management',($htmlsilver -bor $htmlbold),$adPasswordEnabled,$htmlwhite))
				$rowdata += @(,('Enable printer management',($htmlsilver -bor $htmlbold),$printerManagementEnabled,$htmlwhite))
				$rowdata += @(,('Enable streaming of this vDisk',($htmlsilver -bor $htmlbold),$Enabled,$htmlwhite))
				
				$msg = "General"
				FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
				WriteHTMLLine 0 0 ""
			}
			
			Write-Verbose "$(Get-Date): `t`t`t`tProcessing Identification Tab"
			If($MSWord -or $PDF)
			{
				WriteWordLine 0 0 "Identification"
				[System.Collections.Hashtable[]] $ScriptInformation = @()
				If(![String]::IsNullOrEmpty($Disk.description))
				{
					$ScriptInformation += @{ Data = "Description"; Value = $Disk.description; }
				}
				If(![String]::IsNullOrEmpty($Disk.date))
				{
					$ScriptInformation += @{ Data = "Date"; Value = $Disk.date; }
				}
				If(![String]::IsNullOrEmpty($Disk.author))
				{
					$ScriptInformation += @{ Data = "Author"; Value = $Disk.author; }
				}
				If(![String]::IsNullOrEmpty($Disk.title))
				{
					$ScriptInformation += @{ Data = "Title"; Value = $Disk.title; }
				}
				If(![String]::IsNullOrEmpty($Disk.company))
				{
					$ScriptInformation += @{ Data = "Company"; Value = $Disk.company; }
				}
				If(![String]::IsNullOrEmpty($Disk.internalName))
				{
					$ScriptInformation += @{ Data = "Internal name"; Value = $Disk.internalName; }
				}
				If(![String]::IsNullOrEmpty($Disk.originalFile))
				{
					$ScriptInformation += @{ Data = "Original file"; Value = $Disk.originalFile; }
				}
				If(![String]::IsNullOrEmpty($Disk.hardwareTarget))
				{
					$ScriptInformation += @{ Data = "Hardware target"; Value = $Disk.hardwareTarget; }
				}
				$Table = AddWordTable -Hashtable $ScriptInformation `
				-Columns Data,Value `
				-List `
				-Format $wdTableGrid `
				-AutoFit $wdAutoFitContent;

				## IB - Set the header row format
				SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

				$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

				FindWordDocumentEnd
				$Table = $Null
				WriteWordLine 0 0 ""
			}
			ElseIf($Text)
			{
				Line 2 "Identification"
				If(![String]::IsNullOrEmpty($Disk.description))
				{
					Line 3 "Description`t: " $Disk.description
				}
				If(![String]::IsNullOrEmpty($Disk.date))
				{
					Line 3 "Date`t`t: " $Disk.date
				}
				If(![String]::IsNullOrEmpty($Disk.author))
				{
					Line 3 "Author`t`t: " $Disk.author
				}
				If(![String]::IsNullOrEmpty($Disk.title))
				{
					Line 3 "Title`t`t: " $Disk.title
				}
				If(![String]::IsNullOrEmpty($Disk.company))
				{
					Line 3 "Company`t: " $Disk.company
				}
				If(![String]::IsNullOrEmpty($Disk.internalName))
				{
					If($Disk.internalName.Length -le 45)
					{
						Line 3 "Internal name`t: " $Disk.internalName
					}
					Else
					{
						Line 3 "Internal name`t:`n`t`t`t" $Disk.internalName
					}
				}
				If(![String]::IsNullOrEmpty($Disk.originalFile))
				{
					If($Disk.originalFile.Length -le 45)
					{
						Line 3 "Original file`t: " $Disk.originalFile
					}
					Else
					{
						Line 3 "Original file`t:`n`t`t`t" $Disk.originalFile
					}
				}
				If(![String]::IsNullOrEmpty($Disk.hardwareTarget))
				{
					Line 3 "Hardware target: " $Disk.hardwareTarget
				}
				Line 0 ""
			}
			ElseIf($HTML)
			{
				$rowdata = @()
				$columnHeaders = @()
				If(![String]::IsNullOrEmpty($Disk.description))
				{
					If($columnHeaders.Count -eq 0)
					{
						$columnHeaders = @("Description",($htmlsilver -bor $htmlbold),$Disk.description,$htmlwhite)
					}
					Else
					{
						$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$Disk.description,$htmlwhite))
					}
				}
				If(![String]::IsNullOrEmpty($Disk.date))
				{
					If($columnHeaders.Count -eq 0)
					{
						$columnHeaders = @("Date",($htmlsilver -bor $htmlbold),$Disk.date,$htmlwhite)
					}
					Else
					{
						$rowdata += @(,('Date',($htmlsilver -bor $htmlbold),$Disk.date,$htmlwhite))
					}
				}
				If(![String]::IsNullOrEmpty($Disk.author))
				{
					If($columnHeaders.Count -eq 0)
					{
						$columnHeaders = @("Author",($htmlsilver -bor $htmlbold),$Disk.author,$htmlwhite)
					}
					Else
					{
						$rowdata += @(,('Author',($htmlsilver -bor $htmlbold),$Disk.author,$htmlwhite))
					}
				}
				If(![String]::IsNullOrEmpty($Disk.title))
				{
					If($columnHeaders.Count -eq 0)
					{
						$columnHeaders = @("Title",($htmlsilver -bor $htmlbold),$Disk.title,$htmlwhite)
					}
					Else
					{
						$rowdata += @(,('Title',($htmlsilver -bor $htmlbold),$Disk.title,$htmlwhite))
					}
				}
				If(![String]::IsNullOrEmpty($Disk.company))
				{
					If($columnHeaders.Count -eq 0)
					{
						$columnHeaders = @("Company",($htmlsilver -bor $htmlbold),$Disk.company,$htmlwhite)
					}
					Else
					{
						$rowdata += @(,('Company',($htmlsilver -bor $htmlbold),$Disk.company,$htmlwhite))
					}
				}
				If(![String]::IsNullOrEmpty($Disk.internalName))
				{
					If($columnHeaders.Count -eq 0)
					{
						$columnHeaders = @("Internal name",($htmlsilver -bor $htmlbold),$Disk.internalName,$htmlwhite)
					}
					Else
					{
						$rowdata += @(,('Internal name',($htmlsilver -bor $htmlbold),$Disk.internalName,$htmlwhite))
					}
				}
				If(![String]::IsNullOrEmpty($Disk.originalFile))
				{
					If($columnHeaders.Count -eq 0)
					{
						$columnHeaders = @("Original file",($htmlsilver -bor $htmlbold),$Disk.originalFile,$htmlwhite)
					}
					Else
					{
						$rowdata += @(,('Original file',($htmlsilver -bor $htmlbold),$Disk.originalFile,$htmlwhite))
					}
				}
				If(![String]::IsNullOrEmpty($Disk.hardwareTarget))
				{
					If($columnHeaders.Count -eq 0)
					{
						$columnHeaders = @("Hardware target",($htmlsilver -bor $htmlbold),$Disk.hardwareTarget,$htmlwhite)
					}
					Else
					{
						$rowdata += @(,('Hardware target',($htmlsilver -bor $htmlbold),$Disk.hardwareTarget,$htmlwhite))
					}
				}
				
				$msg = "Identification"
				FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
				WriteHTMLLine 0 0 ""
			}

			Write-Verbose "$(Get-Date): `t`t`t`tProcessing Volume Licensing Tab"
			If($MSWord -or $PDF)
			{
				WriteWordLine 0 0 "Microsoft Volume Licensing"
				[System.Collections.Hashtable[]] $ScriptInformation = @()
				$ScriptInformation += @{ Data = "Microsoft license type"; Value = $licenseMode; }
				$Table = AddWordTable -Hashtable $ScriptInformation `
				-Columns Data,Value `
				-List `
				-Format $wdTableGrid `
				-AutoFit $wdAutoFitContent;

				## IB - Set the header row format
				SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

				$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

				FindWordDocumentEnd
				$Table = $Null
				WriteWordLine 0 0 ""
			}
			ElseIf($Text)
			{
				Line 2 "Microsoft Volume Licensing"
				Line 3 "Microsoft license type: " $licenseMode
				Line 0 ""
			}
			ElseIf($HTML)
			{
				$rowdata = @()
				$columnHeaders = @("Microsoft license type",($htmlsilver -bor $htmlbold),$licenseMode,$htmlwhite)
				
				$msg = "Microsoft Volume Licensing"
				FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
				WriteHTMLLine 0 0 ""
			}

			Write-Verbose "$(Get-Date): `t`t`t`tProcessing Auto Update Tab"
			If($MSWord -or $PDF)
			{
				WriteWordLine 0 0 "Auto Update"
				[System.Collections.Hashtable[]] $ScriptInformation = @()
				$ScriptInformation += @{ Data = "Enable automatic updates for the vDisk"; Value = $autoUpdateEnabled; }
				If($Disk.autoUpdateEnabled)
				{
					If($Disk.activationDateEnabled -eq 0)
					{
						$ScriptInformation += @{ Data = "Apply vDisk updates as soon as they are detected by the server"; Value = ""; }
					}
					Else
					{
						$ScriptInformation += @{ Data = "Schedule the next vDisk update to occur on"; Value = $Disk.activeDate; }
					}
				}
				If(![String]::IsNullOrEmpty($Disk.class))
				{
					$ScriptInformation += @{ Data = "Class"; Value = $Disk.class; }
				}
				If(![String]::IsNullOrEmpty($Disk.imageType))
				{
					$ScriptInformation += @{ Data = "Type"; Value = $Disk.imageType; }
				}
				$ScriptInformation += @{ Data = "Major"; Value = $Disk.majorRelease; }
				$ScriptInformation += @{ Data = "Minor"; Value = $Disk.minorRelease; }
				$ScriptInformation += @{ Data = "Build"; Value = $Disk.build; }
				$ScriptInformation += @{ Data = "Serial"; Value = $Disk.serialNumber; }
				$Table = AddWordTable -Hashtable $ScriptInformation `
				-Columns Data,Value `
				-List `
				-Format $wdTableGrid `
				-AutoFit $wdAutoFitContent;

				## IB - Set the header row format
				SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

				$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

				FindWordDocumentEnd
				$Table = $Null
				WriteWordLine 0 0 ""
			}
			ElseIf($Text)
			{
				Line 2 "Auto Update"
				Line 3 "Enable automatic updates for the vDisk: " $autoUpdateEnabled
				If($Disk.autoUpdateEnabled)
				{
					If($Disk.activationDateEnabled -eq 0)
					{
						Line 3 "Apply vDisk updates as soon as they are detected by the server"
					}
					Else
					{
						Line 3 "Schedule the next vDisk update to occur on`t: $($Disk.activeDate)"
					}
				}
				If(![String]::IsNullOrEmpty($Disk.class))
				{
					Line 3 "Class`t: " $Disk.class
				}
				If(![String]::IsNullOrEmpty($Disk.imageType))
				{
					Line 3 "Type`t: " $Disk.imageType
				}
				Line 3 "Major #`t: " $Disk.majorRelease
				Line 3 "Minor #`t: " $Disk.minorRelease
				Line 3 "Build #`t: " $Disk.build
				Line 3 "Serial #: " $Disk.serialNumber
				Line 0 ""
			}
			ElseIf($HTML)
			{
				$rowdata = @()
				$columnHeaders = @("Enable automatic updates for the vDisk",($htmlsilver -bor $htmlbold),$autoUpdateEnabled,$htmlwhite)
				If($Disk.autoUpdateEnabled)
				{
					If($Disk.activationDateEnabled)
					{
						$rowdata += @(,('',($htmlsilver -bor $htmlbold),"Apply vDisk updates as soon as they are detected by the server",$htmlwhite))
					}
					Else
					{
						$rowdata += @(,('',($htmlsilver -bor $htmlbold),"Schedule the next vDisk update to occur on: $($Disk.activeDate)",$htmlwhite))
					}
				}
				If(![String]::IsNullOrEmpty($Disk.class))
				{
					$rowdata += @(,('Class',($htmlsilver -bor $htmlbold),$Disk.class,$htmlwhite))
				}
				If(![String]::IsNullOrEmpty($Disk.imageType))
				{
					$rowdata += @(,('Type',($htmlsilver -bor $htmlbold),$Disk.imageType,$htmlwhite))
				}
				$rowdata += @(,('Major #',($htmlsilver -bor $htmlbold),$Disk.majorRelease,$htmlwhite))
				$rowdata += @(,('Minor #',($htmlsilver -bor $htmlbold),$Disk.minorRelease,$htmlwhite))
				$rowdata += @(,('Build #',($htmlsilver -bor $htmlbold),$Disk.build,$htmlwhite))
				$rowdata += @(,('Serial #',($htmlsilver -bor $htmlbold),$Disk.serialNumber,$htmlwhite))
				
				$msg = "Auto Update"
				FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
				WriteHTMLLine 0 0 ""
			}
			
			#process Versions menu
			#get versions info
			#thanks to the PVS Product team for their help in understanding the Versions information
			Write-Verbose "$(Get-Date): `t`t`tProcessing vDisk Versions"
			$DiskVersions = Get-PvsDiskVersion -diskLocatorName $Disk.diskLocatorName -storeName $disk.storeName -siteName $disk.siteName -EA 0 4>$Null
			If($? -and $DiskVersions -ne $Null)
			{
				If($MSWord -or $PDF)
				{
					WriteWordLine 0 0 "vDisk Versions"
				}
				ElseIf($Text)
				{
					Line 1 "vDisk Versions"
					Line 0 ""
				}
				ElseIf($HTML)
				{
					WriteHTMLLine 4 0 "vDisk Versions"
					WriteHTMLLine 0 0 ""
				}
				#get the current booting version
				#by default, the $DiskVersions object is in version number order lowest to highest
				#the initial or base version is 0 and always exists
				[int]$BootingVersion = "0"
				[bool]$BootOverride = $False
				ForEach($DiskVersion in $DiskVersions)
				{
					If($DiskVersion.access -eq 3)
					{
						#override i.e. manually selected boot version
						$BootingVersion = $DiskVersion.version.ToString()
						$BootOverride = $True
						Break
					}
					ElseIf($DiskVersion.access -eq 0 -and $DiskVersion.IsPending -eq $False )
					{
						$BootingVersion = $DiskVersion.version.ToString()
						$BootOverride = $False
					}
				}
				
				$tmp = ""
				If($BootOverride)
				{
					$tmp = $BootingVersion
				}
				Else
				{
					$tmp = "Newest released"
				}

				If($MSWord -or $PDF)
				{
					[System.Collections.Hashtable[]] $ScriptInformation = @()
					$ScriptInformation += @{ Data = "Boot production devices from version"; Value = $tmp; }
				}
				ElseIf($Text)
				{
					Line 2 "Boot production devices from version`t: " $tmp
				}
				ElseIf($HTML)
				{
					$rowdata = @()
				}
				
				ForEach($DiskVersion in $DiskVersions)
				{
					Write-Verbose "$(Get-Date): `t`t`t`tProcessing vDisk Version $($DiskVersion.version)"
					If($DiskVersion.version -eq $BootingVersion)
					{
						$BootFromVersion = "$($DiskVersion.version) (Current booting version)"
					}
					Else
					{
						$BootFromVersion = $DiskVersion.version
					}

					Switch ($DiskVersion.access)
					{
						"0" {$access = "Production"}
						"1" {$access = "Maintenance"}
						"2" {$access = "Maintenance Highest Version"}
						"3" {$access = "Override"}
						"4" {$access = "Merge"}
						"5" {$access = "Merge Maintenance"}
						"6" {$access = "Merge Test"}
						"7" {$access = "Test"}
						Default {$access = "Access could not be determined: $($DiskVersion.access)"}
					}

					Switch ($DiskVersion.type)
					{
						"0" {$DiskVersionType = "Base"}
						"1" {$DiskVersionType = "Manual"}
						"2" {$DiskVersionType = "Automatic"}
						"3" {$DiskVersionType = "Merge"}
						"4" {$DiskVersionType = "Merge Base"}
						Default {$DiskVersionType = "Type could not be determined: $($DiskVersion.type)"}
					}

					Switch ($DiskVersion.canDelete)
					{
						$False {$canDelete = "No"}
						$True {$canDelete = "Yes"}
					}

					Switch ($DiskVersion.canMerge)
					{
						$False {$canMerge = "No"}
						$True {$canMerge = "Yes"}
					}

					Switch ($DiskVersion.canMergeBase)
					{
						$False {$canMergeBase = "No"}
						$True {$canMergeBase = "Yes"}
					}

					Switch ($DiskVersion.canPromote)
					{
						$False {$canPromote = "No"}
						$True {$canPromote = "Yes"}
					}

					Switch ($DiskVersion.canRevertTest)
					{
						$False {$canRevertTest = "No"}
						$true {$canRevertTest = "Yes"}
					}

					Switch ($DiskVersion.canRevertMaintenance)
					{
						$False {$canRevertMaintenance = "No"}
						$True {$canRevertMaintenance = "Yes"}
					}

					Switch ($DiskVersion.canSetScheduledDate)
					{
						$False {$canSetScheduledDate = "No"}
						$True {$canSetScheduledDate = "Yes"}
					}

					Switch ($DiskVersion.canOverride)
					{
						$False {$canOverride = "No"}
						$True {$canOverride = "Yes"}
					}

					Switch ($DiskVersion.isPending)
					{
						$False {$isPending = "No, version Scheduled Date has occurred"}
						$True {$isPending = "Yes, version Scheduled Date has not occurred"}
					}

					Switch ($DiskVersion.goodInventoryStatus)
					{
						$False {$goodInventoryStatus = "Not available on all servers"}
						$True {$goodInventoryStatus = "Available on all servers"}
						Default {$goodInventoryStatus = "Replication status could not be determined: $($DiskVersion.goodInventoryStatus)"}
					}

					If($MSWord -or $PDF)
					{
						$ScriptInformation += @{ Data = "Version"; Value = $BootFromVersion; }
						$ScriptInformation += @{ Data = "Created"; Value = $DiskVersion.createDate; }
						If(![String]::IsNullOrEmpty($DiskVersion.scheduledDate))
						{
							$ScriptInformation += @{ Data = "Released"; Value = $DiskVersion.scheduledDate; }
						}
						$ScriptInformation += @{ Data = "Devices"; Value = Devices; }
						$ScriptInformation += @{ Data = "Access"; Value = $access; }
						$ScriptInformation += @{ Data = "Type"; Value = $DiskVersionType; }
						If(![String]::IsNullOrEmpty($DiskVersion.description))
						{
							$ScriptInformation += @{ Data = "Properties"; Value = $DiskVersion.description; }
						}
						$ScriptInformation += @{ Data = "Can Delete"; Value = $canDelete; }
						$ScriptInformation += @{ Data = "Can Merge"; Value = $canMerge; }
						$ScriptInformation += @{ Data = "Can Merge Base"; Value = $canMergeBase; }
						$ScriptInformation += @{ Data = "Can Promote"; Value = $canPromote; }
						$ScriptInformation += @{ Data = "Can Revert back to Test"; Value = $canRevertTest; }
						$ScriptInformation += @{ Data = "Can Revert back to Maintenance"; Value = $canRevertMaintenance; }
						$ScriptInformation += @{ Data = "Can Set Scheduled Date"; Value = $canSetScheduledDate; }
						$ScriptInformation += @{ Data = "Can Override"; Value = $canOverride; }
						$ScriptInformation += @{ Data = "Is Pending"; Value = $isPending; }
						$ScriptInformation += @{ Data = "Replication Status"; Value = $goodInventoryStatus; }
						$ScriptInformation += @{ Data = "Disk Filename"; Value = $DiskVersion.diskFileName; }
						$Table = AddWordTable -Hashtable $ScriptInformation `
						-Columns Data,Value `
						-List `
						-Format $wdTableGrid `
						-AutoFit $wdAutoFitContent;

						## IB - Set the header row format
						SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

						$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

						FindWordDocumentEnd
						$Table = $Null
						WriteWordLine 0 0 ""
					}
					ElseIf($Text)
					{
						Line 2 "Version`t`t`t`t`t: " $BootFromVersion
						Line 2 "Created`t`t`t`t`t: " $DiskVersion.createDate
						If(![String]::IsNullOrEmpty($DiskVersion.scheduledDate))
						{
							Line 2 "Released`t`t`t`t: " $DiskVersion.scheduledDate
						}
						Line 2 "Devices`t`t`t`t`t: " $DiskVersion.deviceCount
						Line 2 "Access`t`t`t`t`t: " $access
						Line 2 "Type`t`t`t`t`t: " $DiskVersionType
						If(![String]::IsNullOrEmpty($DiskVersion.description))
						{
							Line 2 "Properties`t`t`t`t: " $DiskVersion.description
						}
						Line 2 "Can Delete`t`t`t`t: " $canDelete
						Line 2 "Can Merge`t`t`t`t: " $canMerge
						Line 2 "Can Merge Base`t`t`t`t: " $canMergeBase
						Line 2 "Can Promote`t`t`t`t: " $canPromote
						Line 2 "Can Revert back to Test`t`t`t: " $canRevertTest
						Line 2 "Can Revert back to Maintenance`t`t: " $canRevertMaintenance
						Line 2 "Can Set Scheduled Date`t`t`t: " $canSetScheduledDate
						Line 2 "Can Override`t`t`t`t: " $canOverride
						Line 2 "Is Pending`t`t`t`t: " $isPending
						Line 2 "Replication Status`t`t`t: " $goodInventoryStatus
						Line 2 "Disk Filename`t`t`t`t: " $DiskVersion.diskFileName
						Line 0 ""
					}
					ElseIf($HTML)
					{
						$columnHeaders = @("Version",($htmlsilver -bor $htmlbold),$BootFromVersion,$htmlwhite)
						$rowdata += @(,('Created',($htmlsilver -bor $htmlbold),$DiskVersion.createDate,$htmlwhite))
						If(![String]::IsNullOrEmpty($DiskVersion.scheduledDate))
						{
							$rowdata += @(,('Released',($htmlsilver -bor $htmlbold),$DiskVersion.scheduledDate,$htmlwhite))
						}
						$rowdata += @(,('Devices',($htmlsilver -bor $htmlbold),$DiskVersion.deviceCount,$htmlwhite))
						$rowdata += @(,('Access',($htmlsilver -bor $htmlbold),$access,$htmlwhite))
						$rowdata += @(,('Type',($htmlsilver -bor $htmlbold),$DiskVersionType,$htmlwhite))
						If(![String]::IsNullOrEmpty($DiskVersion.description))
						{
							$rowdata += @(,('Properties',($htmlsilver -bor $htmlbold),$DiskVersion.description,$htmlwhite))
						}
						$rowdata += @(,('Can Delete',($htmlsilver -bor $htmlbold),$canDelete,$htmlwhite))
						$rowdata += @(,('Can Merge',($htmlsilver -bor $htmlbold),$canMerge,$htmlwhite))
						$rowdata += @(,('Can Merge Base',($htmlsilver -bor $htmlbold),$canMergeBase,$htmlwhite))
						$rowdata += @(,('Can Promote',($htmlsilver -bor $htmlbold),$canPromote,$htmlwhite))
						$rowdata += @(,('Can Revert back to Test',($htmlsilver -bor $htmlbold),$canRevertTest,$htmlwhite))
						$rowdata += @(,('Can Revert back to Maintenance',($htmlsilver -bor $htmlbold),$canRevertMaintenance,$htmlwhite))
						$rowdata += @(,('Can Set Scheduled Date',($htmlsilver -bor $htmlbold),$canSetScheduledDate,$htmlwhite))
						$rowdata += @(,('Can Override',($htmlsilver -bor $htmlbold),$canOverride,$htmlwhite))
						$rowdata += @(,('Is Pending',($htmlsilver -bor $htmlbold),$isPending,$htmlwhite))
						$rowdata += @(,('Replication Status',($htmlsilver -bor $htmlbold),$goodInventoryStatus,$htmlwhite))
						$rowdata += @(,('Disk Filename',($htmlsilver -bor $htmlbold),$DiskVersion.diskFileName,$htmlwhite))
				
						$msg = "Boot production devices from version: $($tmp)"
						FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
						WriteHTMLLine 0 0 ""
					}
				}
			}
			ElseIf($? -and $DiskVersions -ne $Null)
			{
				$txt = "There is no Disk Version information"
				OutputWarning $txt
			}
			Else
			{
				$txt = "Unable to retrieve Disk version information"
				OutputWarning $txt
			}			

			#process vDisk Load Balancing Menu
			Write-Verbose "$(Get-Date): `t`t`tProcessing vDisk Load Balancing Menu"
			If($Disk.rebalanceEnabled)
			{
				$rebalanceEnabled = "Yes"
			}
			Else
			{
				$rebalanceEnabled = "No"
			}

			Switch ($Disk.subnetAffinity)
			{
				0 {$subnetAffinity = "None"}
				1 {$subnetAffinity = "Best Effort"}
				2 {$subnetAffinity = "Fixed"}
				Default {$subnetAffinity = "Subnet Affinity could not be determined: $($Disk.subnetAffinity)"}
			}

			If($MSWord -or $PDF)
			{
				WriteWordLine 3 0 "vDisk Load Balancing"
				[System.Collections.Hashtable[]] $ScriptInformation = @()
				If(![String]::IsNullOrEmpty($Disk.serverName))
				{
					$ScriptInformation += @{ Data = "Use this server to provide the vDisk"; Value = $Disk.serverName; }
				}
				Else
				{
					$ScriptInformation += @{ Data = "Subnet Affinity"; Value = $subnetAffinity; }
					$ScriptInformation += @{ Data = "Rebalance Enabled"; Value = $rebalanceEnabled; }
					If($Disk.rebalanceEnabled)
					{
						$ScriptInformation += @{ Data = "Trigger Percent"; Value = $Disk.rebalanceTriggerPercent; }
					}
				}

				$Table = AddWordTable -Hashtable $ScriptInformation `
				-Columns Data,Value `
				-List `
				-Format $wdTableGrid `
				-AutoFit $wdAutoFitContent;

				SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

				$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

				FindWordDocumentEnd
				$Table = $Null
				WriteWordLine 0 0 ""
			}
			ElseIf($Text)
			{
				Line 1 "vDisk Load Balancing"
				If(![String]::IsNullOrEmpty($Disk.serverName))
				{
					Line 2 "Use this server to provide the vDisk: " $Disk.serverName
				}
				Else
				{
					Line 2 "Subnet Affinity`t`t: " $subnetAffinity
					Line 2 "Rebalance Enabled`t: " $rebalanceEnabled
					If($Disk.rebalanceEnabled)
					{
						Line 2 "Trigger Percent`t`t: $($Disk.rebalanceTriggerPercent)"
					}
				}
				Line 0 ""
			}
			ElseIf($HTML)
			{
				$rowdata = @()
				If(![String]::IsNullOrEmpty($Disk.serverName))
				{
					$columnHeaders = @("Use this server to provide the vDisk",($htmlsilver -bor $htmlbold),$Disk.serverName,$htmlwhite)
				}
				Else
				{
					$columnHeaders = @("Subnet Affinity",($htmlsilver -bor $htmlbold),$subnetAffinity,$htmlwhite)
					$rowdata += @(,('Rebalance Enabled',($htmlsilver -bor $htmlbold),$rebalanceEnabled,$htmlwhite))
					If($Disk.rebalanceEnabled)
					{
						$rowdata += @(,('Trigger Percent',($htmlsilver -bor $htmlbold),"$($Disk.rebalanceTriggerPercent)",$htmlwhite))
					}
				}
				
				$msg = "vDisk Load Balancing"
				FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
				WriteHTMLLine 0 0 ""
			}
		}
	}
	ElseIf($? -and $Disks -eq $Null)
	{
		$txt = "There are no vDisks"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve vDisks"
		OutputWarning $txt
	}

	Write-Verbose "$(Get-Date): `t`tProcessing vDisk Update Management"
	If($MSWord -or $PDF)
	{
		WriteWordLine 2 0 "vDisk Update Management"
	}
	ElseIf($Text)
	{
		Line 0 "vDisk Update Management"
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 "vDisk Update Management"
	}
	
	$Tasks = Get-PvsUpdateTask -siteName $PVSSite.SiteName -EA 0 4>$Null
	
	If($? -and $Tasks -ne $Null)
	{
		WriteWordLine 0 1 "vDisks"
		#process all the Update Managed vDisks for this site
		Write-Verbose "$(Get-Date): `t`t`tProcessing all Update Managed vDisks for this site"
		$ManagedvDisks = Get-PvsdiskUpdateDevice -siteName $PVSSite.SiteName -EA 0 4>$Null
		If($? -and $ManagedvDisks -ne $Null)
		{
			If($MSWord -or $PDF)
			{
				WriteWordLine 3 0 "vDisks"
			}
			ElseIf($Text)
			{
				Line 0 "vDisks"
			}
			ElseIf($HTML)
			{
				WriteHTMLLine 3 0 "vDisks"
			}
			ForEach($ManagedvDisk in $ManagedvDisks)
			{
				Write-Verbose "$(Get-Date): `t`t`t`tProcessing Managed vDisk $($ManagedvDisk.storeName)`\$($ManagedvDisk.disklocatorName)"
				Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing General Tab"
				If($MSWord -or $PDF)
				{
					WriteWordLine 4 0 "$($ManagedvDisk.storeName)`\$($ManagedvDisk.disklocatorName)"
					WriteWordLine 0 0 "General"
					[System.Collections.Hashtable[]] $ScriptInformation = @()
					$ScriptInformation += @{ Data = "vDisk"; Value = "$($ManagedvDisk.storeName)`\$($ManagedvDisk.disklocatorName)"; }
					$ScriptInformation += @{ Data = "Virtual Host Connection"; Value = $ManagedvDisk.virtualHostingPoolName; }
					$ScriptInformation += @{ Data = "VM Name"; Value = $ManagedvDisk.deviceName; }
					$ScriptInformation += @{ Data = "VM MAC"; Value = $ManagedvDisk.deviceMac; }
					$ScriptInformation += @{ Data = "VM Port"; Value = $ManagedvDisk.port; }

					$Table = AddWordTable -Hashtable $ScriptInformation `
					-Columns Data,Value `
					-List `
					-Format $wdTableGrid `
					-AutoFit $wdAutoFitContent;

					SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

					#$Table.Columns.Item(1).Width = 250;
					#$Table.Columns.Item(2).Width = 250;

					$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

					FindWordDocumentEnd
					$Table = $Null
					WriteWordLine 0 0 ""
				}
				ElseIf($Text)
				{
					Line 0 "$($ManagedvDisk.storeName)`\$($ManagedvDisk.disklocatorName)"
					Line 2 "General"
					Line 3 "vDisk`t`t: " "$($ManagedvDisk.storeName)`\$($ManagedvDisk.disklocatorName)"
					Line 3 "Virtual Host Connection: " $ManagedvDisk.virtualHostingPoolName
					Line 3 "VM Name`t: " $ManagedvDisk.deviceName
					Line 3 "VM MAC`t: " $ManagedvDisk.deviceMac
					Line 3 "VM Port`t: " $ManagedvDisk.port
					Line 0 ""
				}
				ElseIf($HTML)
				{
					WriteHTMLLine 4 0 "$($ManagedvDisk.storeName)`\$($ManagedvDisk.disklocatorName)"
					$rowdata = @()
					$columnHeaders = @("vDisk",($htmlsilver -bor $htmlbold),"$($ManagedvDisk.storeName)`\$($ManagedvDisk.disklocatorName)",$htmlwhite)
					$rowdata += @(,('Virtual Host Connection',($htmlsilver -bor $htmlbold),$ManagedvDisk.virtualHostingPoolName,$htmlwhite))
					$rowdata += @(,('VM Name',($htmlsilver -bor $htmlbold),$ManagedvDisk.deviceName,$htmlwhite))
					$rowdata += @(,('VM MAC',($htmlsilver -bor $htmlbold),$ManagedvDisk.deviceMac,$htmlwhite))
					$rowdata += @(,('VM Port',($htmlsilver -bor $htmlbold),$ManagedvDisk.port,$htmlwhite))

					$msg = "General"
					FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
					WriteHTMLLine 0 0 ""
				}
								
				Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Personality Tab"
				#process all personality strings for this device
				$PersonalityStrings = Get-PvsDevicePersonality -deviceName $ManagedvDisk.deviceName -EA 0 4>$Null
				If($? -and $PersonalityStrings -ne $Null)
				{
					If($MSWord -or $PDF)
					{
						WriteWordLine 4 0 "Personality"
						ForEach($PersonalityString in $PersonalityStrings.DevicePersonality)
						{
							[System.Collections.Hashtable[]] $ScriptInformation = @()
							$ScriptInformation += @{ Data = "Name"; Value = $PersonalityString.Name; }
							$ScriptInformation += @{ Data = "String"; Value = $PersonalityString.Value; }

							$Table = AddWordTable -Hashtable $ScriptInformation `
							-Columns Data,Value `
							-List `
							-Format $wdTableGrid `
							-AutoFit $wdAutoFitContent;

							SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

							#$Table.Columns.Item(1).Width = 250;
							#$Table.Columns.Item(2).Width = 250;

							$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

							FindWordDocumentEnd
							$Table = $Null
							WriteWordLine 0 0 ""
						}
					}
					ElseIf($Text)
					{
						Line 0 "Personality"
						ForEach($PersonalityString in $PersonalityStrings.DevicePersonality)
						{
							Line 3 "Name: " $PersonalityString.Name
							Line 3 "String: " $PersonalityString.Value
							Line 0 ""
						}
					}
					ElseIf($HTML)
					{
						WriteHTMLLine 3 0 "Personality"
						ForEach($PersonalityString in $PersonalityStrings.DevicePersonality)
						{
							$rowdata = @()
							$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$PersonalityString.Name,$htmlwhite)
							$rowdata += @(,('String',($htmlsilver -bor $htmlbold),$PersonalityString.Value,$htmlwhite))

							$msg = ""
							FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
							WriteHTMLLine 0 0 ""
						}
					}
				}
				
				Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Status Tab"
				If($MSWord -or $PDF)
				{
					WriteWordLine 4 0 "Status"
				}
				ElseIf($Text)
				{
					Line 0 "Status"
				}
				ElseIf($HTML)
				{
					WriteHTMLLine 3 0 "Status"
				}
				$Device = Get-PvsDeviceInfo -deviceId $ManagedvDisk.deviceId -EA 0 4>$Null
				DeviceStatus $Device
			}
		}
		ElseIf($? -and $ManagedvDisks -eq $Null)
		{
			$txt = "There are no Managed vDisks"
			OutputWarning $txt
		}
		Else
		{
			$txt = "Unable to retrieve Managed vDisks"
			OutputWarning $txt
		}
		
		If($Tasks -ne $Null)
		{
			Write-Verbose "$(Get-Date): `t`t`tProcessing all Update Managed Tasks for this site"
			ForEach($Task in $Tasks)
			{
				Write-Verbose "$(Get-Date): `t`t`t`tProcessing Task $($Task.updateTaskName)"
				Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing General Tab"
				If($Task.enabled)
				{
					$xTaskEnabled = "No"
				}
				Else
				{
					$xTaskEnabled = "Yes"
				}
				
				Switch ($Task.recurrence)
				{
					0 {$xTaskRecurrence = "None"}
					1 {$xTaskRecurrence = "Daily Everyday"}
					2 {$xTaskRecurrence = "Daily Weekdays only"}
					3 {$xTaskRecurrence = "Weekly"}
					4 {$xTaskRecurrence = "Monthly Date"}
					5 {$xTaskRecurrence = "Monthly Type"}
					Default {$xTaskRecurrence = "Recurrence type could not be determined: $($Task.recurrence)"}
				}

				If($Task.recurrence -ne 0)
				{
					$AMorPM = "AM"
					$NumHour = [int]$Task.Hour
					If($NumHour -ge 0 -and $NumHour -lt 12)
					{
						$AMorPM = "AM"
					}
					Else
					{
						$AMorPM = "PM"
					}
					If($NumHour -eq 0)
					{
						$NumHour += 12
					}
					Else
					{
						$NumHour -= 12
					}
					$StrHour = [string]$NumHour
					If($StrHour.length -lt 2)
					{
						$StrHour = "0" + $StrHour
					}
					$tempMinute = ""
					If($Task.Minute.length -lt 2)
					{
						$tempMinute = "0" + $Task.Minute
					}
					$xTaskRunTime = "$($StrHour)`:$($tempMinute) $($AMorPM)"
				}

				If($Task.recurrence -eq 5)
				{
					Switch($Task.monthlyOffset)
					{
						1 {$xTaskmonthlyOffset = "First "}
						2 {$xTaskmonthlyOffset = "Second "}
						3 {$xTaskmonthlyOffset = "Third "}
						4 {$xTaskmonthlyOffset = "Fourth "}
						5 {$xTaskmonthlyOffset = "Last "}
						Default {$xTaskmonthlyOffset = "Monthly Offset could not be determined: $($Task.monthlyOffset)"}
					}
				}

				$dayMask = @{
					1 = "Sunday"
					2 = "Monday";
					4 = "Tuesday";
					8 = "Wednesday";
					16 = "Thursday";
					32 = "Friday";
					64 = "Saturday"}

				Switch($Task.esdType)
				{
					""     {$xTaskesdType = "None (runs a custom script on the client)"}
					"WSUS" {$xTaskesdType = "Microsoft Windows Update Service (WSUS)"}
					"SCCM" {$xTaskesdType = "Microsoft System Center Configuration Manager (SCCM)"}
					Default {$xTaskesdType = "ESD Client could not be determined: $($Task.esdType)"}
				}

				Switch($Task.postUpdateApprove)
				{
					0 {$xTaskpostUpdateApprove = "Production"}
					1 {$xTaskpostUpdateApprove = "Test"}
					2 {$xTaskpostUpdateApprove = "Maintenance"}
					Default {$xTaskpostUpdateApprove = "Access method for vDisk could not be determined: $($Task.postUpdateApprove)"}
				}

				If($MSWord -or $PDF)
				{
					WriteWordLine 0 1 "Tasks"
					WriteWordLine 0 2 "General"
					[System.Collections.Hashtable[]] $ScriptInformation = @()
					$ScriptInformation += @{ Data = "Name"; Value = $Task.updateTaskName; }
					$ScriptInformation += @{ Data = "Description"; Value = $Task.description; }
					$ScriptInformation += @{ Data = "Disable this task"; Value = $xTaskEnabled; }

					$Table = AddWordTable -Hashtable $ScriptInformation `
					-Columns Data,Value `
					-List `
					-Format $wdTableGrid `
					-AutoFit $wdAutoFitContent;

					SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

					#$Table.Columns.Item(1).Width = 250;
					#$Table.Columns.Item(2).Width = 250;

					$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

					FindWordDocumentEnd
					$Table = $Null
					WriteWordLine 0 0 ""
				}
				ElseIf($Text)
				{
					Line 1 "Tasks"
					Line 2 "General"
					Line 3 "Name`t`t: " $Task.updateTaskName
					Line 3 "Description`t: " $Task.description
					Line 3 "Disable this task: " $xTaskEnabled
				}
				ElseIf($HTML)
				{
					WriteHTMLLine 0 1 "Tasks"
					$rowdata = @()
					$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$Task.updateTaskName,$htmlwhite)
					$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$Task.description,$htmlwhite))
					$rowdata += @(,('Disable this task',($htmlsilver -bor $htmlbold),$xTaskEnabled,$htmlwhite))

					$msg = "General"
					FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
				}
				
				Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Schedule Tab"
				If($MSWord -or $PDF)
				{
					WriteWordLine 0 2 "Schedule"
					[System.Collections.Hashtable[]] $ScriptInformation = @()
					$ScriptInformation += @{ Data = "Recurrence"; Value = $xTaskRecurrence; }
					If($Task.recurrence -ne 0)
					{
						$ScriptInformation += @{ Data = "Run the update at"; Value = $xTaskRunTime; }
					}
					If($Task.recurrence -eq 3)
					{
						For($i = 1; $i -le 128; $i = $i * 2)
						{
							If(($Task.dayMask -band $i) -ne 0)
							{
								$ScriptInformation += @{ Data = ""; Value = $dayMask.$i; }
							}
						}
					}
					If($Task.recurrence -eq 4)
					{
						$ScriptInformation += @{ Data = "On Date"; Value = $Task.date; }
					}
					If($Task.recurrence -eq 5)
					{
						$ScriptInformation += @{ Data = "On"; Value = $xTaskmonthlyOffset; }
						For($i = 1; $i -le 128; $i = $i * 2)
						{
							If(($Task.dayMask -band $i) -ne 0)
							{
								$ScriptInformation += @{ Data = ""; Value = $dayMask.$i; }
							}
						}
					}
				}
				ElseIf($Text)
				{
					Line 2 "Schedule"
					Line 3 "Recurrence: " $xTaskRecurrence
					If($Task.recurrence -ne 0)
					{
						Line 3 "Run the update at " $xTaskRunTime
					}
					If($Task.recurrence -eq 3)
					{
						For($i = 1; $i -le 128; $i = $i * 2)
						{
							If(($Task.dayMask -band $i) -ne 0)
							{
								Line 4 $dayMask.$i
							}
						}
					}
					If($Task.recurrence -eq 4)
					{
						Line 3 "On Date " $Task.date
					}
					If($Task.recurrence -eq 5)
					{
						Line 3 "On " $xTaskmonthlyOffset
						For($i = 1; $i -le 128; $i = $i * 2)
						{
							If(($Task.dayMask -band $i) -ne 0)
							{
								Line 0 $dayMask.$i
							}
						}
					}
				}
				ElseIf($HTML)
				{
					WriteHTMLLine 0 2 "Schedule"
					$rowdata = @()
					$columnHeaders = @("Recurrence",($htmlsilver -bor $htmlbold),$xTaskRecurrence,$htmlwhite)
					If($Task.recurrence -ne 0)
					{
						$rowdata += @(,('Run the update at',($htmlsilver -bor $htmlbold),$xTaskRunTime,$htmlwhite))
					}
					If($Task.recurrence -eq 3)
					{
						For($i = 1; $i -le 128; $i = $i * 2)
						{
							If(($Task.dayMask -band $i) -ne 0)
							{
								$rowdata += @(,('',($htmlsilver -bor $htmlbold),$dayMask.$i,$htmlwhite))
							}
						}
					}
					If($Task.recurrence -eq 4)
					{
						$rowdata += @(,('On Date',($htmlsilver -bor $htmlbold),$Task.date,$htmlwhite))
					}
					If($Task.recurrence -eq 5)
					{
						$rowdata += @(,('On',($htmlsilver -bor $htmlbold),$xTaskmonthlyOffset,$htmlwhite))
						For($i = 1; $i -le 128; $i = $i * 2)
						{
							If(($Task.dayMask -band $i) -ne 0)
							{
								$rowdata += @(,('',($htmlsilver -bor $htmlbold),$dayMask.$i,$htmlwhite))
							}
						}
					}
				}
				
				Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing vDisks Tab"
				WriteWordLine 0 2 "vDisks"
				$vDisks = Get-PvsDiskUpdateDevice -deviceId $ManagedvDisk.deviceId -EA 0 4>$Null
				If($? -and $vDisks -ne $Null)
				{
					If($MSWord -or $PDF)
					{
						WriteWordLine 0 3 "vDisks to be updated by this task:"
					}
					ElseIf($Text)
					{
						Line 3 "vDisks to be updated by this task:"
					}
					ElseIf($HTML)
					{
						WriteHTMLLine 0 3 "vDisks to be updated by this task:"
					}
					ForEach($vDisk in $vDisks)
					{
						If($MSWord -or $PDF)
						{
							[System.Collections.Hashtable[]] $ScriptInformation = @()
							$ScriptInformation += @{ Data = "vDisk"; Value = "$($vDisk.storeName)`\$($vDisk.diskLocatorName)"; }
							$ScriptInformation += @{ Data = "Host"; Value = $vDisk.virtualHostingPoolName; }
							$ScriptInformation += @{ Data = "VM"; Value = $vDisk.deviceName; }
							$Table = AddWordTable -Hashtable $ScriptInformation `
							-Columns Data,Value `
							-List `
							-Format $wdTableGrid `
							-AutoFit $wdAutoFitContent;

							SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

							#$Table.Columns.Item(1).Width = 250;
							#$Table.Columns.Item(2).Width = 250;

							$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

							FindWordDocumentEnd
							$Table = $Null
							WriteWordLine 0 0 ""
						}
						ElseIf($Text)
						{
							Line 4 "vDisk`t: " "$($vDisk.storeName)`\$($vDisk.diskLocatorName)"
							Line 4 "Host`t: " $vDisk.virtualHostingPoolName
							Line 4 "VM`t: " $vDisk.deviceName
							Line 0 ""
						}
						ElseIf($HTML)
						{
							$rowdata = @()
							$columnHeaders = @("vDisk",($htmlsilver -bor $htmlbold),"$($vDisk.storeName)`\$($vDisk.diskLocatorName)",$htmlwhite)
							$rowdata += @(,('Host',($htmlsilver -bor $htmlbold),$vDisk.virtualHostingPoolName,$htmlwhite))
							$rowdata += @(,('VM',($htmlsilver -bor $htmlbold),$vDisk.deviceName,$htmlwhite))

							$msg = ""
							FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
							WriteHTMLLine 0 0 ""
						}
					}
				}
				ElseIf($? -and $vDisks -eq $Null)
				{
					$txt = "There are no Disk Update Devices"
					OutputWarning $txt
				}
				Else
				{
					$txt = "Unable to retrieve Disk Update Devices"
					OutputWarning $txt
				}
				
				Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing ESD Tab"
				If($MSWord -or $PDF)
				{
					WriteWordLine 0 2 "ESD"
					[System.Collections.Hashtable[]] $ScriptInformation = @()
					$ScriptInformation += @{ Data = "ESD client to use"; Value = $xTaskesdType; }

					$Table = AddWordTable -Hashtable $ScriptInformation `
					-Columns Data,Value `
					-List `
					-Format $wdTableGrid `
					-AutoFit $wdAutoFitContent;

					SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

					#$Table.Columns.Item(1).Width = 250;
					#$Table.Columns.Item(2).Width = 250;

					$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

					FindWordDocumentEnd
					$Table = $Null
					WriteWordLine 0 0 ""
				}
				ElseIf($Text)
				{
					Line 2 "ESD"
					Line 3 "ESD client to use: " $xTaskesdType
				}
				ElseIf($HTML)
				{
					WriteWordLine 0 2 "ESD"
					$rowdata = @()
					$columnHeaders = @("ESD client to use",($htmlsilver -bor $htmlbold),$xTaskesdType,$htmlwhite)

					$msg = ""
					FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
					WriteHTMLLine 0 0 ""
				}
				
				Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Scripts Tab"
				If(![String]::IsNullOrEmpty($Task.preUpdateScript) -or ![String]::IsNullOrEmpty($Task.preVmScript) -or ![String]::IsNullOrEmpty($Task.postVmScript) -or ![String]::IsNullOrEmpty($Task.postUpdateScript))
				{
					If($MSWord -or $PDF)
					{
						WriteWordLine 0 2 "Scripts"
						[System.Collections.Hashtable[]] $ScriptInformation = @()
						$ScriptInformation += @{ Data = "Scripts that execute with the vDisk update processing"; Value = ""; }
						$ScriptInformation += @{ Data = "Pre-update script"; Value = $Task.preUpdateScript; }
						$ScriptInformation += @{ Data = "Pre-startup script"; Value = $Task.preVmScript; }
						$ScriptInformation += @{ Data = "Post-shutdown script"; Value = $Task.postVmScript; }
						$ScriptInformation += @{ Data = "Post-update script"; Value = $Task.postUpdateScript; }

						$Table = AddWordTable -Hashtable $ScriptInformation `
						-Columns Data,Value `
						-List `
						-Format $wdTableGrid `
						-AutoFit $wdAutoFitContent;

						SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

						#$Table.Columns.Item(1).Width = 250;
						#$Table.Columns.Item(2).Width = 250;

						$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

						FindWordDocumentEnd
						$Table = $Null
						WriteWordLine 0 0 ""
					}
					ElseIf($Text)
					{
						Line 2 "Scripts"
						Line 3 "Scripts that execute with the vDisk update processing:"
						Line 3 "Pre-update script`t: " $Task.preUpdateScript
						Line 3 "Pre-startup script`t: " $Task.preVmScript
						Line 3 "Post-shutdown script`t: " $Task.postVmScript
						Line 3 "Post-update script`t: " $Task.postUpdateScript
						Line 0 ""
					}
					ElseIf($HTML)
					{
						WriteWordLine 0 2 "Scripts"
						$rowdata = @()
						$columnHeaders = @("Scripts that execute with the vDisk update processing",($htmlsilver -bor $htmlbold),"",$htmlwhite)
						$rowdata += @(,('Pre-update script',($htmlsilver -bor $htmlbold),$Task.preUpdateScript,$htmlwhite))
						$rowdata += @(,('Pre-startup script',($htmlsilver -bor $htmlbold),$Task.preVmScript,$htmlwhite))
						$rowdata += @(,('Post-shutdown script',($htmlsilver -bor $htmlbold),$Task.postVmScript,$htmlwhite))
						$rowdata += @(,('Post-update script',($htmlsilver -bor $htmlbold),$Task.postUpdateScript,$htmlwhite))

						$msg = ""
						FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
						WriteHTMLLine 0 0 ""
					}
				}
				
				Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Access Tab"
				If($MSWord -or $PDF)
				{
					WriteWordLine 0 2 "Access"
					[System.Collections.Hashtable[]] $ScriptInformation = @()
					$ScriptInformation += @{ Data = "Upon successful completion, access assigned to the vDisk"; Value = $xTaskpostUpdateApprove; }

					$Table = AddWordTable -Hashtable $ScriptInformation `
					-Columns Data,Value `
					-List `
					-Format $wdTableGrid `
					-AutoFit $wdAutoFitContent;

					SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

					#$Table.Columns.Item(1).Width = 250;
					#$Table.Columns.Item(2).Width = 250;

					$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

					FindWordDocumentEnd
					$Table = $Null
					WriteWordLine 0 0 ""
				}
				ElseIf($Text)
				{
					Line 2 "Access"
					Line 3 "Upon successful completion, access assigned to the vDisk: " $xTaskpostUpdateApprove
				}
				ElseIf($HTML)
				{
					WriteWordLine 0 2 "Access"
					$rowdata = @()
					$columnHeaders = @("Upon successful completion, access assigned to the vDisk",($htmlsilver -bor $htmlbold),$xTaskpostUpdateApprove,$htmlwhite)

					$msg = ""
					FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
					WriteHTMLLine 0 0 ""
				}
			}
		}
	}
	ElseIf($? -and $Tasks -eq $Null)
	{
		$txt = "There are no Update Tasks"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Update Tasks"
		OutputWarning $txt
	}

	#process all device collections in site
	Write-Verbose "$(Get-Date): `t`tProcessing all device collections in site"
	$Collections = Get-PvsCollection -SiteName $PVSSite.SiteName -EA 0 4>$Null

	If($? -and $Collections -ne $Null)
	{
		If($MSWord -or $PDF)
		{
			WriteWordLine 2 0 "Device Collections"
		}
		ElseIf($Text)
		{
			Line 0 "Device Collections"
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 2 0 "Device Collections"
		}

		ForEach($Collection in $Collections)
		{
			Write-Verbose "$(Get-Date): `t`t`tProcessing Collection $($Collection.collectionName)"
			Write-Verbose "$(Get-Date): `t`t`t`tProcessing General Tab"
			If($MSWord -or $PDF)
			{
				WriteWordLine 3 0 $Collection.collectionName
				WriteWordLine 0 0 "General"
				[System.Collections.Hashtable[]] $ScriptInformation = @()
				$ScriptInformation += @{ Data = "Name"; Value = $Collection.collectionName; }
				$ScriptInformation += @{ Data = "Description"; Value = $Collection.description; }

				$Table = AddWordTable -Hashtable $ScriptInformation `
				-Columns Data,Value `
				-List `
				-Format $wdTableGrid `
				-AutoFit $wdAutoFitContent;

				SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

				$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

				FindWordDocumentEnd
				$Table = $Null
				WriteWordLine 0 0 ""
			}
			ElseIf($Text)
			{
				Line 0 $Collection.collectionName
				Line 1 "General"
				Line 2 "Name`t`t: " $Collection.collectionName
				Line 2 "Description`t: " $Collection.description
			}
			ElseIf($HTML)
			{
				WriteHTMLLine 3 0 $Collection.collectionName
				$rowdata = @()
				$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$Collection.collectionName,$htmlwhite)
				$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$Collection.description,$htmlwhite))
				
				$msg = "General"
				FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
				WriteHTMLLine 0 0 ""
			}

			Write-Verbose "$(Get-Date): `t`t`t`tProcessing Security Tab"
			If($MSWord -or $PDF)
			{
				WriteWordLine 0 0 "Security"
			}
			ElseIf($Text)
			{
				Line 2 "Security"
			}
			ElseIf($HTML)
			{
				WriteWordLine 3 0 "Security"
			}
			$AuthGroups = Get-PvsAuthGroup -CollectionId $Collection.collectionId -EA 0 4>$Null

			If($? -and $AuthGroups -ne $Null)
			{
				If($MSWord -or $PDF)
				{
					WriteWordLine 0 0 "Groups with 'Device Administrator' access:"
				}
				ElseIf($Text)
				{
					Line 3 "Groups with 'Device Administrator' access:"
				}
				ElseIf($HTML)
				{
					WriteHTMLLine 3 0 "Groups with 'Device Administrator' access:"
				}

				$tmpAuthGroups = @()
				ForEach($AuthGroup in $AuthGroups)
				{
					$AuthGroupUsages = Get-PvsAuthGroupUsage -Name $authgroup.authGroupName 4>$Null
					If($? -and $AuthGroupUsages -ne $Null)
					{
                        If($AuthGroupUsages.Role -eq 300)
                        {
    						$tmpAuthGroups += $authGroup
                        }
					}
					ElseIf($? -and $AuthGroupUsages -eq $Null)
					{
						$txt = "There are no Groups with 'Device Administrator' access"
						OutputWarning $txt
					}
					Else
					{
						$txt = "Unable to retrieve Groups with 'Device Administrator' access"
						OutputWarning $txt
					}
				}
				OutputauthGroups $tmpAuthGroups

				If($MSWord -or $PDF)
				{
					WriteWordLine 0 0 "Groups with 'Device Operator' access:"
				}
				ElseIf($Text)
				{
					Line 3 "Groups with 'Device Operator' access:"
				}
				ElseIf($HTML)
				{
					WriteHTMLLine 3 0 "Groups with 'Device Operator' access:"
				}
				
				$tmpAuthGroups = @()
				ForEach($AuthGroup in $AuthGroups)
				{
					$AuthGroupUsages = Get-PvsAuthGroupUsage -Name $authgroup.authGroupName 4>$Null
					If($? -and $AuthGroupUsages -ne $Null)
					{
                        If($AuthGroupUsages.Role -eq 400)
                        {
    						$tmpAuthGroups += $authGroup
                        }
					}
					ElseIf($? -and $AuthGroupUsages -eq $Null)
					{
						$txt = "There are no Groups with 'Device Operator' access"
						OutputWarning $txt
					}
					Else
					{
						$txt = "Unable to retrieve Groups with 'Device Operator' access"
						OutputWarning $txt
					}
				}
				OutputauthGroups $tmpAuthGroups
			}
			ElseIf($? -and $AuthGroups -eq $Null)
			{
				$txt = "No Authorized Groups for $($Collection.collectionName)"
				OutputWarning $txt
			}
			Else
			{
				$txt = "Unable to retrieve Authorized Groups for $($Collection.collectionName)"
				OutputWarning $txt
			}
			
			Write-Verbose "$(Get-Date): `t`t`t`tProcessing Auto-Add Tab"
			If($MSWord -or $PDF)
			{
				WriteWordLine 0 0 "Auto-Add"
			}
			ElseIf($Text)
			{
				Line 2 "Auto-Add"
			}
			ElseIf($HTML)
			{
				WriteHTMLLine 3 0 "Auto-Add"
			}
			If($Script:FarmAutoAddEnabled)
			{
				If($Collection.autoAddZeroFill)
				{
					$autoAddZeroFill = "Yes"
				}
				Else
				{
					$autoAddZeroFill = "No"
				}
				If([String]::IsNullOrEmpty($Collection.templateDeviceName))
				{
					$TDN = "No template device"
				}
				Else
				{
					$TDN = $Collection.templateDeviceName
				}
				If($MSWord -or $PDF)
				{
					[System.Collections.Hashtable[]] $ScriptInformation = @()
					$ScriptInformation += @{ Data = "Template target device"; Value = $TDN; }
					$ScriptInformation += @{ Data = "Device Name"; Value = ""; }
					$ScriptInformation += @{ Data = "     Prefix"; Value = $Collection.autoAddPrefix; }
					$ScriptInformation += @{ Data = "     Length"; Value = $Collection.autoAddNumberLength; }
					$ScriptInformation += @{ Data = "     Zero fill"; Value = $autoAddZeroFill; }
					$ScriptInformation += @{ Data = "     Suffix"; Value = $Collection.autoAddSuffix; }
					$ScriptInformation += @{ Data = "     Last incremental #"; Value = $Collection.lastAutoAddDeviceNumber; }

					$Table = AddWordTable -Hashtable $ScriptInformation `
					-Columns Data,Value `
					-List `
					-Format $wdTableGrid `
					-AutoFit $wdAutoFitContent;

					SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

					$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

					FindWordDocumentEnd
					$Table = $Null
					WriteWordLine 0 0 ""
				}
				ElseIf($Text)
				{
					Line 3 "Template target device`t`t: " $TDN
					Line 3 "Device Name"
					Line 4 "Prefix`t`t`t: " $Collection.autoAddPrefix
					Line 4 "Length`t`t`t: " $Collection.autoAddNumberLength
					Line 4 "Zero fill`t`t: " $autoAddZeroFill
					Line 4 "Suffix`t`t`t: " $Collection.autoAddSuffix
					Line 4 "Last incremental #`t: " $Collection.lastAutoAddDeviceNumber
				}
				ElseIf($HTML)
				{
					$rowdata = @()
					$columnHeaders = @("Template target device",($htmlsilver -bor $htmlbold),$TDN,$htmlwhite)
					$rowdata += @(,('Device Name',($htmlsilver -bor $htmlbold),"",$htmlwhite))
					$rowdata += @(,('     Prefix',($htmlsilver -bor $htmlbold),$Collection.autoAddPrefix,$htmlwhite))
					$rowdata += @(,('     Length',($htmlsilver -bor $htmlbold),$Collection.autoAddNumberLength,$htmlwhite))
					$rowdata += @(,('     Zero fill',($htmlsilver -bor $htmlbold),$autoAddZeroFill,$htmlwhite))
					$rowdata += @(,('     Suffix',($htmlsilver -bor $htmlbold),$Collection.autoAddSuffix,$htmlwhite))
					$rowdata += @(,('     Last incremental #',($htmlsilver -bor $htmlbold),$Collection.lastAutoAddDeviceNumber,$htmlwhite))
					
					$msg = ""
					FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
					WriteHTMLLine 0 0 ""
				}
			}
			Else
			{
				If($MSWord -or $PDF)
				{
					WriteWordLine 0 3 "The auto-add feature is not enabled at the PVS Farm level"
				}
				ElseIf($Text)
				{
					Line 3 "The auto-add feature is not enabled at the PVS Farm level"
				}
				ElseIf($HTML)
				{
					WriteHTMLLine 0 0 "The auto-add feature is not enabled at the PVS Farm level"
				}
			}

			#for each collection, process each device
			Write-Verbose "$(Get-Date): `t`t`tProcessing each collection process for each device"
			$Devices = Get-PvsDeviceInfo -collectionId $Collection.collectionId -EA 0 4>$Null
			
			If($? -and $Devices -ne $Null)
			{
				ForEach($Device in $Devices)
				{
					Write-Verbose "$(Get-Date): `t`t`t`tProcessing Device $($Device.deviceName)"
					If($Device.type -eq 3)
					{
						$txt = "Device with Personal vDisk Properties"
					}
					Else
					{
						$txt = "Target Device Properties"
					}

					If($MSWord -or $PDF)
					{
						WriteWordLine 0 0 $txt
					}
					ElseIf($Text)
					{
						Line 0 $txt
					}
					ElseIf($HTML)
					{
						WriteHTMLLine 0 0 $txt
						WriteHTMLLine 0 0 ""
					}

					If($Device.type -ne "3")
					{
						Switch ($Device.type)
						{
							0 {$DeviceType = "Production"}
							1 {$DeviceType = "Test"}
							2 {$DeviceType = "Maintenance"}
							3 {$DeviceType = "Personal vDisk"}
							Default {$DeviceType = "Device type could not be determined: $($Device.type)"}
						}
						Switch ($Device.bootFrom)
						{
							1 {$DeviceBootFrom = "vDisk"}
							2 {$DeviceBootFrom = "Hard Disk"}
							3 {$DeviceBootFrom = "Floppy Disk"}
							Default {$DeviceBootFrom = "Boot from could not be determined: $($Device.bootFrom)"}
						}
						If($Device.enabled)
						{
							$DeviceEnabled = "Unchecked"
						}
						Else
						{
							$DeviceEnabled = "Checked"
						}
					}
					If($Device.localDiskEnabled)
					{
						$DevicelocalDiskEnabled = "Yes"
					}
					Else
					{
						$DevicelocalDiskEnabled = "No"
					}
					Switch($Device.authentication)
					{
						0 {$DeviceAuthentication = "None"}
						1 {$DeviceAuthentication = "Username and password"}
						2 {$DeviceAuthentication = "External verification (User supplied method)"}
						Default {$DeviceAuthentication = "Authentication type could not be determined: $($Device.authentication)"}
					}

					Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing General Tab"
					If($MSWord -or $PDF)
					{
						WriteWordLine 3 0 "General"
						[System.Collections.Hashtable[]] $ScriptInformation = @()
						$ScriptInformation += @{ Data = "Name"; Value = $Device.deviceName; }
						$ScriptInformation += @{ Data = "Description"; Value = $Device.description; }

						If($Device.type -ne "3")
						{
							$ScriptInformation += @{ Data = "Type"; Value = $DeviceType; }
							$ScriptInformation += @{ Data = "Boot from"; Value = $DeviceBootFrom; }
						}

						$ScriptInformation += @{ Data = "MAC"; Value = $Device.deviceMac; }
						$ScriptInformation += @{ Data = "Port"; Value = $Device.port; }
						
						If($Device.type -ne "3")
						{
							$ScriptInformation += @{ Data = "Class"; Value = $Device.className; }
							$ScriptInformation += @{ Data = "Disable this device"; Value = $DeviceEnabled; }
						}
						Else
						{
							$ScriptInformation += @{ Data = "vDisk"; Value = $Device.diskLocatorName; }
							$ScriptInformation += @{ Data = "Personal vDisk Drive"; Value = $Device.pvdDriveLetter; }
						}

						$Table = AddWordTable -Hashtable $ScriptInformation `
						-Columns Data,Value `
						-List `
						-Format $wdTableGrid `
						-AutoFit $wdAutoFitContent;

						SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

						$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

						FindWordDocumentEnd
						$Table = $Null
						WriteWordLine 0 0 ""
					}
					ElseIf($Text)
					{
						Line 0 "General"
						Line 3 "Name`t`t`t: " $Device.deviceName
						Line 3 "Description`t`t: " $Device.description

						If($Device.type -ne 3)
						{
							Line 3 "Type`t`t`t: " $DeviceType
							Line 3 "Boot from`t`t: " $DeviceBootFrom
						}

						Line 3 "MAC`t`t`t: " $Device.deviceMac
						Line 3 "Port`t`t`t: " $Device.port
						
						If($Device.type -ne 3)
						{
							Line 3 "Class`t`t`t: " $Device.className
							Line 3 "Disable this device`t: " $DeviceEnabled
						}
						Else
						{
							Line 3 "vDisk`t`t`t: " $Device.diskLocatorName
							Line 3 "Personal vDisk Drive`t: " $Device.pvdDriveLetter
						}
					}
					ElseIf($HTML)
					{
						#WriteWordLine 3 0 "General"
						$rowdata = @()
						$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$Device.deviceName,$htmlwhite)
						$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$Device.deviceName,$htmlwhite))

						If($Device.type -ne "3")
						{
							$rowdata += @(,('Type',($htmlsilver -bor $htmlbold),$DeviceType,$htmlwhite))
							$rowdata += @(,('Boot from',($htmlsilver -bor $htmlbold),$DeviceBootFrom,$htmlwhite))
						}

						$rowdata += @(,('MAC',($htmlsilver -bor $htmlbold),$Device.deviceMac,$htmlwhite))
						$rowdata += @(,('Port',($htmlsilver -bor $htmlbold),$Device.port,$htmlwhite))
						
						If($Device.type -ne "3")
						{
							$rowdata += @(,('Class',($htmlsilver -bor $htmlbold),$Device.className,$htmlwhite))
							$rowdata += @(,('Disable this device',($htmlsilver -bor $htmlbold),$DeviceEnabled,$htmlwhite))
						}
						Else
						{
							$rowdata += @(,('vDisk',($htmlsilver -bor $htmlbold),$Device.diskLocatorName,$htmlwhite))
							$rowdata += @(,('Personal vDisk Drive',($htmlsilver -bor $htmlbold),$Device.pvdDriveLetter,$htmlwhite))
						}
					
						$msg = "General"
						FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
						WriteHTMLLine 0 0 ""
					}
					
					Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing vDisks Tab"
					If($MSWord -or $PDF)
					{
						WriteWordLine 3 0 "vDisks"
					}
					ElseIf($Text)
					{
						Line 0 "vDisks"
					}
					ElseIf($HTML)
					{
						#WriteWordLine 3 0 "vDisks"
					}
					#process all vdisks for this device
					$vDisks = Get-PvsDiskInfo -deviceName $Device.deviceName -EA 0 4>$Null
					If($? -and $vDisks -ne $Null)
					{
						#WriteWordLine 0 3 "Name: "
						$vDiskArray = @()
						ForEach($vDisk in $vDisks)
						{
							$vDiskArray += "$($vDisk.storeName)`\$($vDisk.diskLocatorName)"
						}
						If($MSWord -or $PDF)
						{
							[System.Collections.Hashtable[]] $ScriptInformation = @()
							$ScriptInformation += @{ Data = "Name"; Value = $vDiskarray[0]; }
							$cnt = -1
							ForEach($tmp in $vDiskArray)
							{
								$cnt++
								If($cnt -gt 0)
								{
									$ScriptInformation += @{ Data = ""; Value = $tmp; }
								}
							}

							$Table = AddWordTable -Hashtable $ScriptInformation `
							-Columns Data,Value `
							-List `
							-Format $wdTableGrid `
							-AutoFit $wdAutoFitContent;

							SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

							$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

							FindWordDocumentEnd
							$Table = $Null
							WriteWordLine 0 0 ""
						}
						ElseIf($Text)
						{
							Line 3 "Name: " $vDiskArray[0]
							$cnt = -1
							ForEach($tmp in $vDiskArray)
							{
								$cnt++
								If($cnt -gt 0)
								{
									Line 5 "  " $tmp
								}
							}
						}
						ElseIf($HTML)
						{
							$rowdata = @()
							$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$vDiskArray[0],$htmlwhite)
							$cnt = -1
							ForEach($tmp in $vDiskArray)
							{
								$cnt++
								If($cnt -gt 0)
								{
									$rowdata += @(,('',($htmlsilver -bor $htmlbold),$tmp,$htmlwhite))
								}
							}
					
							$msg = "vDisks"
							FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
							WriteHTMLLine 0 0 ""
						}
					}
					ElseIf($? -and $vDisks -eq $Null)
					{
						$txt = "There are no vDisks"
						OutputWarning $txt
					}
					Else
					{
						$txt = "Unable to retrieve vDisks"
						OutputWarning $txt
					}
					
					If($MSWord -or $PDF)
					{
						[System.Collections.Hashtable[]] $ScriptInformation = @()
						WriteWordLine 4 0 "Options"
						$ScriptInformation += @{ Data = "List local hard drive in boot menu"; Value = $DevicelocalDiskEnabled; }
						#process all bootstrap files for this device
						Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing all bootstrap files for this device"
						$Bootstraps = Get-PvsDeviceBootstrap -deviceName $Device.deviceName -EA 0 4>$Null
						If($? -and $Bootstraps -ne $Null)
						{
							$BootstrapsArray = @()
							ForEach($Bootstrap in $Bootstraps)
							{
								$BootstrapsArray += "$($Bootstrap.devicebootstrap.Name) `($($Bootstrap.devicebootstrap.menuText)`)"
							}
							$ScriptInformation += @{ Data = "Custom bootstrap file"; Value = $BootstrapsArray[0]; }
							$cnt = -1
							ForEach($tmp in $BootstrapsArray)
							{
								$cnt++
								If($cnt -gt 0)
								{
									$ScriptInformation += @{ Data = ""; Value = $tmp; }
								}
							}
						}

						$Table = AddWordTable -Hashtable $ScriptInformation `
						-Columns Data,Value `
						-List `
						-Format $wdTableGrid `
						-AutoFit $wdAutoFitContent;

						SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

						$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

						FindWordDocumentEnd
						$Table = $Null
						WriteWordLine 0 0 ""
					}
					ElseIf($Text)
					{
						Line 3 "Options"
						Line 4 "List local hard drive in boot menu: " $DevicelocalDiskEnabled
						#process all bootstrap files for this device
						Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing all bootstrap files for this device"
						$Bootstraps = Get-PvsDeviceBootstrap -deviceName $Device.deviceName -EA 0 4>$Null
						If($? -and $Bootstraps -ne $Null)
						{
							$BootstrapsArray = @()
							ForEach($Bootstrap in $Bootstraps)
							{
								$BootstrapsArray += "$($Bootstrap.devicebootstrap.Name) `($($Bootstrap.devicebootstrap.menuText)`)"
							}
							Line 4 "Custom bootstrap file: " $BootstrapsArray[0]
							$cnt = -1
							ForEach($tmp in $BootstrapsArray)
							{
								$cnt++
								If($cnt -gt 0)
								{
									Line 7 "  " $tmo
								}
							}
						}
					}
					ElseIf($HTML)
					{
						$rowdata = @()
						$columnHeaders = @("Options",($htmlsilver -bor $htmlbold),"",$htmlwhite)
						$rowdata += @(,('List local hard drive in boot menu',($htmlsilver -bor $htmlbold),$DevicelocalDiskEnabled,$htmlwhite))
						#process all bootstrap files for this device
						Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing all bootstrap files for this device"
						$Bootstraps = Get-PvsDeviceBootstrap -deviceName $Device.deviceName -EA 0 4>$Null
						If($? -and $Bootstraps -ne $Null)
						{
							$BootstrapsArray = @()
							ForEach($Bootstrap in $Bootstraps)
							{
								$BootstrapsArray += "$($Bootstrap.devicebootstrap.Name) `($($Bootstrap.devicebootstrap.menuText)`)"
							}
							$rowdata += @(,('Custom bootstrap file',($htmlsilver -bor $htmlbold),$BootstrapsArray[0],$htmlwhite))
							$cnt = -1
							ForEach($tmp in $BootstrapsArray)
							{
								$cnt++
								If($cnt -gt 0)
								{
									$rowdata += @(,('',($htmlsilver -bor $htmlbold),$tmp,$htmlwhite))
								}
							}
						}
					
						$msg = ""
						FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
						WriteHTMLLine 0 0 ""
					}
					
					Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Authentication Tab"
					If($MSWord -or $PDF)
					{
						[System.Collections.Hashtable[]] $ScriptInformation = @()
						WriteWordLine 4 0 "Authentication"
						
						$ScriptInformation += @{ Data = "Type of authentication to use for this device"; Value = $DeviceAuthentication; }
						If($DeviceAuthentication -eq "Username and password")
						{
							$ScriptInformation += @{ Data = "Username"; Value = $Device.user; }
							$ScriptInformation += @{ Data = "Password"; Value = $Device.password; }
						}
						$Table = AddWordTable -Hashtable $ScriptInformation `
						-Columns Data,Value `
						-List `
						-Format $wdTableGrid `
						-AutoFit $wdAutoFitContent;

						SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

						#$Table.Columns.Item(1).Width = 250;
						#$Table.Columns.Item(2).Width = 250;

						$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

						FindWordDocumentEnd
						$Table = $Null
						WriteWordLine 0 0 ""
					}
					ElseIf($Text)
					{
						Line 2 "Authentication"
						Line 3 "Type of authentication to use for this device: " $DeviceAuthentication
						If($DeviceAuthentication -eq "Username and password")
						{
							Line 4 "Username: " $Device.user
							Line 4 "Password: " $Device.password
						}
					}
					ElseIf($HTML)
					{
						$rowdata = @()
						$columnHeaders = @("Type of authentication to use for this device",($htmlsilver -bor $htmlbold),$DeviceAuthentication,$htmlwhite)
						If($DeviceAuthentication -eq "Username and password")
						{
							$rowdata += @(,('Username',($htmlsilver -bor $htmlbold),$Device.user,$htmlwhite))
							$rowdata += @(,('Password',($htmlsilver -bor $htmlbold),$Device.password,$htmlwhite))
						}
						$msg = "Authentication"
						FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
					}
					
					Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Personality Tab"
					#process all personality strings for this device
					$PersonalityStrings = Get-PvsDevicePersonality -deviceName $Device.deviceName -EA 0 4>$Null
					If($? -and $PersonalityStrings -ne $Null)
					{
						If($MSWord -or $PDF)
						{
							WriteWordLine 4 0 "Personality"
							ForEach($PersonalityString in $PersonalityStrings.DevicePersonality)
							{
								[System.Collections.Hashtable[]] $ScriptInformation = @()
								$ScriptInformation += @{ Data = "Name"; Value = $PersonalityString.Name; }
								$ScriptInformation += @{ Data = "String"; Value = $PersonalityString.Value; }

								$Table = AddWordTable -Hashtable $ScriptInformation `
								-Columns Data,Value `
								-List `
								-Format $wdTableGrid `
								-AutoFit $wdAutoFitContent;

								SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

								#$Table.Columns.Item(1).Width = 250;
								#$Table.Columns.Item(2).Width = 250;

								$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

								FindWordDocumentEnd
								$Table = $Null
								WriteWordLine 0 0 ""
							}
						}
						ElseIf($Text)
						{
							Line 0 "Personality"
							ForEach($PersonalityString in $PersonalityStrings.DevicePersonality)
							{
								Line 3 "Name: " $PersonalityString.Name
								Line 3 "String: " $PersonalityString.Value
								Line 0 ""
							}
						}
						ElseIf($HTML)
						{
							WriteHTMLLine 3 0 "Personality"
							ForEach($PersonalityString in $PersonalityStrings.DevicePersonality)
							{
								$rowdata = @()
								$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$PersonalityString.Name,$htmlwhite)
								$rowdata += @(,('String',($htmlsilver -bor $htmlbold),$PersonalityString.Value,$htmlwhite))

								$msg = ""
								FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
								WriteHTMLLine 0 0 ""
							}
						}
					}
					
					If($MSWord -or $PDF)
					{
						WriteWordLine 4 0 "Status"
					}
					ElseIf($Text)
					{
						Line 0 "Status"
					}
					ElseIf($HTML)
					{
						WriteHTMLLine 3 0 "Status"
					}
					DeviceStatus $Device
				}
			}
			ElseIf($? -and $Devices -eq $Null)
			{
				$txt = "There are no devices"
				OutputWarning $txt
			}
			Else
			{
				$txt = "Unable to retrieve devices"
				OutputWarning $txt
			}

		}
	}
	ElseIf($? -and $Collections -eq $Null)
	{
		$txt = "There are no Device Collections"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Device Collections"
		OutputWarning $txt
	}	
#>

	#process all site views in site
	Write-Verbose "$(Get-Date): `t`tProcessing all site views in site"
	$SiteViews = Get-PVSSiteView -SiteName $PVSSite.siteName -EA 0 4>$Null
	
	If($? -and $SiteViews -ne $Null)
	{
		If($MSWord -or $PDF)
		{
			WriteWordLine 2 0 "Site Views"
		}
		ElseIf($Text)
		{
			Line 0 "Site Views"
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 2 0 "Site Views"
		}
		
		ForEach($SiteView in $SiteViews)
		{
			Write-Verbose "$(Get-Date): `t`t`tProcessing Site View $($SiteView.siteViewName)"
			Write-Verbose "$(Get-Date): `t`t`t`tProcessing General Tab"
			If($MSWord -or $PDF)
			{
				WriteWordLine 3 0 $SiteView.siteViewName
				WriteWordLine 0 0 "View Properties"
				WriteWordLine 0 0 "General"
				[System.Collections.Hashtable[]] $ScriptInformation = @()
				$ScriptInformation += @{ Data = "Name"; Value = $SiteView.siteViewName; }
				If(![String]::IsNullOrEmpty($SiteView.description))
				{
					$ScriptInformation += @{ Data = "Description"; Value = $SiteView.description; }
				}
				$Table = AddWordTable -Hashtable $ScriptInformation `
				-Columns Data,Value `
				-List `
				-Format $wdTableGrid `
				-AutoFit $wdAutoFitContent;

				## IB - Set the header row format
				SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

				$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

				FindWordDocumentEnd
				$Table = $Null
				WriteWordLine 0 0 ""
			}
			ElseIf($Text)
			{
				Line 0 $SiteView.siteViewName
				Line 1 "View Properties"
				Line 2 "General"
				Line 3 "Name`t`t: " $SiteView.siteViewName
				If(![String]::IsNullOrEmpty($SiteView.description))
				{
					Line 3 "Description`t: " $SiteView.description
				}
			}
			ElseIf($HTML)
			{
				WriteHTMLLine 3 0 $SiteView.siteViewName
				WriteWordLine 0 0 "View Properties"
				$rowdata = @()
				$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$SiteView.siteViewName,$htmlwhite)
				If(![String]::IsNullOrEmpty($SiteView.description))
				{
					$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$SiteView.description,$htmlwhite))
				}
				
				$msg = "General"
				FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
				WriteHTMLLIne 0 0 ""
			}
			
			Write-Verbose "$(Get-Date): `t`t`t`tProcessing Members Tab"
			WriteWordLine 4 0 "Members"
			#process each target device contained in the site view
			$Members = Get-PVSDevice -SiteViewId $SiteView.siteViewId -EA 0 4>$Null
			If($? -and $Members -ne $Null)
			{
				OutputViewMembers $Members
			}
			ElseIf($? -and $Members -eq $Null)
			{
				$txt = "There are no Site Views members"
				OutputWarning $txt
			}
			Else
			{
				$txt = "Unable to retrieve Site View members"
				OutputWarning $txt
			}
		}
	}
	ElseIf($? -and $SiteViews -eq $Null)
	{
		$txt = "There are no Site Views configured"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Site Views"
		OutputWarning $txt
	}
	
	#process all virtual hosts for this site
	Write-Verbose "$(Get-Date): `t`t`tProcessing virtual hosts"
	$vHosts = Get-PvsVirtualHostingPool -siteName $PVSSite.SiteName -EA 0 4>$Null
	If($? -and $vHosts -ne $Null)
	{
		If($MSWord -or $PDF)
		{
			WriteWordLine 2 0 "Hosts"
		}
		ElseIf($Text)
		{
			Line 0 ""
			Line 0 "Hosts"
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 2 0 "Hosts"
		}
		ForEach($vHost in $vHosts)
		{
			Write-Verbose "$(Get-Date): `t`t`t`tProcessing virtual host $($vHost.virtualHostingPoolName)"
			Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing General Tab"
			Switch ($vHost.type)
			{
				0 {$vHostType = "Citrix XenServer"}
				1 {$vHostType = "Microsoft SCVMM/Hyper-V"}
				2 {$vHostType = "VMWare vSphere/ESX"}
				Default {$vHostType = "Virtualization Host type could not be determined: $($vHost.type)"}
			}

			If($MSWord -or $PDF)
			{
				WriteWordLine 3 0 $vHost.virtualHostingPoolName
				WriteWordLine 4 0 "General"
				[System.Collections.Hashtable[]] $ScriptInformation = @()
				$ScriptInformation += @{ Data = "Type"; Value = $vHosttype; }
				$ScriptInformation += @{ Data = "Name"; Value = $vHost.virtualHostingPoolName; }
				If(![String]::IsNullOrEmpty($vHost.description))
				{
					$ScriptInformation += @{ Data = "Description"; Value = $vHost.description; }
				}
				$ScriptInformation += @{ Data = "Host"; Value = $vHost.server; }
				$Table = AddWordTable -Hashtable $ScriptInformation `
				-Columns Data,Value `
				-List `
				-Format $wdTableGrid `
				-AutoFit $wdAutoFitContent;

				## IB - Set the header row format
				SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

				$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

				FindWordDocumentEnd
				$Table = $Null
				WriteWordLine 0 0 ""
				
				Write-Verbose "$(Get-Date): Processing vDisk Update Tab"
				WriteWordLine 4 0 "vDisk Update"
				[System.Collections.Hashtable[]] $ScriptInformation = @()
				$ScriptInformation += @{ Data = "Update limit"; Value = $vHost.updateLimit; }
				$ScriptInformation += @{ Data = "Update timeout"; Value = "$($vHost.updateTimeout) minutes"; }
				$ScriptInformation += @{ Data = "Shutdown timeout"; Value = "$($vHost.shutdownTimeout) minutes"; }
				$Table = AddWordTable -Hashtable $ScriptInformation `
				-Columns Data,Value `
				-List `
				-Format $wdTableGrid `
				-AutoFit $wdAutoFitContent;

				## IB - Set the header row format
				SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

				$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

				FindWordDocumentEnd
				$Table = $Null
				WriteWordLine 0 0 ""
			}
			ElseIf($Text)
			{
				Line 1 $vHost.virtualHostingPoolName
				Line 2 "General"
				Line 3 "Type`t`t: " $vHosttype
				Line 3 "Name`t`t: " $vHost.virtualHostingPoolName
				If(![String]::IsNullOrEmpty($vHost.description))
				{
					Line 3 "Description`t: " $vHost.description
				}
				Line 3 "Host`t`t: " $vHost.server
				
				Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing vDisk Update Tab"
				Line 2 "vDisk Update"
				Line 3 "Update limit`t: " $vHost.updateLimit
				Line 3 "Update timeout`t: $($vHost.updateTimeout) minutes"
				Line 3 "Shutdown timeout: $($vHost.shutdownTimeout) minutes"
				Line 0 ""
			}
			ElseIf($HTML)
			{
				WriteHTMLLine 3 0 $vHost.virtualHostingPoolName
				$rowdata = @()
				$columnHeaders = @("Type",($htmlsilver -bor $htmlbold),$vHosttype,$htmlwhite)
				$rowdata += @(,('Name',($htmlsilver -bor $htmlbold),$vHost.virtualHostingPoolName,$htmlwhite))
				If(![String]::IsNullOrEmpty($vHost.description))
				{
					$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$vHost.description,$htmlwhite))
				}
				$rowdata += @(,('Host',($htmlsilver -bor $htmlbold),$vHost.server,$htmlwhite))
				
				$msg = "General"
				FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
				WriteHTMLLine 0 0 ""
				
				Write-Verbose "$(Get-Date): Processing vDisk Update Tab"
				$columnHeaders = @("Update limit",($htmlsilver -bor $htmlbold),$vHost.updateLimit,$htmlwhite)
				$rowdata += @(,('Update timeout',($htmlsilver -bor $htmlbold),"$($vHost.updateTimeout) minutes",$htmlwhite))
				$rowdata += @(,('Shutdown timeout',($htmlsilver -bor $htmlbold),"$($vHost.shutdownTimeout) minutes",$htmlwhite))
				
				$msg = "vDisk Update"
				FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
				WriteHTMLLine 0 0 ""
			}
		}
	}
	ElseIf($? -and $vHosts -eq $Null)
	{
		$txt = "There are no Virtual Hosting Pools"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Virtual Hosting Pools"
		OutputWarning $txt
	}
	
	#add Audit Trail
	Write-Verbose "$(Get-Date): `t`t`tProcessing Audit Trail"
	$Audits = Get-PVSAuditTrail -SiteName $PVSSite.siteName -BeginDate $StartDate -EndDate $EndDate -EA 0 4>$Null
	
	If($? -and $Audits -ne $Null)
	{
		OutputAuditTrail $Audits "Site"
	}
	ElseIf($? -and $Audits -eq $Null)
	{
		$txt = "There are no Site Audit Trail items"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Site Audit Trail items"
		OutputWarning $txt
	}
}

Function OutputServers
{
	Param([object] $Servers)
	
	If($MSWord -or $PDF)
	{
		$selection.InsertNewPage()
		WriteWordLine 2 0 "Servers"
	}
	ElseIf($Text)
	{
		Line 0 ""
		Line 0 "Servers"
		Line 0 ""
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 "Servers"
	}

	ForEach($Server in $Servers)
	{
		Write-Verbose "$(Get-Date): `t`t`tProcessing Server $($Server.serverName)"
		#general tab
		Write-Verbose "$(Get-Date): `t`t`t`tProcessing General Tab"
		$xeventLoggingEnabled = ""
		If($Server.eventLoggingEnabled)
		{
			$xeventLoggingEnabled = "Yes"
		}
		Else
		{
			$xeventLoggingEnabled = "No"
		}
		
		$StreamingIPs = @()
		ForEach($ip in $Server.ip)
		{
			$StreamingIPs += $ip
		}

		$adMaxPasswordAgeEnabled = ""
		If($Server.adMaxPasswordAgeEnabled)
		{
			$adMaxPasswordAgeEnabled = "Yes"
		}
		Else
		{
			$adMaxPasswordAgeEnabled = "No"
		}

		$nonBlockingIoEnabled = ""
		If($Server.nonBlockingIoEnabled)
		{
			$nonBlockingIoEnabled = "Yes"
		}
		Else
		{
			$nonBlockingIoEnabled = "No"
		}

		$MaxBootTime = SecondsToMinutes $Server.maxBootSeconds
		$LicenseTimeout = SecondsToMinutes $Server.licenseTimeout

		If($MSWord -or $PDF)
		{
			WriteWordLine 3 0 $Server.serverName
			WriteWordLine 4 0 "Server Properties"
			WriteWordLine 0 0 "General"
			[System.Collections.Hashtable[]] $ScriptInformation = @()
			$ScriptInformation += @{ Data = "Name"; Value = $Server.serverName; }
			If(![String]::IsNullOrEmpty($Server.description))
			{
				$ScriptInformation += @{ Data = "Description"; Value = $Server.description; }
			}
			$ScriptInformation += @{ Data = "Power Rating"; Value = $Server.powerRating; }
			$ScriptInformation += @{ Data = "Log events to the server's Windows Event Log"; Value = $xeventLoggingEnabled; }
			$Table = AddWordTable -Hashtable $ScriptInformation `
			-Columns Data,Value `
			-List `
			-Format $wdTableGrid `
			-AutoFit $wdAutoFitContent;

			## IB - Set the header row format
			SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

			$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

			FindWordDocumentEnd
			$Table = $Null
			WriteWordLine 0 0 ""
		}
		ElseIf($Text)
		{
			Line 0 $Server.serverName
			Line 0 "Server Properties"
			Line 1 "General"
			Line 2 "Name`t`t: " $Server.serverName
			If(![String]::IsNullOrEmpty($Server.description))
			{
				Line 2 "Description`t: " $Server.description
			}
			Line 2 "Power Rating`t: " $Server.powerRating
			Line 2 "Log events to the server's Windows Event Log: " $xeventLoggingEnabled
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 3 0 $Server.serverName
			WriteHTMLLine 4 0 "Server Properties"
			$rowdata = @()
			$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$Server.serverName,$htmlwhite)
			If(![String]::IsNullOrEmpty($Server.description))
			{
				$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$Server.description,$htmlwhite))
			}
			$rowdata += @(,('Power Rating',($htmlsilver -bor $htmlbold),$Server.powerRating,$htmlwhite))
			$rowdata += @(,("Log events to the server's Windows Event Log",($htmlsilver -bor $htmlbold),$xeventLoggingEnabled,$htmlwhite))
			
			$msg = "General"
			FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
			WriteHTMLLine 0 0 ""
		}
			
		Write-Verbose "$(Get-Date): `t`t`t`tProcessing Network Tab"
		If($MSWord -or $PDF)
		{
			WriteWordLine 0 0 "Network"
			[System.Collections.Hashtable[]] $ScriptInformation = @()
			$ScriptInformation += @{ Data = "Streaming IP addresses"; Value = $StreamingIPs[0]; }
			$cnt = -1
			ForEach($tmp in $StreamingIPs)
			{
				$cnt++
				If($cnt -gt 0)
				{
					$ScriptInformation += @{ Data = ""; Value = $tmp; }
				}
			}
			$ScriptInformation += @{ Data = "Ports"; Value = ""; }
			$ScriptInformation += @{ Data = "     First port"; Value = $Server.firstPort; }
			$ScriptInformation += @{ Data = "     Last port"; Value = $Server.lastPort; }
			$ScriptInformation += @{ Data = "Management IP"; Value = $Server.managementIp; }
			$Table = AddWordTable -Hashtable $ScriptInformation `
			-Columns Data,Value `
			-List `
			-Format $wdTableGrid `
			-AutoFit $wdAutoFitContent;

			## IB - Set the header row format
			SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

			$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

			FindWordDocumentEnd
			$Table = $Null
			WriteWordLine 0 0 ""
		}
		ElseIf($Text)
		{
			Line 1 "Network"
			Line 2 "Streaming IP addresses`t: " $StreamingIPs[0]
			$cnt = -1
			ForEach($tmp in $StreamingIPs)
			{
				$cnt++
				If($cnt -gt 0)
				{
					Line 5 "  " $tmp
				}
			}
			Line 2 "Ports"
			Line 3 "First port`t: " $Server.firstPort
			Line 3 "Last port`t: " $Server.lastPort
			Line 2 "Management IP`t`t: " $Server.managementIp
		}
		ElseIf($HTML)
		{
			$rowdata = @()
			$columnHeaders = @("Streaming IP addresses",($htmlsilver -bor $htmlbold),"$($StreamingIPs[0])",$htmlwhite)
			$cnt = -1
			ForEach($tmp in $StreamingIPs)
			{
				$cnt++
				If($cnt -gt 0)
				{
					$rowdata += @(,('',($htmlsilver -bor $htmlbold),$tmp,$htmlwhite))
				}
			}
			$rowdata += @(,('Ports',($htmlsilver -bor $htmlbold),"",$htmlwhite))
			$rowdata += @(,('     First port',($htmlsilver -bor $htmlbold),$Server.firstPort,$htmlwhite))
			$rowdata += @(,('     Last port',($htmlsilver -bor $htmlbold),$Server.lastPort,$htmlwhite))
			$rowdata += @(,('Management IP',($htmlsilver -bor $htmlbold),$Server.managementIp,$htmlwhite))
			$msg = "Network"
			FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
			WriteHTMLLine 0 0 ""
		}
			
		Write-Verbose "$(Get-Date): `t`t`t`tProcessing Stores Tab"
		#process all stores for this server
		Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Stores for server"
		$Stores = Get-PVSStore -ServerName $Server.serverName -EA 0 4>$Null

		If($? -and $Stores -ne $Null)
		{
			If($MSWord -or $PDF)
			{
				WriteWordLine 0 0 "Stores that this server supports:"
			}
			ElseIf($Text)
			{
				Line 1 "Stores"
				Line 2 "Stores that this server supports:"
			}
			ElseIf($HTML)
			{
				WriteHTMLLine 3 0 "Stores"
			}
			ForEach($store in $stores)
			{
				Write-Verbose "$(Get-Date): `t`t`t`t`t`tProcessing Store $($store.storename)"
				
				$StorePath = ""
				If($store.path.length -gt 0)
				{
					$StorePath = $store.path
				}
				Else
				{
					$StorePath = "<Using the Default path from the store>"
				}
				
				$WriteCachePaths = @()
				ForEach($WCPath in $store.cachePath)
				{
					$WriteCachePaths += $WCPath
				}
				If($WriteCachePaths.Count -eq 0)
				{
					$WriteCachePaths += "<Using the Default path from the store>"
				}
				
				If($MSWord -or $PDF)
				{
					[System.Collections.Hashtable[]] $ScriptInformation = @()
					$ScriptInformation += @{ Data = "Store"; Value = $store.storename; }
					$ScriptInformation += @{ Data = "Path"; Value = $StorePath; }
					$ScriptInformation += @{ Data = "Write cache paths"; Value = $WriteCachePaths[0]; }
					$cnt = -1
					ForEach($tmp in $WriteCachePaths)
					{
						$cnt++
						If($cnt -gt 0)
						{
							$ScriptInformation += @{ Data = ""; Value = $tmp; }
						}
					}
					$Table = AddWordTable -Hashtable $ScriptInformation `
					-Columns Data,Value `
					-List `
					-Format $wdTableGrid `
					-AutoFit $wdAutoFitContent;

					## IB - Set the header row format
					SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

					$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

					FindWordDocumentEnd
					$Table = $Null
					WriteWordLine 0 0 ""
				}
				ElseIf($Text)
				{
					Line 3 "Store`t: " $store.storename
					Line 3 "Path`t: " $StorePath
					Line 3 "Write cache paths: " $WriteCachePaths[0]
					$cnt = -1
					ForEach($tmp in $WriteCachePaths)
					{
						$cnt++
						If($cnt -gt 0)
						{
							Line 5 "  " $tmp
						}
					}
					Line 0 ""
				}
				ElseIf($HTML)
				{
					$rowdata = @()
					$columnHeaders = @("Store",($htmlsilver -bor $htmlbold),$store.storename,$htmlwhite)
					$rowdata += @(,('Path',($htmlsilver -bor $htmlbold),$StorePath,$htmlwhite))
					$rowdata += @(,('Write cache paths',($htmlsilver -bor $htmlbold),$WriteCachePaths[0],$htmlwhite))
					$cnt = -1
					ForEach($tmp in $WriteCachePaths)
					{
						$cnt++
						If($cnt -gt 0)
						{
							$rowdata += @(,('',($htmlsilver -bor $htmlbold),$tmp,$htmlwhite))
						}
					}

					$msg = "Stores that this server supports:"
					FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
					WriteHTMLLine 0 0 ""
				}
			}
		}
		ElseIf($? -and $Stores -eq $Null)
		{
			$txt = "There are no Stores"
			OutputWarning $txt
		}
		Else
		{
			$txt = "Unable to retrieve Stores"
			OutputWarning $txt
		}

		Write-Verbose "$(Get-Date): `t`t`t`tProcessing Options Tab"
		If($MSWord -or $PDF)
		{
			WriteWordLine 0 0 "Options"
			[System.Collections.Hashtable[]] $ScriptInformation = @()
			$ScriptInformation += @{ Data = "Active Directory"; Value = ""; }
			$ScriptInformation += @{ Data = "     Automate computer account password updates"; Value = $adMaxPasswordAgeEnabled; }
			If($Server.adMaxPasswordAgeEnabled)
			{
				$ScriptInformation += @{ Data = "     Days between password updates"; Value = $Server.adMaxPasswordAge; }
			}
			$Table = AddWordTable -Hashtable $ScriptInformation `
			-Columns Data,Value `
			-List `
			-Format $wdTableGrid `
			-AutoFit $wdAutoFitContent;

			## IB - Set the header row format
			SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

			$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

			FindWordDocumentEnd
			$Table = $Null
			WriteWordLine 0 0 ""
		}
		ElseIf($Text)
		{
			Line 1 "Options"
			Line 2 "Active directory"
			Line 3 "Automate computer account password updates: " $adMaxPasswordAgeEnabled
			If($Server.adMaxPasswordAgeEnabled)
			{
				Line 3 "Days between password updates: " $Server.adMaxPasswordAge
			}
		}
		ElseIf($HTML)
		{
			$rowdata = @()
			$columnHeaders = @("Active directory",($htmlsilver -bor $htmlbold),"",$htmlwhite)
			$rowdata += @(,('     Automate computer account password updates',($htmlsilver -bor $htmlbold),$adMaxPasswordAgeEnabled,$htmlwhite))
			If($Server.adMaxPasswordAgeEnabled)
			{
				$rowdata += @(,('     Days between password updates',($htmlsilver -bor $htmlbold),$Server.adMaxPasswordAge,$htmlwhite))
			}

			$msg = "Options"
			FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
			WriteHTMLLine 0 0 ""
		}
		
		#create array for appendix A
		
		Write-Verbose "$(Get-Date): `t`t`t`t`tGather Advanced server info for Appendix A and B"
		$obj1 = New-Object -TypeName PSObject
		$obj2 = New-Object -TypeName PSObject
		
		$obj1 | Add-Member -MemberType NoteProperty -Name ServerName              -Value $Server.serverName
		$obj1 | Add-Member -MemberType NoteProperty -Name ThreadsPerPort          -Value $Server.threadsPerPort
		$obj1 | Add-Member -MemberType NoteProperty -Name BuffersPerThread        -Value $Server.buffersPerThread
		$obj1 | Add-Member -MemberType NoteProperty -Name ServerCacheTimeout      -Value $Server.serverCacheTimeout
		$obj1 | Add-Member -MemberType NoteProperty -Name LocalConcurrentIOLimit  -Value $Server.localConcurrentIoLimit
		$obj1 | Add-Member -MemberType NoteProperty -Name RemoteConcurrentIOLimit -Value $Server.remoteConcurrentIoLimit
		$obj1 | Add-Member -MemberType NoteProperty -Name maxTransmissionUnits    -Value $Server.maxTransmissionUnits
		$obj1 | Add-Member -MemberType NoteProperty -Name IOBurstSize             -Value $Server.ioBurstSize
		$obj1 | Add-Member -MemberType NoteProperty -Name NonBlockingIOEnabled    -Value $Server.nonBlockingIoEnabled

		$obj2 | Add-Member -MemberType NoteProperty -Name ServerName              -Value $Server.serverName
		$obj2 | Add-Member -MemberType NoteProperty -Name BootPauseSeconds        -Value $Server.bootPauseSeconds
		$obj2 | Add-Member -MemberType NoteProperty -Name MaxBootSeconds          -Value $Server.maxBootSeconds
		$obj2 | Add-Member -MemberType NoteProperty -Name MaxBootDevicesAllowed   -Value $Server.maxBootDevicesAllowed
		$obj2 | Add-Member -MemberType NoteProperty -Name vDiskCreatePacing       -Value $Server.vDiskCreatePacing
		$obj2 | Add-Member -MemberType NoteProperty -Name LicenseTimeout          -Value $Server.licenseTimeout
		
		$Script:AdvancedItems1 +=  $obj1
		$Script:AdvancedItems2 +=  $obj2
		
		#advanced button at the bottom
		Write-Verbose "$(Get-Date): `t`t`t`tProcessing Server Advanced button"
		Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Server Tab"
		If($MSWord -or $PDF)
		{
			WriteWordLine 4 0 "Advanced"
			WriteWordLine 0 0 "Server"
			[System.Collections.Hashtable[]] $ScriptInformation = @()
			$ScriptInformation += @{ Data = "Threads per port"; Value = $Server.threadsPerPort; }
			$ScriptInformation += @{ Data = "Buffers per thread"; Value = $Server.buffersPerThread; }
			$ScriptInformation += @{ Data = "Server cache timeout"; Value = "$($Server.serverCacheTimeout) (seconds)"; }
			$ScriptInformation += @{ Data = "Local concurrent I/O limit"; Value = "$($Server.localConcurrentIoLimit) (transactions)"; }
			$ScriptInformation += @{ Data = "Remote concurrent I/O limit"; Value = "$($Server.remoteConcurrentIoLimit) (transactions)"; }
			$Table = AddWordTable -Hashtable $ScriptInformation `
			-Columns Data,Value `
			-List `
			-Format $wdTableGrid `
			-AutoFit $wdAutoFitContent;

			## IB - Set the header row format
			SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

			$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

			FindWordDocumentEnd
			$Table = $Null
			WriteWordLine 0 0 ""
		}
		ElseIf($Text)
		{
			Line 1 "Advanced"
			Line 2 "Server"
			Line 3 "Threads per port`t`t: " $Server.threadsPerPort
			Line 3 "Buffers per thread`t`t: " $Server.buffersPerThread
			Line 3 "Server cache timeout`t`t: $($Server.serverCacheTimeout) (seconds)"
			Line 3 "Local concurrent I/O limit`t: $($Server.localConcurrentIoLimit) (transactions)"
			Line 3 "Remote concurrent I/O limit`t: $($Server.remoteConcurrentIoLimit) (transactions)"
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 3 0 "Advanced"
			$rowdata = @()
			$columnHeaders = @("Threads per port",($htmlsilver -bor $htmlbold),"$($Server.threadsPerPort)",$htmlwhite)
			$rowdata += @(,('Buffers per thread',($htmlsilver -bor $htmlbold),$Server.buffersPerThread,$htmlwhite))
			$rowdata += @(,('Server cache timeout',($htmlsilver -bor $htmlbold),"$($Server.serverCacheTimeout) (seconds)",$htmlwhite))
			$rowdata += @(,('Local concurrent I/O limit',($htmlsilver -bor $htmlbold),"$($Server.localConcurrentIoLimit) (transactions)",$htmlwhite))
			$rowdata += @(,('Remote concurrent I/O limit',($htmlsilver -bor $htmlbold),"$($Server.remoteConcurrentIoLimit) (transactions)",$htmlwhite))

			$msg = "Server"
			FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
			WriteHTMLLine 0 0 ""
		}

		Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Network Tab"
		If($MSWord -or $PDF)
		{
			WriteWordLine 0 0 "Network"
			[System.Collections.Hashtable[]] $ScriptInformation = @()
			$ScriptInformation += @{ Data = "Ethernet MTU"; Value = "$($Server.maxTransmissionUnits) (bytes)"; }
			$ScriptInformation += @{ Data = "I/O burst size"; Value = "$($Server.ioBurstSize) (KB)"; }
			$ScriptInformation += @{ Data = "Enable non-blocking I/O for network communications"; Value = $nonBlockingIoEnabled; }
			$Table = AddWordTable -Hashtable $ScriptInformation `
			-Columns Data,Value `
			-List `
			-Format $wdTableGrid `
			-AutoFit $wdAutoFitContent;

			## IB - Set the header row format
			SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

			$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

			FindWordDocumentEnd
			$Table = $Null
			WriteWordLine 0 0 ""
		}
		ElseIf($Text)
		{
			Line 2 "Network"
			Line 3 "Ethernet MTU`t`t`t: $($Server.maxTransmissionUnits) (bytes)"
			Line 3 "I/O burst size`t`t`t: $($Server.ioBurstSize) (KB)"
			Line 3 "Enable non-blocking I/O for network communications: " $nonBlockingIoEnabled
		}
		ElseIf($HTML)
		{
			$rowdata = @()
			$columnHeaders = @("Ethernet MTU",($htmlsilver -bor $htmlbold),"$($Server.maxTransmissionUnits) (bytes)",$htmlwhite)
			$rowdata += @(,('I/O burst size',($htmlsilver -bor $htmlbold),"$($Server.ioBurstSize) (KB)",$htmlwhite))
			$rowdata += @(,('Enable non-blocking I/O for network communications',($htmlsilver -bor $htmlbold),$nonBlockingIoEnabled,$htmlwhite))

			$msg = "Network"
			FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
			WriteHTMLLine 0 0 ""
		}

		Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Pacing Tab"
		If($MSWord -or $PDF)
		{
			WriteWordLine 0 0 "Pacing"
			[System.Collections.Hashtable[]] $ScriptInformation = @()
			$ScriptInformation += @{ Data = "Boot pause seconds"; Value = $Server.bootPauseSeconds; }
			$ScriptInformation += @{ Data = "Maximum boot time"; Value = "$($MaxBootTime) (minutes:seconds)"; }
			$ScriptInformation += @{ Data = "Maximum devices booting"; Value = "$($Server.maxBootDevicesAllowed) devices"; }
			$ScriptInformation += @{ Data = "vDisk Creation pacing"; Value = "$($Server.vDiskCreatePacing) milliseconds"; }
			$Table = AddWordTable -Hashtable $ScriptInformation `
			-Columns Data,Value `
			-List `
			-Format $wdTableGrid `
			-AutoFit $wdAutoFitContent;

			## IB - Set the header row format
			SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

			$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

			FindWordDocumentEnd
			$Table = $Null
			WriteWordLine 0 0 ""
		}
		ElseIf($Text)
		{
			Line 2 "Pacing"
			Line 3 "Boot pause seconds`t`t: " $Server.bootPauseSeconds
			Line 3 "Maximum boot time`t`t: $($MaxBootTime) (minutes:seconds)"
			Line 3 "Maximum devices booting`t`t: $($Server.maxBootDevicesAllowed) devices"
			Line 3 "vDisk Creation pacing`t`t: $($Server.vDiskCreatePacing) milliseconds"
		}
		ElseIf($HTML)
		{
			$rowdata = @()
			$columnHeaders = @("Boot pause seconds",($htmlsilver -bor $htmlbold),"$($Server.bootPauseSeconds)",$htmlwhite)
			$rowdata += @(,('Maximum boot time',($htmlsilver -bor $htmlbold),"$($MaxBootTime) (minutes:seconds)",$htmlwhite))
			$rowdata += @(,('Maximum devices booting',($htmlsilver -bor $htmlbold),"$($Server.maxBootDevicesAllowed) devices",$htmlwhite))
			$rowdata += @(,('vDisk Creation pacing',($htmlsilver -bor $htmlbold),"$($Server.vDiskCreatePacing) milliseconds",$htmlwhite))

			$msg = "Pacing"
			FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
			WriteHTMLLine 0 0 ""
		}

		Write-Verbose "$(Get-Date): `t`t`t`t`tProcessing Device Tab"
		If($MSWord -or $PDF)
		{
			WriteWordLine 0 0 "Device"
			[System.Collections.Hashtable[]] $ScriptInformation = @()
			$ScriptInformation += @{ Data = "License timeout"; Value = "$($LicenseTimeout) (minutes:seconds)"; }
			$Table = AddWordTable -Hashtable $ScriptInformation `
			-Columns Data,Value `
			-List `
			-Format $wdTableGrid `
			-AutoFit $wdAutoFitContent;

			## IB - Set the header row format
			SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

			$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

			FindWordDocumentEnd
			$Table = $Null
			WriteWordLine 0 0 ""
		}
		ElseIf($Text)
		{
			Line 2 "Device"
			Line 3 "License timeout`t`t`t: $($LicenseTimeout) (minutes:seconds)"
			Line 0 ""
		}
		ElseIf($HTML)
		{
			$rowdata = @()
			$columnHeaders = @("License timeout",($htmlsilver -bor $htmlbold),"$($LicenseTimeout) (minutes:seconds)",$htmlwhite)

			$msg = "Device"
			FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
			WriteHTMLLine 0 0 ""
		}
		
		If($Hardware)
		{
			If(Test-Connection -ComputerName $server.servername -quiet -EA 0)
			{
				GetComputerWMIInfo $server.ServerName
			}
		}
	}
}
#endregion

#region farmviews
Function ProcessFarmViews
{
	#process the farm views now
	Write-Verbose "$(Get-Date): Processing all PVS Farm Views"
	$selection.InsertNewPage()
	WriteWordLine 1 0 "Farm Views"
	$Temp = $PVSSite.siteName
	$FarmViews = Get-PVSFarmView -EA 0 4>$Null
	
	If($? -and $FarmViews -ne $Null)
	{
		ForEach($FarmView in $FarmViews)
		{
			OutputFarmView $FarmView
		}
	}
	ElseIf($? -and $FarmViews -eq $Null)
	{
		$txt = "There are no Farm Views"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Farm Views"
		OutputWarning $txt
	}
}

Function OutputFarmView
{
	Param([object] $FarmView)
	
	Write-Verbose "$(Get-Date): `tProcessing Farm View $($FarmView.farmViewName)"
	Write-Verbose "$(Get-Date): `t`tProcessing General Tab"
	If($MSWord -or $PDF)
	{
		WriteWordLine 2 0 $FarmView.farmViewName
		WriteWordLine 0 0 "View Properties"
		[System.Collections.Hashtable[]] $ScriptInformation = @()
		$ScriptInformation += @{ Data = "Name"; Value = $FarmView.farmViewName; }
		If(![String]::IsNullOrEmpty($FarmView.description))
		{
			$ScriptInformation += @{ Data = "Description"; Value = $FarmView.description; }
		}
		$Table = AddWordTable -Hashtable $ScriptInformation `
		-Columns Data,Value `
		-List `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 0 $FarmView.farmViewName
		Line 1 "View Properties"
		Line 2 "General"
		Line 3 "Name`t`t: " $FarmView.farmViewName
		If(![String]::IsNullOrEmpty($FarmView.description))
		{
			Line 3 "Description`t: " $FarmView.description
		}
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 $FarmView.farmViewName
		WriteHTMLLine 3 0 "View Properties"
		$rowdata = @()
		$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$FarmView.farmViewName,$htmlwhite)
		If(![String]::IsNullOrEmpty($FarmView.description))
		{
			$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$FarmView.description,$htmlwhite))
		}

		$msg = "General"
		FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
		WriteHTMLLine 0 0 ""
	}
	
	Write-Verbose "$(Get-Date): `t`tProcessing Members Tab"
	If($MSWord -or $PDF)
	{
		WriteWordLine 0 0 "Members"
	}
	ElseIf($Text)
	{
		Line 2 "Members"
	}
	ElseIf($HTML)
	{
	}
	#process each target device contained in the farm view
	$Members = Get-PVSDevice -FarmViewID $FarmView.farmViewId -EA 0 4>$Null
	If($? -and $Members -ne $Null)
	{
		OutputViewMembers $Members
	}
	ElseIf($? -and $Members -eq $Null)
	{
		$txt = "There are no Farm View members"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Farm View members"
		OutputWarning $txt
	}
}
#endregion

#region stores
Function ProcessStores
{
	#process the stores now
	Write-Verbose "$(Get-Date): Processing Stores"
	$Stores = Get-PVSStore -EA 0 4>$Null
	
	If($? -and $Stores -ne $Null)
	{
		If($MSWord -or $PDF)
		{
			$selection.InsertNewPage()
			WriteWordLine 1 0 "Stores Properties"
		}
		ElseIf($Text)
		{
			Line 0 ""
			Line 0 "Stores Properties"
		}
		ElseIf($HTML)
		{
			WriteHTMLLine 1 0 "Stores Properties"
		}
		
		ForEach($Store in $Stores)
		{
			OutputStore $Store
		}
	}
	ElseIf($? -and $Stores -eq $Null)
	{
		$txt = "There are no Stores"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Stores"
		OutputWarning $txt
	}
	Write-Verbose "$(Get-Date): "
}

Function OutputStore
{
	Param([object] $Store)
	Write-Verbose "$(Get-Date): `tProcessing Store $($Store.StoreName)"
	Write-Verbose "$(Get-Date): `t`tProcessing General Tab"
	$xStoreOwner = ""
	If([String]::IsNullOrEmpty($Store.siteName))
	{
		$xStoreOwner = "None"
	}
	Else
	{
		$xStoreOwner = $Store.siteName
	}

	If($MSWord -or $PDF)
	{
		WriteWordLine 2 0 $Store.StoreName
		WriteWordLine 0 0 "General"
		[System.Collections.Hashtable[]] $ScriptInformation = @()
		$ScriptInformation += @{ Data = "Name"; Value = $Store.StoreName; }
		If(![String]::IsNullOrEmpty($Store.description))
		{
			$ScriptInformation += @{ Data = "Description"; Value = $Store.description; }
		}
		$ScriptInformation += @{ Data = "Store owner"; Value = $xStoreOwner; }
		$Table = AddWordTable -Hashtable $ScriptInformation `
		-Columns Data,Value `
		-List `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 0 $Store.StoreName
		Line 1 "General"
		Line 2 "Name`t`t: " $Store.StoreName
		If(![String]::IsNullOrEmpty($Store.description))
		{
			Line 2 "Description`t: " $Store.description
		}
		Line 2 "Store owner`t: " $xStoreOwner
		Line 0 ""
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 2 0 $Store.StoreName
		$rowdata = @()
		$columnHeaders = @("Name",($htmlsilver -bor $htmlbold),$Store.StoreName,$htmlwhite)
		If(![String]::IsNullOrEmpty($Store.description))
		{
			$rowdata += @(,('Description',($htmlsilver -bor $htmlbold),$Store.description,$htmlwhite))
		}
		$rowdata += @(,('Store owner',($htmlsilver -bor $htmlbold),$xStoreOwner,$htmlwhite))
		
		$msg = "General"
		FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
		WriteHTMLLine 0 0 ""
	}
	
	Write-Verbose "$(Get-Date): `t`tProcessing Servers Tab"
	#find the servers (and the site) that serve this store
	$Servers = Get-PVSServer -EA 0 4>$Null
	
	If($? -and $Servers -ne $Null)
	{
		$StoreSite = ""
		$StoreServers = @()
		ForEach($Server in $Servers)
		{
			Write-Verbose "$(Get-Date): `t`t`tProcessing Server $($Server.serverName)"
			$ServerStore = Get-PVSServerStore -ServerName $Server.serverName 4>$Null
			If(($? -and $ServerStore -ne $Null) -and ($ServerStore.storeName -eq $Store.StoreName))
			{
				$StoreSite = $Server.siteName
				$StoreServers +=  $Server.serverName
			}
		}	
	}
	ElseIf($? -and $Servers -eq $Null)
	{
		$txt = "There are no Servers"
		OutputWarning $txt
	}
	Else
	{
		$txt = "Unable to retrieve Servers"
		OutputWarning $txt
	}
	
	If($MSWord -or $PDF)
	{
		WriteWordLine 0 0 "Servers"
		[System.Collections.Hashtable[]] $ScriptInformation = @()
		$ScriptInformation += @{ Data = "Site"; Value = $StoreSite; }
		$ScriptInformation += @{ Data = "Servers that provide this store"; Value = $StoreServers[0]; }
		$cnt = -1
		ForEach($StoreServer in $StoreServers)
		{
			$cnt++
			If($cnt -gt 0)
			{
				$ScriptInformation += @{ Data = ""; Value = $StoreServer; }
			}
		}
		
		$Table = AddWordTable -Hashtable $ScriptInformation `
		-Columns Data,Value `
		-List `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 1 "Servers"
		Line 2 "Site: " $StoreSite
		Line 2 "Servers that provide this store: " $StoreServers[0]
		$cnt = -1
		ForEach($StoreServer in $StoreServers)
		{
			$cnt++
			If($cnt -gt 0)
			{
				Line 6 " " $StoreServer
			}
		}
	}
	ElseIf($HTML)
	{
		$rowdata = @()
		$columnHeaders = @("Site",($htmlsilver -bor $htmlbold),$StoreSite,$htmlwhite)
		$rowdata += @(,('Servers that provide this store',($htmlsilver -bor $htmlbold),$StoreServers[0],$htmlwhite))
		$cnt = -1
		ForEach($StoreServer in $StoreServers)
		{
			$cnt++
			If($cnt -gt 0)
			{
				$rowdata += @(,('',($htmlsilver -bor $htmlbold),$StoreServer,$htmlwhite))
			}
		}
		
		$msg = "Servers"
		FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
		WriteHTMLLine 0 0 ""
	}

	Write-Verbose "$(Get-Date): `t`tProcessing Paths Tab"
	If($MSWord -or $PDF)
	{
		WriteWordLine 0 0 "Paths"
		[System.Collections.Hashtable[]] $ScriptInformation = @()
		$ScriptInformation += @{ Data = "Default store path"; Value = $Store.path; }
		$ScriptInformation += @{ Data = "Server to run vDisk updates for this site"; Value = $PVSSite.diskUpdateServerName; }
		If(![String]::IsNullOrEmpty($Store.cachePath))
		{
			$WCPaths = $Store.cachePath
			$ScriptInformation += @{ Data = "Default write-cache paths"; Value = $WCPaths[0]; }
			$cnt = -1
			ForEach($WCPath in $WCPaths)
			{
				$cnt++
				If($cnt -gt 0)
				{
					$ScriptInformation += @{ Data = ""; Value = $WCPath; }	
				}
			}
		}
		Else
		{
			$ScriptInformation += @{ Data = "Default store path"; Value = "<none>"; }
		}
		$Table = AddWordTable -Hashtable $ScriptInformation `
		-Columns Data,Value `
		-List `
		-Format $wdTableGrid `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format
		SetWordCellFormat -Collection $Table.Columns.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
		WriteWordLine 0 0 ""
	}
	ElseIf($Text)
	{
		Line 1 "Paths"
		Line 2 "Default store path: " $Store.path
		If(![String]::IsNullOrEmpty($Store.cachePath))
		{
			Line 2 "Default write-cache paths: "
			$WCPaths = $Store.cachePath
			ForEach($WCPath in $WCPaths)
			{
				Line 3 $WCPaths		
			}
		}
		Else
		{
			Line 2 "Default write-cache paths: <none>"
		}
	}
	ElseIf($HTML)
	{
		$rowdata = @()
		$columnHeaders = @("Default store path",($htmlsilver -bor $htmlbold),$Store.path,$htmlwhite)
		If(![String]::IsNullOrEmpty($Store.cachePath))
		{
			$WCPaths = $Store.cachePath
			$rowdata += @(,('Default write-cache paths',($htmlsilver -bor $htmlbold),$WCPaths[0],$htmlwhite))
			$cnt = -1
			ForEach($WCPath in $WCPaths)
			{
				$cnt++
				If($cnt -gt 0)
				{
					$ScriptInformation += @{ Data = ""; Value = $WCPath; }	
				}
			}
		}
		Else
		{
			$rowdata += @(,('Default write-cache paths',($htmlsilver -bor $htmlbold),"none",$htmlwhite))
		}
		
		$msg = "Paths"
		FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
		WriteHTMLLine 0 0 ""
	}
}
#endregion

#region Appendix A and B
Function ProcessAppendixA
{
	OutputAppendixA
}

Function OutputAppendixA
{
	Write-Verbose "$(Get-Date): Create Appendix A Advanced Server Items (Server/Network)"
	Write-Verbose "$(Get-Date): `t`tAdd Advanced Server Items table to doc"
	If($MSWord -or $PDF)
	{
		$selection.InsertNewPage()
		WriteWordLine 1 0 "Appendix A - Advanced Server Items (Server/Network)"
		## Create an array of hashtables to store our services
		[System.Collections.Hashtable[]] $ItemsWordTable = @();
		## Seed the row index from the second row
		[int] $CurrentServiceIndex = 2;
	}
	ElseIf($Text)
	{
		Line 0 ""
		Line 0 "Appendix A - Advanced Server Items (Server/Network)"
		Line 0 ""
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 1 0 "Appendix A - Advanced Server Items (Server/Network)"
		$rowdata = @()
	}

	ForEach($Item in $Script:AdvancedItems1)
	{
		If($MSWord -or $PDF)
		{
			## Add the required key/values to the hashtable
			$WordTableRowHash = @{ 
			ServerName = $Item.serverName; 
			ThreadsperPort = $Item.threadsPerPort; 
			BuffersperThread = $Item.buffersPerThread; 
			ServerCacheTimeout = $Item.serverCacheTimeout; 
			LocalConcurrentIOLimit = $Item.localConcurrentIoLimit; 
			RemoteConcurrentIOLimit = $Item.remoteConcurrentIoLimit; 
			EthernetMTU = $Item.maxTransmissionUnits; 
			IOBurstSize = $Item.ioBurstSize; 
			EnableNonblockingIO = $Item.nonBlockingIoEnabled}

			## Add the hash to the array
			$ItemsWordTable += $WordTableRowHash;

			$CurrentServiceIndex++;
		}
		ElseIf($Text)
		{
			Line 1 "Server Name`t`t`t: " $Item.serverName
			Line 1 "Threads per Port`t`t: " $Item.threadsPerPort
			Line 1 "Buffers per Thread`t`t: " $Item.buffersPerThread
			Line 1 "Server Cache Timeout`t`t: " $Item.serverCacheTimeout
			Line 1 "Local Concurrent IO Limit`t: " $Item.localConcurrentIoLimit
			Line 1 "Remote Concurrent IO Limit`t: " $Item.remoteConcurrentIoLimit
			Line 1 "Ethernet MTU`t`t`t: " $Item.maxTransmissionUnits
			Line 1 "IO Burst Size`t`t`t: " $Item.ioBurstSize
			Line 1 "Enable Non-blocking IO`t`t: " $Item.nonBlockingIoEnabled
			Line 0 ""
		}
		ElseIf($HTML)
		{
			$rowdata += @(,(
			$Item.serverName,$htmlwhite,
			$Item.threadsPerPort,$htmlwhite,
			$Item.buffersPerThread,$htmlwhite,
			$Item.serverCacheTimeout,$htmlwhite,
			$Item.localConcurrentIoLimit,$htmlwhite,
			$Item.remoteConcurrentIoLimit,$htmlwhite,
			$Item.maxTransmissionUnits,$htmlwhite,
			$Item.ioBurstSize,$htmlwhite,
			$Item.nonBlockingIoEnabled,$htmlwhite))
		}
	}

	If($MSWord -or $PDF)
	{
		## Add the table to the document, using the hashtable (-Alt is short for -AlternateBackgroundColor!)
		$Table = AddWordTable -Hashtable $ItemsWordTable `
		-Columns ServerName, ThreadsperPort, BuffersperThread, ServerCacheTimeout, LocalConcurrentIOLimit, RemoteConcurrentIOLimit, EthernetMTU, IOBurstSize, EnableNonblockingIO `
		-Headers "Server Name", "Threads per Port", "Buffers per Thread", "Server Cache Timeout", "Local Concurrent IO Limit", "Remote Concurrent IO Limit", "Ethernet MTU", "IO Burst Size", "Enable Non-blocking IO" `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format after the SetWordTableAlternateRowColor function as it will paint the header row!
		SetWordCellFormat -Collection $Table.Rows.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$TableRange = $Null
		$Table = $Null
	}
	ElseIf($HTML)
	{
		$columnHeaders = @(
		'Server Name',($htmlsilver -bor $htmlbold),
		'Threads per Port',($htmlsilver -bor $htmlbold),
		'Buffers per Thread',($htmlsilver -bor $htmlbold),
		'Server Cache Timeout',($htmlsilver -bor $htmlbold),
		'Local Concurrent IO Limit',($htmlsilver -bor $htmlbold),
		'Remote Concurrent IO Limit',($htmlsilver -bor $htmlbold),
		'Ethernet MTU',($htmlsilver -bor $htmlbold),
		'IO Burst Size',($htmlsilver -bor $htmlbold),
		'Enable Non-blocking IO',($htmlsilver -bor $htmlbold))
		
		$msg = ""
		FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
		WriteHTMLLine 0 0 ""
	}
	
	Write-Verbose "$(Get-Date): `tFinished Creating Appendix A - Advanced Server Items (Server/Network)"
	Write-Verbose "$(Get-Date): "
}

Function ProcessAppendixB
{
	OutputAppendixB
}

Function OutputAppendixB
{
	Write-Verbose "$(Get-Date): Create Appendix B Advanced Server Items (Pacing/Device)"
	Write-Verbose "$(Get-Date): `t`tAdd Advanced Server Items table to doc"

	If($MSWord -or $PDF)
	{
		$selection.InsertNewPage()
		WriteWordLine 1 0 "Appendix B - Advanced Server Items (Pacing/Device)"
		## Create an array of hashtables to store our services
		[System.Collections.Hashtable[]] $ItemsWordTable = @();
		## Seed the row index from the second row
		[int] $CurrentServiceIndex = 2;
	}
	ElseIf($Text)
	{
		Line 0 "Appendix B - Advanced Server Items (Pacing/Device)"
		Line 0 ""
	}
	ElseIf($HTML)
	{
		WriteHTMLLine 1 0 "Appendix B - Advanced Server Items (Pacing/Device)"
		$rowdata = @()
	}

	ForEach($Item in $Script:AdvancedItems2)
	{
		If($MSWord -or $PDF)
		{
			## Add the required key/values to the hashtable
			$WordTableRowHash = @{ 
			ServerName = $Item.serverName; 
			BootPauseSeconds = $Item.bootPauseSeconds; 
			MaximumBootTime = $Item.maxBootSeconds; 
			MaximumDevicesBooting = $Item.maxBootDevicesAllowed; 
			vDiskCreationPacing = $Item.vDiskCreatePacing; 
			LicenseTimeout = $Item.licenseTimeout}

			## Add the hash to the array
			$ItemsWordTable += $WordTableRowHash;

			$CurrentServiceIndex++;
		}
		ElseIf($Text)
		{
			Line 1 "Server Name`t`t: " $Item.serverName
			Line 1 "Boot Pause Seconds`t: " $Item.bootPauseSeconds
			Line 1 "Maximum Boot Time`t: " $Item.maxBootSeconds
			Line 1 "Maximum Devices Booting`t: " $Item.maxBootDevicesAllowed
			Line 1 "vDisk Creation Pacing`t: " $Item.vDiskCreatePacing
			Line 1 "License Timeout`t`t: " $Item.licenseTimeout
			Line 0 ""
		}
		ElseIf($HTML)
		{
			$rowdata += @(,(
			$Item.serverName,$htmlwhite,
			$Item.bootPauseSeconds,$htmlwhite,
			$Item.maxBootSeconds,$htmlwhite,
			$Item.maxBootDevicesAllowed,$htmlwhite,
			$Item.vDiskCreatePacing,$htmlwhite,
			$Item.licenseTimeout,$htmlwhite))
		}
	}

	If($MSWord -or $PDF)
	{
		## Add the table to the document, using the hashtable (-Alt is short for -AlternateBackgroundColor!)
		$Table = AddWordTable -Hashtable $ItemsWordTable `
		-Columns ServerName, BootPauseSeconds, MaximumBootTime, MaximumDevicesBooting, vDiskCreationPacing, LicenseTimeout `
		-Headers "Server Name", "Boot Pause Seconds", "Maximum Boot Time", "Maximum Devices Booting", "vDisk Creation Pacing", "License Timeout" `
		-AutoFit $wdAutoFitContent;

		## IB - Set the header row format after the SetWordTableAlternateRowColor function as it will paint the header row!
		SetWordCellFormat -Collection $Table.Rows.Item(1).Cells -Bold -BackgroundColor $wdColorGray15;

		$Table.Rows.SetLeftIndent($Indent0TabStops,$wdAdjustProportional)

		FindWordDocumentEnd
		$Table = $Null
	}
	ElseIf($HTML)
	{
		$columnHeaders = @(
		'Server Name',($htmlsilver -bor $htmlbold),
		'Boot Pause Seconds',($htmlsilver -bor $htmlbold),
		'Maximum Boot Time',($htmlsilver -bor $htmlbold),
		'Maximum Devices Booting',($htmlsilver -bor $htmlbold),
		'vDisk Creation Pacing',($htmlsilver -bor $htmlbold),
		'License Timeout',($htmlsilver -bor $htmlbold))
		
		$msg = ""
		FormatHTMLTable $msg "auto" -rowArray $rowdata -columnArray $columnHeaders
		WriteHTMLLine 0 0 ""
	}

	Write-Verbose "$(Get-Date): `tFinished Creating Appendix B - Advanced Server Items (Pacing/Device)"
	Write-Verbose "$(Get-Date): "
}
#endregion

#region ClearPVSConnection
Function ClearPVSConnection
{
	#if the script created a remote connection to a PVS server, remove the connection
	If($Script:Remoting)
	{
		Write-Verbose "$(Get-Date): Removing connection to PVS Server $($AdminAddress)"
		Clear-PVSConnection 4>$Null
	}
}
#endregion

#region script core
#Script begins

ProcessScriptSetup

###REPLACE AFTER THIS SECTION WITH YOUR SCRIPT###

Write-Verbose "$(Get-Date): Start writing report data"

ProcessFarm

ProcessSites

ProcessFarmViews

ProcessStores

ProcessAppendixA

ProcessAppendixB

###REPLACE BEFORE THIS SECTION WITH YOUR SCRIPT###
#endregion

#region finish script
Write-Verbose "$(Get-Date): Finishing up document"
#end of document processing

###Change the two lines below for your script###
$AbstractTitle = "Citrix Provisioning Services Inventory"
$SubjectTitle = "Citrix Provisioning Services Inventory"

UpdateDocumentProperties $AbstractTitle $SubjectTitle

ProcessDocumentOutput

ClearPVSConnection

Write-Verbose "$(Get-Date): Script has completed"
Write-Verbose "$(Get-Date): "

#http://poshtips.com/measuring-elapsed-time-in-powershell/
Write-Verbose "$(Get-Date): Script started: $($Script:StartTime)"
Write-Verbose "$(Get-Date): Script ended: $(Get-Date)"
$runtime = $(Get-Date) - $Script:StartTime
$Str = [string]::format("{0} days, {1} hours, {2} minutes, {3}.{4} seconds", `
	$runtime.Days, `
	$runtime.Hours, `
	$runtime.Minutes, `
	$runtime.Seconds,
	$runtime.Milliseconds)
Write-Verbose "$(Get-Date): Elapsed time: $($Str)"
$runtime = $Null
$Str = $Null
$ErrorActionPreference = $SaveEAPreference
#endregion
# SIG # Begin signature block
# MIIgCgYJKoZIhvcNAQcCoIIf+zCCH/cCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU19zkGem89DVr9qC7VVOAgOlK
# kxygghtxMIIDtzCCAp+gAwIBAgIQDOfg5RfYRv6P5WD8G/AwOTANBgkqhkiG9w0B
# AQUFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMDYxMTEwMDAwMDAwWhcNMzExMTEwMDAwMDAwWjBlMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3Qg
# Q0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCtDhXO5EOAXLGH87dg
# +XESpa7cJpSIqvTO9SA5KFhgDPiA2qkVlTJhPLWxKISKityfCgyDF3qPkKyK53lT
# XDGEKvYPmDI2dsze3Tyoou9q+yHyUmHfnyDXH+Kx2f4YZNISW1/5WBg1vEfNoTb5
# a3/UsDg+wRvDjDPZ2C8Y/igPs6eD1sNuRMBhNZYW/lmci3Zt1/GiSw0r/wty2p5g
# 0I6QNcZ4VYcgoc/lbQrISXwxmDNsIumH0DJaoroTghHtORedmTpyoeb6pNnVFzF1
# roV9Iq4/AUaG9ih5yLHa5FcXxH4cDrC0kqZWs72yl+2qp/C3xag/lRbQ/6GW6whf
# GHdPAgMBAAGjYzBhMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0G
# A1UdDgQWBBRF66Kv9JLLgjEtUYunpyGd823IDzAfBgNVHSMEGDAWgBRF66Kv9JLL
# gjEtUYunpyGd823IDzANBgkqhkiG9w0BAQUFAAOCAQEAog683+Lt8ONyc3pklL/3
# cmbYMuRCdWKuh+vy1dneVrOfzM4UKLkNl2BcEkxY5NM9g0lFWJc1aRqoR+pWxnmr
# EthngYTffwk8lOa4JiwgvT2zKIn3X/8i4peEH+ll74fg38FnSbNd67IJKusm7Xi+
# fT8r87cmNW1fiQG2SVufAQWbqz0lwcy2f8Lxb4bG+mRo64EtlOtCt/qMHt1i8b5Q
# Z7dsvfPxH2sMNgcWfzd8qVttevESRmCD1ycEvkvOl77DZypoEd+A5wwzZr8TDRRu
# 838fYxAe+o0bJW1sj6W3YQGx0qMmoRBxna3iw/nDmVG3KwcIzi7mULKn+gpFL6Lw
# 8jCCBTAwggQYoAMCAQICEAQJGBtf1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAw
# ZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBS
# b290IENBMB4XDTEzMTAyMjEyMDAwMFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUg
# U2lnbmluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/
# DhGvZ3cH0wsxSRnP0PtFmbE620T1f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2
# qvCchqXYJawOeSg6funRZ9PG+yknx9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrsk
# acLCUvIUZ4qJRdQtoaPpiCwgla4cSocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/
# 6XzLkqHlOzEcz+ryCuRXu0q16XTmK/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE
# 94zRICUj6whkPlKWwfIPEvTFjg/BougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8
# np+mM6n9Gd8lk9ECAwEAAaOCAc0wggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYD
# VR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0w
# azAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUF
# BzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVk
# SURSb290Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3Js
# ME8GA1UdIARIMEYwOAYKYIZIAYb9bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczov
# L3d3dy5kaWdpY2VydC5jb20vQ1BTMAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7
# KgqjpepxA8Bg+S32ZXUOWDAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823I
# DzANBgkqhkiG9w0BAQsFAAOCAQEAPuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh
# 134LYP3DPQ/Er4v97yrfIFU3sOH20ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63X
# X0R58zYUBor3nEZOXP+QsRsHDpEV+7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPA
# JRHinBRHoXpoaK+bp1wgXNlxsQyPu6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC
# /i9yfhzXSUWW6Fkd6fp0ZGuy62ZD2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG
# /AeB+ova+YJJ92JuoVP6EpQYhS6SkepobEQysmah5xikmmRR7zCCBT8wggQnoAMC
# AQICEAiC+NNp9bm9724Ps8KDdBIwDQYJKoZIhvcNAQELBQAwcjELMAkGA1UEBhMC
# VVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0
# LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2ln
# bmluZyBDQTAeFw0xNTEwMjkwMDAwMDBaFw0xNjExMDIxMjAwMDBaMHwxCzAJBgNV
# BAYTAlVTMQswCQYDVQQIEwJUTjESMBAGA1UEBxMJVHVsbGFob21hMSUwIwYDVQQK
# ExxDYXJsIFdlYnN0ZXIgQ29uc3VsdGluZywgTExDMSUwIwYDVQQDExxDYXJsIFdl
# YnN0ZXIgQ29uc3VsdGluZywgTExDMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEAqCow39iik1NgLgX1WoMWlQgf/t5u7vvauRv1iiY9/ws6SRGeWMqyWZJ6
# 32vZbZjpIPjCyNabRLhCgPXBg8U2GZd3z9zCaPwyjdQWpgbuNnAA/sswtUt+Nm0D
# w9TNjLaSam71aE1EncNh/eOH/kvHmIlVTyiw3DNn3J7bNgWLvVstWRYoF+MvuiG8
# D0Cqh8eLE1j1PIVHUqZkJrG7UZBAFxcf//07cG+CqLuOe+ySjrcfyK1xL/mycNTa
# wY81r364jH2tSmRD25Id6YSgPsLrMk4yhvRXtKDd+bO4nHLDb04Y2UO2CEKKEoX9
# f60j/E2X0Zz0+bjnz6WpCl1GfkqPxwIDAQABo4IBxTCCAcEwHwYDVR0jBBgwFoAU
# WsS5eyoKo6XqcQPAYPkt9mV1DlgwHQYDVR0OBBYEFHkE7x8lmydNQU2oMjTEOiDj
# WxUUMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzB3BgNVHR8E
# cDBuMDWgM6Axhi9odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVk
# LWNzLWcxLmNybDA1oDOgMYYvaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NoYTIt
# YXNzdXJlZC1jcy1nMS5jcmwwTAYDVR0gBEUwQzA3BglghkgBhv1sAwEwKjAoBggr
# BgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAIBgZngQwBBAEw
# gYQGCCsGAQUFBwEBBHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNl
# cnQuY29tME4GCCsGAQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRTSEEyQXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/
# BAIwADANBgkqhkiG9w0BAQsFAAOCAQEAYJ6p9Y6KLrY5EybKshVNlvEvoMO8UM0h
# eW7SzRJtfAqbUsryru5pbcH590zIQ9GEniKg5y/3GrvTu33+l0a6/fj+1rfHGsiz
# qfsKHPv3ZGSBc2+eJ13qvtPR7cJrAEM0g1/qfll5KvGQkvhmocG5OF/h8QsJ2M8K
# S3WCCnDWq7VN+GNK/w7Id0PgyPo9cxg1rdDyosoK7P4+AIdMeg4gLW3Z/wIlfh3O
# 1gZ12IDb9bVmL2uDR25SmKXfaoLsqyL4/MG6rPT9G7Yuh8u0ekQBTbT2ERyu5/eC
# 5T2G6Hu1VROOyv8g89etmITdhLrxyybkaq8xPOg329B/v3HM7lUgEjCCBmowggVS
# oAMCAQICEAMBmgI6/1ixa9bV6uYX8GYwDQYJKoZIhvcNAQEFBQAwYjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBDQS0xMB4XDTE0
# MTAyMjAwMDAwMFoXDTI0MTAyMjAwMDAwMFowRzELMAkGA1UEBhMCVVMxETAPBgNV
# BAoTCERpZ2lDZXJ0MSUwIwYDVQQDExxEaWdpQ2VydCBUaW1lc3RhbXAgUmVzcG9u
# ZGVyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAo2Rd/Hyz4II14OD2
# xirmSXU7zG7gU6mfH2RZ5nxrf2uMnVX4kuOe1VpjWwJJUNmDzm9m7t3LhelfpfnU
# h3SIRDsZyeX1kZ/GFDmsJOqoSyyRicxeKPRktlC39RKzc5YKZ6O+YZ+u8/0SeHUO
# plsU/UUjjoZEVX0YhgWMVYd5SEb3yg6Np95OX+Koti1ZAmGIYXIYaLm4fO7m5zQv
# MXeBMB+7NgGN7yfj95rwTDFkjePr+hmHqH7P7IwMNlt6wXq4eMfJBi5GEMiN6ARg
# 27xzdPpO2P6qQPGyznBGg+naQKFZOtkVCVeZVjCT88lhzNAIzGvsYkKRrALA76Tw
# iRGPdwIDAQABo4IDNTCCAzEwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAw
# FgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwggG/BgNVHSAEggG2MIIBsjCCAaEGCWCG
# SAGG/WwHATCCAZIwKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNv
# bS9DUFMwggFkBggrBgEFBQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYA
# IAB0AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkA
# dAB1AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAA
# RABpAGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAA
# UgBlAGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAA
# dwBoAGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4A
# ZAAgAGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkA
# bgAgAGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4wCwYJYIZIAYb9bAMVMB8GA1Ud
# IwQYMBaAFBUAEisTmLKZB+0e36K+Vw0rZwLNMB0GA1UdDgQWBBRhWk0ktkkynUoq
# eRqDS/QeicHKfTB9BgNVHR8EdjB0MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRBc3N1cmVkSURDQS0xLmNybDA4oDagNIYyaHR0cDovL2Ny
# bDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcmwwdwYIKwYB
# BQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20w
# QQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEFzc3VyZWRJRENBLTEuY3J0MA0GCSqGSIb3DQEBBQUAA4IBAQCdJX4bM02yJoFc
# m4bOIyAPgIfliP//sdRqLDHtOhcZcRfNqRu8WhY5AJ3jbITkWkD73gYBjDf6m7Gd
# JH7+IKRXrVu3mrBgJuppVyFdNC8fcbCDlBkFazWQEKB7l8f2P+fiEUGmvWLZ8Cc9
# OB0obzpSCfDscGLTYkuw4HOmksDTjjHYL+NtFxMG7uQDthSr849Dp3GdId0UyhVd
# kkHa+Q+B0Zl0DSbEDn8btfWg8cZ3BigV6diT5VUW8LsKqxzbXEgnZsijiwoc5ZXa
# rsQuWaBh3drzbaJh6YoLbewSGL33VVRAA5Ira8JRwgpIr7DUbuD0FAo6G+OPPcqv
# ao173NhEMIIGzTCCBbWgAwIBAgIQBv35A5YDreoACus/J7u6GzANBgkqhkiG9w0B
# AQUFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMDYxMTEwMDAwMDAwWhcNMjExMTEwMDAwMDAwWjBiMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTEw
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDogi2Z+crCQpWlgHNAcNKe
# VlRcqcTSQQaPyTP8TUWRXIGf7Syc+BZZ3561JBXCmLm0d0ncicQK2q/LXmvtrbBx
# MevPOkAMRk2T7It6NggDqww0/hhJgv7HxzFIgHweog+SDlDJxofrNj/YMMP/pvf7
# os1vcyP+rFYFkPAyIRaJxnCI+QWXfaPHQ90C6Ds97bFBo+0/vtuVSMTuHrPyvAwr
# mdDGXRJCgeGDboJzPyZLFJCuWWYKxI2+0s4Grq2Eb0iEm09AufFM8q+Y+/bOQF1c
# 9qjxL6/siSLyaxhlscFzrdfx2M8eCnRcQrhofrfVdwonVnwPYqQ/MhRglf0HBKIJ
# AgMBAAGjggN6MIIDdjAOBgNVHQ8BAf8EBAMCAYYwOwYDVR0lBDQwMgYIKwYBBQUH
# AwEGCCsGAQUFBwMCBggrBgEFBQcDAwYIKwYBBQUHAwQGCCsGAQUFBwMIMIIB0gYD
# VR0gBIIByTCCAcUwggG0BgpghkgBhv1sAAEEMIIBpDA6BggrBgEFBQcCARYuaHR0
# cDovL3d3dy5kaWdpY2VydC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQG
# CCsGAQUFBwICMIIBVh6CAVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMA
# IABDAGUAcgB0AGkAZgBpAGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMA
# IABhAGMAYwBlAHAAdABhAG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMA
# ZQByAHQAIABDAFAALwBDAFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkA
# bgBnACAAUABhAHIAdAB5ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgA
# IABsAGkAbQBpAHQAIABsAGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUA
# IABpAG4AYwBvAHIAcABvAHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAA
# cgBlAGYAZQByAGUAbgBjAGUALjALBglghkgBhv1sAxUwEgYDVR0TAQH/BAgwBgEB
# /wIBADB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHoweDA6oDig
# NoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9v
# dENBLmNybDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# QXNzdXJlZElEUm9vdENBLmNybDAdBgNVHQ4EFgQUFQASKxOYspkH7R7for5XDStn
# As0wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQEF
# BQADggEBAEZQPsm3KCSnOB22WymvUs9S6TFHq1Zce9UNC0Gz7+x1H3Q48rJcYaKc
# lcNQ5IK5I9G6OoZyrTh4rHVdFxc0ckeFlFbR67s2hHfMJKXzBBlVqefj56tizfuL
# LZDCwNK1lL1eT7EF0g49GqkUW6aGMWKoqDPkmzmnxPXOHXh2lCVz5Cqrz5x2S+1f
# wksW5EtwTACJHvzFebxMElf+X+EevAJdqP77BzhPDcZdkbkPZ0XN1oPt55INjbFp
# jE/7WeAjD9KqrgB87pxCDs+R1ye3Fu4Pw718CqDuLAhVhSK46xgaTfwqIa1JMYNH
# lXdx3LEbS0scEJx3FMGdTy9alQgpECYxggQDMIID/wIBATCBhjByMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBT
# aWduaW5nIENBAhAIgvjTafW5ve9uD7PCg3QSMAkGBSsOAwIaBQCgQDAZBgkqhkiG
# 9w0BCQMxDAYKKwYBBAGCNwIBBDAjBgkqhkiG9w0BCQQxFgQUoXVlwl4gt4bc4W6g
# lJ7KSM8c3HMwDQYJKoZIhvcNAQEBBQAEggEAJVEeNrQvNqRwsMkDvK+Re3zocbtI
# Hs2cD1ZQ107zoqNIgWwf5f7LeLfhNupTJDDnrC43nnhSwvPcdraiCQXQt5p7nCNo
# 5zq8KfVB5qxjCa3Dt4J4X8MohstxkOnqoMQBqC9GudiaJOtTGNLORSnc2hl+cKR0
# xbKRyrBQ41BUoOUGuLjDXKQmiZ3gPRYsntcSEwmG9UvP7n8FdxWtM9EJnkr2ZuYe
# eKXLaA8ksAMFV3oDjff3PP3JMJlC13qL48L9k5z96d5uWIqxuBsd2betb4sbSlnY
# 86NFscGWbrwZwaH+ZKKvFTq90jxgffm1Kq8KZICXOnbyyayDFRzIlHORB6GCAg8w
# ggILBgkqhkiG9w0BCQYxggH8MIIB+AIBATB2MGIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAf
# BgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMQIQAwGaAjr/WLFr1tXq5hfw
# ZjAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG
# 9w0BCQUxDxcNMTUxMjI4MjI1NTI2WjAjBgkqhkiG9w0BCQQxFgQUlNCJlRRg8ESW
# 9WMCg6JHs8rEP28wDQYJKoZIhvcNAQEBBQAEggEAAGjy38fS5QYSVYh0fI6oZ3Nn
# SEwYghF5ZqeNn/awqi2GrfgX8kI0955GE8mr7GpOsROT0D/MA91WNWxWo81dWFh6
# PwNmxi6/adSd1oRaJ3U609Uw/UJR8FpgHH4WlzMUMX+oXz8Ks3Eysz4EmtmqkqjT
# WOSF6JMJAOBsjb3y6gscCvlTlEoIf0zbsBQCgKczFWuQBue2qE26CACCgZ3k4T2X
# ou1z8oxZ2HSRk/RvXpyl7wrz71RCk/ceI8Waix2QMwHNLCmkMQjLn9zKPe3+2p2n
# EQYWRPkPf3Ub2vfR58Ao2cs4cfMJ9vtEvIWhdzypQtVggxaN1R3ixxDLAH7GqA==
# SIG # End signature block
