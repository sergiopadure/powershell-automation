$SIDs = get-vm | Select-Object -ExpandProperty VMID | Select-Object -ExpandProperty 'Guid'
$folder = "C:\VM"

foreach ($SID in $SIDs){
    $SIDcode = "$SID" + ":(OI)(CI)(F)"
    icacls $folder /grant $SIDcode
}