########################################################################################
#     This tool can be used to install an msi/msp onto a remote machines in 1 hit      #
########################################################################################

# To get this working you will need to make sure that you have: 
# 1) The file you're installing located at \\ws64\share\XX.msi (or somewhere else if you change the $HotFixPath var). 
# 2) PSExec located in system32
# 3) A list of the machines you want to install to located in C:\Computers.txt
#    If you want to push out manually to a single machine(s), comment out the $Computers =Get-Content and the very last '}' and then uncomment the line under the cls

# NOTES: 
# 1) I may add the ability to pick your own install location /install type. without having to change items in the script itself. 
# 2) This is only really intended for a quick push to avoid interruptions to the end user, it will not allow reboots. 
# 3) If you're installing an MSI, use the /i switch with MSIEXEC, if it's an .MSP use /p.

#Version: 1.1
# - v1.1 - added the ability to do multiple machines instead of manually, currently you have to change this manually to switch betweent the 2, if I can be bothered to do this nicer then I shall. 
# - v1.0 - initial

########################################################################################
#                                    install phase                                     #
########################################################################################
cls

#$Computer = Read-Host -Prompt "Computer to deploy to?"

$Computers =Get-Content -Path C:\computers.txt

$HotfixPath = '\\ws64\share\SCOMUR13.msp'

foreach ($Computer in $Computers) { 
$OnC=Test-Path "\\$Computer\C$"
 
 # First we will check that the computer is on, 

 IF ($OnC -eq $True -And $Computer -ne "") {
        Write-Host "Processing $Computer..."  

# Remove the package name if it exists already, and copy new package to local folder on server/computer. This will throw an error if the file doesn't exist, but that's OK. 
    IF (test-path "\\$Computer\c$\SCOMUR13.msp") {
        Remove-Item "\\$Computer\c$\SCOMUR13.msp"
}
        Copy-Item $Hotfixpath "\\$Computer\c$"

# Run install using PSExec

        C:\Windows\System32\Psexec.exe \\$Computer msiexec /p C:\SCOMUR13.msp /quiet /norestart

# Delete local copy of update package

        Remove-Item "\\$Computer\c$\SCOMUR13.msp"

        Write-Host "If error code = '0' the install was successfull. 3010 is install successful pending reboot" #{break} # the break here is experimental, it should stop the below write-host running if the install completes anyway. Untested though
    } else {

#This will throw in the event that the user is using a letter other than C:\ (unlikely) or the machine name is null (likely)
      
      Add-Content C:\Users\lee.jones\Desktop\Errors.txt "Computer `n$computer is either not using C:\ or is null" 

    }

}


#experimental - Ignore
#PsExec -s \\$computer MSIexec /update "\\ws64\share\SCVMM UR7\kb3078314_AdminConsole_amd64.msp" /quiet /norestart

# Full list of MSIEXEC error codes here: https://msdn.microsoft.com/en-us/library/windows/desktop/aa376931(v=vs.85).aspx