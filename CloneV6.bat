@ECHO OFF

ECHO ****************************** HCIS Clone Routine ******************************
ECHO This routine has two options, M-AT and NPR.
ECHO *
ECHO The M-AT option stops the ANPServer Service, copies the source directory to the target 
ECHO directory, and then restarts the service. 
ECHO *
ECHO The NPR option stops the CSMagic Service, copies the VMAGICData and VMagicOther
ECHO directories from the source to the target, and then restarts the service.
ECHO *
ECHO Prereq: Do not run this until the target HCIS's have been created via the UNV
ECHO HCIS Enter/Edit routine.
ECHO ********************************************************************************
PAUSE

set /p UnvMnemonic=What is the Universe Source Mnemonic...e.g. BPT, CUS3? 
set /p UnvTMnemonic=What is the Universe Target Mnemonic...e.g. BPT, CUS61? 
set /p Version=What verion would you like to use...enter M-AT or NPR? 

ECHO You have selected %Version%.
   if %Version%==M-AT GOTO M-ATCopy
   if %Version%==NPR GOTO NPRCopy 
 
PAUSE

:M-ATCopy
set /p SourceDIR=What is the Source Directory...e.g GLDBPT.TEST615F? 
set /P TargetDIR=What is the Target Directory...e.g. CUSBPT.TEST615F? 
set /p CopyMATFrom=What is the M-AT Source Server...CUS3-FS01? 
set /p CopyMATTo= What is the M-AT Target Server...CUS61-MATFS01? 

set /p StopAnp=Would you like to stop the ANPServer on %CopyMATFrom% Server before the rename...Y/N? 
if /i "%StopAnp:~,1%" EQU "Y" sc \\%CopyMATTo% stop ANPServer

set /p StopCSFileServer=Would you like to stop the CS File Server Service on %CopyMATFrom% before the rename...Y/N? 
if /i "%StopCSFileServer:~,1%" EQU "Y" sc \\%CopyMATTo% stop "MEDITECH CS File Server"

set /p StopAnp=Would you like to stop the ANPServer on %CopyMATTo% before the rename...Y/N? 
if /i "%StopAnp:~,1%" EQU "Y" sc \\%CopyMATFrom% stop ANPServer

set /p StopCSFileServer=Would you like to stop the CS File Server Service on %CopyMATTo% before the rename...Y/N? 
if /i "%StopCSFileServer:~,1%" EQU "Y" sc \\%CopyMATFrom% stop "MEDITECH CS File Server"

RENAME \\%CopyMATTo%\E$\FOCUS\%UnvTMnemonic%.Universe\%TargetDir%.HCIS\MIS originalMIS
ECHO The MIS folder in %TargetDir% has been renamed. >> \\HCA-FS06\E$\%TargetDir%_results.txt
REM PAUSE

ECHO The Contents of %SourceDir% are copying over now... >> \\HCA-FS06\E$\%TargetDir%_results.txt
REM XCOPY \\%CopyMATFrom%\E$\FOCUS\%UnvMnemonic%.Universe\%SourceDir%.HCIS \\%CopyMATTo%\E$\FOCUS\%UnvTMnemonic%.Universe\%TargetDir%.HCIS /S
FOR /F "tokens=*" %%g IN ('dir "\\%CopyMATFrom%\E$\FOCUS\%UnvMnemonic%.Universe\%SourceDir%.HCIS" /b /ad') DO (
	ECHO Copying M-AT %%g to %TargetDir% >> \\HCA-FS06\E$\%TargetDir%_results.txt
	START ROBOCOPY \\%CopyMATFrom%\E$\FOCUS\%UnvMnemonic%.Universe\%SourceDir%.HCIS\%%g \\%CopyMATTo%\E$\FOCUS\%UnvTMnemonic%.Universe\%TargetDir%.HCIS\%%g /s
)
GOTO WAITLOOP
RMDIR \\%CopyMATTo%\E$\FOCUS\%UnvTMnemonic%.Universe\%TargetDir%.HCIS\!Errors
DEL \\%CopyMATTo%\E$\FOCUS\%UnvTMnemonic%.Universe\%TargetDir%.HCIS\!Errors
PAUSE

sc \\%CopyMATTo% start ANPServer
sc \\%CopyMATFrom% start ANPServer
sc \\%CopyMATTo% start "MEDITECH CS File Server"
sc \\%CopyMATFrom% start "MEDITECH CS File Server"

REM ECHO CsFileService and ANPServer has been started and this process is complete.
REM PAUSE

ECHO The CS File Server Service has been started and this process is complete. >> \\HCA-FS06\E$\%TargetDir%_results.txt
PAUSE

EXIT

:NPRCopy
set /p SourceDIR=What is the Source Directory...e.g GLDBPT.TEST615N? 
set /P TargetDIR=What is the Target Directory...e.g. CUSBPT.TEST615N? 
set /p CopyNPRFrom= What is the NPR Source Server.. CUS3-FS01? 
set /p CopyNPRTo= What is the NPR Target Server.. CUS61-NPRFS01? 

set /p StopAnp=Would you like to stop the ANPServer on %CopyNPRTo% before the rename...Y/N? 
if /i "%StopAnp:~,1%" EQU "Y" sc \\%CopyNPRTo% stop ANPServer

