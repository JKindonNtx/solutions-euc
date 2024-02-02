# hack2024-d1158

# Nutanix Hackathon 2024 - EUC Benchmark with X-Ray

**Goal: X-Ray scenario with an EUC workload. A workload that simulates a user working with applications. Create a workload with and without MS Office. Metrics from the VMs must be captured and presented in X-Ray.**

Starting points:
- We're using last year's hackathon project "Windows Density Tester" as a starting point.
- We will use Windows Exporter to get metrics from the VMs.

Original Gdoc: https://docs.google.com/document/d/1DnKY1csZlLMbfXEh3ZBtv4Lo_Xzd8m81kiHzjebyAOw/edit#heading=h.siyek0tx4xm3
## Tasks

| What | Comment | Who | Completed |
| ----------- | ----------- | ----------- | ----------- |
| Create X-Ray scenario to run workload |  | Dave, Sven | ![](https://geps.dev/progress/90) |
| Inject optimizations/GPOs | We’re working with workgroup VMs, so any (office) optimizations that we normally apply using GPOs need to be injected using the configure-base.yml |  |  |
| Create TaskT EUC workload | TaskT is open source. It will start and interact with applications. It can record start/stop times that we will send to windows exporter | James, Kees | ![](https://geps.dev/progress/90) |
| Cluster/Host metrics in X-Ray |  | David, Alan |  |
| VM metrics from Windows exporter |  | Sven | ![](https://geps.dev/progress/100) |
| Set # nodes to test on |  | David | |
| Create new scenario for EUC bootstorm testing (optional) |  | | ![](https://geps.dev/progress/90) |

## Apps

The following applications are required on the image used for EUC benchmarking:

| Category | Product | Deployment | Comments |
| --- | --- | --- | --- |
| Productivity | Word | Ansible - image build | |
| Productivity | Excel | Ansible - image build | |
| Productivity | PowerPoint | Ansible - image build | |
| Browser | Microsoft Edge | Ansible - image build | |
| Tooling | 7-zip | Ansible - image build | Performs zip benchmarks |
| PDF | Adobe Reader | Ansible - image build | |
| RPA | TaskT | Ansible - Workload deployment | | 

## Files 

The following files are required to be available on the image for TaskT testing:

| File Type | File Name | Location | Detail |
| --- | --- | --- | --- |
| PDF | Internal_post.pdf | `C:\Scripts\Internal_post.pdf` | Used for PDF browsing |
| PDF | Sven_post.pdf | `C:\Scripts\Sven_post.pdf` | Used for PDF browsing |
| PDF | Hackathon.pdf | `C:\Scripts\Hackathon.pdf` | Used for PDF browsing |
| MP4 | Video.mp4 | `C:\Scripts\Video.mp4` | Used to play a video via Microsoft Edge |
| PPTX | Nutanix Slide Library.pptx | `C:\Scripts\Nutanix Slide Library.pptx` | Used to alter a PowerPoint File |
| PPTX | Nutanix Slide Library Mega.pptx | `C:\Scripts\Nutanix Slide Library Mega.pptx` | Used to load a big PowerPoint file and trawl to the end interactively |
| PS1 | Set-ScreenResolution.ps1 | `C:\Scripts\Set-ScreenResolution.ps1` | Used to Set Screen res to 1920 x 1080 |
| HTML | Nutanix.html | `C:\Scripts\Nutanix.html` | Used to render 15 local tabs with a single web page | 
| REG | Adobe_reg_reader_user.reg | `c:\Scripts\Adobe_reg_reader_user.reg` | Imports Adobe Reader settings to make sure Adobe isn't annoying |
| REG | Turn_on_show_files_extraction.reg | `C:\Scripts\Turn_on_show_files_extraction.reg` | Imports a reg setting to always have the "show extracted files" ticked. We untick this as part of the flow |
| JPG | Nutanix.jpg | `C:\Scripts\Nutanix.jpg` | Imported into the word document |
| ZIP | DemoZip.zip | `C:\Scripts\DemoZip.zip` | Contains files used for measuring zip extraction and compaction |
| PS1 | Cleanup.ps1 | `C:\Scripts\Cleanup.ps1 `| Cleans up after each iteration, deleting content ready for the next run |
| EXE | fio.exe | `C:\Scripts\fio.exe` | |
| FIO | fio_randrd_fix_rate.fio | `C:\Scripts\fio_randrd_fix_rate.fio` | |
| lnk | Taskt.lnk | `C:\Scripts\Taskt.lnk` | Needed on the desktop to ensure correct positioning of items in recordings |

## Task Flow

The following flow occurs via the TaskT execution:

| Task Detail | Type | Change Risk | 
| --- | --- | --- | 
| Launches PowerShell to make sure the resolution is at `1920x1080` | Process Launch | 📗 |
| An adobe reg file is imported `Adobe_reg_reader_user.reg` to make it quiet | Process Launch | 📗 |
| Import a reg file `Turn_on_show_files_extraction.reg` so that Windows Explorer always plays the same with extraction settings | Process Launch | 📗 |
| Launches Excel, Word, PowerPoint, Adobe reader, Edge, 7zip and records the time it takes for each one out to a file | Process Launch/Process Stop | 📗 |
| Extract the contents of `c:\scripts\demozip.zip` to `c:\users\nutanix\documents\ZipExtract`. We output the time taken to the same log file | Native Call | 📗 |
| via 7zip cli, we then zip those files back up into a file called `c:\users\nutanix\Appdata\Roaming\Test\compaction.zip`. We output the time taken to the same log file | Process Launch | 📗 |
| Launch Edge. Stop Edge. This gets past the initial browser update window | Process Launch | 📗 |
| Launch Edge, perform a search for `Who is Dave Brett at Nutanix?` then navigate to Daves blog. Then exit | Recorded Procedure | ⚠️ |
| Copy the file `c:\Scripts\Nutanix.jpg` to `c:\users\nutanix\documents\nutanix.jpg` | Native call | 📗 |
| Create a word instance. Add some data, add the above image, save the file, open the file, replace some text. Save to the desktop, and also save a PDF equivalent | Native Call | 📗 |
| Launch File Explorer, navigate to the desktop folder, compact the `test.docx` and `test.pdf` file into a zip file `Hello.zip`. Then extract that same zip file to a folder called `hello_its_james` on the desktop | Recorded Procedure | ⚠️ |
| Copy the file `c:\scripts\Nutanix Slide Library.pptx` to `c:\users\nutanix\documents\Nutanix Slide Library.pptx` | Native Call | 📗 |
| Launch File Explorer, navigate to the documents folder and open `c:\users\nutanix\documents\Nutanix Slide Library.pptx`. Select slide 2, replace some text, save the file. | Recorded Procedure | ⚠️ |
| Copy 3 PDF files from `c:\scripts\` (`Internal_post.pdf`, `hackathon.pdf`, `sven_post.pdf`) across to `c:\users\nutanix\documents\` | Native Call | 📗 |
| Search the Start Menu and Launch Adobe Reader. Set the window to full screen | Recorded Procedure | ⚠️ |
| Via Adobe Reader, Open each of the three PDF files (`Internal_post.pdf`, `hackathon.pdf`, `sven_post.pdf`) and navigate through to the end of each file and back interactively. Close each PDF Tab, Close Adobe | Recorded Procedure | ⚠️ |
| Play the `c:\Scripts\Video.mp4` video via Microsoft Edge. Terminate the task after a set period | Process Launch/Process Stop | 📗 |
| Launch edge with 15 tabs all point at `C:\Scripts\Nutanix.html`. Wait for 15 seconds, then terminate the edge process | Process Launch/Process Stop | 📗 |
| Copy the `c:\scripts\Nutanix Slide Library Mega.pptx` file to `c:\users\nutanix\documents\Mega\Nutanix Slide Library Mega.pptx` | Native Call | 📗 |
| Execute a 7zip benchmark test | Process Launch | 📗 |
| Launch File Explorer and navigate to the documents\mega folder. Open the mega powerpoint `Nutanix Slide Library Mega.pptx`, then scrolls through 170 slides, selects the last slide as focus. Then gracefully closes. | Recorded Procedure | ⚠️ |
| Cleanup the current run via `C:\Scripts\Cleanup.ps1` | Process Launch | 📗 |
| Wait 60 seconds, and go again | Loop Call | 📗 |

### Pending Additions

-  Microsoft Teams. Job is done, it's a launch, wait, click sign in, terminate job. Recorded because CLI fails with permissions on MSIX packages.
-  fio.exe processing - need to tweak, but job is in place


Potential mini benchmark tests to use in the workload (need to be low impact):
- Jetstream (benchmark from last years project)
- 7zip benchmark ("c:\program files\7-zip\7z.exe b -mmt1” will only use 1 thread)
- fio (with fixed rate and then look at latency)

## Issues/Considerations

-  Be conscious of any changes you make the file system mid-flight, it will impact anything that is pre-recorded. Prefer AppData locations for new/additional items
-  Make sure on anything recorded that you start with nothing, launch, execute, and close gracefully
-  Watch out for input when recorded, the tool does weird things with some text inputs, and also grabbing context of windows when it shouldn't.
-  The tool hates any form of multi-select or grab and drag functions
-  The tool fails on tab keyboard strokes
-  Logging is **c:\users\nutanix\documents\taskt\logs**
-  X-Ray scenario needs to be compressed with 7Zip, it won't work with Windows-native 'Compress to file' explorer option.
  
## Metrics

Cluster/Hosts:
- CPU usage
- Cluster controller IOPS
- Cluster controller latency
- Cluster memory usage
- Average CPU ready time
- Per host CPU usage


UVM:
- App start times
    * Word
    * Excel
    * Powerpoint
    * Edge
    * 7Zip
    * Adobe Reader
- App specific:
    * Time to zip file(s)
    * Time to open large powerpoint
    * Time to perform calculator calculation 
-Mini benchmark results
    * 7Zip (MIPS)
    * Fio (latency)
    * Jetstream (score)

## App Notes

This workload will:
- Launch calc with a custom timer
- Navigate to Scientific view
- Perform calculation: 0.1 n! (factorial), repeating the n! function for the defined amount in global vars
    * This will stress CPU
    * On the machine used to create the workload was about ~8% usage
- Close calc
Baremetal development machine and software information:
- Winver Windows 11 Professional x64 21H2
- Toshiba nVME m.2 KXG60ZNV512G | 16GB DDR4 3200MHz | Intel Core i7-8850H
- Login Enterprise version 4.7.5 Application Xray and Script Editor
Other metadata:
- Last updated 30 November 2021

```c
*/
// Set global vars
double globalIntermittentWaitInSeconds = 0.5; // 1
int globalFunctionTimeoutInSeconds = 30;
int globalCharacterPerMinuteToType = 2000; // 350
double timeBetweenFactorialButtonClicksInSeconds = 1.0; // This being faster (less time) can mean more CPU stress. This will vary from system to system. Suggest determining what is the best value here by manual testing.
int factorialButtonClicksAmount = 30;
ShellExecute(@"cmd /c taskkill /f /im calc*",timeout:globalFunctionTimeoutInSeconds,waitForProcessEnd:true); // Ensuring calc's closed out of before starting
// Launching calc, using custom timer, and ensuring it's running
StartTimer("CalcLaunchTime");
START(mainWindowTitle:"*Calc*",timeout:globalFunctionTimeoutInSeconds);
MainWindow.FindControlWithXPath(xPath : "Xaml Window:Windows.UI.Core.CoreWindow/Custom/Group:LandmarkTarget/Text",timeout:globalFunctionTimeoutInSeconds); // Looking for the output/input string pane
StopTimer("CalcLaunchTime");
MainWindow.Maximize();
Wait(globalIntermittentWaitInSeconds);
var hamburgerButton = MainWindow.FindControlWithXPath(xPath : "Xaml Window:Windows.UI.Core.CoreWindow/Custom/Button:Button",timeout:globalFunctionTimeoutInSeconds);
Wait(globalIntermittentWaitInSeconds);
// Go into Scientific mode
hamburgerButton.Click();
var scientificModeToggleButton = MainWindow.FindControlWithXPath(xPath : "Xaml Window:Windows.UI.Core.CoreWindow/Custom/Xaml Window:SplitViewPane/Pane:ScrollViewer/Group/ListItem:Microsoft.UI.Xaml.Controls.NavigationViewItem[1]",timeout:globalFunctionTimeoutInSeconds);
Wait(globalIntermittentWaitInSeconds);
scientificModeToggleButton.Click();
var factorialButton = MainWindow.FindControl(className : "Button:Button", title : "Factorial",timeout:globalFunctionTimeoutInSeconds);
Wait(globalIntermittentWaitInSeconds);
// Input 0.1
MainWindow.Type("0.1",cpm:globalCharacterPerMinuteToType);
MainWindow.FindControl(className : "Text", title : "Display is 0.1",timeout:globalFunctionTimeoutInSeconds);
// Iterate through the defined factorial button clicks
int factorialButtonClickCounter = 1;
while(factorialButtonClickCounter < factorialButtonClicksAmount) {
factorialButton.Click();
factorialButtonClickCounter++;
Wait(timeBetweenFactorialButtonClicksInSeconds);
}
STOP(timeout:globalFunctionTimeoutInSeconds); // Closing the calc app
```

### Follow these instructions to get access https://confluence.eng.nutanix.com:8443/pages/viewpage.action?spaceKey=DPRO&title=Setup+GitHub.com+account.

### NOTE: For Hackathon Repos, you don't need to add your team mates for write access, everyone will automatically get write access.


