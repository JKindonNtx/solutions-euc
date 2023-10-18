<#
.SYNOPSIS
    Takes a Solutions Engineering created markdown report and removes all HTML content ready for Documentation Process
.DESCRIPTION
    Aligns markdowndown content to Nutanix MD standards
.PARAMETER mdFile
    Mandatory String. Input path of the source MD file
.PARAMETER mdOutfile
    Optional String. Output path of the new MD file. If empty, will use existing file namee and path and replace with a _nohtml.md extension
.EXAMPLE
    .\FixMDOutput.ps1 -mdFile c:\temp\readme.MD
    Will strip all HTML and dump a c:\temp\readme_nothtml.MD file
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $True)]
    [string]$mdFile, # Markdown input file name

    [Parameter(Mandatory = $false)]
    [string]$mdOutfile # MarkDown Output File
)

#endregion Params

#region Functions
# ============================================================================
# Functions
# ============================================================================
function Write-Screen {
    param
    (
        $Message
    )

    Write-Host "$(get-date -format "dd/MM/yyyy HH:mm") - $($Message)"
} # Write formatted output to screen

#endregion Functions

#region Variables
# ============================================================================
# Variables
# ============================================================================
if (-not $mdOutfile) {
    $mdOutfile = (($mdfile -replace ".MD","") + "_nohtml.MD")
}
if ($mdOutfile -notlike "*.MD") {
    Write-Screen -Message "You must specify a markdown extension of .MD. Setting Markdown file Extension"
    $mdOutfile = ($mdOutfile + ".MD")
}

Write-Screen -Message "Outfile is $($mdOutfile)"

#endregion Variables

#Region Execute
# ============================================================================
# Execute
# ============================================================================

if (Test-Path -Path $mdFile) {
    Write-Screen -Message "MD Path is valid. Proceeding with import"
    $OriginalFile = Get-Content $mdFile
}
else {
    Write-Screen -Message "MD Path at $($mdPath) is not valid"
    Write-Warning $_
    Exit 1
}

#region Remove Nested Images
##------------------------------------------------------------
# Removes Nested Images from Tables. Do this first So that inline HTML images are easier to loop through
##------------------------------------------------------------
$Table_Images_To_Delete = @(
    "<img src=../images/rdainfo.png alt=Remote Display Analytics>",
    "<img src=../images/hardware.png alt=Hardware Specifics>",
    "<img src=../images/broker.png alt=Broker Specifics>",
    "<img src=../images/targetvm.png alt=Target VM Specifics>",
    "<img src=../images/loginenterprise.png alt=Login Enterprise Specifics>",
    "<img src=../images/testicon.png alt=Test Specifics>",
    "<img src=../images/rdainfo.png alt=Remote Display Analytics>",
    "<img src=../images/appsperf.png alt=Applications>"
    "<img src=../images/infrastructure.png alt=Infrastructure Specifics>",
    "<img src=../images/logintimes.png alt=Login Times>"
)

$Reference_To_Convert = "Nested Table Image References"
$TotalCount = $Table_Images_To_Delete.Count
Write-Screen -Message "There are $($TotalCount) $($Reference_To_Convert) to convert"

$CurrentCount = 1
foreach ($_ in $Table_Images_To_Delete) {
    Write-Screen -Message "Processing $($CurrentCount) of $($TotalCount)"
    Write-Screen -Message "The current value is: $($_)"
    $OriginalFile = $OriginalFile -replace $_,""
    $CurrentCount ++
}
#endregion Remove Nested Images

#region Convert Misc Images
##------------------------------------------------------------
# Remove Images without alt="word" and only alt=word. Do this Second
##------------------------------------------------------------
$Misc_HTML_Image_references = @(
    "<img src=../images/Nutanix-Logo.png alt=Nutanix>",
    "<img src=../images/base_image.png alt=Nutanix>"
)

