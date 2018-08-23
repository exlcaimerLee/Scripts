$title = "Run in auto mode?"
$message = "Do you want to run in auto mode? This will skip the pause between phases and continue straight to the install."

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "This will bypass the pause between phases."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "This will allow you to check the progress manually before continuing with the install phase."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 


    If ($result -eq 0) { write-host "You said yes" } 


