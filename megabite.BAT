@echo off
title GodMode System Toolkit
color 0A
setlocal enabledelayedexpansion

:: ============================================================
:: 1) SELF-ELEVATE TO ADMINISTRATOR (manual confirmation)
:: ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [i] Administrator rights required.
    echo [i] A UAC prompt will appear - click YES.
    echo.
    timeout /t 2 /nobreak >nul
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: ============================================================
:: 2) MAIN MENU - every action is manual, you choose each time
:: ============================================================
:menu
cls
echo ============================================================
echo              GODMODE SYSTEM TOOLKIT - MAIN MENU
echo ============================================================
echo.
echo   [1]  Create GodMode Folder (all Windows settings in one place)
echo   [2]  Full System Information Report
echo   [3]  System File Checker  (sfc /scannow)
echo   [4]  DISM Repair Tool     (online image health)
echo   [5]  Disk Cleanup Tools   (cleanmgr + temp files)
echo   [6]  Network Diagnostics  (ipconfig, ping, flushdns, tracert)
echo   [7]  Performance Tweaks   (registry optimizations)
echo   [8]  Privacy Tweaks       (disable telemetry, etc.)
echo   [9]  Create System Restore Point
echo  [10]  Launch Windows Tools (Control Panel, Task Manager, etc.)
echo  [11]  Quick System Shortcuts (apps, folders)
echo  [12]  Backup Registry
echo  [13]  Exit
echo.
set /p choice="Select an option [1-13]: "

if "%choice%"=="1"  goto godmode
if "%choice%"=="2"  goto sysinfo
if "%choice%"=="3"  goto sfc
if "%choice%"=="4"  goto dism
if "%choice%"=="5"  goto diskclean
if "%choice%"=="6"  goto netdiag
if "%choice%"=="7"  goto perf
if "%choice%"=="8"  goto privacy
if "%choice%"=="9"  goto restorepoint
if "%choice%"=="10" goto wintools
if "%choice%"=="11" goto shortcuts
if "%choice%"=="12" goto backupreg
if "%choice%"=="13" exit /b
echo [x] Invalid choice.
timeout /t 2 /nobreak >nul
goto menu

:: ============================================================
:: OPTION 1 - GODMODE FOLDER
:: ============================================================
:godmode
cls
echo [i] Creating GodMode folder on Desktop...
set "gm=GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
if exist "%USERPROFILE%\Desktop\%gm%" (
    echo [i] GodMode folder already exists on Desktop.
) else (
    mkdir "%USERPROFILE%\Desktop\%gm%" 2>nul && echo [OK] Created: %USERPROFILE%\Desktop\%gm%
)
echo [i] Open it to browse every Windows setting (200+ shortcuts).
echo.
pause
goto menu

:: ============================================================
:: OPTION 2 - SYSTEM INFORMATION
:: ============================================================
:sysinfo
cls
echo ============================================================
echo                  SYSTEM INFORMATION REPORT
echo ============================================================
echo.
echo [Hostname]      %COMPUTERNAME%
echo [User]          %USERNAME%
echo [OS]            
for /f "tokens=4-5 delims=. " %%a in ('ver') do echo                 Windows version %%a.%%b
echo [Processor]     
wmic cpu get name /value | find "="
echo [RAM Total]     
wmic ComputerSystem get TotalPhysicalMemory /value | find "="
echo [GPU]           
wmic path win32_VideoController get name /value | find "="
echo [Disk]          
wmic logicaldisk get caption,size,freespace /format:list | find "="
echo [Motherboard]   
wmic baseboard get product,manufacturer /value | find "="
echo [BIOS]          
wmic bios get smbiosbiosversion,releasedate /value | find "="
echo [Windows Key]   
wmic path softwarelicensingservice get OA3xOriginalProductKey /value 2>nul | find "="
echo [Uptime]        
powershell -Command "(Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime" 
echo [IP Address]    
ipconfig | findstr /i "IPv4"
echo.
pause
goto menu

