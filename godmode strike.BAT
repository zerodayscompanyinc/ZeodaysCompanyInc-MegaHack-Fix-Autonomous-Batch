@echo off
setlocal enabledelayedexpansion
title GodStrike - Ultimate God Mode Toolkit
color 0A
mode con cols=100 lines=50

:: ============================================================
:: SELF-ELEVATE TO ADMINISTRATOR (manual UAC confirmation)
:: ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [i] GodStrike requires Administrator rights.
    echo [i] A UAC prompt will appear - click YES.
    echo.
    timeout /t 2 /nobreak >nul
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: ============================================================
:: DETECT WINDOWS VERSION (7 / 8 / 8.1 / 10 / 11)
:: ============================================================
for /f "tokens=2,* delims= " %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul ^| findstr /i "ProductName"') do set "OSNAME=%%b"
for /f "tokens=3 delims= " %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2^>nul ^| findstr /i "CurrentBuild"') do set "BUILD=%%a"
if "%OSNAME%"=="" set "OSNAME=Windows (unknown)"

:: ============================================================
:: BANNER
:: ============================================================
:menu
cls
echo.
echo   ██████╗  ██████╗ ██████╗ ███████╗████████╗██████╗ ██╗██╗  ██╗███████╗
echo  ██╔════╝ ██╔═══██╗██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██║██║ ██╔╝██╔════╝
echo  ██║  ███╗██║   ██║██║  ██║███████╗   ██║   ██████╔╝██║█████╔╝ █████╗
echo  ██║   ██║██║   ██║██║  ██║╚════██║   ██║   ██╔══██╗██║██╔═██╗ ██╔══╝
echo  ╚██████╔╝╚██████╔╝██████╔╝███████║   ██║   ██║  ██║██║██║  ██╗███████╗
echo   ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚══════╝
echo.
echo   Detected OS : %OSNAME%  (Build %BUILD%)
echo   Mode        : 100%% MANUAL - nothing runs without your command
echo.
echo ============================================================
echo                  GODSTRIKE MAIN MENU
echo ============================================================
echo.
echo   [1]  GodMode Creator  - original Win 7/8/10/11 folders
echo   [2]  System Information Report
echo   [3]  System File Checker  (sfc /scannow)
echo   [4]  DISM Repair Tools
echo   [5]  Disk Cleanup
echo   [6]  Network Diagnostics
echo   [7]  Performance Tweaks
echo   [8]  Privacy Tweaks
echo   [9]  Create System Restore Point
echo  [10]  Windows Tools Launcher
echo  [11]  Quick Shortcuts
echo  [12]  Backup Registry
echo  [13]  About GodStrike
echo  [14]  Exit
echo.
set /p choice="Select an option [1-14]: "

if "%choice%"=="1"  goto gm
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
if "%choice%"=="13" goto about
if "%choice%"=="14" exit /b
echo [x] Invalid choice.
timeout /t 2 /nobreak >nul
goto menu

