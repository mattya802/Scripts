<# This script will copy registry keys and files based on a servermap.txt file for migrating servers.
    The file will be in the following format:
        ProdServer1<tab>TempServer1
        ProdServer2<tab>TempServer2
        ...
#>

#Get Current Directory
$dir = split-path -parent $MyInvocation.MyCommand.Definition

#Variables
$date = (get-date -Format 'yyyyMMdd_HHmm')
$LogFile = "$dir\Results\ResultsMigration_$date.txt"
$servers = Get-Content "$dir\ServerMaps.txt" 
$files= Get-Content "$dir\files.txt"
$regkeys = Get-Content "$dir\Regkeys.txt"

#Setup Results folder if it doesn't exist
if(-Not (Test-Path -PathType Container -Path "$dir\Results") ) {New-Item -ItemType Directory -Path "$dir\Results" }

Function LogWrite ([string]$logstring, [string]$color) {
    if ($color){ Write-Host $logstring -ForegroundColor $color}
    Add-content $Logfile -value $logstring
}

foreach ($line in $servers) {
    $servermap = $line.split("`t")
    $ServerSource = $servermap[0]
    $ServerTarget = $servermap[1]
    LogWrite "$ServerSource to $ServerTarget" White

    if (-not (Test-Connection -ComputerName “$ServerSource” -Quiet -Count 1 -ErrorAction SilentlyContinue) ) {
        LogWrite "$serverSource unreachable" Red
    }else {

        if (-not ( Test-Connection -ComputerName “$ServerTarget” -Quiet -Count 1 -ErrorAction SilentlyContinue) ) {
            LogWrite "  $ServerTarget unreachable" Red
        }else {
            foreach ( $regkey in $regkeys ) {
                If(-not (Test-Path -Path "\\$ServerSource\C$\Temp") ) {
                    LogWrite "  Creating $ServerSource\C$\Temp" White
                    New-Item -ItemType Directory -Path "\\$ServerSource\C$\Temp" | out-null
                }
                $result = Invoke-Command -ComputerName $ServerSource -ScriptBlock { Reg Export $Using:regkey C:\Temp\Tempreg.reg /y }
                Copy-Item "\\$ServerSource\C$\Temp\Tempreg.reg" -Destination "\\$ServerTarget\C$\Temp" -force
                Invoke-Command -ComputerName $ServerTarget -ScriptBlock { Reg Import C:\Temp\Tempreg.reg } *>&1 | out-null
                LogWrite "  $Regkey copied from $ServerSource to $ServerTarget" White
            } #End foreach Regkey

            foreach ($file in $files) {
                if ( -not (Test-Path -Path "\\$ServerSource\$file") ){
                    LogWrite "  $ServerSource\\$file does not exist. Make sure pre-req steps are complete." "Red"
                } else {
                    Copy-Item "\\$ServerSource\$file" -Destination "\\$ServerTarget\$file" -force
                    LogWrite "  $file copied from $ServerSource to $ServerTarget" White
                }
            } #End of ForEachFile
        } #End TestConnection ServerTarget
    } #End TestConnection Server Source
    LogWrite "" White
} #End of ForEachServer

Write-Host Done! -ForegroundColor Green