$Reference_To_Convert = "Misc HTML Image Reference"
$TotalCount = $Misc_HTML_Image_references.Count
Write-Screen -Message "There are $($TotalCount) $($Reference_To_Convert) to convert"

$CurrentCount = 1
foreach ($_ in $Misc_HTML_Image_references) {
    Write-Screen -Message "Processing $($CurrentCount) of $($TotalCount)"
    Write-Screen -Message "The current value is: $($_)"
    $OriginalValue = $_
    $OriginalValue = $OriginalValue -replace "<img src=","(" 
    $OriginalValue = $OriginalValue -replace 'style="border: 2px solid #7855FA;">',""
    $OriginalValue = $OriginalValue -replace '\(\../', '[](../'
    $Original_Image_Value = ($OriginalValue | Select-String -Pattern 'alt=([^"]*)').Matches.Groups[1].value
    $OriginalValue = $OriginalValue -replace '\[]',"![$Original_Image_Value]"
    $OriginalValue = $OriginalValue -replace 'alt=','"'
    $OriginalValue = $OriginalValue -replace ">",""
    $OriginalValue = $OriginalValue + '")'
    $NewValue = $OriginalValue
    Write-Screen -Message "The new Value is: $($NewValue)"
    $OriginalFile = $OriginalFile -replace $_ , $NewValue
    $CurrentCount ++
}
#endregion Convert Misc Images

#region Convert HTML Images
##------------------------------------------------------------
# Convert inline Image HTML References. Do this third
##------------------------------------------------------------
$TextMatch = '<img src=../images/.*'
$HTML_Image_References = @()
$HTML_Image_References += $OriginalFile | Select-String -Pattern $TextMatch -AllMatches | ForEach-Object {
    $_.Matches.Value
}

$Reference_To_Convert = "Standard HTML Image References"
$TotalCount = $HTML_Image_References.Count
Write-Screen -Message "There are $($TotalCount) $($Reference_To_Convert) to convert"

$CurrentCount = 1
foreach ($_ in $HTML_Image_References) {
    Write-Screen -Message "Processing $($CurrentCount) of $($TotalCount)"
    Write-Screen -Message "The current value is: $($_)"
    $OriginalValue = $_
    $OriginalValue = $OriginalValue -replace "<img src=","(" 
    $OriginalValue = $OriginalValue -replace 'style="border: 2px solid #7855FA;">',""
    $OriginalValue = $OriginalValue -replace '\(\../', '[](../'
    $Original_Image_Value = ($OriginalValue | Select-String -Pattern 'alt="([^"]*)"').Matches.Groups[1].value
    $OriginalValue = $OriginalValue -replace '\[]',"![$Original_Image_Value]"
    $OriginalValue = $OriginalValue -replace "alt=",""
    $OriginalValue = $OriginalValue + ")"
    $OriginalValue = $OriginalValue -replace '" \)','")'
    $NewValue = $OriginalValue
    Write-Screen -Message "The new Value is: $($NewValue)"
    $OriginalFile = $OriginalFile -replace $_ , $NewValue
    $CurrentCount ++
}
#endregion Convert HTML Images

#region Convert HTML Headers
##------------------------------------------------------------
# Convert inline HTML Headers - Do this fifth
##------------------------------------------------------------
$TextMatch = '## <span style=.*'
$HTML_Heading_References = @()
$HTML_Heading_References += $OriginalFile | Select-String -Pattern $TextMatch -AllMatches | ForEach-Object {
    $_.Matches.Value
}

$Reference_To_Convert = "Level 2 Header References"
$TotalCount = $HTML_Heading_References.Count
Write-Screen -Message "There are $($TotalCount) $($Reference_To_Convert) to convert"

