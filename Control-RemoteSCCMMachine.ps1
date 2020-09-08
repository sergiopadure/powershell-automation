<#
.SYNOPSIS
    Script to automatically start a remote control session via SCCM remote control when it identifies the machine being online
.EXAMPLE
    Just call the script with the hostname of the remote machine as argument
    PS C:\> .\Control-RemoteSCCMMachine.ps1 WindowsLaptop
.NOTES
    Author: Padure Sergio
    Last Edit: 2020-09-08
    Version 1.0 - Creation

#>

#Defining variables
$hostname = $args[0]
$sccmpath = "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\i386"
$i = 0

#Clearing screen of any previous data
cls
#Looping through pinging and testing if C$ is available until both return $true
do
{
$dateandtime = Get-Date -Format "dd_MM_yyyy_HH-mm-ss"
$i += 1
Clear-DnsClientCache
$ping = Test-Connection -BufferSize 32 -Count 1 -ComputerName $hostname -Quiet
$pathremote = Test-Path -Path "\\$hostname\C$"
Start-Sleep -Seconds 1
Write-Warning "$hostname still offline. Retry number $i at $dateandtime"
}
while (-not $ping -OR -not $pathremote)

#Using Get-WmiObject to pull the current user logged in on the machine and putting it in the variable $loggedin
$loggedin = Invoke-Command -ComputerName $hostname -Argumentlist $hostname -ScriptBlock {
$explorerprocesses = @(Get-WmiObject -Query "Select * FROM Win32_Process WHERE Name='explorer.exe'" -ErrorAction SilentlyContinue)
if ($explorerprocesses.Count -eq 0)
{
    "Nobody"
} else {
    foreach ($i in $explorerprocesses)
    {
        $Username = $i.GetOwner().User
        $Domain = $i.GetOwner().Domain
        $Username
    }
}
}

#Using the value in $loggedin to pull the email address and displayname of the logged in user after checking if somebody is actually connected
if ($loggedin -eq "Nobody"){
    Write-Warning "Nobody is logged in on $hostname"
    }else{
$email = Get-ADUser $loggedin -Properties * | Select-Object -ExpandProperty 'mail'
$displayname = Get-ADUser $loggedin -Properties * | Select-Object -ExpandProperty 'displayname'
}

#Outputting the information to the terminal
Write-Host "$hostname Is online at $dateandtime with user $loggedin connected. `nEmail Address is $email and name is $displayname"

#Sending Windows Notification
New-BurntToastNotification -Text "$hostname is online at $dateandtime with user $loggedin connected. `nEmail Address is $email and name is $displayname"

#Waiting 1 second
Start-Sleep -Seconds 1

#Starting remote control
& "$sccmpath\CmRcViewer.exe" $hostname
Start-Sleep -Seconds 3
