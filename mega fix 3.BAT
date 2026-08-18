@echo off
title AntiIntruder - Breach Response / Anti-Hacker Toolkit
color 0C

:: ---- Admin check ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ADMIN RIGHTS REQUIRED - right-click and Run as administrator.
    pause
    exit /b 1
)

set "RPT=%SystemDrive%\BreachReport.txt"

:: ============================================================
::  MAIN MENU
:: ============================================================
:menu
cls
echo ================================================================
echo    ANTI-INTRUDER  - detect hidden attackers and remove them
echo ================================================================
echo   DETECTION:                      EVICTION / DEFENSE:
echo   1  Active connections           16  Kill process by name
echo   2  Listening ports              17  Kill process by PID
echo   3  Suspicious processes         18  Block attacker IP
echo   4  Local user accounts          19  Disable / delete account
echo   5  Administrators group         20  Delete scheduled task
echo   6  Scheduled tasks              21  Disable rogue service
echo   7  Startup entries              22  Remove startup entry
echo   8  Auto services (temp paths)   23  Force password change
echo   9  WMI backdoor check           24  Logoff remote session
echo  10  ADS hidden-stream scan       25  NETWORK KILL SWITCH
echo  11  Hidden executables           26  Restore firewall default
echo  12  Unsigned driver flag         27  Emergency hardening
echo  13  Failed logons (4625)         28  Full report to file
echo  14  Account created (4720)       29  Unblock an IP
echo  15  New service events (7045)     0  Exit
echo ================================================================
set /p n="Pick: "
if "%n%"=="1"  call :ir_conn
if "%n%"=="2"  call :ir_listen
if "%n%"=="3"  call :ir_susproc
if "%n%"=="4"  call :ir_users
if "%n%"=="5"  call :ir_admins
if "%n%"=="6"  call :ir_tasks
if "%n%"=="7"  call :ir_startup
if "%n%"=="8"  call :ir_services
if "%n%"=="9"  call :ir_wmi
if "%n%"=="10" call :ir_ads
if "%n%"=="11" call :ir_hidden
if "%n%"=="12" call :ir_drivers
if "%n%"=="13" call :ir_logons
if "%n%"=="14" call :ir_acctcreate
if "%n%"=="15" call :ir_svcinstall
if "%n%"=="16" call :ir_killname
if "%n%"=="17" call :ir_killpid
if "%n%"=="18" call :ir_blockip
if "%n%"=="19" call :ir_user
if "%n%"=="20" call :ir_deltask
if "%n%"=="21" call :ir_svc
if "%n%"=="22" call :ir_runentry
if "%n%"=="23" call :ir_passwd
if "%n%"=="24" call :ir_logoff
if "%n%"=="25" call :ir_killswitch
if "%n%"=="26" call :ir_fwrestore
if "%n%"=="27" call :ir_harden
if "%n%"=="28" call :ir_report
if "%n%"=="29" call :ir_unblock
if "%n%"=="0"  exit /b
pause
goto menu

:: ============================================================
::  DETECTION
:: ============================================================
:ir_conn
echo [*] ACTIVE CONNECTIONS (process = remote host):
powershell -nop -c "Get-NetTCPConnection -State Established | ForEach-Object { $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; if ($p) { Write-Host ('{0,-22} {1}:{2}  ->  {3}:{4}   PID {5}' -f $p.ProcessName, $_.LocalAddress, $_.LocalPort, $_.RemoteAddress, $_.RemotePort, $_.OwningProcess) } }"
echo [*] Look for odd processes talking to foreign IPs.
pause
goto :eof

:ir_listen
echo [*] LISTENING PORTS (open doors):
powershell -nop -c "Get-NetTCPConnection -State Listen | ForEach-Object { $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; if ($p) { Write-Host ('{0,-22} {1}:{2}   PID {3}' -f $p.ProcessName, $_.LocalAddress, $_.LocalPort, $_.OwningProcess) } }"
echo [*] Anything listening you do not recognize = suspicious.
pause
goto :eof

:ir_susproc
echo [*] PROCESSES RUNNING FROM TEMP / PUBLIC FOLDERS (red flag):
powershell -nop -c "Get-Process | Where-Object { $_.Path -match '\\Temp\\|\\AppData\\Local\\Temp\\|\\Users\\Public\\|\\Windows\\Temp\\' } | Select-Object ProcessName, Id, Path | Format-Table -AutoSize"
pause
goto :eof

:ir_users
echo [*] LOCAL USER ACCOUNTS:
powershell -nop -c "Get-LocalUser | Select-Object Name, Enabled, LastLogon | Format-Table -AutoSize"
echo [*] Any account you never created = backdoor account.
pause
goto :eof

:ir_admins
echo [*] MEMBERS OF ADMINISTRATORS:
net localgroup administrators
pause
goto :eof

