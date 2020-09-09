<#
.SYNOPSIS
    Script to start connection to remote switch without having to input the tacacas creds every time
.EXAMPLE
    Run script
    PS C:\> .\kitty.ps1
.NOTES
    Author: Padure Sergio
    Last Edit: 2020-09-10
    Version 1.0 - Creation

#>

$userid = 'tacacsuserid'
$password = 'tacacspassword'
$scriptdir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$kitty = "$scriptdir\kitty-0.73.2.4.exe"
$connectiontarget = Read-Host -Prompt 'Provide switch to connect to'
$term = "terminal length 0"

start-process "$kitty" -PassThru -argumentlist " `"$userid`"@`"$connectiontarget`" -pass `"$password`" -cmd `"enable\n$password\n$term`""
