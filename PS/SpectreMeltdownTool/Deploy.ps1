####################################################################################################
#    This tool can be used to assist in implementing fixes needed for meltdown/spectre exploits    #
####################################################################################################

# Make sure you have a list of machines that you want to check on separate lines in a text file called "computers.txt" in C:\
# Ensure PSexec exists on the machine you're running this on it's used to push install the update, though it is included in this folder

# Change the output file location from my desktop to something else (do a ctrl + H)

cls

#Getting region name, this is used for log output
$Region="$env:ComputerName"
$Region=$Region.Substring(0,2)

#Here we give the option to run the script in remedy mode, this will make servers compliant by installing updates and creating reg keys.

$AMTitle = "Remedy Mode?"
$AMMessage = "Do you want to run in remedy mode? This will install required patches and write reg keys to make mitigations live, machines will be rebooted."

$AMYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Remedy mode."

$AMNo = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Check-only mode."

$AMOptions = [System.Management.Automation.Host.ChoiceDescription[]]($AMYes, $AMNo)

$AMResult = $host.ui.PromptForChoice($AMTitle, $AMMessage, $AMOptions, 0) 

# AMResult = 0  means remedy mode
# AMResult = 1  means check-only mode

IF ($AMResult -eq "1" )  { 
    
    Add-Content C:\Softarc\SpectreMeltdownTool\$Region.Deployps1_OutputNet.csv "Running in check-only mode"

    $HotfixInstalled = "N/A"
    $MitigationsEnabled = "N/A"
}

#Beginning script.
$prog = 1

cls
Clear-Variable AVReady
Clear-Variable prog
cls
Write-Host ""
Write-Host "" -ForegroundColor Cyan
Write-host ""

$Computers =Get-Content -Path C:\Softarc\SpectreMeltdownTool\computers.txt

$HotfixPath = 'C:\Softarc\SpectreMeltdownTool\windows8.1-kb4056898.msu'

function Get-TimeStamp {
    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    
}

Add-Content C:\Softarc\SpectreMeltdownTool\$Region.Deployps1_OutputNet.csv "Time,Name,On,AV Reg key,Hotfix Present,Hotfix Installed,Mitigations Present,Mitigations Added,"

########################################################################################
#                              This is the checking phase                              #
########################################################################################