:ir_tasks
echo [*] SCHEDULED TASKS (non-Microsoft = persistence candidates):
powershell -nop -c "Get-ScheduledTask | Where-Object { $_.TaskPath -notlike '\Microsoft\*' } | Select-Object TaskName, TaskPath, State | Format-Table -AutoSize"
pause
goto :eof

:ir_startup
echo [*] STARTUP ENTRIES (registry + folders):
powershell -nop -c "Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | Format-Table -AutoSize"
pause
goto :eof

:ir_services
echo [*] AUTO-START SERVICES WITH ODD PATHS (Temp/AppData):
powershell -nop -c "Get-CimInstance Win32_Service | Where-Object { $_.StartMode -eq 'Auto' -and $_.PathName -match 'Temp|AppData|Public' } | Select-Object Name, State, PathName | Format-Table -AutoSize"
pause
goto :eof

:ir_wmi
echo [*] WMI PERSISTENCE (event filters/consumers - rootkit hiding spot):
powershell -nop -c "Get-CimInstance -Namespace root/subscription -ClassName __EventFilter -ErrorAction SilentlyContinue | Select-Object Name, Query | Format-List; Get-CimInstance -Namespace root/subscription -ClassName CommandLineEventConsumer -ErrorAction SilentlyContinue | Select-Object Name, CommandLineTemplate | Format-List; Get-CimInstance -Namespace root/subscription -ClassName __FilterToConsumerBinding -ErrorAction SilentlyContinue | Select-Object Filter, Consumer | Format-List"
pause
goto :eof

:ir_ads
echo [*] ALTERNATE DATA STREAMS (hidden payloads attached to files):
powershell -nop -c "$dirs = @('C:\Windows\Temp', $env:TEMP, 'C:\ProgramData', 'C:\Users\Public'); foreach ($d in $dirs) { Get-ChildItem $d -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { $s = Get-Item $_.FullName -Stream * -ErrorAction SilentlyContinue | Where-Object { $_.Stream -ne ':$DATA' }; if ($s) { $extra = $s.Stream | Where-Object { $_ -ne ':$DATA' }; Write-Host ($_.FullName + '  -> ADS: ' + ($extra -join ',')) } } }"
echo [*] Files with hidden streams can hide executables. Delete them.
pause
goto :eof

:ir_hidden
echo [*] HIDDEN EXECUTABLES in common drop locations:
powershell -nop -c "$dirs = @('C:\Windows\Temp', $env:TEMP, 'C:\ProgramData', 'C:\Users\Public'); foreach ($d in $dirs) { Get-ChildItem $d -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -match 'Hidden' -and $_.Extension -match 'exe|dll|bat|cmd|ps1|vbs|scr' } | Select-Object FullName | Format-Table -AutoSize }"
pause
goto :eof

:ir_drivers
echo [*] DRIVERS MARKED NOT SIGNED (possible rootkit):
driverquery /v /fo csv | findstr /i "false"
echo [*] Unsigned kernel drivers = high-risk. Note names, verify online.
pause
goto :eof

:ir_logons
echo [*] LATEST FAILED LOGON ATTEMPTS (4625) - brute force source:
wevtutil qe Security "/q:*[System[(EventID=4625)]]" /c:8 /rd:true /f:text
pause
goto :eof

:ir_acctcreate
echo [*] RECENTLY CREATED ACCOUNTS (4720) - backdoor detection:
wevtutil qe Security "/q:*[System[(EventID=4720)]]" /c:8 /rd:true /f:text
pause
goto :eof

:ir_svcinstall
echo [*] RECENTLY INSTALLED SERVICES (7045) - persistence detection:
wevtutil qe System "/q:*[System[(EventID=7045)]]" /c:8 /rd:true /f:text
pause
goto :eof

:: ============================================================
::  EVICTION / DEFENSE
:: ============================================================
:ir_killname
set /p p="Process name (with .exe): "
taskkill /F /IM "%p%" /T
echo [*] Kill attempt on %p% done.
pause
goto :eof

:ir_killpid
set /p p="PID: "
taskkill /F /PID %p% /T
pause
goto :eof

:ir_blockip
set /p ip="Attacker IP: "
netsh advfirewall firewall add rule name="BlockIn %ip%" dir=in action=block remoteip=%ip%
netsh advfirewall firewall add rule name="BlockOut %ip%" dir=out action=block remoteip=%ip%
echo [*] IP %ip% blocked inbound AND outbound.
pause
goto :eof

:ir_unblock
set /p ip="IP to unblock: "
netsh advfirewall firewall delete rule name="BlockIn %ip%"
netsh advfirewall firewall delete rule name="BlockOut %ip%"
echo [*] Unblocked.
pause
goto :eof

:ir_user
set /p u="Username: "
echo  1 = disable   2 = delete
set /p m="Mode: "
if "%m%"=="1" net user "%u%" /active:no
if "%m%"=="2" net user "%u%" /delete
echo [*] Done.
pause
goto :eof