:: ============================================================
:: OPTION 3 - SFC SCANNOW
:: ============================================================
:sfc
cls
echo [i] Running System File Checker - this can take several minutes.
echo [i] It will NOT fix anything without asking; run sfc /verifyonly
echo     first to just check integrity if you prefer.
echo.
sfc /scannow
echo.
echo [i] SFC finished. Exit code: %errorlevel%
echo     (0 = no violations found, 1 = fixed, 2 = reboot needed)
pause
goto menu

:: ============================================================
:: OPTION 4 - DISM REPAIR
:: ============================================================
:dism
cls
echo ============================================================
echo                 DISM REPAIR OPTIONS
echo ============================================================
echo   [A] Check health only  (dism /online /cleanup-image /checkhealth)
echo   [B] Full scan          (dism /online /cleanup-image /scanhealth)
echo   [C] Restore health     (dism /online /cleanup-image /restorehealth)
echo   [X] Back to main menu
echo.
set /p dch="Choose: "
if /i "%dch%"=="a" dism /online /cleanup-image /checkhealth
if /i "%dch%"=="b" dism /online /cleanup-image /scanhealth
if /i "%dch%"=="c" dism /online /cleanup-image /restorehealth
if /i "%dch%"=="x" goto menu
echo.
pause
goto dism

:: ============================================================
:: OPTION 5 - DISK CLEANUP
:: ============================================================
:diskclean
cls
echo ============================================================
echo                 DISK CLEANUP OPTIONS
echo ============================================================
echo   [A] Windows Disk Cleanup GUI  (cleanmgr)
echo   [B] Clean Temp files          (user + system temp)
echo   [C] Clean Windows Update cache
echo   [D] Empty Recycle Bin
echo   [X] Back to main menu
echo.
set /p dc="Choose: "
if /i "%dc%"=="a" (
    echo [i] Launching Disk Cleanup - select drive and categories manually.
    cleanmgr
)
if /i "%dc%"=="b" (
    echo [i] Cleaning temp files...
    del /q /f /s "%TEMP%\*" >nul 2>&1
    del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
    echo [OK] Temp files cleaned (in-use files skipped).
)
if /i "%dc%"=="c" (
    echo [i] Cleaning Windows Update cache...
    net stop wuauserv >nul 2>&1
    del /q /f /s "C:\Windows\SoftwareDistribution\Download\*" >nul 2>&1
    net start wuauserv >nul 2>&1
    echo [OK] Update cache cleaned.
)
if /i "%dc%"=="d" (
    echo [i] Emptying Recycle Bin...
    powershell -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
    echo [OK] Recycle Bin emptied.
)
if /i "%dc%"=="x" goto menu
echo.
pause
goto diskclean

:: ============================================================
:: OPTION 6 - NETWORK DIAGNOSTICS
:: ============================================================
:netdiag
cls
echo ============================================================
echo                NETWORK DIAGNOSTICS
echo ============================================================
echo   [A] Show IP configuration    (ipconfig /all)
echo   [B] Ping gateway + 8.8.8.8
echo   [C] Flush DNS cache
echo   [D] Trace route to a host
echo   [E] Show active connections  (netstat -ano)
echo   [X] Back to main menu
echo.
set /p nc="Choose: "
if /i "%nc%"=="a" ipconfig /all
if /i "%nc%"=="b" (
    ipconfig | findstr /i "Default Gateway" >nul 2>&1
    for /f "tokens=13" %%g in ('ipconfig ^| findstr /i "Default Gateway"') do (
        echo [i] Pinging gateway %%g ...
        ping -n 4 %%g
    )
    echo [i] Pinging 8.8.8.8 ...
    ping -n 4 8.8.8.8
)
if /i "%nc%"=="c" (
    ipconfig /flushdns
    echo [OK] DNS cache flushed.
)
if /i "%nc%"=="d" (
    set /p trhost="Host to trace (default: google.com): "
    if "!trhost!"=="" set trhost=google.com
    tracert !trhost!
)
if /i "%nc%"=="e" netstat -ano
if /i "%nc%"=="x" goto menu
echo.
pause
goto netdiag

