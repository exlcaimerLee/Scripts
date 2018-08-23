@echo off

wmic pagefile list /format:list
pause
wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False
wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=16384,MaximumSize=16384
pause
shutdown -r -t 0