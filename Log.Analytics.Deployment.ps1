#Establishing variables
$WorkingDirectory = "C:\temp"
$WDExists = Test-Path -Path $WorkingDirectory
$Installer = "MMASetup-AMD64.exe"
$InstallerFullPath = Join-Path -Path $WorkingDirectory -ChildPath $Installer
$downloadpath = "https://go.microsoft.com/fwlink/?LinkId=828603"
$workspaceid = "YourWorkSpaceID"
$workspacekey = "YourWorkSpaceKey"


#Starting processing
if (-not $WDExists){
    New-Item -Path $WorkingDirectory -ItemType 'directory'
}
Set-Location $WorkingDirectory
$Installerexists = Test-Path -Path $InstallerFullPath
if (-not $Installerexists)
    {
            Invoke-WebRequest -Uri $downloadpath -OutFile $InstallerFullPath | Out-Null
    }
$arguments = '/C:"setup.exe /qn NOAPM=1 ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_ID=' + $workspaceid + ' OPINSIGHTS_WORKSPACE_KEY=' + $workspacekey + ' AcceptEndUserLicenseAgreement=1"'
Start-Process -FilePath $InstallerFullPath -ArgumentList $arguments -ErrorAction Stop -Wait