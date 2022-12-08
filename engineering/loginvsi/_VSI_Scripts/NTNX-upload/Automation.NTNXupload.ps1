Function Upload-NTNX {
    ##############################
    #.SYNOPSIS
    #Send results to database with Python
    #
    #.DESCRIPTION
    #Send results to database with Python 
    #
    #.PARAMETER TestName
    #Defines the used testname
    #
    #.PARAMETER Share
    #Location of the Login VSI share
    #
    #
    #.EXAMPLE
    #Upload-NTNX -Config $Config -TestName $TestName -Share $Share
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [System.Object]$Config,
        [string]$TestName,
        [string]$Share

    )
    $configNTNXupload = Get-Content -Path "$PSScriptRoot\config.ntnxupload.json" -Raw | ConvertFrom-Json
    $pythonpath="C:\ProgramData\Anaconda3\python.exe"
    $setpath="C:\ProgramData\Anaconda3;C:\ProgramData\Anaconda3\Library\mingw-w64\bin;C:\ProgramData\Anaconda3\Library\usr\bin;C:\ProgramData\Anaconda3\Library\bin;C:\ProgramData\Anaconda3\Scripts;C:\ProgramData\Anaconda3\bin;%PATH%"
    start-Process cmd.exe -ArgumentList "/K SET PATH=$setpath & $pythonpath $Share\_VSI_Scripts\NTNX-upload\import_loginvsi.py -c $config -r $Share\_VSI_Results\$TestName\$TestName.csv -b $Share\_VSI_Results\$TestName\$TestName-boottime.csv -a $($configNTNXupload.api) -t $($configNTNXupload.token) & exit"
}

Function Upload-Github {
    ##############################
    #.SYNOPSIS
    #Send results to Github repo
    #
    #.DESCRIPTION
    #Send results to Github repo
    #
    #.PARAMETER TestName
    #Defines the used testname
    #
    #.PARAMETER Share
    #Location of the Login VSI share
    #
    #
    #.EXAMPLE
    #Upload-github -Config $Config -Share $Share -TestNameRun $TestNameRun
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param(
        [System.Object]$Config,
        [string]$Resultsfolder,
        [string]$Share,
        [string]$TestNameRun   
    )
    
    $localrepo = $config.localgitrepo
    # copy jpg to local repo
    if ($TestNameRun -eq $($config.TestName)){ 
        Copy-Item -Path "$Share\$Resultsfolder\$TestNameRun\$TestNameRun-CPU.png" -Destination "$localrepo\$TestNameRun-CPU.png" -Force
    }
    Else {
        Copy-Item -Path "$Share\$Resultsfolder\$TestNameRun\$TestNameRun.png" -Destination "$localrepo\$TestNameRun.png" -Force
    }
    # Add, commit and push file to Github
    Start-Sleep -Seconds 3
    start-process cmd.exe -WorkingDirectory "$($localrepo)" -ArgumentList "/c git pull & git add . & git commit -m `"upload $($TestnameRun)`" & git push" -Wait
    start-sleep -Seconds 10
}