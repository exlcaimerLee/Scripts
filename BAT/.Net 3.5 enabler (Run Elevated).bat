@echo off
cls
echo Ensure Installation CD is inserted. . .
ping localhost -1 >nul
cls
echo Drive letter?
set /p dlet=

DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:%dlet%:\sources\sxs

exit