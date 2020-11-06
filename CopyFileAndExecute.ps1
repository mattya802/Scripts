#Get Current Directory
$dir = split-path -parent $MyInvocation.MyCommand.Definition

#Variables
$LogFile = "$dir/CopyResults.txt"
$date = (get-date -Format d) -replace("/")
$time = (get-date -Format t)
$servers = Get-Content "$dir\servers.txt" 
$files= Get-Content "$dir\FileArgList.txt"
#$path = Read-Host "Enter target path (use $, not :)"
$path = "C$\temp"

Function LogWrite
{
    Param ([string]$logstring)
    Add-content $Logfile -value $logstring
}

foreach ($server in $servers) {

    foreach ($line in $files) {
        $filearg = $line.split("`t")
        $file = $filearg[0]
        $arg = $filearg[1]
        $location = "\\$server\$path\$file"
        $newname = "$file"+"_zold_"+"$date"

        if (-not (Test-Path -Path \\$server\$path) ) {
            New-Item -ItemType Directory -Path "\\$server\$path"
        } #End of Folder TestPath

        if (Test-Path -Path \\$server\$path\$file){
            Rename-Item -Path \\$server\$path\$file -NewName $newname
            LogWrite "Copied $file to $server"
        } #End of File TestPath

        Copy-Item "$dir\files\$file" -Destination "\\$server\$path" -force
        Write-Host "Beginning install on $server with $path\$file $arg"
        Invoke-Command –ComputerName "$server" –ScriptBlock {Start-Process -FilePath "$Using:location" -ArgumentList $using:arg -Wait}
        Start-Sleep -m 500 # Give time for Wsman service on remote server to go back to normal

        #Delete file after executing
        if (Test-Path -Path "\\$server\$path\$file") {
            Remove-Item "\\$server\$path\$file"
        } #End of File Delete

    } #End of ForEachFile

} #End of ForEachServer

Write-Host Done! -ForegroundColor Green