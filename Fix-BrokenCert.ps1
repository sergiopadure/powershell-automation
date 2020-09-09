<#
.SYNOPSIS
    The culmination of 2 months of troubleshooting and research into the cause of the issue. Eventually I found out that it was a few certificates being corrupted when importing the roots.sst obtained via certutil so I created this script as an automated restore of these 8 corrupted certificates
.EXAMPLE
    Run the script on the remote machine
.NOTES
    Author: Padure Sergio
    Last Edit: 2020-09-09
    Version 1.0 - Creation

#>
#Establishing variables and copy the roots.sst
$src = "" #Network Location of the good certificates
$dst ="C:\temp\certs"
 
#Preparing logging
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path "C:\log\$env:computername-certs.log" -append
 
 
#Deleting broken certificates

Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Subject -match 'Microsoft Root' } | Remove-Item
Get-ChildItem Cert:\LocalMachine\Root\7F88CD7223F3C813818C994614A89C99FA3B5247 | Remove-Item
Get-ChildItem Cert:\LocalMachine\Root\31F9FC8BA3805986B721EA7295C65B3A44534274 | Remove-Item
Get-ChildItem Cert:\LocalMachine\Root\06F1AA330B927B753A40E68CDF22E34BCBEF3352 | Remove-Item

 
#Copying pfx file to machine

new-item -ItemType Directory $dst -Force 
robocopy.exe $src $dst /e /is /copy:dat /LOG:c:\temp\microsoft_pfx_copyjob.log
 
#Pausing for 1 seconds to solve file being in use
Start-Sleep -s 1
 
#Installing the certificates
$certs = Get-ChildItem $dst
 
foreach ($cert in $certs){
    Import-Certificate -FilePath $cert.Fullname -CertStoreLocation "Cert:\LocalMachine\Root"
}

#stop logging
Stop-Transcript

# clean up temp folder
Remove-Item -Path $dst -Recurse
