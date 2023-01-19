
@{
    RootModule           = 'VSI.LoginEnterprise.psm1'
    # Version number of this module.
    ModuleVersion        = '0.0.0.1'

    # Supported PSEditions
    CompatiblePSEditions = @("Core", "Desktop")

    # ID used to uniquely identify this module
    GUID                 = 'd497ff62-4f63-4c55-9ed5-bec0ff464fd5'

    # Author of this module
    Author               = 'h.hofs@loginvsi.com, h.koelewijn@loginvsi.com, p.bislimi@loginvsi.com'

    # Company or vendor of this module
    CompanyName          = 'LoginVSI'

    # Copyright statement for this module
    Copyright            = '(c) LoginVSI. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Module for Login Enterprise'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    CmdLetsToExport      = @('*-LE*')
    FunctionsToExport    = @('*-LE*')
    VariablesToExport    = @("LE_*")

}
