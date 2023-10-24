function Get-VSIGraphs {
    <#
        .SYNOPSIS
        Gets the VSI Graphs from Grafana
    
        .DESCRIPTION
        This function will Uget the VSI Graph images from Grafana
        
        .PARAMETER TestConfig
        The test name
    
        .PARAMETER OutputFolder
        The Path to the test results
    #>
    
    
        [CmdletBinding()]
    
        Param(
            $TestConfig,
            $OutputFolder,
            $TestName
        )

        $BucketName = $TestConfig.test.BucketName

        # Graph for Single Run
        # Check on Bucketname and build Uri accordingly

            if($BucketName -eq "NetScaler"){
                $PanelID = "158"
                $OutFile = Join-Path -Path "$($OutputFolder)" -ChildPath "$($TestName)_NetScaler.png"
                $Year = get-date -Format "yyyy"
                $Month = get-date -Format "MM"
                $Comment = ($TestConfig.Test.Comment).Replace(" ", "_")
                $DocName = ($TestConfig.Test.DocumentName).Replace(" ", "_")
                $Uri = "$($TestConfig.General.GrafanaUriNetScaler)&var-Bucketname=$($BucketName)&var-Year=$($Year)&var-Month=$($Month)&var-DocumentName=$($DocName)&var-Comment=$($Comment)&var-Testname=$($TestName)&var-Naming=Comment&from=1672534800000&to=1672538820000&panelId=$($PanelID)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
                Invoke-WebRequest -Uri $Uri -outfile $OutFile
            } else {
                break
            }

        $File = Get-Item $OutFile
        Return $File.fullname
    } 
    