<#
.SYNOPSIS
    Conversion script from FakeNameGenerator CSVs to O365 import
.DESCRIPTION
    Script created to convert CSVs ordered from Fake Name Generator to CSVs that can be imported into Microsoft 365 to create test accounts
.PARAMETER csvpath
    Specifies the path to the FakeNameGenerator CSV file
.PARAMETER prefix
    Specifies the prefix of the file to create. Purpose is to identify the file from other similar files
.PARAMETER domain
    Specifies the domain of the tenant in which this will be imported
.EXAMPLE
    PS C:\> Convert-FakeCSVto365csv.ps1 -csvpath "C:\temp\FakeNameGenerator.csv" -prefix "FakeUser" -domain "Contoso.com"
.NOTES
    Written because of laziness and because excel sucks
#>
[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $true)]
    [string]$csvpath,
    [Parameter(Mandatory = $true)]
    [string]$prefix,
    [Parameter(Mandatory = $true)]
    [string]$domain
)

function Remove-StringDiacritic {
    <#
.SYNOPSIS
    This function will remove the diacritics (accents) characters from a string.
.DESCRIPTION
    This function will remove the diacritics (accents) characters from a string.
.PARAMETER String
    Specifies the String(s) on which the diacritics need to be removed
.PARAMETER NormalizationForm
    Specifies the normalization form to use
    https://msdn.microsoft.com/en-us/library/system.text.normalizationform(v=vs.110).aspx
.EXAMPLE
    PS C:\> Remove-StringDiacritic "L'été de Raphaël"
    L'ete de Raphael
.NOTES
    Francois-Xavier Cat
    @lazywinadmin
    lazywinadmin.com
    github.com/lazywinadmin
#>
    [CMdletBinding()]
    PARAM
    (
        [ValidateNotNullOrEmpty()]
        [Alias('Text')]
        [System.String[]]$String,
        [System.Text.NormalizationForm]$NormalizationForm = "FormD"
    )

    FOREACH ($StringValue in $String) {
        Write-Verbose -Message "$StringValue"
        try {
            # Normalize the String
            $Normalized = $StringValue.Normalize($NormalizationForm)
            $NewString = New-Object -TypeName System.Text.StringBuilder

            # Convert the String to CharArray
            $normalized.ToCharArray() |
            ForEach-Object -Process {
                if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($psitem) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
                    [void]$NewString.Append($psitem)
                }
            }

            #Combine the new string chars
            Write-Output $($NewString -as [string])
        }
        Catch {
            Write-Error -Message $Error[0].Exception.Message
        }
    }
}

#Starting the actual processing
try {
    #Importing files and preparing variables
    $dateandtime = Get-Date -Format "dd_MM_yyyy_HH-mm"
    $workdirectory = Split-Path -Path $csvpath
    $TempFile = (Get-Content $csvpath) -replace "`'", ""
    $TempFile = Remove-StringDiacritic $TempFile
    $CSVImport = ConvertFrom-Csv $TempFile
    $finalobject = @()

    Write-Output "Processing"
    #Building the psobject
    foreach ($user in $CSVImport) {
        $tempobject = New-Object -TypeName PSObject
        $name = $user | Select-Object -ExpandProperty 'GivenName'
        $surname = $user | Select-Object -ExpandProperty 'Surname'
        $username = "$name" + "$surname" + "@" + "$domain"
        $username = $username -replace " ", ""
        $tempobject | Add-Member -MemberType NoteProperty -Name "User Name" -Value $username
        $tempobject | Add-Member -MemberType NoteProperty -Name "First Name" -Value $name
        $tempobject | Add-Member -MemberType NoteProperty -Name "Last Name" -Value $surname
        $displayname = "$name" + " " + "$surname"
        $tempobject | Add-Member -MemberType NoteProperty -Name "Display Name" -Value $displayname
        $tempobject | Add-Member -MemberType NoteProperty -Name "Job Title" -Value ($user | Select-Object -ExpandProperty 'Occupation')
        $tempobject | Add-Member -MemberType NoteProperty -Name "Department" -Value ($user | Select-Object -ExpandProperty 'Company')
        $tempobject | Add-Member -MemberType NoteProperty -Name "Office Number" -Value ($user | Select-Object -ExpandProperty 'Number')
        $tempobject | Add-Member -MemberType NoteProperty -Name "Office Phone" -Value $null
        $tempobject | Add-Member -MemberType NoteProperty -Name "Mobile Phone" -Value $null
        $tempobject | Add-Member -MemberType NoteProperty -Name "Fax" -Value $null
        $tempobject | Add-Member -MemberType NoteProperty -Name "Address" -Value ($user | Select-Object -ExpandProperty 'StreetAddress')
        $tempobject | Add-Member -MemberType NoteProperty -Name "City" -Value ($user | Select-Object -ExpandProperty 'City')
        $tempobject | Add-Member -MemberType NoteProperty -Name "State or Province" -Value $($user | Select-Object -ExpandProperty 'StateFull')
        $tempobject | Add-Member -MemberType NoteProperty -Name "IP or Postal Code" -Value ($user | Select-Object -ExpandProperty 'ZipCode')
        $tempobject | Add-Member -MemberType NoteProperty -Name "Country or Region" -Value ($user | Select-Object -ExpandProperty 'CountryFull')
        $finalobject += $tempobject
    }
    Write-Output "Exporting CSV"
    $finalobject | Export-Csv -NoTypeInformation -Path "$workdirectory\$prefix-Fake365Import-$dateandtime.csv" 
    Write-Output "Exporting txt"
    $finalobject | Select-Object -ExpandProperty "User Name" | Out-File -FilePath "$workdirectory\$prefix-Fake365ImportforAutomation-$dateandtime.txt"

}
catch {
    $_
}