:: ============================================================
:: OPTION 7 - PERFORMANCE TWEAKS (registry, reversible)
:: ============================================================
:perf
cls
echo ============================================================
echo              PERFORMANCE TWEAKS  (manual selection)
echo ============================================================
echo   [A] Disable visual effects animations (faster UI)
echo   [B] Set processor scheduling to Programs
echo   [C] Disable Superfetch/SysMain (SSD users)
echo   [D] Disable startup delay (PreloadApp)
echo   [E] Menu show delay to 0
echo   [F] Show seconds in taskbar clock
echo   [X] Back to main menu
echo.
echo   [i] All tweaks are registry changes; a restore point is
echo       recommended first (option 9). Each tweak asks Y/N.
echo.
set /p pc="Choose: "
if /i "%pc%"=="a" (
    set /p ok="Disable UI animations? [Y/N]: "
    if /i "!ok!"=="y" reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f
    if /i "!ok!"=="y" reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f
)
if /i "%pc%"=="b" (
    set /p ok="Set scheduling to Programs? [Y/N]: "
    if /i "!ok!"=="y" reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f
)
if /i "%pc%"=="c" (
    set /p ok="Disable SysMain (Superfetch)? [Y/N]: "
    if /i "!ok!"=="y" sc config SysMain start= disabled
    if /i "!ok!"=="y" sc stop SysMain
)
if /i "%pc%"=="d" (
    set /p ok="Disable PreloadApp startup delay? [Y/N]: "
    if /i "!ok!"=="y" reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f
)
if /i "%pc%"=="e" (
    set /p ok="Set menu delay to 0? [Y/N]: "
    if /i "!ok!"=="y" reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f
)
if /i "%pc%"=="f" (
    set /p ok="Show seconds in taskbar clock? [Y/N]: "
    if /i "!ok!"=="y" reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSecondsInSystemClock /t REG_DWORD /d 1 /f
)
if /i "%pc%"=="x" goto menu
echo.
echo [i] Some changes require sign-out or reboot to take effect.
pause
goto perf

:: ============================================================
:: OPTION 8 - PRIVACY TWEAKS
:: ============================================================
:privacy
cls
echo ============================================================
echo                PRIVACY TWEAKS  (manual selection)
echo ============================================================
echo   [A] Disable telemetry (DiagTrack)
echo   [B] Disable Wi-Fi Sense / ad ID tracking
echo   [C] Disable Cortana
echo   [D] Disable advertising ID
echo   [E] Disable feedback requests
echo   [X] Back to main menu
echo.
set /p pr="Choose: "
if /i "%pr%"=="a" (
    set /p ok="Disable telemetry service? [Y/N]: "
    if /i "!ok!"=="y" sc config DiagTrack start= disabled
    if /i "!ok!"=="y" sc stop DiagTrack
    if /i "!ok!"=="y" reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
)
if /i "%pr%"=="b" (
    set /p ok="Disable advertising ID tracking? [Y/N]: "
    if /i "!ok!"=="y" reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f
)
if /i "%pr%"=="c" (
    set /p ok="Disable Cortana? [Y/N]: "
    if /i "!ok!"=="y" reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f
)
if /i "%pr%"=="d" (
    set /p ok="Disable ad ID (HKLM)? [Y/N]: "
    if /i "!ok!"=="y" reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v DisabledByGroupPolicy /t REG_DWORD /d 1 /f
)
if /i "%pr%"=="e" (
    set /p ok="Disable feedback prompts? [Y/N]: "
    if /i "!ok!"=="y" reg add "HKCU\Software\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f
)
if /i "%pr%"=="x" goto menu
echo.
pause
goto privacy

:: ============================================================
:: OPTION 9 - RESTORE POINT
:: ============================================================
:restorepoint
cls
echo [i] Creating a System Restore Point...
powershell -Command "Checkpoint-Computer -Description 'GodMode Toolkit' -RestorePointType MODIFY_SETTINGS"
if %errorlevel% equ 0 (
    echo [OK] Restore point created successfully.
) else (
    echo [x] Failed. Note: System Protection must be enabled for the
    echo     system drive (System Properties ^> System Protection).
)
echo.
pause
goto menu

