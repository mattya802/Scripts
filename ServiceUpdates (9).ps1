# Initialization
#Requires -Version 5.0
$dir = split-path -parent $MyInvocation.MyCommand.Definition
$date = get-date -Format 'yyyyMMdd_HHmmss'
$logfile = "$dir\Results\Results_$date.txt"
$servers = Get-Content "$dir\servers.txt" | ForEach-Object { if ( -Not($_[0] -match "#")) { $_ } }
$services = Get-Content "$dir\services.txt" | ForEach-Object { if ( -Not($_[0] -match "#")) { $_ } }

#Directory Allocates
if (-Not (Test-Path -PathType Container -Path "$dir\Results") ) { New-Item -ItemType Directory -Path "$dir\Results" | Out-Null }

Function LogWrite ([string]$logstring, [string]$color) {
    if ($color) { Write-Host $logstring -ForegroundColor $color }
    Add-content $logfile -value $logstring
}

function GenerateForm {
   
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
    [reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null

    #Setup Form Window with variable height based on # of services
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "Update Services"
    $Form.Width = 600
    if ($services.length -gt 10) { $Form.Height = 100 + (10 * 25) }else { $Form.Height = 100 + ($services.length * 25) }
    $Form.StartPosition = "CenterScreen"

    #Setup Start Button    
    $StartButton = New-Object System.Windows.Forms.Button
    $StartButton.Text = "Start"
    $StartButton.Size = New-Object System.Drawing.Size(75, 23)
    $StartButton.Top = ($Form.Height - 75)
    $StartButton.Left = ($Form.Width - 100)
    $StartButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right

    #Setup ServicesChecked array if user hits Start button
    $StartButtonClick = {
        for ($i = 0; $i -lt $Checkboxes.Length; $i++) {
            if ($Checkboxes[$i].Checked -eq $True) {
                $Script:ServicesChecked += $services[$i]
            }
        }
        $form.Close()
    }
    $StartButton.Add_Click($StartButtonClick)
    $Form.Controls.Add($StartButton)

    #Setup Cancel Button
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Size = New-Object System.Drawing.Size(75, 23)
    $CancelButton.Top = $StartButton.Top ; $CancelButton.Left = $StartButton.Left - $StartButton.Width - 5
    $CancelButton.Left = ($Form.Width - 180)
    $CancelButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click( { $form.Close() })
    $Form.Controls.Add($CancelButton)

    $Form.AcceptButton = $StartButton          # ENTER = Ok 
    $Form.CancelButton = $CancelButton      # ESCAPE = Cancel 

    # When we create a new textbox, we add it to an array for easy reference later

    $Checkboxes = @()
    if ( $services.length -gt 10 ) { Write-Warning "Only 10 services will display/update per run." }

    #Setup the Checkboxes based on the number of services (max 10)
    For ($CheckboxCnt = 0; ($CheckboxCnt -lt $services.length) -AND ($CheckboxCnt -lt 10); $CheckboxCnt++) {

        $CheckBox = New-Object System.Windows.Forms.CheckBox        
        $CheckBox.UseVisualStyleBackColor = $True
        $CheckBox.AutoSize = $True
        $CheckBox.Text = $services[$CheckboxCnt].replace("`t", "   ")
        $System_Drawing_Point = New-Object System.Drawing.Point
        $System_Drawing_Point.X = 27
        #Vertically space them dynamically
        $System_Drawing_Point.Y = 13 + ($CheckBoxCnt * 31)
        $CheckBox.Location = $System_Drawing_Point
        $CheckBox.Name = "CheckBox$CheckBoxCnt"
        $Form.Controls.Add($CheckBox)
        #Setup array of Checkboxes to loop through after Start is clicked
        $Checkboxes += $CheckBox
    }

    #Save the initial state of the form
    $InitialFormWindowState = $Form.WindowState
    #Init the OnLoad event to correct the initial state of the form
    $Form.add_Load($OnLoadForm_StateCorrection)
    #Show the Form
    $Form.ShowDialog() | Out-Null

} #End Function


#Main

#Call Window Form and get the checked off services
$ServicesChecked = @()
GenerateForm

ForEach ($serviceinfo in $ServicesChecked) {
    $service = $serviceinfo.split("`t")[0]
    $servicesrcdir = $serviceinfo.split("`t")[1]
    $servicestop = $serviceinfo.split("`t")[3] #2 is set down below for paths without a service
    LogWrite "Updating Service: $service..." Cyan
    $servicefiles = Get-ChildItem "$dir\$servicesrcdir" -Recurse -Name -File

    ForEach ($server in  $servers) {
        if ( Test-Connection -ComputerName $server -Count 1 -ErrorAction SilentlyContinue ) {
            LogWrite "`n  $server" Magenta
                $session = New-PSSession -ComputerName "$server" -ErrorAction SilentlyContinue # Start a PS Session for Getting path and restarting service
                If ($session) {
                    #Get Path to service executable
                    $servicepath = $null
                    if ($service -ne "NONE") {
                        $servicepath = Invoke-Command -Session $session { Get-WmiObject win32_service | ? { $_.Name -eq "$using:service" } | select PathName -ExpandProperty PathName }
                    }
                    if ( $serviceinfo.split("`t")[2]) {
                        $servicepath = $serviceinfo.split("`t")[2]
                        $servicepath = $servicepath.replace(":", "$")
                        if ( -not(Test-Path -PathType Container -Path "\\$server\$servicepath") ) {$servicepath = $null}
                    }
                    elseif ($servicepath) {
                        $servicepath = ( $servicepath -split "`" `"" ) #Deal with services that reference multiple paths by searching for a space betweeen quotes
                        $servicepath = ($servicepath[0].replace( '"', "" ) | Split-Path) #Remove quotes from paths
                        $servicepath = $servicepath.replace(":", "$")
                    }
                    
                    If ( ($servicepath)) {
                        $servicepathzold = ($servicepath | Split-Path -Parent) + "\Zold_" + $date + "_" + $servicepath.split("\")[-1]

                        LogWrite "    Backing up directory: \\$server\$servicepath" White
                        Copy-Item "\\$server\$servicepath" -Destination "\\$server\$servicepathzold" -Recurse

                        #Stop Service if Stop Before Update Flag is Set to Y
                        if ( ($servicestop -eq "Y") -AND ($service -ne "NONE") ) {
                            LogWrite "    Stopping $service service for $server" White
                            Invoke-Command -Session $session -ScriptBlock { Stop-Service -Name "$using:service" }
                        }
       
                        Write-Host "    Doing Renames, Copies, and Deletes. See $logfile for more details." -ForegroundColor White
                        ForEach ($servicefile in $servicefiles) {
                            $servicefilezold = "Zold" + $date + "_" + ([io.fileinfo]$servicefile | % basename) + "." + $servicefile.split(".")[-1]
                            #If File exists in target, rename it
                            if (Test-Path -PathType leaf -Path "\\$server\$servicepath\$servicefile") {
                                LogWrite "      Renaming \\$server\$servicepath\$servicefile to $servicefilezold"
                                Rename-Item -Path \\$server\$servicepath\$servicefile -NewName $servicefilezold
                            }

                            LogWrite "      Copying $servicefile to \\$server\$servicepath\$servicefile"
                            Copy-Item "$dir\$servicesrcdir\$servicefile" -Destination "\\$server\$servicepath\$servicefile" -force

                            if ( (Get-FileHash "$dir\$servicesrcdir\$servicefile").Hash -ne (Get-FileHash "\\$server\$servicepath\$servicefile").Hash) {
                                LogWrite "      Update ERROR: File Hash mismatch for \\$server\$servicepath\$servicefile!" Red
                            }
                        } #End ForEach ServiceFile
                    } #End If $servicepath
                    if (($service -ne "NONE") -AND ($servicepath)) {
                        #Restart the Service or Start it if the Stop Before Flag was set
                        if ($servicestop -eq "Y") {
                            LogWrite "    Starting $service service for $server" White
                            Invoke-Command -Session $session -ScriptBlock { Start-Service -Name "$using:service" }
                        }
                        else {
                            LogWrite "    Restarting $service service for $server" White
                            Invoke-Command -Session $session -ScriptBlock { Restart-Service -Name "$using:service" }
                        }
                    }
                    If ($servicepath) { 
                        Logwrite "    Cleaning up renamed files..." White
                        Start-Sleep -Milliseconds 10
                        ForEach ($servicefile in $servicefiles) {
                            $servicefilezold = "Zold" + $date + "_" + ([io.fileinfo]$servicefile | % basename) + "." + $servicefile.split(".")[-1]
                            if (Test-Path -PathType leaf -Path "\\$server\$servicepath\$servicefilezold") {
                                LogWrite "      Deleting $servicefilezold"
                                Remove-Item "\\$server\$servicepath\$servicefilezold" | Out-Null
                            }
                        }
                    }
                    Disconnect-PSSession -Session $session -ErrorAction SilentlyContinue | Out-Null
                }
                else { LogWrite "Could not start Powershell Session on $server!" Red } #End  if $session
        }
        else { LogWrite "  $server unreachable" Red } #End TestConnection
    } #End ForEach Server
} #End ForEach ServiceInfo

Write-Host "Done!" -ForegroundColor Green