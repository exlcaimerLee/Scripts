########################################################################################
# This tool can be used to check and update SCVMM Consoles on remote machines in 1 hit #
########################################################################################

# To get this working you will need to make sure that you have: 
# 1) A text file "Computers.txt" located on your C:\ with every machine you want to check on a separate line
# 2) Done a CTRL+H on this doc and replaced "C:\Users\admin.lee.DCSL\Desktop\" with your own desktop/location (remember to end with a slash)
# 3) Set the $HotfixPath variable to the location of the file you're installing for SCVMM, it's further down the script near the 2nd foreach
# 4) Run this as an Admin that has at least computer admin priviledges and preferably in ISE
# 5) Replaced all instances of the version number (currently "4.0.2244.0" ) in the script with the latest. See: https://buildnumbers.wordpress.com/scvmm/
# 6) PSExec in System32

# NOTES: 
# 1) After checking the list of machines, the script will pause before going to the install phase. This is so that you can re-check everything after completion
# 2) After the checking phase, you'll have 2 files on your desktop. "Computer_OutputSCVMM" is for you, the other is for the script
# 3) Computers that don't have the console installed will not be sent to the output file, they will be logged to the console though (See point 4)
# 4) Ignore errors that start with "You cannot call a method on a null valued expression." This is thrown when the reg key does not exist on a machine, thus SCVMM isn't installed
# 5) I probably need to change the way that the file for the install phase is created. When getting the contents back it is magically adding blank lines
#    An Error_OutputSCVMM file is made to workaround this. After running, it will have "computer is not using C" entries you can ignore these as long as the computer name is blank
# 6) A successful install is denoted with a error code of 0. 3010 means that the install was successful, but that a reboot is pending
# 7) After running through once completely, you should re run the check phase to be sure all machines are udpated (and incase you missed any that were off)


#Version: 1.2
# - v1.2 - Stopped a pointless error throwing on every install and added the option to let the script run on it's own at the start. 
# - v1.1 - Added a progress bar, so that it is easier to see how far in you are on the check and install phases. Look for the variable $prog.
# - v1.0 - Initial

cls

#Here we give the option to run the script in auto mode, this will skip the pause between the check and install phase.

$AutoModeTitle = "Run in auto mode?"
$AutoModeMessage = "Do you want to run in auto mode? This will skip the pause between phases and continue straight to the install."

$AutoModeYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "This will bypass the pause between phases."

$AutoModeNo = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "This will allow you to check the progress manually before continuing with the install phase."

$AutoModeOptions = [System.Management.Automation.Host.ChoiceDescription[]]($AutoModeYes, $AutoModeNo)

$AutoModeResult = $host.ui.PromptForChoice($AutoModeTitle, $AutoModeMessage, $AutoModeOptions, 0) 

#Beginning script.


cls
Clear-Variable SCVMM_Ver
Clear-Variable prog

Write-Host ""
Write-Host "Computers that are on and don't have SCVMM will not be logged!" -ForegroundColor Cyan
Write-host ""

$Computers =Get-Content -Path C:\computers.txt

########################################################################################
#                              This is the checking phase                              #
########################################################################################

