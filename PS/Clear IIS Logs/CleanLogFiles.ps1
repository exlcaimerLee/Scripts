Remove-item C:\Softarc\LogFilesDeleted.txt

Get-ChildItem C:\Inetpub -Recurse -File -Include *.log | Where-Object { $_.CreationTime -lt [datetime]::Today.AddDays(-28) } | Out-File C:\Softarc\LogFilesDeleted.txt
Get-ChildItem C:\Inetpub -Recurse -File -Include *.log | Where-Object { $_.CreationTime -lt [datetime]::Today.AddDays(-28) } | Remove-Item -Force 