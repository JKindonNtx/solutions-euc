

@{
    RootModule           = 'VSI.ResourceMonitor.NTNX.psm1'
    # Version number of this module.
    ModuleVersion        = '0.0.0.1'

    # Supported PSEditions
    CompatiblePSEditions = @("Core", "Desktop")

    # ID used to uniquely identify this module
    GUID                 = ''

    # Author of this module
    Author               = 'h.hofs@loginvsi.com', 'h.koelewijn@loginvsi.com', 'sven.huisman@nutanix.com'

    # Company or vendor of this module
    CompanyName          = 'LoginVSI'

    # Copyright statement for this module
    Copyright            = '(c) LoginVSI. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Module for Automating Nutanix actions'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    CmdLetsToExport      = @('*NTNX*')
    FunctionsToExport    = @('*NTNX*')
    VariablesToExport    = @("*NTNX_*")

}
