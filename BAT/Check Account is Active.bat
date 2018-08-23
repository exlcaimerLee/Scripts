@echo off

echo Enter user name:
echo. 
Set /p username=

:loop
cls
net user %username% /domain | find "Account active"
timeout /t 1 /nobreak > nul
goto loop



 