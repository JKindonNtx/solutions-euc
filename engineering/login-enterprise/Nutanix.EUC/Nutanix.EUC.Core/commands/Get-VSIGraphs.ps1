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

    Param (
        $TestConfig,
        $OutputFolder,
        $RunNumber,
        $TestName
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
        $BucketName = $TestConfig.test.BucketName
    }

    process {
        if(!($null -eq $RunNumber)){
            # Graph for Single Run
            # Check on Bucketname and build Uri accordingly
            Write-Log -Message "BucketName: $($Bucketname)" -Level Info
            if($BucketName -eq "LoginDocuments"){
                if($TestConfig.Testinfra.SingleNodeTest -eq "true"){
                    # Single Node
                    $PanelID = "83"
                    $OutFile = Join-Path -Path "$($OutputFolder)" -ChildPath "$($TestName)_Run$($RunNumber)_Host_CPU_With_EUX.png"
                } else {
                    $PanelID = "118"
                    $OutFile = Join-Path -Path "$($OutputFolder)" -ChildPath "$($TestName)_Run$($RunNumber)_Cluster_CPU_With_EUX.png"
                }
                $Year = get-date -Format "yyyy"
                $Month = get-date -Format "MM"
                $Comment = ($TestConfig.Target.ImagesToTest[0].Comment).Replace(" ", "_")
                $DocName = ($TestConfig.Test.DocumentName).Replace(" ", "_")
                $Run = "&var-Run=$($TestName)_Run$($RunNumber)"
                $Uri = "$($TestConfig.Testinfra.GrafanaUriDocs)&var-Bucketname=$($BucketName)&var-Year=$($Year)&var-Month=$($Month)&var-DocumentName=$($DocName)&var-Comment=$($Comment)&var-Testname=$($TestName)$($Run)&var-Naming=Comment&from=1672534800000&to=1672538820000&panelId=$($PanelID)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
                Write-Log -Message "Downloading $($OutFile) from Grafana" -Level Info
                try {
                    Invoke-WebRequest -Uri $Uri -outfile $OutFile -ErrorAction Stop
                }
                catch {
                    Write-Log -Message $_ -Level Error
                    #What do we want to do here?
                }
                
            } else {
                if($Bucketname -eq "LoginRegression"){
                    # Post Holiday Task
                } else {
                    Write-Log -Mesage "Invalid Bucket" -Level Warn
                    break
                }
            }
        } else {
            # Graph for Test
            # Graph for Single Run
            # Check on Bucketname and build Uri accordingly
            Write-Log -Message "BucketName: $($Bucketname)" -Level Info
            if($BucketName -eq "LoginDocuments"){
                if($TestConfig.Testinfra.SingleNodeTest -eq "true"){
                    # Single Node
                    $PanelID = "67" 
                    $OutFile = Join-Path -Path "$($OutputFolder)" -ChildPath "$($TestName)_Host_CPU_With_EUX.png"
                } else {
                    $PanelID = "119" 
                    $OutFile = Join-Path -Path "$($OutputFolder)" -ChildPath "$($TestName)_Cluster_CPU_With_EUX.png"
                }
                $Year = get-date -Format "yyyy"
                $Month = get-date -Format "MM"
                $Comment = ($TestConfig.Target.ImagesToTest[0].Comment).Replace(" ", "_")
                $DocName = ($TestConfig.Test.DocumentName).Replace(" ", "_")
                $Run = ""
                for ($i = 1 ; $i -le ($TestConfig.target.ImageIterations) ; $i++)
                {
                        $Run = "$($Run)&var-Run=$($TestName)_Run$($i)"
                }
                $Uri = "$($TestConfig.Testinfra.GrafanaUriDocs)&var-Bucketname=$($BucketName)&var-Year=$($Year)&var-Month=$($Month)&var-DocumentName=$($DocName)&var-Comment=$($Comment)&var-Testname=$($TestName)$($Run)&var-Naming=Comment&from=1672534800000&to=1672538820000&panelId=$($PanelID)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
                Write-Log -Message "Downloading $($OutFile) from Grafana" -Level Info
                try {
                    Invoke-WebRequest -Uri $Uri -outfile $OutFile -ErrorAction Stop
                }
                catch {
                    #What do we want to do here?
                }
                
            } else {
                if($Bucketname -eq "LoginRegression"){
                    # Post Holiday Task
                } else {
                    Write-Log -Message "Invalid Bucket" -Level Warn
                    break
                }
            }
        }

        $File = Get-Item $OutFile
        Return $File.fullname
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