:: ============================================================
:: OPTION 1 - GODMODE CREATOR (original trick, all Windows)
:: ============================================================
:gm
cls
echo ============================================================
echo      GODMODE CREATOR - original Windows 7/8/10/11 trick
echo ============================================================
echo.
echo   How it works: a folder named "Name.{CLSID}" becomes a
echo   full settings hub. GodMode.{ED7BA470-...} shows 200+
echo   admin tools in one window. Works on Win 7, 8, 8.1, 10, 11.
echo.
echo   [A] GodMode (All Tasks / 200+ settings)   - Win 7/8/10/11
echo   [B] GodMode-Win7   (named for Win 7)
echo   [C] GodMode-Win8   (named for Win 8/8.1)
echo   [D] GodMode-Win10  (named for Win 10)
echo   [E] GodMode-Win11  (named for Win 11)
echo   [F] Control Panel master folder
echo   [G] Network Connections folder
echo   [H] Printers and Devices folder
echo   [I] Installed Programs folder
echo   [J] Fonts folder
echo   [K] Create ALL of the above on Desktop
echo   [X] Back to main menu
echo.
set /p gdc="Choose: "
if /i "%gdc%"=="a"  call :makegm "GodMode" "{ED7BA470-8E54-465E-825C-99712043E01C}"
if /i "%gdc%"=="b"  call :makegm "GodMode-Win7" "{ED7BA470-8E54-465E-825C-99712043E01C}"
if /i "%gdc%"=="c"  call :makegm "GodMode-Win8" "{ED7BA470-8E54-465E-825C-99712043E01C}"
if /i "%gdc%"=="d"  call :makegm "GodMode-Win10" "{ED7BA470-8E54-465E-825C-99712043E01C}"
if /i "%gdc%"=="e"  call :makegm "GodMode-Win11" "{ED7BA470-8E54-465E-825C-99712043E01C}"
if /i "%gdc%"=="f"  call :makegm "ControlPanel" "{21EC2020-3AEA-1069-A2DD-08002B30309D}"
if /i "%gdc%"=="g"  call :makegm "Network" "{7007ACC7-3202-11D1-AAD2-00805FC1270E}"
if /i "%gdc%"=="h"  call :makegm "DevicesPrinters" "{2227A280-3AEA-1069-A2DE-08002B30309D}"
if /i "%gdc%"=="i"  call :makegm "Programs" "{7b81be6a-ce2b-4676-a29e-eb907a5126c5}"
if /i "%gdc%"=="j"  call :makegm "Fonts" "{D20EA4E1-3957-11d2-A40B-0C5020524153}"
if /i "%gdc%"=="k" (
    call :makegm "GodMode" "{ED7BA470-8E54-465E-825C-99712043E01C}"
    call :makegm "GodMode-Win7" "{ED7BA470-8E54-465E-825C-99712043E01C}"
    call :makegm "GodMode-Win8" "{ED7BA470-8E54-465E-825C-99712043E01C}"
    call :makegm "GodMode-Win10" "{ED7BA470-8E54-465E-825C-99712043E01C}"
    call :makegm "GodMode-Win11" "{ED7BA470-8E54-465E-825C-99712043E01C}"
    call :makegm "ControlPanel" "{21EC2020-3AEA-1069-A2DD-08002B30309D}"
    call :makegm "Network" "{7007ACC7-3202-11D1-AAD2-00805FC1270E}"
    call :makegm "DevicesPrinters" "{2227A280-3AEA-1069-A2DE-08002B30309D}"
    call :makegm "Programs" "{7b81be6a-ce2b-4676-a29e-eb907a5126c5}"
    call :makegm "Fonts" "{D20EA4E1-3957-11d2-A40B-0C5020524153}"
)
if /i "%gdc%"=="x" goto menu
echo.
echo [i] Folders created on your Desktop. Open one to browse settings.
pause
goto gm

:: helper - creates one master folder on the Desktop
:makegm
if "%~2"=="" goto :eof
set "gmpath=%USERPROFILE%\Desktop\%~1.%~2"
if exist "%gmpath%" (
    echo [i] Already exists: %~1
) else (
    mkdir "%gmpath%" 2>nul && echo [OK] Created: %~1
)
goto :eof

:: ============================================================
:: OPTION 2 - SYSTEM INFORMATION
:: ============================================================
:sysinfo
cls
echo ============================================================
echo                  SYSTEM INFORMATION REPORT
echo ============================================================
echo.
echo [OS]            %OSNAME% (Build %BUILD%)
echo [Hostname]      %COMPUTERNAME%
echo [User]          %USERNAME%
echo [Processor]
wmic cpu get name /value | find "="
echo [RAM Total]
wmic ComputerSystem get TotalPhysicalMemory /value | find "="
echo [GPU]
wmic path win32_VideoController get name /value | find "="
echo [Disks]
wmic logicaldisk get caption,size,freespace /format:list | find "="
echo [Motherboard]
wmic baseboard get product,manufacturer /value | find "="
echo [BIOS]
wmic bios get smbiosbiosversion,releasedate /value | find "="
echo [Windows Key]
wmic path softwarelicensingservice get OA3xOriginalProductKey /value 2>nul | find "="
echo [Uptime]
powershell -Command "(Get-Date) - (gcim Win32_OperatingSystem).LastBootUpTime"
echo [IPv4]
ipconfig | findstr /i "IPv4"
echo.
pause
goto menu

