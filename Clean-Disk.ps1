<#
.SYNOPSIS
    Script to do a basic disk cleanup with cleanmgrand delete user profiles older than 60 days
.EXAMPLE
    Run the script on the remote machine
.NOTES
    Author: Padure Sergio
    Last Edit: 2020-09-09
    Version 1.0 - Creation

#>


#Establishing variables and preparing transcription to log file
$hour = Get-Date -Format yyyy.MM.dd.HH.mm
$registryPath = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
$strValueName = "StateFlags0003"
$Users = Get-WMIObject -class Win32_UserProfile
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\temp\Cleanup_$(gc env:computername)_$hour.log -append

Write-Host "Please Wait, PC is being cleaned"

$subkeys = gci -LiteralPath Registry::"$registryPath" -Name
ForEach ($subkey in $subkeys) {
New-ItemProperty -Path Registry::$registryPath\$subkey -Name $strValueName -PropertyType DWord -Value 3 -ErrorAction SilentlyContinue | Out-Null
}
Start-Process cleanmgr -ArgumentList "/sagerun:3" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -NoNewWindow

#Deleting user profiles older than 60 days while skipping important system accounts.
$Users | Where {
                    (($_.ConvertToDateTime($_.LastUseTime) -lt (Get-Date).AddDays(-60)) -and $_.Localpath -notlike ("C:\Users\administrator") -and $_.Localpath -notlike ("C:\windows*"))
                } | Remove-WmiObject

Stop-Transcript

exit 0
