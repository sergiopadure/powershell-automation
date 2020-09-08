<#
.SYNOPSIS
    Script to gather useful information about the remote machine
.EXAMPLE
    Just call the script with the hostname of the remote machine as argument
    PS C:\> .\Get-InfoRemoteMachine.ps1 WindowsLaptop
.NOTES
    Author: Padure Sergio
    Last Edit: 2020-09-08
    Version 1.0 - Creation

#>

#Defining variables
$hostname = $args[0]
$i = 0

#Starting loop for verifying if machine is online and available
do
{
$i += 1
$i
Clear-DnsClientCache
$ping = Test-Connection -BufferSize 32 -Count 1 -ComputerName $hostname -Quiet
$pathremote = Test-Path -Path "\\$hostname\C$"
}
while (-not $ping -OR -not $pathremote)

#Writing in terminal that the machine is online and showing notification
Write-Host "$hostname Is online"
New-BurntToastNotification -Text "$hostname is online"

#Starting data gathering and presentation
Invoke-Command -ComputerName $hostname -Argumentlist $hostname, $Hotfix -ScriptBlock {
#Gathering data on Windows Version
$version = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID -ErrorAction Stop).ReleaseID
$version
switch ($version) {
    '1809' {
            Write-Host "Windows 10 Version is $version"
            }
    '1903' {
            Write-Warning "Windows 10 Version is $version!"
            }
    '1909' {
            Write-Warning "Windows 10 Version is $version!"
            }
}

#Gathering power and battery status
$poweronline = Get-WmiObject -Class BatteryStatus -Namespace root\wmi -ErrorAction SilentlyContinue | Where-Object -Property "InstanceName" -Like '*0_0' | Select-Object -ExpandProperty "PowerOnline"
$batterylevel = Get-WmiObject win32_battery | Select-Object -ExpandProperty EstimatedChargeRemaining
Write-Host "Battery is at $batterylevel %"
switch ($poweronline){
    'True' {
            Write-Host "PC is connected to power"
            }
    'False' {
            Write-Warning "PC is not connected to power"
            }
}

#Gathering uptime
function Get-Uptime {
   $os = Get-WmiObject win32_operatingsystem
   $uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
   $Display = "Uptime: " + $Uptime.Days + " days, " + $Uptime.Hours + " hours, " + $Uptime.Minutes + " minutes" 
   Write-Output $Display

}
Get-Uptime
#Processor info
Get-WmiObject Win32_Processor

#Office version
Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\O365ProPlusRetail*" | Select-Object DisplayName, DisplayVersion, Publisher

#Last installed hotfixes
Get-HotFix | Sort-Object InstalledOn -Descending | ft Description, HotFixID, InstalledBy, InstalledOn, PSComputerName
Get-WinEvent -FilterHashtable @{logname = 'setup'} | Sort-Object TimeCreated -Descending | select -first 10 | Format-Table timecreated, message -AutoSize -Wrap
Get-WinEvent -FilterHashtable @{logname = 'System'; ID = 6008 } | Sort-Object TimeCreated -Descending | select -first 20 | Format-Table timecreated, message -AutoSize -Wrap

#Logged in user
$explorerprocesses = @(Get-WmiObject -Query "Select * FROM Win32_Process WHERE Name='explorer.exe'" -ErrorAction SilentlyContinue)
if ($explorerprocesses.Count -eq 0)
{
    "No explorer process found / Nobody interactively logged on"
} else {
    foreach ($i in $explorerprocesses)
    {
        $Username = $i.GetOwner().User
        $Domain = $i.GetOwner().Domain
        $Domain + "\" + $Username + " logged on since: " + ($i.ConvertToDateTime($i.CreationDate))
    }
}
}
