<#

$var= Read-host -Prompt "Enter a variable value"

Write-Host "You entered: $var"

#>


<# ParamScript.ps1

param($name=$(throw "You must specify your name"))

"Hello, $name"

So you could enter:

.\MyScript joecool

#>


#The below examples were taken from: https://technet.microsoft.com/en-us/library/jj554301.aspx


<#

Param(
 [string]$FirstName,
 [string]$LastName
 
 )
Write-Host "You passed the parameters $FirstName and $Lastname for first and lastnames"
 
 #>

 [CmdletBinding()]
 Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$FirstName,

    [Parameter(Mandatory=$True,Position=1)]
        [string]$LastName
        
        )

Write-Host "You passed the parameters $FirstName and $LastName for first and lastnames"

