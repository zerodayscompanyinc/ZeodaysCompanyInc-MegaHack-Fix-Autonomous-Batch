@echo off
:: ============================================================
::  MULTI FIXER - Windows Repair & Maintenance Toolkit
::  Fixes common Windows problems automatically:
::    - Network (DNS / IP / Winsock / TCP-IP stack)
::    - Corrupted system files (SFC + DISM)
::    - Junk / temporary files
::    - Disk errors (CHKDSK)
::    - Windows Update components
::    - Proxy / Hosts file hijacks
::    - Stuck services
::    - Group Policy / Power plan issues
::
::  USAGE:
::   1. Save this file as  MultiFixer.bat  (not .txt)
::   2. Right-click it -> Run as administrator
::   3. Choose an option, or type 0 for FULL FIX
:: ============================================================
title Multi Fixer - Windows Repair Tool
color 0A
setlocal EnableExtensions

set "LOGFILE=%SystemDrive%\MultiFixer_Log.txt"

:: ---- Admin rights check ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    cls
    echo [!] ADMINISTRATOR PRIVILEGES REQUIRED
    echo.
    echo     Right-click this file and select:
    echo     "Run as administrator"
    echo.
    pause
    exit /b 1
)

:: ============================================================
::  MAIN MENU
:: ============================================================
:menu
cls
echo ============================================================
echo                  MULTI FIXER  v1.0
echo        Windows Repair and Maintenance Toolkit
echo ============================================================
echo.
echo   [1]  Network Repair (DNS, IP, Winsock, TCP-IP)
echo   [2]  System File Checker  (sfc /scannow)
echo   [3]  DISM Component Repair
echo   [4]  Disk Cleanup + Delete Temp Files
echo   [5]  Disk Check  (CHKDSK on next reboot)
echo   [6]  Repair Windows Update Components
echo   [7]  Reset Proxy + Restore Hosts File
echo   [8]  Restart Common Stuck Services
echo   [9]  Refresh Group Policy + Power Plan
echo.
echo   [0]  FIX EVERYTHING  (runs all of the above)
echo   [R]  Restart computer now
echo   [X]  Exit
echo.
set "choice="
set /p "choice=Select an option: "

if /i "%choice%"=="1"  call :network_repair
if /i "%choice%"=="2"  call :sfc_scan
if /i "%choice%"=="3"  call :dism_repair
if /i "%choice%"=="4"  call :disk_cleanup
if /i "%choice%"=="5"  call :disk_check
if /i "%choice%"=="6"  call :update_repair
if /i "%choice%"=="7"  call :proxy_hosts
if /i "%choice%"=="8"  call :services_restart
if /i "%choice%"=="9"  call :policy_power
if /i "%choice%"=="0"  (
    call :network_repair
    call :sfc_scan
    call :dism_repair
    call :disk_cleanup
    call :disk_check
    call :update_repair
    call :proxy_hosts
    call :services_restart
    call :policy_power
    echo.
    echo  ============================================
    echo   [*] FULL FIX COMPLETE - ALL MODULES DONE
    echo  ============================================
    echo   A REBOOT IS STRONGLY RECOMMENDED.
    set /p "reboot=Restart now? [Y/N]: "
)
if /i "%reboot%"=="Y" shutdown /r /t 10 /c "Multi Fixer completed - restarting"
if /i "%choice%"=="R" shutdown /r /t 10 /c "Restart requested by Multi Fixer"
if /i "%choice%"=="X" exit /b

echo.
pause
goto menu

:: ============================================================
::  1. NETWORK REPAIR
:: ============================================================
:network_repair
echo.
echo  [1/9] Network repair: flushing DNS, renewing IP, resetting stacks...
echo  [1/9] Network repair started at %time% >> "%LOGFILE%"
ipconfig /flushdns
ipconfig /registerdns
nbtstat -R
arp -d *
netsh int ip reset "%SystemDrive%\netreset.log"
netsh winsock reset
ipconfig /release >nul 2>&1
ipconfig /renew
netsh winhttp reset proxy
ping -n 3 8.8.8.8
echo  [1/9] Network repair finished. REBOOT required for full effect.
goto :eof

:: ============================================================
::  2. SYSTEM FILE CHECKER
:: ============================================================
:sfc_scan
echo.
echo  [2/9] Scanning and repairing protected system files...
echo  [2/9] SFC scan started at %time% >> "%LOGFILE%"
sfc /scannow
echo  [2/9] SFC scan finished.
goto :eof

