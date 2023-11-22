function Get-VSIGraphs {
    <#
        .SYNOPSIS
        Gets the VSI Graphs from Grafana
    
        .DESCRIPTION
        This function will Uget the VSI Graph images from Grafana

    #>

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $false)]$TestConfig,
        [Parameter(Mandatory = $false)][string]$OutputFolder,
        [Parameter(Mandatory = $false)]$RunNumber,
        [Parameter(Mandatory = $false)][string]$TestName,
        [Parameter(Mandatory = $false)][int]$ImageDownloadRetryCount = 5 #How many times to rety the download if it fails due to timeout 
    )

    $BucketName = $TestConfig.test.BucketName
    Write-Log -Message "BucketName: $($Bucketname)" -Level Info

    # Check on Bucketname and build Uri accordingly
    if (!($BucketName -eq "LoginDocuments") -or !($BucketName -eq "LoginRegression")) {
        Write-Log -Message "Invalid Bucket: $($BucketName)" -Level Warn
        break
    }

    $Year = get-date -Format "yyyy"
    $Month = get-date -Format "MM"
    $Comment = ($TestConfig.Target.ImagesToTest[0].Comment).Replace(" ", "_")
    $DocName = ($TestConfig.Test.DocumentName).Replace(" ", "_")

    if (!($null -eq $RunNumber)) {
        if ($TestConfig.Testinfra.SingleNodeTest -eq "true") {
            # Single Node
            $PanelID = "83"
            $OutFile = Join-Path -Path "$($OutputFolder)" -ChildPath "$($TestName)_Run$($RunNumber)_Host_CPU_With_EUX.png"
        }
        else {
            $PanelID = "118"
            $OutFile = Join-Path -Path "$($OutputFolder)" -ChildPath "$($TestName)_Run$($RunNumber)_Cluster_CPU_With_EUX.png"
        }
        $Run = "&var-Run=$($TestName)_Run$($RunNumber)"

        # Build Uri for download
        if ($BucketName -eq "LoginDocuments") {
            #$Uri = "$($TestConfig.Testinfra.GrafanaUriDocs)&var-Bucketname=$($BucketName)&var-Year=$($Year)&var-Month=$($Month)&var-DocumentName=$($DocName)&var-Comment=$($Comment)&var-Testname=$($TestName)$($Run)&var-Naming=Comment&from=1672534800000&to=1672538820000&panelId=$($PanelID)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
            $Uri = "$($TestConfig.Testinfra.GrafanaUriDocs)&var-Bucketname=$($BucketName)&var-Year=$($Year)&var-Month=$($Month)&var-DocumentName=$($DocName)&var-Comment=$($Comment)&var-Testname=$($TestName)$($Run)&var-Naming=Comment&from=1672534800000&to=1672538820000&panelId=$($PanelID)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
        } elseif ($BucketName -eq "LoginRegression" ) {
            # Placeholder for Uri to get Filters for Regression Graph $TestConfig.Testinfra.GrafanaUriRegression
        }

        Write-Log -Message "Downloading $($OutFile) from Grafana" -Level Info
        try {
            Invoke-WebRequest -Uri $Uri -outfile $OutFile -ErrorAction Stop
        }
        catch {
            Write-Log -Message "Download of Image failed. Retrying. Grafana could be busy" -Level Warn
            Write-Log -Message $_ -Level Warn
            $count = 0 # Initialize a counter
            Write-Log -Message "Retrying Download of image $($ImageDownloadRetryCount) times." -Level Info
            while ($count -lt $ImageDownloadRetryCount) {
                $count++
                Write-Log -Message "Retry Iteration $($count) of $($ImageDownloadRetryCount)" -Level Info
                try {
                    Invoke-WebRequest -Uri $Uri -outfile $OutFile -ErrorAction Stop
                }
                catch {
                    Write-Log -Message "Download of Image failed. Retries left: $($ImageDownloadRetryCount - $count)" -Level Warn
                }
            }
            Write-Log -Message "Image Failed to download" -Level Error
        }
    }
    else {
        # Graph for Test
        # Graph for Single Run
        if ($TestConfig.Testinfra.SingleNodeTest -eq "true") {
            # Single Node
            $PanelID = "67" 
            $OutFile = Join-Path -Path "$($OutputFolder)" -ChildPath "$($TestName)_Host_CPU_With_EUX.png"
        }
        else {
            $PanelID = "119" 
            $OutFile = Join-Path -Path "$($OutputFolder)" -ChildPath "$($TestName)_Cluster_CPU_With_EUX.png"
        }

        $Run = ""
        for ($i = 1 ; $i -le ($TestConfig.target.ImageIterations) ; $i++) {
            $Run = "$($Run)&var-Run=$($TestName)_Run$($i)"
        }

        # Build Uri for download
        if ($BucketName -eq "LoginDocuments") {
            #$Uri = "$($TestConfig.Testinfra.GrafanaUriDocs)&var-Bucketname=$($BucketName)&var-Year=$($Year)&var-Month=$($Month)&var-DocumentName=$($DocName)&var-Comment=$($Comment)&var-Testname=$($TestName)$($Run)&var-Naming=Comment&from=1672534800000&to=1672538820000&panelId=$($PanelID)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
            $Uri = "$($TestConfig.Testinfra.GrafanaUriDocs)&var-Bucketname=$($BucketName)&var-Year=$($Year)&var-Month=$($Month)&var-DocumentName=$($DocName)&var-Comment=$($Comment)&var-Testname=$($TestName)$($Run)&var-Naming=Comment&from=1672534800000&to=1672538820000&panelId=$($PanelID)&width=1600&height=800&tz=Atlantic%2FCape_Verde"
        } elseif ($BucketName -eq "LoginRegression" ) {
            # Placeholder for Uri to get Filters for Regression Graph $TestConfig.Testinfra.GrafanaUriRegression
        }

        Write-Log -Message "Downloading $($OutFile) from Grafana" -Level Info
        try {
            Invoke-WebRequest -Uri $Uri -outfile $OutFile -ErrorAction Stop
        }
        catch {
            Write-Log -Message "Download of Image failed. Retrying. Grafana could be busy" -Level Warn
            Write-Log -Message $_ -Level Warn
            $count = 0 # Initialize a counter
            Write-Log -Message "Retrying Download of image $($ImageDownloadRetryCount) times." -Level Info
            while ($count -lt $ImageDownloadRetryCount) {
                $count++
                Write-Log -Message "Retry Iteration $($count) of $($ImageDownloadRetryCount)" -Level Info
                try {
                    Invoke-WebRequest -Uri $Uri -outfile $OutFile -ErrorAction Stop
                }
                catch {
                    Write-Log -Message "Download of Image failed. Retries left: $($ImageDownloadRetryCount - $count)" -Level Warn
                }
            }
            Write-Log -Message "Image Failed to download" -Level Error
        }
    }

    try {
        $File = Get-Item $OutFile -ErrorAction Stop
        Return $File.fullname
    }
    catch {
        Write-Log -Message $_ -Level Error
    }
    
}