#
# Module manifest for module 'PLAY'
#
# Generated by: h.hofs
#
# Generated on: 21/11/2020
#

@{
    RootModule           = 'VSI.AD.psm1'
    # Version number of this module.
    ModuleVersion        = '0.0.0.1'

    # Supported PSEditions
    CompatiblePSEditions = @("Core","Desktop")

    # ID used to uniquely identify this module
    GUID                 = '81f33f0d-fc08-4ad0-b1f8-ff6a58d7c3e5'

    # Author of this module
    Author               = 'h.hofs@loginvsi.com', 'h.koelewijn@loginvsi.com'

    # Company or vendor of this module
    CompanyName          = 'LoginVSI'

    # Copyright statement for this module
    Copyright            = '(c) LoginVSI. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Module for Automationg AD actions'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    CmdLetsToExport      = @('*-VSIAD*')
    FunctionsToExport    = @('*-VSIAD*')
    VariablesToExport    = @("VSIAD_*")

}