#Script do download the latest version of Powershell Universal Nigtly and save it to a local folder
#Find latest installer
Clear-Host
$destination = "C:\temp\Nightly\"
$url = 'https://imsreleases.blob.core.windows.net/universal-nightly?restype=container&comp=list'

$xml = Invoke-WebRequest $url -UseBasicParsing | Select-Object -ExpandProperty 'Content'

#Mitigation for BOM bug: https://www.cryingcloud.com/blog/2017/05/11/azure-blob-storage-and-powershell-the-hard-way
[xml]$xml2 = $xml.substring(3)

#Getting the latest zip file
$todownload = $xml2.EnumerationResults.Blobs.Blob | Where-Object -property 'Name' -like "*Universal.win-x64.1.5.*.zip" | Sort-Object -Property 'Name' -Descending | Select-Object -first 1

#Fixing Name
$OutName = $todownload.Name
$array = $OutName -split '/'
$Number = $array[0]
$Name2 = $array[1]
$Name = [IO.Path]::GetFileNameWithoutExtension($Name2)
$dst = $destination + $Name + "_" + $Number + ".zip"

Invoke-WebRequest $todownload.Url -OutFile $dst
