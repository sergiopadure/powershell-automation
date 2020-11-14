
<#
.SYNOPSIS
    Script do download the latest version of Powershell Universal Nigtly and save it to a local folder
.EXAMPLE
    Edit the $destination and $iispath variablesd then run the script
.NOTES
    Author: Padure Sergio
    Last Edit: 2020-11-14
    Version 0.8 - Creation
#>

# Find latest installer
Clear-Host
#Variable for the folder to store the temporary files in
$destination = ""
#Powershell where the Powershell Universal binary is
$iispath = ""

#Setting up other vars
$dateandtime = Get-Date -Format "dd_MM_yyyy_HH-mm"
$url = 'https://imsreleases.blob.core.windows.net/universal-nightly?restype=container&comp=list'

#Getting xml of the list of blobs
$xml = Invoke-WebRequest $url -UseBasicParsing | Select-Object -ExpandProperty 'Content'

#Mitigation for BOM bug: https://www.cryingcloud.com/blog/2017/05/11/azure-blob-storage-and-powershell-the-hard-way
[xml]$xml2 = $xml.substring(3)

#Getting the latest windows zip file
$todownload = $xml2.EnumerationResults.Blobs.Blob | Where-Object -property 'Name' -like "*Universal.win-x64.*.zip" | Sort-Object -Property 'Name' -Descending | Select-Object -first 1

#Fixing Name
$OutName = $todownload.Name
$array = $OutName -split '/'
$Number = $array[0]
$Name2 = $array[1]
$Name = [IO.Path]::GetFileNameWithoutExtension($Name2)
$dst = $destination + $Name + "_" + $Number + ".zip"

#Testing if the file is already present
$exists = Test-Path -Path $dst
If ($exists){
    Write-Host "File already exists, no action required"
} else {
    #Executing download, renaming current folder of PU and unzipping the latest version into the good folder, with a start/stop of the website in IIS to avoid any additional issues
    Invoke-WebRequest $todownload.Url -OutFile $dst
    Stop-Website -name "Powershell Universal"
    $newpath = $iispath + "_" + $dateandtime
    Rename-Item $iispath $newpath
    Expand-Archive -LiteralPath $dst -DestinationPath $iispath
    Start-Website -name "Powershell Universal"
}