:: ============================================================
::  3. DISM COMPONENT REPAIR
:: ============================================================
:dism_repair
echo.
echo  [3/9] Repairing Windows image with DISM (this can take 10-20 min)...
echo  [3/9] DISM started at %time% >> "%LOGFILE%"
DISM /Online /Cleanup-Image /RestoreHealth
echo  [3/9] DISM finished.
goto :eof

:: ============================================================
::  4. DISK CLEANUP
:: ============================================================
:disk_cleanup
echo.
echo  [4/9] Cleaning temporary and junk files...
echo  [4/9] Cleanup started at %time% >> "%LOGFILE%"
del /f /q "%TEMP%\*"              >nul 2>&1
del /f /q "%LOCALAPPDATA%\Temp\*" >nul 2>&1
del /f /q "%SystemRoot%\Temp\*"   >nul 2>&1
del /f /q "%SystemRoot%\Prefetch\*" >nul 2>&1
for /d %%D in ("%TEMP%\*")            do rd /s /q "%%D" 2>nul
for /d %%D in ("%SystemRoot%\Temp\*") do rd /s /q "%%D" 2>nul
rd /s /q "%SystemDrive%\$Recycle.Bin" 2>nul
cleanmgr /sagerun:65535 >nul 2>&1
echo  [4/9] Cleanup finished.
goto :eof

:: ============================================================
::  5. DISK CHECK
:: ============================================================
:disk_check
echo.
echo  [5/9] Scheduling disk check on next reboot...
echo  [5/9] CHKDSK scheduled at %time% >> "%LOGFILE%"
echo Y | chkdsk %SystemDrive% /f /r
echo  [5/9] Disk check will run on next reboot.
goto :eof

:: ============================================================
::  6. WINDOWS UPDATE REPAIR
:: ============================================================
:update_repair
echo.
echo  [6/9] Stopping update services and clearing corrupted caches...
echo  [6/9] Update repair started at %time% >> "%LOGFILE%"
net stop wuauserv >nul 2>&1
net stop bits     >nul 2>&1
net stop cryptsvc >nul 2>&1
net stop msiserver >nul 2>&1
if exist "%SystemRoot%\SoftwareDistribution" (
    ren "%SystemRoot%\SoftwareDistribution" "SoftwareDistribution.old" >nul 2>&1
)
if exist "%SystemRoot%\System32\catroot2" (
    ren "%SystemRoot%\System32\catroot2" "catroot2.old" >nul 2>&1
)
net start wuauserv >nul 2>&1
net start bits     >nul 2>&1
net start cryptsvc >nul 2>&1
net start msiserver >nul 2>&1
echo  [6/9] Update components rebuilt. Old caches saved as *.old
goto :eof

:: ============================================================
::  7. PROXY + HOSTS RESET
:: ============================================================
:proxy_hosts
echo.
echo  [7/9] Resetting proxy settings and restoring clean hosts file...
echo  [7/9] Proxy/hosts reset at %time% >> "%LOGFILE%"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
netsh winhttp reset proxy
attrib -r -s -h "%SystemRoot%\System32\drivers\etc\hosts" >nul 2>&1
if exist "%SystemRoot%\System32\drivers\etc\hosts" (
    copy /y "%SystemRoot%\System32\drivers\etc\hosts" "%SystemRoot%\System32\drivers\etc\hosts.bak" >nul 2>&1
)
(
    echo # Hosts file reset by Multi Fixer
    echo 127.0.0.1 localhost
    echo ::1 localhost
) > "%SystemRoot%\System32\drivers\etc\hosts"
echo  [7/9] Done. Original hosts file backed up as hosts.bak
goto :eof

:: ============================================================
::  8. RESTART COMMON SERVICES
:: ============================================================
:services_restart
echo.
echo  [8/9] Restarting common stuck services...
echo  [8/9] Service restart at %time% >> "%LOGFILE%"
for %%S in (Dnscache Spooler Themes FontCache wuauserv) do (
    net stop  "%%S" >nul 2>&1
    net start "%%S" >nul 2>&1
)
echo  [8/9] Services restarted.
goto :eof

:: ============================================================
::  9. GROUP POLICY + POWER PLAN
:: ============================================================
:policy_power
echo.
echo  [9/9] Refreshing Group Policy and restoring default power plans...
echo  [9/9] GPUpdate/power at %time% >> "%LOGFILE%"
gpupdate /force
powercfg -restoredefaultschemes
echo  [9/9] Finished.
goto :eof