foreach ($Computer in $Computers) { 
$prog++
$AVReady = "-"

Write-Host "Machine name: " $Computer -ForegroundColor Cyan

$IsUp =Test-Connection -Quiet $Computer
IF ($IsUp -eq $True) {$IsUp = "Yes" }
IF ($IsUp -eq $False) {$IsUp = "No" }

# Update progress bar
Write-Progress -activity "Checking Progress" -status "Currently on: $computer" -PercentComplete (($prog / $Computers.length)  * 100 -1)



# Check for AV reg key existence
$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
$regKey = $reg.OpenSubKey("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\QualityCompat")
$AVReady = $regkey.GetValue("cadca5fe-87d3-4b96-b7fb-a231484277cc") 
IF ($AVReady -eq $null) {$AVReady = "-" }

# Set AV reg key variable

IF ($AVReady -eq "-" -And $IsUp -eq "Yes") {
        $AVReady = "No" 
    }
IF ($AVReady -eq "-" -And $IsUp -eq "No") {
        $AVReady = "N/A" 
    }
IF ($AVReady -eq "0" -And $IsUp -eq "Yes") {
        $AVReady = "Yes" 
    }
IF ($AVReady -eq "0" -And $IsUp -eq "No") {
        $AVReady = "No" 
    }

########################################################################################
#                            Check that patch is installed                             #
########################################################################################

$HotfixPresent = "-"
# Checking for specific patch
IF (Get-Hotfix -id KB4056898 -Computername $Computer -ErrorAction 2) {
        $HotfixPresent = "Yes"
    }
# Checking for monthly rollup that contains patch
IF (Get-Hotfix -id KB4056895 -Computername $Computer -ErrorAction 2) {
        $HotfixPresent = "Yes"
    }

IF (Get-Hotfix -id KB4056805 -Computername $Computer -ErrorAction 2) {
        $HotfixPresent = "Yes"
    }

IF (Get-Hotfix -id KB4056891 -Computername $Computer -ErrorAction 2) {
        $HotfixPresent = "Yes"
    }

IF (Get-Hotfix -id KB4056892 -Computername $Computer -ErrorAction 2) {
        $HotfixPresent = "Yes"
    }

IF (Get-Hotfix -id KB4056888 -Computername $Computer -ErrorAction 2) {
        $HotfixPresent = "Yes"
    }
    
# Set HotfixInstalled variable
IF ($HotfixPresent -eq "-" -And $IsUp -eq "Yes") { 
        $HotfixPresent = "No"
    }
IF ($HotfixPresent -eq "-" -And $IsUp -eq "No") { 
        $HotfixPresent = "N/A"
    }
IF ($HotfixPresent -eq "Yes" -And $IsUp -eq "No") { 
        $HotfixPresent = "N/A"
}
IF ($HotfixPresent -eq "Yes" -And $IsUp -eq "Yes") { 
        $HotfixPresent = "Yes"
    }

########################################################################################
#                Remedy missing patch if appropriate and in remedy mode                #
########################################################################################

<# 

IF ($HotfixPresent -eq "No" -And $AMResult -eq "0") {
# Remove the package name if it exists already where we will put it. This will throw an error if the file doesn't exist, but that's OK. 
        IF (test-path "\\$Computer\c$\windows8.1-kb4056898.msu") {
            Remove-Item "\\$Computer\c$\windows8.1-kb4056898.msu"
        } 
#Copy package to be installed
        Copy-Item $HotfixPath "\\$Computer\c$"

# Run install using PSExec
        C:\Softarc\SpectreMeltdownTool\PsExec.exe -s \\$Computer wusa.exe C:\windows8.1-kb4056898.msu /quiet /norestart

# Checking return code from installation

        IF ($LASTEXITCODE -eq "3010" ) {

            Write-Host "Exit code: $LASTEXITCODE. The install has completed and restart was surpressed"
            $HotfixInstalled = "Yes"
        } else { Write-Host "Exit code $LASTEXITCODE, investigate" }

        IF ($LASTEXITCODE -eq "1618" ) {

            Write-Host "Exit code: $LASTEXITCODE. Install could not complete, as an install is already under way/waiting to be completed, restarting the machine to try again"
            $HotfixInstalled = "No, another install is getting in the way. Restarting the machine, try running again."
            Write-Host "Waiting for machine to come back up before proceeding"
            Restart-Computer -ComputerName $Computer -Force -Wait -For WMI -Delay 5

        }

        Remove-Item "\\$Computer\c$\windows8.1-kb4056898.msu"
}
 
#>

$HotfixInstalled = "No"

########################################################################################
#                           Check that mitigations are live                            #
########################################################################################

$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
$regKey = $reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management")
$MitigationsPresent = $regkey.GetValue("FeatureSettingsOverride") 
IF ($MitigationsPresent -eq $null) {$MitigationsPresent = "-" }

IF ($MitigationsPresent -eq "-" -And $IsUp -eq "Yes") {
        $MitigationsPresent = "No" 
    }
IF ($MitigationsPresent -eq "-" -And $IsUp -eq "No") {
        $MitigationsPresent = "N/A" 
    }
IF ($MitigationsPresent -eq "0" -And $IsUp -eq "Yes") {
        $MitigationsPresent = "Yes" 
    }
IF ($MitigationsPresent -eq "3" -And $IsUp -eq "Yes") {
        $MitigationsPresent = "No" 
    }

########################################################################################
#                Enabled mitigations if appropriate and in remedy mode                 #
########################################################################################

IF ($MitigationsPresent -eq "No" -And $AMResult -eq "0") {
    Write-host "Adding 3 mitigation registry keys"
    C:\Softarc\SpectreMeltdownTool\PsExec.exe -s \\$Computer reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 0 /f
    C:\Softarc\SpectreMeltdownTool\PsExec.exe -s \\$Computer reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f
    C:\Softarc\SpectreMeltdownTool\PsExec.exe -s \\$Computer reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization" /v MinVmVersionForCpuBasedMitigations /t REG_SZ /d "1.0" /f 
       
        IF ($LASTEXITCODE -eq "0" ) {

            Write-Host "Exit code: $LASTEXITCODE. Values added successfully. A restart will be required along with the patch and firmware for the changes to go live."
            $MitigationsEnabled = "Yes"
<#          Write-Host "Restarting. And waiting for machine to come back up before proceeding"
            Restart-Computer -ComputerName $Computer -Force -Wait -For WMI -Delay 5
#>
        } else {

            Write-Host "Exit code: $LASTEXITCODE. Investigate. No reboot will occur."
            $MitigationsEnabled = "Investigate"
        }

}

########################################################################################
#                              Write over view to console                              #
########################################################################################

Write-Host ""
Write-Host "--------------------------------"
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host $(Get-TimeStamp) -ForegroundColor Cyan
Write-Host "Machine name: " $Computer -ForegroundColor Cyan
Write-Host "Turned on: " $IsUp -ForegroundColor Cyan
Write-Host "AV reg key set: " $AVReady -ForegroundColor Cyan
Write-Host "Hotfix present: " $HotfixPresent -ForegroundColor Cyan
Write-Host "Hotfix installed: " $HotfixInstalled -ForegroundColor Cyan
Write-Host "Mitigations present: " $MitigationsPresent -ForegroundColor Cyan
Write-Host "Mitigations Enabled: " $MitigationsEnabled -ForegroundColor Cyan
Write-Host ""
Write-Host "--------------------------------"
Write-Host ""

Add-Content C:\Softarc\SpectreMeltdownTool\$Region.Deployps1_OutputNet.csv "$(Get-TimeStamp),$Computer,$IsUp,$AVReady,$HotfixPresent,$HotfixInstalled,$MitigationsPresent,$MitigationsEnabled,"

}

###END
#This will remove the checking phase progress bar.
Write-Progress -activity "Total Progress" -Completed

Write-Host "Finished! Check outputs." -ForegroundColor Green
