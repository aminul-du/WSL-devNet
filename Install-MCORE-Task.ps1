# Run in Administrator PowerShell to enable silent auto-boot (no UAC prompt)
Remove-Item "\$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\MCORE-AutoBoot.bat" -ErrorAction SilentlyContinue

\$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Scripts\MCORE-AutoBoot.ps1"
\$trigger = New-ScheduledTaskTrigger -AtLogOn
principal = New-ScheduledTaskPrincipal -UserId "env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
\$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "MCORE-AutoBoot" -Action action -Trigger trigger -Principal principal -Settings settings -Force
Write-Host "Silent Task Scheduler job 'MCORE-AutoBoot' registered!" -ForegroundColor Green