$CurrentCount = 1
foreach ($_ in $HTML_Heading_References) {
    Write-Screen -Message "Processing $($CurrentCount) of $($TotalCount)"
    Write-Screen -Message "The current value is: $($_)"
    $OriginalValue = $_
    $OriginalValue = $OriginalValue -replace '<span style="color:#7855FA">',''
    $OriginalValue = $OriginalValue -replace '</span>',''
    $NewValue = $OriginalValue
    Write-Screen -Message "The new Value is: $($NewValue)"
    $OriginalFile = $OriginalFile -replace $_ , $NewValue
    $CurrentCount ++
}
#endregion Convert HTML Headers

#region Remove Inline HTML in Tables
##------------------------------------------------------------
# Remove inline table HTML
##------------------------------------------------------------
#$TextMatch = '- <span style=".*(?:[^>]*>){2}'
#start of reference removal
$TextMatch = '<span style="color:#[0-9A-F]{6}">'

$HTML_Inline_Table_References_start = @()
$HTML_Inline_Table_References_start += $OriginalFile | Select-String -Pattern $TextMatch -AllMatches | ForEach-Object {
    $_.Matches.Value
}

$Reference_To_Convert = "Inline HTML Table References Start"
$TotalCount = $HTML_Inline_Table_References_start.Count
Write-Screen -Message "There are $($TotalCount) $($Reference_To_Convert) to convert"

$CurrentCount = 1
foreach ($_ in $HTML_Inline_Table_References_start) {
    Write-Screen -Message "Processing $($CurrentCount) of $($TotalCount)"
    Write-Screen -Message "The current value is: $($_)"
    $OriginalValue = $_
    $OriginalValue = $OriginalValue -replace $_ ,''
    $OriginalValue = $OriginalValue -replace 'seconds  ','seconds '
    $NewValue = $OriginalValue
    $OriginalFile = $OriginalFile -replace $_ , $NewValue
    $CurrentCount ++
}

#end of reference removal
$TextMatch = '</span>'
$HTML_Inline_Table_References_end = @()
$HTML_Inline_Table_References_end += $OriginalFile | Select-String -Pattern $TextMatch -AllMatches | ForEach-Object {
    $_.Matches.Value
}

$Reference_To_Convert = "Inline HTML Table References End"
$TotalCount = $HTML_Inline_Table_References_end.Count
Write-Screen -Message "There are $($TotalCount) $($Reference_To_Convert) to convert"

$CurrentCount = 1
foreach ($_ in $HTML_Inline_Table_References_end) {
    Write-Screen -Message "Processing $($CurrentCount) of $($TotalCount)"
    Write-Screen -Message "The current value is: $($_)"
    $OriginalValue = $_
    $OriginalValue = $OriginalValue -replace $_ ,''
    $OriginalValue = $OriginalValue -replace 'seconds  ','seconds '
    $NewValue = $OriginalValue
    $OriginalFile = $OriginalFile -replace $_ , $NewValue
    $CurrentCount ++
}
#endregion Remove Inline HTML in Tables

#region Fix Remaining Misc HTML
Write-Screen -Message "Replacing Start of document Inline HTML"
$OriginalFile = $OriginalFile -replace '<div style="text-align: center;">',"`n"
$OriginalFile = $OriginalFile -replace '<h1>',"`n#"
$OriginalFile = $OriginalFile -replace ' </h1>',"`n"
$OriginalFile = $OriginalFile -replace '</div>',''
$OriginalFile = $OriginalFile -replace "^\s$",'' # Fix Single indented lines

#endregion Fix Remaining Misc HTML
Write-Screen -Message "Replacing Percentage Spaces"
$OriginalFile = $OriginalFile -replace '(?<=\d) %',"%"
#region Fix Percentage layouts

#endregion Fix Percentage layouts

#output content to new file
try {
    Set-Content -Path $mdOutfile -Value $OriginalFile -Force -ErrorAction Stop
    Write-Screen -Message "Successfully wrote output to: $($mdOutfile)"
}
catch {
    Write-Warning "Failed to write output file: $($mdOutfile)"
    Write-Warning $_
    Exit 1
}

#endregion Execute

Exit 0

