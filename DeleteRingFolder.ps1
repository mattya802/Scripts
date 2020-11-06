$root = split-path -parent $MyInvocation.MyCommand.Definition
$LogFile = "$root/RingDeleteResults.txt"
$path = "C$\Program Files (x86)\MEDITECH"
$UNV = Read-Host "Enter in the Universe name"
$Ring = Read-Host "Enter in the Ring name (blank for all)"
$FullPath = "$path\$UNV.Universe\$Ring.Ring"
$BkgPath = "$path\$UNV.Universe\$Ring.Ring-BkgJob"
$DesktopPath = "C$\Users\Public\Desktop\$Ring.lnk"
$TempPath = "C$\ProgramData\Meditech\$UNV.Universe\$Ring.Ring"

Function LogWrite
{
Param ([string]$logstring)

Add-content $Logfile -value $logstring
}

IF ($Ring -eq "") {

Do {
Try {

$inputok = $true
$Cont = Read-Host "Are you sure you want to delete all Rings?"

} #End of Try

Catch {$inputok = $false}

} #End of Do

Until ($Cont -eq "No" -or $Cont -eq "Yes" -or $Cont -eq "N" -or $Cont -eq "Y")

IF ($Cont -eq "No" -or $Cont -eq "N") {

return

} #End of Continue IF

ELSE { 

$FullPath = $FullPath -replace ".{5}$"

} #End of Continue ELSE

} #End of $Ring blank IF

# Loop through machines in list.txt
Get-Content $root/list.txt | ForEach-Object -Process {

$computer = $_
"Working on $computer" | Out-Host

# Try to reach/ping machine
IF (Test-Connection $computer -Quiet) {

LogWrite $computer
LogWrite "--------------------------------------------------------"

IF (Test-Path "\\$computer\$FullPath"){

Remove-Item -LiteralPath "\\$computer\$FullPath" -Recurse
LogWrite "Removed $FullPath on $Computer."

} #End of Test-Path

ELSE {

LogWrite ".Ring Path doesn't exist"

} #End of Test-Path ELSE

IF (Test-Path "\\$computer\$BkgPath"){

Remove-Item -LiteralPath "\\$computer\$BkgPath" -Recurse
LogWrite "Removed $BkgPath on $Computer."

} #End of -BkgJob Test-Path

ELSE {

LogWrite ".Ring-BkgJob Path doesn't exist"

} #End of -BkgJob Test-Path ELSE

IF (Test-Path "\\$computer\$TempPath"){

Remove-Item -LiteralPath "\\$computer\$TempPath" -Recurse
LogWrite "Removed ProgramData on $Computer."

} #End of ProgramData Test-Path

ELSE {

LogWrite "ProgramData doesn't exist"

} #End of ProgramData Test-Path ELSE

IF (Test-Path "\\$computer\$DesktopPath"){

Remove-Item -LiteralPath "\\$computer\$DesktopPath" -Recurse
LogWrite "Removed desktop icon on $Computer."

} #End of Desktop Test-Path

ELSE {

LogWrite "Desktop icon doesn't exist"

} #End of Desktop Test-Path ELSE

} #End of Test-Connection IF

ELSE {

LogWrite "Can't access $computer"
LogWrite ""

} #End of Test-Connection ELSE

LogWrite ""

} #End of Computer ForEach

"Script Done" | Out-Host