:ir_deltask
set /p t="Task name (exact, from menu 6): "
schtasks /delete /tn "%t%" /f
pause
goto :eof

:ir_svc
set /p s="Service name (from menu 8): "
sc stop "%s%" >nul 2>&1
sc config "%s%" start= disabled
echo [*] Service %s% stopped and disabled.
pause
goto :eof

:ir_runentry
set /p v="Startup value name (from menu 7): "
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "%v%" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "%v%" /f >nul 2>&1
echo [*] Startup entry %v% removed (also check Startup folders manually).
pause
goto :eof

:ir_passwd
set /p u="Username: "
set /p pw="New password (press Enter to force change at next logon): "
if "%pw%"=="" (
    net user "%u%" /logonpasswordchg:yes
    echo [*] %u% must set a new password at next logon.
) else (
    net user "%u%" "%pw%"
    echo [*] Password changed.
)
pause
goto :eof

:ir_logoff
echo [*] CURRENT SESSIONS:
query session
set /p id="Session ID to logoff: "
logoff %id%
pause
goto :eof

:ir_killswitch
echo [*] KILL SWITCH: blocking ALL inbound AND outbound traffic now.
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound
echo [*] System isolated from the network. Use option 26 to restore.
pause
goto :eof

:ir_fwrestore
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound
echo [*] Firewall back to default (inbound blocked, outbound allowed).
pause
goto :eof

:ir_harden
echo [*] EMERGENCY HARDENING...
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
net accounts /lockoutthreshold:5 /lockoutduration:15 /lockoutwindow:15
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel /t REG_DWORD /d 5 /f
netsh advfirewall set allprofiles state on
echo [*] Auditing on, lockout on, UAC on, RDP off, NTLMv2 only, firewall on.
echo [*] REBOOT REQUIRED.
pause
goto :eof

:: ============================================================
::  FULL REPORT
:: ============================================================
:ir_report
echo Building report: %RPT%
echo ============ ANTI-INTRUDER REPORT %date% %time% ============ > "%RPT%"
echo. >> "%RPT%"
echo === 1. ACTIVE CONNECTIONS === >> "%RPT%"
powershell -nop -c "Get-NetTCPConnection -State Established | ForEach-Object { $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; if ($p) { Write-Output ('{0} {1}:{2} -> {3}:{4} PID {5}' -f $p.ProcessName, $_.LocalAddress, $_.LocalPort, $_.RemoteAddress, $_.RemotePort, $_.OwningProcess) } }" >> "%RPT%"
echo. >> "%RPT%"
echo === 2. LISTENING PORTS === >> "%RPT%"
powershell -nop -c "Get-NetTCPConnection -State Listen | ForEach-Object { $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; if ($p) { Write-Output ('{0} {1}:{2} PID {3}' -f $p.ProcessName, $_.LocalAddress, $_.LocalPort, $_.OwningProcess) } }" >> "%RPT%"
echo. >> "%RPT%"
echo === 3. USER ACCOUNTS === >> "%RPT%"
powershell -nop -c "Get-LocalUser | Select-Object Name, Enabled, LastLogon | Format-Table -AutoSize | Out-String" >> "%RPT%"
echo === 4. ADMINISTRATORS === >> "%RPT%"
net localgroup administrators >> "%RPT%"
echo. >> "%RPT%"
echo === 5. NON-MICROSOFT TASKS === >> "%RPT%"
powershell -nop -c "Get-ScheduledTask | Where-Object { $_.TaskPath -notlike '\Microsoft\*' } | Select-Object TaskName, TaskPath, State | Format-Table -AutoSize | Out-String" >> "%RPT%"
echo. >> "%RPT%"
echo === 6. SUSPICIOUS SERVICES === >> "%RPT%"
powershell -nop -c "Get-CimInstance Win32_Service | Where-Object { $_.StartMode -eq 'Auto' -and $_.PathName -match 'Temp|AppData|Public' } | Select-Object Name, State, PathName | Format-Table -AutoSize | Out-String" >> "%RPT%"
echo. >> "%RPT%"
echo === 7. WMI SUBSCRIPTIONS === >> "%RPT%"
powershell -nop -c "Get-CimInstance -Namespace root/subscription -ClassName __EventFilter -ErrorAction SilentlyContinue | Select-Object Name, Query | Format-List | Out-String" >> "%RPT%"
echo. >> "%RPT%"
echo === 8. FAILED LOGONS (last 50) === >> "%RPT%"
powershell -nop -c "Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 50 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id | Format-Table -AutoSize | Out-String" >> "%RPT%"
echo. >> "%RPT%"
echo === 9. RECENT SERVICES INSTALLED === >> "%RPT%"
wevtutil qe System "/q:*[System[(EventID=7045)]]" /c:10 /rd:true /f:text >> "%RPT%"
echo. >> "%RPT%"
echo Report written to %RPT%
pause
goto :eof