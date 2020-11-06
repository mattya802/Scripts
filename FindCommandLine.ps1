$root = split-path -parent $MyInvocation.MyCommand.Definition
$LogFile = "$root/ProcessResults.txt"
$Processes = Get-Content $root/Processes.txt
$SearchString = Read-Host "Enter in the string you want to search for"

Do {
Try {

$inputok = $true
$Switch = Read-Host "Do you want to scan all processes?"

} #End of Try

Catch {$inputok = $false}

} #End of Do

Until ($Switch -eq "No" -or $Switch -eq "Yes" -or $Switch -eq "N" -or $Switch -eq "Y")

IF ($Switch -eq "No" -or $Switch -eq "N") {

"Please be sure processes.txt is setup in the same directory with the list of processes you want to scan." | Out-Host
Read-Host "Continue?"

}


Function LogWrite
{
Param ([string]$logstring)

Add-content $Logfile -value $logstring
}

Function LoopThroughProc
{
ForEach ($proc in $All) {

$Procid = ($proc | Select-Object ProcessID) -replace '\D+(\d+)\D+','$1'
$Command = $proc | Select-Object CommandLine

IF ($Command | Select-String -Pattern $SearchString)
{

LogWrite "$Procid : $Command"
LogWrite ""

} #End of IF
} #End of proc ForEach
} #End of Function



# Loop through machines in list.txt
Get-Content $root/list.txt | ForEach-Object -Process {

$computer = $_
"Working on $computer" | Out-Host

LogWrite $computer
LogWrite "--------------------------------------------------------"

# Try to reach/ping machine
IF (Test-Connection $computer -Quiet) {

IF ($switch -eq "yes" -or $switch -eq "Y") {

$All = Get-WmiObject Win32_Process -ComputerName $computer | Select-Object ProcessID,CommandLine
LoopThroughProc

} #End of Switch IF

ELSE {

ForEach($process in $processes) {

$All = Get-WmiObject Win32_Process -Filter "name = '$process'" -ComputerName $computer | Select-Object ProcessID,CommandLine
LoopThroughProc

} #End of Process ForEach
} #End of Else
} #End of Test-Connection IF

ELSE {

LogWrite "Can't access $computer"
LogWrite ""

} #End of ELSE
} #End of Computer ForEach

"Script Done" | Out-Host