:: ============================================================
:: OPTION 3 - SFC
:: ============================================================
:sfc
cls
echo [i] Running System File Checker. This can take several minutes.
echo [i] Manual note: sfc /verifyonly checks without repairing;
echo     sfc /scannow (below) repairs protected files automatically.
echo.
sfc /scannow
echo.
echo [i] SFC finished. Exit code: !errorlevel!
echo     (0 = no violations, 1 = fixed, 2 = reboot required)
pause
goto menu

:: ============================================================
:: OPTION 4 - DISM
:: ============================================================
:dism
cls
echo ============================================================
echo                 DISM REPAIR OPTIONS
echo ============================================================
echo   [A] Check health only   (checkhealth - fast)
echo   [B] Full scan           (scanhealth)
echo   [C] Restore health      (restorehealth - needs internet)
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
echo   [B] Clean user + system Temp files
echo   [C] Clean Windows Update cache
echo   [D] Empty Recycle Bin
echo   [X] Back to main menu
echo.
set /p dc="Choose: "
if /i "%dc%"=="a" (
    echo [i] Launching Disk Cleanup - pick drive and categories manually.
    cleanmgr
)
if /i "%dc%"=="b" (
    set /p ok="Delete ALL temp files? (in-use files are skipped) [Y/N]: "
    if /i "!ok!"=="y" (
        del /q /f /s "%TEMP%\*" >nul 2>&1
        del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
        echo [OK] Temp files cleaned.
    )
)
if /i "%dc%"=="c" (
    set /p ok="Stop Windows Update and clear download cache? [Y/N]: "
    if /i "!ok!"=="y" (
        net stop wuauserv >nul 2>&1
        del /q /f /s "C:\Windows\SoftwareDistribution\Download\*" >nul 2>&1
        net start wuauserv >nul 2>&1
        echo [OK] Update cache cleaned.
    )
)
if /i "%dc%"=="d" (
    set /p ok="Empty the Recycle Bin? [Y/N]: "
    if /i "!ok!"=="y" (
        powershell -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
        echo [OK] Recycle Bin emptied.
    )
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
echo   [A] Show IP configuration      (ipconfig /all)
echo   [B] Ping default gateway + 8.8.8.8
echo   [C] Flush DNS cache
echo   [D] Trace route to a host
echo   [E] Show active connections    (netstat -ano)
echo   [F] Reset TCP/IP stack         (netsh winsock reset)
echo   [X] Back to main menu
echo.
set /p nc="Choose: "
if /i "%nc%"=="a" ipconfig /all
if /i "%nc%"=="b" (
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
if /i "%nc%"=="f" (
    set /p ok="Reset Winsock/TCP-IP stack? (reboot recommended after) [Y/N]: "
    if /i "!ok!"=="y" (
        netsh winsock reset
        netsh int ip reset
    )
)
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
echo              PERFORMANCE TWEAKS  (manual, Y/N each)
echo ============================================================
echo   [A] Disable UI animations (faster UI)
echo   [B] Prioritize programs over background services
echo   [C] Disable SysMain/Superfetch  (SSD users)
echo   [D] Disable startup delay
echo   [E] Menu show delay to 0
echo   [F] Show seconds in taskbar clock
echo   [G] Disable transparency effects
echo   [X] Back to main menu
echo.
echo   [i] Restore point (option 9) + registry backup (option 12)
echo       recommended before changing anything.
echo.
set /p pc="Choose: "
if /i "%pc%"=="a" (
    set /p ok="Disable UI animations? [Y/N]: "
    if /i "!ok!"=="y" (
        reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul
        reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul
        echo [OK] Animations disabled.
    )
)
if /i "%pc%"=="b" (
    set /p ok="Set scheduling to Programs? [Y/N]: "
    if /i "!ok!"=="y" (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f >nul
        echo [OK] Programs prioritized.
    )
)
if /i "%pc%"=="c" (
    set /p ok="Disable SysMain (Superfetch)? [Y/N]: "
    if /i "!ok!"=="y" (
        sc config SysMain start= disabled >nul
        sc stop SysMain >nul
        echo [OK] SysMain disabled.
    )
)
if /i "%pc%"=="d" (
    set /p ok="Disable startup delay? [Y/N]: "
    if /i "!ok!"=="y" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f >nul
        echo [OK] Startup delay removed.
    )
)
if /i "%pc%"=="e" (
    set /p ok="Set menu delay to 0? [Y/N]: "
    if /i "!ok!"=="y" (
        reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul
        echo [OK] Menu delay set to 0.
    )
)
if /i "%pc%"=="f" (
    set /p ok="Show seconds in taskbar clock? [Y/N]: "
    if /i "!ok!"=="y" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSecondsInSystemClock /t REG_DWORD /d 1 /f >nul
        echo [OK] Seconds enabled.
    )
)
if /i "%pc%"=="g" (
    set /p ok="Disable transparency effects? [Y/N]: "
    if /i "!ok!"=="y" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul
        echo [OK] Transparency disabled.
    )
)
if /i "%pc%"=="x" goto menu
echo.
echo [i] Some changes need sign-out or reboot to take effect.
pause
goto perf

