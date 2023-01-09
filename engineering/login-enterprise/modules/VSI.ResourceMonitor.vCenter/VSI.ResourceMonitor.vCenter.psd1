

@{
    RootModule           = 'VSI.ResourceMonitor.vCenter.psm1'
    # Version number of this module.
    ModuleVersion        = '0.0.0.1'

    # Supported PSEditions
    CompatiblePSEditions = @("Core", "Desktop")

    # ID used to uniquely identify this module
    GUID                 = '2a8339c8-de31-4dae-9844-a70c5ec4e1d0'

    # Author of this module
    Author               = 'h.hofs@loginvsi.com', 'h.koelewijn@loginvsi.com'

    # Company or vendor of this module
    CompanyName          = 'LoginVSI'

    # Copyright statement for this module
    Copyright            = '(c) LoginVSI. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Module for Automationg Horizon View actions'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    CmdLetsToExport      = @('*-VSIVC*')
    FunctionsToExport    = @('*-VSIVC*')
    VariablesToExport    = @("VSIVC_*")

}
