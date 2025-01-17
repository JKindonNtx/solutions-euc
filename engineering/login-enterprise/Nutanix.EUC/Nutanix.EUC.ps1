# Launch Text
write-host @"
 _   _       _              _       
| \ | |     | |            (_)      
|  \| |_   _| |_ __ _ _ __  ___  __ 
| . ` | | | | __/ _` | '_ \| \ \/ / 
| |\  | |_| | || (_| | | | | |>  <  
\_| \_/\__,_|\__\__,_|_| |_|_/_/\_\ 
                                                  
Welcome to the Nutanix Solutions Engineering Test Automation Module
For any issues please see: https://github.com/nutanix-enterprise/solutions-euc/engineering

Current Contributors:

The Big Man       - Kees Baggerman
The Doc           - Sven Huisman
The Aussie        - James Kindon
The Hair          - Jarian Gibson
Mr Ultra          - Dave Brett

"@        

# Common Global Variables
# Add any variables here that you want to have globally available
New-Variable -Name RunPhases -Value 18 -Option ReadOnly
New-Variable -Name PreRunPhases -Value 6 -Option ReadOnly
