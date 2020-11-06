$dir = split-path -parent $MyInvocation.MyCommand.Definition
$date = get-date -Format 'yyyyMMdd_HHmmss'
$LogFile = "$dir\Results\Results_$date.txt"
$StoppedLog = "$dir\Results\Stopped_$date.txt"
$Servers = Get-Content "$dir\servers.txt"
$Ask = Read-Host "Start all stopped service? (Y or N)"

while("Y","N" -notcontains $Ask)
{
	$Ask = Read-Host "Y or N"
}

if(-Not (Test-Path -PathType Container -Path "$dir\Results") ) {New-Item -ItemType Directory -Path "$dir\Results" | Out-Null}

if (Test-Path $LogFile) {Remove-Item $LogFile}
if (Test-Path $StoppedLog) {Remove-Item $StoppedLog}

filter NotRunning { if ($_.Status -eq "Stopped") { $_ } }
$ServicesNotRunning = @()
ForEach ($server in  $servers) {
    Write-Host "Getting services for $server"
    "Services for $server"+": " | Out-File -FilePath $LogFile -Append
    
    $results = Get-Service -ComputerName $server -DisplayName "Meditech*","ANP*","MSO*","MAST*"
    $results | Out-File -FilePath $LogFile -Append
    if ($results | NotRunning) {
        "Services for $server"+": " | Out-File -FilePath $StoppedLog -Append
        $results | NotRunning | Out-File -FilePath $StoppedLog -Append
        ForEach ($result in ($results | NotRunning)){ $ServicesNotRunning += "$server"+"="+$result.name }
    }
} #End of ForEach Server

If($Ask -eq "Y") {
    Write-Host "Starting Services:"
    ForEach($result in $ServicesNotRunning) {
        $server = $result.Split("=")[0]
        $service = $result.Split("=")[1]
        Write-Host "  $server - $service"
        #$using only supported in PS3+. Use the Invoke-Command without $using for old OSes
        #Invoke-Command –ComputerName "$server" –ScriptBlock {Param([String]$service); Start-Service -Name "$service"} -ArgumentList $service
        Invoke-Command –ComputerName "$server" –ScriptBlock {Start-Service -Name "$Using:service"}
    }
}


#Open Log Files
. $LogFile
if (Test-Path $StoppedLog) {. $StoppedLog}

Write-Host "Done!" -ForegroundColor Green