foreach ($Computer in $Computers) { 
$prog++
$SCVMM_Ver = "-"

$IsUp =Test-Connection -Quiet $Computer
IF ($IsUp -eq $True) {$IsUp = "Yes" }
IF ($IsUp -eq $False) {$IsUp = "No" }

# Update progress bar
Write-Progress -activity "Checking Progress" -status "Currently on: $computer" -PercentComplete (($prog / $Computers.length)  * 100)

$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
$regKey = $reg.OpenSubKey("SOFTWARE\\Microsoft\\Microsoft System Center Virtual Machine Manager Administrator Console\\Setup")
$SCVMM_Ver = $regkey.GetValue("ProductVersion") 
IF ($SCVMM_Ver -eq $null) {$SCVMM_Ver = "-" }


Write-Host "--------------------------------"
Write-Host ""
Write-Host "Machine Name:" $Computer -ForegroundColor Cyan
Write-Host "Version number:" $SCVMM_Ver -ForegroundColor Cyan

#####Does it exist?#####
#IF ($IsUp -eq "Yes" -And $SCVMM_Ver -eq "-") 

#{
#    Write-Host "Doing Nothing"
#}

IF ($SCVMM_Ver -eq "-" -And $IsUp -eq "Yes")

{
    
    Write-Host "Key Not Found! Does Not Exist!" -ForegroundColor Red
    Write-Host "" 
    $SCVMM_Ver = "9.9.9999.999"
    

} 

IF ($SCVMM_Ver -eq "-" -And $IsUp -eq "No")

{
    
    Write-Host "Computer not contactable" -ForegroundColor Red
    Add-Content C:\Users\admin.lee.DCSL\Desktop\Computer_OutputSCVMM.txt "Computer: `n$computer is off, or does not exist." 
    Write-Host ""
    $SCVMM_Ver = "9.9.9999.999"
    
} 


#####Is Version Newer#####

IF ($SCVMM_Ver -lt "4.0.2244.0" -And $isUp -eq "Yes")

{
    Write-Host "This version needs updating." -ForegroundColor Yellow
    Add-Content C:\Users\admin.lee.DCSL\Desktop\Computer_OutputSCVMM.txt "Computer `n$computer is on. SCVMM: $SCVMM_Ver, needs updating."
    Write-Host ""
    Add-Content C:\Users\admin.lee.DCSL\Desktop\DueSCVMMUpgrade.txt "`n$computer"
    Write-Host ""   
} 

IF ($SCVMM_Ver -lt "4.0.2244.0" -And $isUp -eq "No")

{
    Write-Host "Computer is off" -ForegroundColor Yellow
    Add-Content C:\Users\admin.lee.DCSL\Desktop\Computer_OutputSCVMM.txt "Computer: `n$computer is off."
    Write-Host ""   
} 


IF ($SCVMM_Ver -eq "4.0.2244.0")

{
    Write-Host "This version is correct" -ForegroundColor Green
    Add-Content C:\Users\admin.lee.DCSL\Desktop\Computer_OutputSCVMM.txt "Is `n$computer up?: $IsUp. This version does not need updating"
    Write-Host ""

}

}

#This will remove the checking phase progress bar.
Write-Progress -activity "Total Progress" -Completed

#Output the data so the user can see what machines will be updated.

$Computers =Get-Content -Path C:\Users\admin.lee.DCSL\Desktop\DueSCVMMUpgrade.txt

Write-Host "The below machines will have their SCVMM versions upgraded:"
ForEach ($computer in $computers) { 

    Write-Host "$computer" 

} 
Write-Host " "

########################################################################################
#                              This is the install phase                               #
########################################################################################

IF ($AutoModeResult -eq 1) { 

    write-host "Moving to install phase, all ok?" -ForegroundColor Cyan
    Pause 

}


Clear-Variable prog

$Computers =Get-Content -Path C:\Users\admin.lee.DCSL\Desktop\DueSCVMMUpgrade.txt
 
$HotfixPath = '\\ws64\share\URX.msp'
 
foreach ($Computer in $Computers){ 
$prog++
$OnC=Test-Path "\\$Computer\C$"

# Update progress bar
Write-Progress -activity "Total Progress" -status "Currently on: $computer" -PercentComplete (($prog / $Computers.length)  * 100)

 IF ($OnC -eq $True -And $Computer -ne "") {
        
        Write-Host "Processing $Computer..."  
  
  #If package already exists on target machine, remove it"
     IF (test-path "\\$Computer\c$\URX.msp") {
        Remove-Item "\\$Computer\c$\URX.msp"
} 

  # Copy update package to local folder on server
        Copy-Item $Hotfixpath "\\$Computer\c$"
  
  # Run command as SYSTEM via PsExec (-s switch)
        C:\Windows\System32\Psexec.exe \\$Computer msiexec /p C:\URX.msp /quiet /norestart
  #        if ($LastExitCode -eq 3010) {
  #           $ConfirmReboot = $False
  #      } else {
  #         $ConfirmReboot = $True
  #    }
  # Delete local copy of update package after update
        Remove-Item "\\$Computer\c$\URX.msp"

 

  #        Write-Host "Restarting $Server..."
  #        Restart-Computer -ComputerName $Server -Force -Confirm:$ConfirmReboot

        Write-Host "Done" {break} # the break here is experimental, it should stop the below write-host running if the install completes anyway. Untested though
    } else {
      #This will throw in the event that the user is using a letter other than C:\ (unlikely) or the machine name is null (likely)
      Add-Content C:\Users\admin.lee.DCSL\Desktop\Errors_OutputSCVMM.txt "Computer `n$computer is either not using C:\ or is null" 

    }
}


#experimental - Ignore
#PsExec -s \\$computer MSIexec /update "\\ws64\share\SCVMM UR7\kb3078314_AdminConsole_amd64.msp" /quiet /norestart


