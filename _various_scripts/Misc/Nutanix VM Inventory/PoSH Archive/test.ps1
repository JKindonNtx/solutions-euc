<#
.Synopsis
   Creates a dummy Word Document
.EXAMPLE
   New-DummyDocument -DocumentName 'TestDoc1' -Path "c:\test\" -Headings 1 -Paragraphs 1 -Keyword "Zebra" 

.EXAMPLE
  New-DummyDocument -DocumentName 'Test Doc 1','Test Doc 2','Test Doc 3' -Path "c:\test\" -Headings 1 -Paragraphs 1 -Keyword "Zebra"
#>
function New-DummyDocument
{
    Param(
        $DocumentName,​
        $Path,
        [int]$Headings,
        [int]$Paragraphs,
        [string]$Keyword)

    # Loop through all of the documents (Usefull if you need to create lots of documents with different names)
    foreach($docname in $DocumentName){
        #Opens up Word            
        $word =  New-Object -ComObject Word.Application
        #Creates a new document (Same as pressing File > New )
        $doc = $word.Documents.Add()
        #Put the cursor at  the top of the page
        $selection = $word.Selection
        #Make the text a heading
        $selection.Style = "Heading 1"
        #Write the name of the document as a heading
        $selection.TypeText($docname)
        #If a Keyword has been specified, add this into the heading. Useful for testing search
        if($Keyword){
            $selection.TypeText(" " + $Keyword);
        }
        #Start a new paragraph
        $selection.TypeParagraph()
        #Allows the creation of multiple headings. Usefull to test large documents
        for($i = 0; $i -lt $Headings; $i++)
        {
            #Set the style to Heading 2
            $selection.Style = "Heading 2"
            #Write out heading 2
            $selection.TypeText("This is Heading $i")
            #Start a new paragraph
            $selection.TypeParagraph()
            #Get some dummy data, and save as a variable. Uses an API on http://loripsum.net/
            $content = Invoke-WebRequest -Uri http://loripsum.net/api/$Pargraphs/plaintext
            #Set the style to Normal
            $selection.Style = "Normal"
            #Processes the text. Turns each paragraph from the API into a paragarph in word
            $textArray = $content.Content.Split("`n")
            for($j = 0; $j -lt $textArray.Length; $j++)
            {
                #Ensures the string has content
                if($textArray[$j].length -gt 0)
                {
                    #Type the paragraph
                    $selection.TypeText($textArray[$j])
                    #Start a new paragraph
                    $selection.TypeParagraph()
                }
            }

        }
        #Tests if the path exists, if not creates it
        if((Test-Path $Path) -eq $false){
            New-Item $Path -ItemType directory
            write-host ($Path + ' Created')
        }
        #Saves the document.(same as pressing file > save)
        $doc.SaveAs([ref]"$Path\$docname.docx")
        #Closes word
        $word.Quit()
    }
   