:: ============================================================
:: OPTION 8 - PRIVACY TWEAKS
:: ============================================================
:privacy
cls
echo ============================================================
echo                PRIVACY TWEAKS  (manual, Y/N each)
echo ============================================================
echo   [A] Disable telemetry (DiagTrack service)
echo   [B] Disable advertising ID tracking
echo   [C] Disable Cortana
echo   [D] Disable feedback requests
echo   [E] Disable location tracking
echo   [F] Disable web search in Start menu
echo   [X] Back to main menu
echo.
set /p pr="Choose: "
if /i "%pr%"=="a" (
    set /p ok="Disable telemetry? [Y/N]: "
    if /i "!ok!"=="y" (
        sc config DiagTrack start= disabled >nul
        sc stop DiagTrack >nul
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul
        echo [OK] Telemetry disabled.
    )
)
if /i "%pr%"=="b" (
    set /p ok="Disable advertising ID? [Y/N]: "
    if /i "!ok!"=="y" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v DisabledByGroupPolicy /t REG_DWORD /d 1 /f >nul
        echo [OK] Advertising ID disabled.
    )
)
if /i "%pr%"=="c" (
    set /p ok="Disable Cortana? [Y/N]: "
    if /i "!ok!"=="y" (
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f >nul
        echo [OK] Cortana disabled.
    )
)
if /i "%pr%"=="d" (
    set /p ok="Disable feedback prompts? [Y/N]: "
    if /i "!ok!"=="y" (
        reg add "HKCU\Software\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f >nul
        echo [OK] Feedback prompts disabled.
    )
)
if /i "%pr%"=="e" (
    set /p ok="Disable location tracking? [Y/N]: "
    if /i "!ok!"=="y" (
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v Value /t REG_SZ /d Deny /f >nul
        echo [OK] Location tracking disabled.
    )
)
if /i "%pr%"=="f" (
    set /p ok="Disable web search in Start menu? [Y/N]: "
    if /i "!ok!"=="y" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f >nul
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v CortanaConsent /t REG_DWORD /d 0 /f >nul
        echo [OK] Web search disabled.
    )
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
powershell -Command "Checkpoint-Computer -Description 'GodStrike' -RestorePointType MODIFY_SETTINGS"
if !errorlevel! equ 0 (
    echo [OK] Restore point created.
) else (
    echo [x] Failed. Enable System Protection first:
    echo     System Properties ^> System Protection ^> Configure ^> On.
)
echo.
pause
goto menu

