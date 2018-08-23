
@echo off
Echo Please Wait. Currently Uninstalling Microsoft SCCM 2010 Client
IF EXIST C:\Windows\System32\ccmsetup\ccmsetup.exe GOTO REMOVE
GOTO END
:REMOVE
c:\Windows\System32\ccmsetup\ccmsetup.exe /uninstall
RD /S /Q C:\Windows\System32\ccmsetup
:END