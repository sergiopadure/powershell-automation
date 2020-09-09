<#
.SYNOPSIS
    Script to pull the list of Azure AD groups the user is part of
.EXAMPLE
    Connect to AzureAD and run the script
    PS C:\> .\Get-AzureADPrincipalGroupMembership.ps1
.NOTES
    Author: Padure Sergio
    Last Edit: 2020-09-10
    Version 1.0 - Creation

#>


$roles = Get-AzureADDirectoryRole | Select-Object -ExpandProperty 'ObjectID'
$groups = @()
$UPN = "" #Provide UPN to verify

foreach ($role in $roles) {
    #Get-AzureADDirectoryRole | Where-Object -Property 'ObjectID' -EQ "$role" | Format-Table ObjectID,DisplayName,Description -AutoSize
    $loop = Get-AzureADDirectoryRoleMember -ObjectId "$role" | Where-Object -Property 'UserPrincipalName' -EQ $UPN
    if ($loop){
        $groups += "$role"
        }
    }
foreach ($group in $groups) {
    Get-AzureADDirectoryRole | Where-Object -Property 'ObjectID' -EQ "$group" | Format-Table ObjectID,DisplayName,Description -AutoSize
    }
