<#
.SYNOPSIS
    Script to uninstall a remote application through WMI
.EXAMPLE
    Call the script and follow the instructions
    PS C:\> .\Remove-RemoteApplication.ps1
.NOTES
    Author: Padure Sergio
    Last Edit: 2020-09-10
    Version 1.0 - Creation

#>

#Establishing variables
$scriptdir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$dateandtime = Get-Date -Format "dd_MM_yyyy_HH-mm"
$computerfilter = "" # Define the regex filter for the machines in your ORG
$appfilter = "[%]\w*[%]"

#Asking for hostname and filtering by regex
do
{
$hostname = Read-Host -Prompt "Please provide the hostname of the machine on which to uninstall in your organization's format"
}
while ($hostname -cnotmatch $computerfilter)

#Testing if PC is on the network then testing if C$ is available
$ping = Test-Connection -BufferSize 32 -Count 1 -ComputerName $hostname -Quiet
$pathremote = Test-Path -Path "\\$hostname\C$"
if (-not $ping -and -not $pathremote){
        throw "Device if offline or unaccessible. Please verify device."
        }

#Asking for app to verify and testing for compliance to regex filter
do
{
$software = Read-Host -Prompt "Please provide a significant part of the name you're searching with % as wildcards. Example: %adobe%"
}
while ($software -cnotmatch $appfilter)
$software2 = "'$software'"

#Starting execution
$session = New-PSSession -ComputerName $hostname
Invoke-Command -Session $session -ArgumentList $software2 -ScriptBlock {
$B = Get-WmiObject -class win32_product -Filter "Name like $using:software2"
$B
$C = $B | measure | Select-Object -ExpandProperty 'Count'
if ($C -eq 0){
    throw "No such application installed on machine. Try with another keyword"
    }elseif ($c -eq 1){
    do
    {
    $choice = Read-Host "Do you want to uninstall this application? Answer y or n"
    }
    while ($choice -cnotmatch '[yn]')
    if ($choice -eq 'y'){
    Write-Host "Starting Uninstall"
    $un = ($b.Uninstall()).ReturnValue
        if ($un -eq 0){
        Write-Host "Uninstall successful"
        exit 0
        }else{
        throw "Uninstall has failed with errorcode $un"
        }
    }else{
        throw "Aborted"
        }
    }else{
    $appscountfilter = "[0-$C]{1}"
    do
    {
    $touninstall = Read-Host -Prompt "Please provide a number that corresponds to the application to want to uninstall, from 1 to $C. 0 to cancel"
    }
    while ($touninstall -cnotmatch $appscountfilter)
    if ($touninstall -eq 0){
    throw "Aborted"
    }else{
    $touninstall -= 1
    $nameuninstall = $B[$touninstall]
    $app = $nameuninstall | Out-String
    Write-Warning $app
    do
    {
    $choice = Read-Host "Are you sure you want to uninstall the selected application? Answer y or n"
    }
    while ($choice -cnotmatch '[yn]')
    }
    if ($choice -eq 'y'){
    Write-Host "Starting Uninstall"
    $un = ($nameuninstall.Uninstall()).ReturnValue
        if ($un -eq 0){
        Write-Host "Uninstall successful"
        exit 0
        }else{
        throw "Uninstall has failed with errorcode $un"
        }
    }else{
        throw "Aborted"
        }
    }
}