:: ============================================================
:: OPTION 10 - WINDOWS TOOLS MENU
:: ============================================================
:wintools
cls
echo ============================================================
echo                 WINDOWS TOOLS LAUNCHER
echo ============================================================
echo   [A] Control Panel              [B] Task Manager
echo   [C] Device Manager             [D] Services
echo   [E] Disk Management            [F] Event Viewer
echo   [G] Registry Editor            [H] Group Policy (gpedit)
echo   [I] System Properties          [J] Network Connections
echo   [K] Power Options              [L] Programs and Features
echo   [M] Computer Management        [N] Command Prompt (admin)
echo   [O] PowerShell (admin)         [X] Back to main menu
echo.
set /p wt="Choose: "
if /i "%wt%"=="a" start control
if /i "%wt%"=="b" start taskmgr
if /i "%wt%"=="c" start devmgmt.msc
if /i "%wt%"=="d" start services.msc
if /i "%wt%"=="e" start diskmgmt.msc
if /i "%wt%"=="f" start eventvwr.msc
if /i "%wt%"=="g" start regedit
if /i "%wt%"=="h" start gpedit.msc
if /i "%wt%"=="i" start sysdm.cpl
if /i "%wt%"=="j" start ncpa.cpl
if /i "%wt%"=="k" start powercfg.cpl
if /i "%wt%"=="l" start appwiz.cpl
if /i "%wt%"=="m" start compmgmt.msc
if /i "%wt%"=="n" start cmd
if /i "%wt%"=="o" start powershell
if /i "%wt%"=="x" goto menu
echo.
pause
goto wintools

:: ============================================================
:: OPTION 11 - QUICK SHORTCUTS
:: ============================================================
:shortcuts
cls
echo ============================================================
echo                QUICK SHORTCUTS LAUNCHER
echo ============================================================
echo   [A] Downloads folder          [B] Documents folder
echo   [C] Windows folder            [D] System32
echo   [E] Notepad                   [F] Calculator
echo   [G] Run dialog                [H] This PC (Explorer)
echo   [I] Recycle Bin               [J] Task Scheduler
echo   [K] Startup folder            [L] Hosts file (notepad)
echo   [M] Environment Variables     [X] Back to main menu
echo.
set /p sc="Choose: "
if /i "%sc%"=="a" start explorer "%USERPROFILE%\Downloads"
if /i "%sc%"=="b" start explorer "%USERPROFILE%\Documents"
if /i "%sc%"=="c" start explorer C:\Windows
if /i "%sc%"=="d" start explorer C:\Windows\System32
if /i "%sc%"=="e" start notepad
if /i "%sc%"=="f" start calc
if /i "%sc%"=="g" start rundll32 shell32.dll,#61
if /i "%sc%"=="h" start explorer
if /i "%sc%"=="i" start explorer shell:RecycleBinFolder
if /i "%sc%"=="j" start taskschd.msc
if /i "%sc%"=="k" start explorer shell:startup
if /i "%sc%"=="l" start notepad C:\Windows\System32\drivers\etc\hosts
if /i "%sc%"=="m" start rundll32 sysdm.cpl,EditEnvironmentVariables
if /i "%sc%"=="x" goto menu
echo.
pause
goto shortcuts

:: ============================================================
:: OPTION 12 - BACKUP REGISTRY
:: ============================================================
:backupreg
cls
set "bkf=%USERPROFILE%\Desktop\RegistryBackup_%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%.reg"
echo [i] Exporting registry to: %bkf%
reg export HKLM\SOFTWARE "%bkf%" /y
if %errorlevel% equ 0 (
    echo [OK] Registry exported successfully.
) else (
    echo [x] Export failed. Run as Administrator and try again.
)
echo.
pause
goto menu