set /p StopCSFileServer=Would you like to stop the CSFileService on %CopyNPRTo% before the rename...Y/N? 
if /i "%StopCSFileServer:~,1%" EQU "Y" sc \\%CopyNPRTo% stop "MEDITECH CS File Server"

set /p StopAnp=Would you like to stop the ANPServer on %CopyNPRFrom% before the rename...Y/N? 
if /i "%StopAnp:~,1%" EQU "Y" sc \\%CopyNPRFrom% stop ANPServer

set /p StopCSFileServer=Would you like to stop the CSFileService on %CopyNPRFrom% before the rename...Y/N? 
if /i "%StopCSFileServer:~,1%" EQU "Y" sc \\%CopyNPRFrom% stop "MEDITECH CS File Server"
PAUSE

ECHO The contents of %SourceDir% will be copied to %TargetDir%.
PAUSE

RENAME \\%CopyNPRTo%\E$\VMagicData\%UnvTMnemonic%.Universe\%TargetDir%.HCIS\MIS originalMIS
RENAME \\%CopyNPRTo%\E$\VMagicOther\%UnvTMnemonic%.Universe\%TargetDir%.HCIS\MIS originalMIS
DEL \\%CopyNPRTo%\E$\VMagicData\%UnvTMnemonic%.Universe\%TargetDir%.HCIS\!D
DEL \\%CopyNPRTo%\E$\VMagicOther\%UnvTMnemonic%.Universe\%TargetDir%.HCIS\!D
ECHO The MIS folders in %TargetDir% has been renamed. >> \\HCA-FS06\E$\%TargetDir%_results.txt
PAUSE

ECHO The Contents of %SourceDir% are copying over now... >> \\HCA-FS06\E$\%TargetDir%_results.txt
REM XCOPY \\%CopyNPRFrom%\E$\VMagicData\%UnvMnemonic%.Universe\%SourceDir%.HCIS \\%CopyNPRTo%\E$\VMagicData\%UnvTMnemonic%.Universe\%TargetDir%.HCIS /S
REM XCOPY \\%CopyNPRFrom%\E$\VMagicOther\%UnvMnemonic%.Universe\%SourceDir%.HCIS \\%CopyNPRTo%\E$\VMagicOther\%UnvTMnemonic%.Universe\%TargetDir%.HCIS /S
FOR /F "tokens=*" %%g IN ('dir "\\%CopyNPRFrom%\E$\VMagicData\%UnvMnemonic%.Universe\%SourceDir%.HCIS" /b /ad') DO (
	ECHO Copying %%g VMagicData to %TargetDir% >> \\HCA-FS06\E$\%TargetDir%_results.txt
	START ROBOCOPY \\%CopyNPRFrom%\E$\VMagicData\%UnvMnemonic%.Universe\%SourceDir%.HCIS\%%g \\%CopyNPRTo%\E$\VMagicData\%UnvTMnemonic%.Universe\%TargetDir%.HCIS\%%g /s
)
START ROBOCOPY \\%CopyNPRFrom%\E$\VMagicData\%UnvMnemonic%.Universe\%SourceDir%.HCIS \\%CopyNPRTo%\E$\VMagicData\%UnvTMnemonic%.Universe\%TargetDir%.HCIS !D
FOR /F "tokens=*" %%g IN ('dir "\\%CopyNPRFrom%\E$\VMagicData\%UnvMnemonic%.Universe\%SourceDir%.HCIS" /b /ad') DO (
	ECHO Copying %%g VMagicOther to %TargetDir% >> \\HCA-FS06\E$\%TargetDir%_results.txt
	START ROBOCOPY \\%CopyNPRFrom%\E$\VMagicOther\%UnvMnemonic%.Universe\%SourceDir%.HCIS\%%g \\%CopyNPRTo%\E$\VMagicOther\%UnvTMnemonic%.Universe\%TargetDir%.HCIS\%%g /s
)
START ROBOCOPY \\%CopyNPRFrom%\E$\VMagicOther\%UnvMnemonic%.Universe\%SourceDir%.HCIS \\%CopyNPRTo%\E$\VMagicOther\%UnvTMnemonic%.Universe\%TargetDir%.HCIS !D
GOTO WAITLOOP
PAUSE

sc \\%CopyNPRTo% start ANPServer
sc \\%CopyNPRFrom% start ANPServer
sc \\%CopyNPRTo% start "MEDITECH CS File Server"
sc \\%CopyNPRFrom% start "MEDITECH CS File Server"

ECHO The CSFileService and ANP Service has been started and this process is complete. >> \\HCA-FS06\E$\%TargetDir%_results.txt
PAUSE
EXIT

:WAITLOOP
tasklist /FI "IMAGENAME eq robocopy.exe" 2>NUL | find /I /N "robocopy.exe">NUL
if "%ERRORLEVEL%"=="0" goto RUNNING
goto NOTRUNNING

:RUNNING
ping -n 11 127.0.0.1 > nul
goto WAITLOOP

:NOTRUNNING
echo %DATE% %TIME% Done for %TargetDir% >> \\HCA-FS06\E$\%TargetDir%_results.txt