:: ============================================================
:: OPTION 10 - WINDOWS TOOLS LAUNCHER
:: ============================================================
:wintools
cls
echo ============================================================
echo                 WINDOWS TOOLS LAUNCHER
echo ============================================================
echo   [A]  Control Panel        [B]  Task Manager
echo   [C]  Device Manager       [D]  Services
echo   [E]  Disk Management      [F]  Event Viewer
echo   [G]  Registry Editor      [H]  Group Policy (gpedit)
echo   [I]  System Properties    [J]  Network Connections
echo   [K]  Power Options        [L]  Programs and Features
echo   [M]  Computer Management  [N]  Command Prompt (admin)
echo   [O]  PowerShell (admin)   [P]  System Configuration (msconfig)
echo   [Q]  Windows Features     [R]  System Info (msinfo32)
echo   [S]  DirectX Diagnostic   [T]  Resource Monitor
echo   [U]  Local Users/Group    [V]  Local Security Policy
echo   [X]  Back to main menu
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
if /i "%wt%"=="p" start msconfig
if /i "%wt%"=="q" start optionalfeatures
if /i "%wt%"=="r" start msinfo32
if /i "%wt%"=="s" start dxdiag
if /i "%wt%"=="t" start resmon
if /i "%wt%"=="u" start lusrmgr.msc
if /i "%wt%"=="v" start secpol.msc
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
echo   [A] Downloads folder    [B] Documents folder
echo   [C] Windows folder      [D] System32
echo   [E] Notepad             [F] Calculator
echo   [G] Run dialog          [H] This PC
echo   [I] Recycle Bin         [J] Task Scheduler
echo   [K] Startup folder      [L] Hosts file (notepad)
echo   [M] Environment Vars    [N] Clipboard history
echo   [X] Back to main menu
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
if /i "%sc%"=="n" start ms-settings:clipboard
if /i "%sc%"=="x" goto menu
echo.
pause
goto shortcuts

:: ============================================================
:: OPTION 12 - BACKUP REGISTRY
:: ============================================================
:backupreg
cls
set "ts=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%"
set "ts=%ts: =0%"
set "bkf=%USERPROFILE%\Desktop\GodStrike_RegistryBackup_%ts%.reg"
echo [i] Exporting HKLM\SOFTWARE to:
echo     %bkf%
reg export HKLM\SOFTWARE "%bkf%" /y
if !errorlevel! equ 0 (
    echo [OK] Registry exported successfully.
) else (
    echo [x] Export failed. Run as Administrator and retry.
)
echo.
pause
goto menu

:: ============================================================
:: OPTION 13 - ABOUT
:: ============================================================
:about
cls
echo ============================================================
echo                    ABOUT GODSTRIKE
echo ============================================================
echo.
echo   GodStrike is a fully MANUAL system toolkit:
echo   - Recreates the original GodMode folder trick
echo     (Windows 7 / 8 / 8.1 / 10 / 11)
echo   - 200+ settings exposed in one folder view
echo   - Diagnostics, repair, cleanup, tweaks - all manual
echo   - No automation, no scheduled tasks, no startup entries
echo   - Every change is either a menu choice, a Y/N confirm,
echo     or a tool you launch yourself
echo.
echo   Safety tips:
echo   - Always create a restore point (option 9) first
echo   - Back up the registry (option 12) before tweaks
echo   - Registry tweaks are reversible - delete the key or
echo     restore from backup to undo
echo.
pause
goto menu

goto :eof