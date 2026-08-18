@echo off
setlocal enabledelayedexpansion
title CaleBoard - Unauthorized Access Scanner & Remover
color 0B
mode con cols=112 lines=55 >nul 2>&1

:: ============================================================
:: SELF-ELEVATE (UAC, manual confirmation)
:: ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [i] CaleBoard needs Administrator rights.
    echo [i] A UAC prompt will appear - click YES.
    echo.
    timeout /t 2 /nobreak >nul
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "LOG=%USERPROFILE%\Desktop\CaleBoard_Log.txt"
set "MODE="

:: ============================================================
:: MODE SELECTION - AUTOMATIC or MANUAL (user chooses)
:: ============================================================
:modeselect
cls
echo.
echo   ============================================================
echo               CALE BOARD  -  MODE SELECTION
echo   ============================================================
echo.
echo     [A] AUTOMATIC  - full quick-scan + deep check run
echo                      back-to-back with minimal prompts.
echo                      Removal still asks ONE confirmation
echo                      before each destructive action.
echo.
echo     [M] MANUAL     - every check and every removal is
echo                      step-by-step, Y/N per item.
echo.
echo     [X] Exit
echo.
set /p MODE="Choose mode [A/M/X]: "
if /i "%MODE%"=="a" goto menu
if /i "%MODE%"=="m" goto menu
if /i "%MODE%"=="x" exit /b
echo [x] Invalid. Type A, M or X.
timeout /t 2 /nobreak >nul
goto modeselect

:: ============================================================
:: MAIN MENU
:: ============================================================
:menu
cls
echo.
echo    ____      _      _____                 _     _
echo   / ___|__ _| | ___| ____|__ _ ___ _ __  | |__ | |__   __ _
echo  | |   / _` | |/ _ \  _| / _` / __| '_ \ | '_ \| '_ \ / _` |
echo  | |__| (_| | |  __/ |__| (_| \__ \ |_) || |_) | |_) | (_| |
echo   \____\__,_|_|\___|_____\__,_|___/ .__/ |_.__/|_.__/ \__,_|
echo                                   |_|
echo.
echo   Mode : [%MODE%]      Log  : %LOG%
echo.
echo   ============================================================
echo                 CALE BOARD MAIN MENU
echo   ============================================================
echo.
echo   [1] Quick Scan          - ~10 second sweep for active
echo                             sessions, admins, startups, RDP,
echo                             connections, shares, suspicious
echo                             processes, failed logons.
echo   [2] Deep Check          - event logs, new accounts, group
echo                             changes, WMI persistence, hidden
echo                             backdoors, hijacked Winlogon.
echo   [3] Remove/Revoke       - remove unauthorized users and
echo                             access (accounts, sessions,
echo                             startup, tasks, services, RDP...)
echo   [4] View Log
echo   [5] Exit
echo.
set /p choice="Select option [1-5]: "
if "%choice%"=="1" goto qscan
if "%choice%"=="2" goto deep
if "%choice%"=="3" goto remove
if "%choice%"=="4" goto viewlog
if "%choice%"=="5" exit /b
echo [x] Invalid choice.
timeout /t 2 /nobreak >nul
goto menu

:: ============================================================
:: HELPER - pause in MANUAL mode, brief wait in AUTO mode
:: ============================================================
:wait
if /i "%MODE%"=="a" (
    timeout /t 1 /nobreak >nul
) else (
    pause
)
exit /b

:: ============================================================
:: HELPER - write to log
:: ============================================================
:log
echo [%DATE% %TIME%] %~1 >> "%LOG%"
exit /b

:: ============================================================
:: OPTION 1 - QUICK SCAN (~10 seconds)
:: ============================================================
:qscan
cls
call :log "=== QUICK SCAN STARTED (mode %MODE%) ==="
echo [i] Quick Scan started. Target: ~10 seconds.
echo.
for /f %%a in ('powershell -NoProfile -Command "[int64][double](Get-Date -UFormat %%s)"') do set "T0=%%a"
set /a FINDINGS=0
echo.

echo   [01] ACTIVE SESSIONS  ---------------------------------
query user 2>nul
query user 2>nul | findstr /i "rdp-tcp" >nul && (
    echo   [!] REMOTE SESSION DETECTED - someone may be connected remotely.
    set /a FINDINGS+=1
) || (
    echo   [OK] No remote (RDP) sessions. Console only.
)
echo.
call :wait

echo   [02] ADMINISTRATOR ACCOUNTS  --------------------------
net localgroup administrators
echo.
call :wait

echo   [03] HIDDEN USER ACCOUNTS  ----------------------------
net user | findstr /i "$" >nul && (
    echo   [!] HIDDEN USER ACCOUNT(S) FOUND:
    net user | findstr /i "$"
    set /a FINDINGS+=1
) || (
    echo   [OK] No hidden (name ending with $) user accounts.
)
echo.
call :wait

echo   [04] GUEST ACCOUNT  -----------------------------------
net user guest | findstr /i "active" | findstr /i "yes" >nul && (
    echo   [!] GUEST ACCOUNT IS ENABLED - disable it (option 3).
    set /a FINDINGS+=1
) || (
    echo   [OK] Guest account is disabled.
)
echo.
call :wait

echo   [05] STARTUP ENTRIES (Run keys + Startup folder) ------
set "RUNFOUND=0"
for %%k in (
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    "HKLM\Software\Microsoft\Windows\CurrentVersion\Run"
    "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce"
) do (
    reg query "%%~k" 2>nul | findstr /i "REG_SZ REG_EXPAND_SZ" >nul && (
        echo   Key: %%~k
        reg query "%%~k" 2>nul
        set RUNFOUND=1
    )
)
if "!RUNFOUND!"=="1" set /a FINDINGS+=1
dir /b "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" 2>nul | findstr . >nul && (
    echo   Startup folder contents:
    dir /b "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
)
echo.
call :wait

echo   [06] REMOTE DESKTOP STATUS  ---------------------------
for /f "tokens=3" %%v in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections 2^>nul ^| findstr /i "fDenyTSConnections"') do set "RDP=%%v"
if "%RDP%"=="0x0" (
    echo   [!] REMOTE DESKTOP IS ENABLED - remote access possible.
    set /a FINDINGS+=1
) else (
    echo   [OK] Remote Desktop disabled (fDenyTSConnections=1).
)
echo.
call :wait

echo   [07] NETWORK SHARES  ----------------------------------
net share
echo.
call :wait

echo   [08] LISTENING PORTS (first 20) -----------------------
netstat -ano | findstr "LISTENING" | findstr /v "127.0.0.1" | more +0
echo.
call :wait

echo   [09] ESTABLISHED OUTBOUND CONNECTIONS (first 20) ------
netstat -ano | findstr "ESTABLISHED" | more +0
echo.
call :wait

echo   [10] SUSPICIOUS PROCESSES (running from Temp/AppData) -
powershell -NoProfile -Command "Get-Process | Where-Object { $_.Path -and ($_.Path -like '*\Temp\*' -or $_.Path -like '*\AppData\*') } | Select-Object -ExpandProperty ProcessName -Unique" 2>nul | findstr . >nul && (
    echo   [!] PROCESSES RUNNING FROM USER DIRS:
    powershell -NoProfile -Command "Get-Process | Where-Object { $_.Path -and ($_.Path -like '*\Temp\*' -or $_.Path -like '*\AppData\*') } | Select-Object ProcessName,Id,Path | Format-Table -AutoSize | Out-String -Width 200" 2>nul
    set /a FINDINGS+=1
) || (
    echo   [OK] No processes running from Temp/AppData.
)
echo.

echo   [11] FAILED LOGONS (last 24h - brute force indicator) -
for /f "delims=" %%c in ('powershell -NoProfile -Command "$c=(Get-WinEvent -FilterHashtable @{LogName='Security';Id=4625;StartTime=(Get-Date).AddHours(-24)} -ErrorAction SilentlyContinue).Count; if($c){$c}else{0}"') do set "FAIL=%%c"
if defined FAIL (
    if !FAIL! GTR 0 (
        echo   [!] !FAIL! failed logon attempt(s) in the last 24 hours.
        set /a FINDINGS+=1
    ) else (
        echo   [OK] No failed logons in the last 24 hours.
    )
) else (
    echo   [OK] Security log unavailable - skipped.
)
echo.

echo   [12] NEW USER ACCOUNTS (last 7 days) ------------------
for /f "delims=" %%c in ('powershell -NoProfile -Command "$e=Get-WinEvent -FilterHashtable @{LogName='Security';Id=4720;StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue; if($e){$e.Count}else{0}"') do set "NEWU=%%c"
if defined NEWU (
    if !NEWU! GTR 0 (
        echo   [!] !NEWU! new user account(s) created in last 7 days:
        powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='Security';Id=4720;StartTime=(Get-Date).AddDays(-7)} -MaxEvents 10 -ErrorAction SilentlyContinue | ForEach-Object { '     ' + $_.TimeCreated.ToString('yyyy-MM-dd HH:mm') + '  new account: ' + $_.Properties[0].Value }" 2>nul
        set /a FINDINGS+=1
    ) else (
        echo   [OK] No new accounts in the last 7 days.
    )
) else (
    echo   [OK] Security log unavailable - skipped.
)
echo.

echo   [13] HOSTS FILE CHECK  --------------------------------
type C:\Windows\System32\drivers\etc\hosts | findstr /v "^#" | findstr . >nul && (
    echo   [!] Non-default entries in hosts file:
    type C:\Windows\System32\drivers\etc\hosts | findstr /v "^#"
    set /a FINDINGS+=1
) || (
    echo   [OK] Hosts file has no custom entries.
)
echo.

echo   [14] FIREWALL STATE  ----------------------------------
netsh advfirewall show allprofiles state | findstr /i "state"
echo.

for /f %%a in ('powershell -NoProfile -Command "[int64][double](Get-Date -UFormat %%s)"') do set "T1=%%a"
set /a DELTA=T1-T0
echo.
echo   ============================================================
echo   QUICK SCAN COMPLETE
echo   Elapsed : ~!DELTA! second(s)
echo   Findings: !FINDINGS! item(s) flagged (see [!!] above)
echo   ============================================================
call :log "QUICK SCAN finished: ~%DELTA%s, %FINDINGS% findings"
echo.
if /i "%MODE%"=="a" (
    echo [i] Automatic mode: continuing to Deep Check...
    timeout /t 3 /nobreak >nul
    goto deep
)
pause
goto menu

:: ============================================================
:: OPTION 2 - DEEP UNAUTHORIZED ACCESS CHECK
:: ============================================================
:deep
cls
call :log "=== DEEP CHECK STARTED (mode %MODE%) ==="
echo.
echo   ============================================================
echo           DEEP UNAUTHORIZED ACCESS / BACKDOOR CHECK
echo   ============================================================
echo.

echo   [A] RECENT LOGONS (4624, last 24h) --------------------
powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='Security';Id=4624;StartTime=(Get-Date).AddHours(-24)} -MaxEvents 12 -ErrorAction SilentlyContinue | ForEach-Object { $_.TimeCreated.ToString('MM-dd HH:mm') + '  type=' + $_.Properties[5].Value + '  user=' + $_.Properties[1].Value }" 2>nul | findstr . >nul && (
    powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='Security';Id=4624;StartTime=(Get-Date).AddHours(-24)} -MaxEvents 12 -ErrorAction SilentlyContinue | ForEach-Object { $_.TimeCreated.ToString('MM-dd HH:mm') + '  type=' + $_.Properties[5].Value + '  user=' + $_.Properties[1].Value }" 2>nul
    echo   (logon type 10 = RDP, 3 = network, 2 = local console)
) || echo   [OK] No logons in the last 24h (or log not available).
echo.
call :wait

echo   [B] GROUP MEMBERSHIP CHANGES (4728/4732, last 7 days) -
powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='Security';Id=4728,4732;StartTime=(Get-Date).AddDays(-7)} -MaxEvents 12 -ErrorAction SilentlyContinue | ForEach-Object { $_.TimeCreated.ToString('MM-dd HH:mm') + '  member=' + $_.Properties[0].Value + '  group=' + $_.Properties[2].Value }" 2>nul | findstr . >nul && (
    powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='Security';Id=4728,4732;StartTime=(Get-Date).AddDays(-7)} -MaxEvents 12 -ErrorAction SilentlyContinue | ForEach-Object { $_.TimeCreated.ToString('MM-dd HH:mm') + '  member=' + $_.Properties[0].Value + '  group=' + $_.Properties[2].Value }" 2>nul
) || echo   [OK] No admin group membership changes in last 7 days.
echo.
call :wait

echo   [C] ALL USERS + LAST LOGON ----------------------------
powershell -NoProfile -Command "if (Get-Command Get-LocalUser -ErrorAction SilentlyContinue) { Get-LocalUser | Select-Object Name,Enabled,LastLogon | Format-Table -AutoSize | Out-String -Width 200 } else { net user }" 2>nul
echo.
call :wait

echo   [D] WINLOGON HIJACK CHECK -----------------------------
echo   Userinit (default: C:\Windows\system32\userinit.exe):
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Userinit 2>nul | findstr /i "Userinit"
echo   Shell (default: explorer.exe):
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell 2>nul | findstr /i "Shell"
echo.
call :wait

echo   [E] WMI PERSISTENCE (event subscriptions) -------------
powershell -NoProfile -Command "Get-CimInstance -Namespace root\subscription -ClassName __EventFilter -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name; Get-CimInstance -Namespace root\subscription -ClassName CommandLineEventConsumer -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name" 2>nul | findstr . >nul && (
    echo   [!] WMI EVENT SUBSCRIPTIONS PRESENT (possible persistence):
    powershell -NoProfile -Command "Get-CimInstance -Namespace root\subscription -ClassName __EventFilter -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name" 2>nul
) || echo   [OK] No WMI event subscription persistence found.
echo.
call :wait

echo   [F] SERVICES RUNNING FROM NON-WINDOWS PATHS -----------
powershell -NoProfile -Command "Get-CimInstance Win32_Service | Where-Object { $_.PathName -and $_.PathName -notmatch 'C:\\(Windows|Program Files)' } | Select-Object -First 15 Name,State,StartMode,PathName | Format-Table -AutoSize | Out-String -Width 200" 2>nul
echo.
call :wait

echo   [G] SCHEDULED TASKS RUNNING FROM USER DIRS ------------
powershell -NoProfile -Command "Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $a=$_.Actions; $a -and ($a.Execute -like '*AppData*' -or $a.Execute -like '*Temp*') } | Select-Object -First 10 TaskName,TaskPath,State | Format-Table -AutoSize | Out-String -Width 200" 2>nul
echo.
call :wait

echo   [H] KNOWN BACKDOOR / HACKING TOOL NAMES IN PROCESSES --
tasklist 2>nul | findstr /i "ncat nc.exe socat sbd psexec mimikatz meterpreter koadic sliver cobalt beacon" >nul && (
    echo   [!] POSSIBLE BACKDOOR TOOL DETECTED:
    tasklist | findstr /i "ncat nc.exe socat sbd psexec mimikatz meterpreter koadic sliver cobalt beacon"
) || echo   [OK] No known backdoor tool names in the process list.
echo.
call :wait

echo   [I] CONNECTED NETWORK DRIVES / SESSIONS ---------------
echo   -- mapped drives:
net use
echo   -- active sessions:
query session
echo.
call :wait

echo   [J] WINLOGON / RDP SECURITY SETTINGS ------------------
echo   -- RDP (fDenyTSConnections=0 means ENABLED):
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections 2>nul | findstr /i "fDenyTSConnections"
echo   -- RDP Network Level Auth (UserAuthentication=1 is good):
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication 2>nul | findstr /i "UserAuthentication"
echo.
call :wait

echo   [K] INBOUND FIREWALL RULES ALLOWING REMOTE ------------
netsh advfirewall firewall show rule name=all dir=in action=allow 2>nul | findstr /i /c:"Rule Name" | findstr /i /v "Core Net" | more +0
echo.
echo   ============================================================
echo   DEEP CHECK COMPLETE - review anything marked [!!]
echo   then use option 3 to remove/revoke unauthorized access.
echo   ============================================================
call :log "DEEP CHECK finished"
echo.
if /i "%MODE%"=="a" (
    echo [i] Automatic mode: returning to main menu.
    timeout /t 3 /nobreak >nul
)
pause
goto menu

:: ============================================================
:: OPTION 3 - REMOVE / REVOKE UNAUTHORIZED ACCESS
:: ============================================================
:remove
cls
echo.
echo   ============================================================
echo           REMOVE / REVOKE ACCESS  (mode: %MODE%)
echo   ============================================================
echo.
echo   [A] Users        - list, delete, disable, change password,
echo                      remove from Administrators group
echo   [B] Sessions     - show sessions, force logoff others
echo   [C] Startup      - show Run keys, delete entries
echo   [D] Tasks        - show scheduled tasks, disable suspicious
echo   [E] Services     - show non-Windows services, stop+disable
echo   [F] Connections  - kill suspicious network connections by PID
echo   [G] RDP          - disable Remote Desktop + block port 3389
echo   [H] Hosts        - back up + reset hosts file
echo   [I] Guest        - disable Guest account
echo   [J] Firewall     - block all inbound (strict mode)
echo   [P] AUTO-PURGE   - runs G + H + I + logoff of remote
echo                      sessions in one go (1 confirmation)
echo   [X] Back to main menu
echo.
set /p rm="Choose: "
if /i "%rm%"=="a" goto rmusers
if /i "%rm%"=="b" goto rmsessions
if /i "%rm%"=="c" goto rmstartup
if /i "%rm%"=="d" goto rmtasks
if /i "%rm%"=="e" goto rmservices
if /i "%rm%"=="f" goto rmconn
if /i "%rm%"=="g" goto rmrdp
if /i "%rm%"=="h" goto rmhosts
if /i "%rm%"=="i" goto rmguest
if /i "%rm%"=="j" goto rmfirewall
if /i "%rm%"=="p" goto rmpurge
if /i "%rm%"=="x" goto menu
echo [x] Invalid.
timeout /t 2 /nobreak >nul
goto remove

:: --- A) USERS ---
:rmusers
cls
echo   ============================================================
echo                   USER ACCOUNT MANAGEMENT
echo   ============================================================
echo.
net user
echo.
net localgroup administrators
echo.
set /p uname="Enter EXACT username to modify (or SKIP): "
if /i "%uname%"=="skip" goto remove
if "%uname%"=="" goto remove
echo.
echo   [1] Delete user permanently      [2] Disable account
echo   [3] Enable account               [4] Change password
echo   [5] Remove from Administrators   [6] Add to Administrators
echo   [X] Back
echo.
set /p uact="Action: "
if "%uact%"=="1" (
    echo   [!!!] Deleting a user is PERMANENT and cannot be undone.
    set /p ok="   Really delete '%uname%'? Type YES to confirm: "
    if /i "!ok!"=="yes" (
        net user "!uname!" /delete
        call :log "DELETED user: %uname%"
        echo   [OK] User deleted.
    ) else echo   [x] Cancelled.
)
if "%uact%"=="2" (
    net user "!uname!" /active:no
    call :log "DISABLED user: %uname%"
    echo   [OK] Account disabled.
)
if "%uact%"=="3" (
    net user "!uname!" /active:yes
    call :log "ENABLED user: %uname%"
    echo   [OK] Account enabled.
)
if "%uact%"=="4" (
    echo   [i] Type the new password twice (hidden input).
    net user "!uname!" *
    call :log "PASSWORD CHANGED for: %uname%"
)
if "%uact%"=="5" (
    set /p ok="Remove '%uname%' from Administrators? [Y/N]: "
    if /i "!ok!"=="y" (
        net localgroup administrators "!uname!" /delete
        call :log "REMOVED from Administrators: %uname%"
        echo   [OK] Removed from Administrators.
    )
)
if "%uact%"=="6" (
    set /p ok="Add '%uname%' to Administrators? [Y/N]: "
    if /i "!ok!"=="y" (
        net localgroup administrators "!uname!" /add
        call :log "ADDED to Administrators: %uname%"
        echo   [OK] Added.
    )
)
echo.
pause
goto rmusers

:: --- B) SESSIONS ---
:rmsessions
cls
echo   ============================================================
echo                    ACTIVE SESSIONS
echo   ============================================================
query session
echo.
echo   [i] Your current session ID is shown as 'console' or your ID.
set /p sid="Session ID to log off (or SKIP): "
if /i "%sid%"=="skip" goto remove
if "%sid%"=="" goto remove
set /p ok="Force logoff session %sid%? Unsaved work will be lost! [Y/N]: "
if /i "%ok%"=="y" (
    logoff %sid%
    call :log "LOGGED OFF session: %sid%"
    echo   [OK] Logoff command sent.
)
echo.
pause
goto remove

:: --- C) STARTUP ---
:rmstartup
cls
echo   ============================================================
echo                     STARTUP ENTRIES
echo   ============================================================
echo.
echo   [A] HKCU Run
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
echo   [B] HKLM Run
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
echo   [C] HKCU RunOnce
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" 2>nul
echo.
echo   [D] HKLM RunOnce
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" 2>nul
echo.
echo   [E] Startup folder:
dir /b "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" 2>nul
echo.
set /p rk="Which key [A/B/C/D/E or X]: "
if /i "%rk%"=="x" goto remove
set /p rv="Exact value/file name to delete (or SKIP): "
if /i "%rv%"=="skip" goto remove
if /i "%rk%"=="a" reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "!rv!" /f
if /i "%rk%"=="b" reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "!rv!" /f
if /i "%rk%"=="c" reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "!rv!" /f
if /i "%rk%"=="d" reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "!rv!" /f
if /i "%rk%"=="e" del /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\!rv!" 2>nul
call :log "DELETED startup entry: %rv% from key %rk%"
echo   [OK] Attempted deletion of '%rv%'.
echo.
pause
goto remove

:: --- D) TASKS ---
:rmtasks
cls
echo   ============================================================
echo                  SCHEDULED TASKS
echo   ============================================================
schtasks /query /fo table 2>nul | findstr /v "Microsoft\\Windows" | more +0
echo.
set /p tn="Exact task name to DISABLE (or SKIP): "
if /i "%tn%"=="skip" goto remove
if "%tn%"=="" goto remove
set /p ok="Disable task '%tn%'? [Y/N]: "
if /i "%ok%"=="y" (
    schtasks /change /tn "!tn!" /disable
    call :log "DISABLED scheduled task: %tn%"
    echo   [OK] Task disabled (if it existed).
)
echo.
pause
goto remove

:: --- E) SERVICES ---
:rmservices
cls
echo   ============================================================
echo          SERVICES RUNNING FROM NON-WINDOWS PATHS
echo   ============================================================
powershell -NoProfile -Command "Get-CimInstance Win32_Service | Where-Object { $_.PathName -and $_.PathName -notmatch 'C:\\(Windows|Program Files)' } | Select-Object Name,State,StartMode,PathName | Format-Table -AutoSize | Out-String -Width 200" 2>nul
echo.
set /p svc="Exact service name to STOP + DISABLE (or SKIP): "
if /i "%svc%"=="skip" goto remove
if "%svc%"=="" goto remove
set /p ok="Stop and disable service '%svc%'? [Y/N]: "
if /i "%ok%"=="y" (
    sc stop "!svc!" >nul 2>&1
    sc config "!svc!" start= disabled
    call :log "STOPPED+DISABLED service: %svc%"
    echo   [OK] Service stopped and set to disabled.
)
echo.
pause
goto remove

:: --- F) CONNECTIONS ---
:rmconn
cls
echo   ============================================================
echo              ESTABLISHED CONNECTIONS (with PID)
echo   ============================================================
netstat -ano | findstr "ESTABLISHED"
echo.
set /p pid="PID of connection to KILL (or SKIP): "
if /i "%pid%"=="skip" goto remove
if "%pid%"=="" goto remove
set /p ok="Terminate process PID %pid%? [Y/N]: "
if /i "%ok%"=="y" (
    taskkill /f /pid !pid!
    call :log "KILLED process PID: %pid%"
    echo   [OK] Kill command sent.
)
echo.
pause
goto remove

:: --- G) RDP ---
:rmrdp
cls
echo   ============================================================
echo              DISABLE REMOTE DESKTOP ACCESS
echo   ============================================================
echo   [i] This disables RDP and blocks inbound TCP 3389.
set /p ok="Disable Remote Desktop now? [Y/N]: "
if /i "%ok%"=="y" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f
    netsh advfirewall firewall delete rule name="CaleBlock-RDP" >nul 2>&1
    netsh advfirewall firewall add rule name="CaleBlock-RDP" dir=in action=block protocol=TCP localport=3389
    call :log "RDP DISABLED + port 3389 blocked"
    echo   [OK] RDP disabled and port 3389 blocked.
) else echo   [x] Cancelled.
echo.
pause
goto remove

:: --- H) HOSTS ---
:rmhosts
cls
echo   ============================================================
echo                    RESET HOSTS FILE
echo   ============================================================
echo   [i] Current non-default entries:
type C:\Windows\System32\drivers\etc\hosts | findstr /v "^#"
echo.
set /p ok="Back up and reset hosts file to default? [Y/N]: "
if /i "%ok%"=="y" (
    copy /y C:\Windows\System32\drivers\etc\hosts C:\Windows\System32\drivers\etc\hosts.bak >nul
    echo # Hosts file reset by CaleBoard > C:\Windows\System32\drivers\etc\hosts
    echo 127.0.0.1       localhost >> C:\Windows\System32\drivers\etc\hosts
    echo ::1             localhost >> C:\Windows\System32\drivers\etc\hosts
    ipconfig /flushdns >nul
    call :log "HOSTS file reset (backup: hosts.bak)"
    echo   [OK] Hosts reset to default. Backup saved as hosts.bak
) else echo   [x] Cancelled.
echo.
pause
goto remove

:: --- I) GUEST ---
:rmguest
cls
echo   ============================================================
echo                    DISABLE GUEST ACCOUNT
echo   ============================================================
set /p ok="Disable the Guest account? [Y/N]: "
if /i "%ok%"=="y" (
    net user guest /active:no
    call :log "GUEST account disabled"
    echo   [OK] Guest account disabled.
) else echo   [x] Cancelled.
echo.
pause
goto remove

:: --- J) FIREWALL ---
:rmfirewall
cls
echo   ============================================================
echo               FIREWALL - STRICT INBOUND MODE
echo   ============================================================
echo   [i] Blocks ALL inbound connections on every profile.
echo       Outbound stays allowed. Use [R]estore to undo.
set /p ok="Block all inbound connections? [Y/N]: "
if /i "%ok%"=="y" (
    netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound
    call :log "FIREWALL set to block all inbound"
    echo   [OK] All inbound blocked. Outbound allowed.
)
echo.
set /p ok2="Restore default (allow inbound per rules)? [Y/N]: "
if /i "%ok2%"=="y" (
    netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound
    call :log "FIREWALL restored to default"
    echo   [OK] Firewall restored to default policy.
)
echo.
pause
goto remove

:: --- P) AUTO-PURGE ---
:rmpurge
cls
echo   ============================================================
echo              AUTO-PURGE (one confirmation only)
echo   ============================================================
echo.
echo   This will:
echo     1. Disable the Guest account
echo     2. Log off ALL other sessions (unsaved work is lost!)
echo     3. Disable Remote Desktop + block port 3389
echo     4. Reset the hosts file (backup created)
echo.
if /i "%MODE%"=="a" (
    set "confirm=Y"
) else (
    set "confirm="
)
if /i "%MODE%"=="m" set /p confirm="Type YES to execute Auto-Purge: "
if /i "%confirm%"=="y" goto dopurge
if /i "%confirm%"=="yes" goto dopurge
echo   [x] Cancelled.
pause
goto remove

:dopurge
echo   [1/4] Disabling Guest...
net user guest /active:no
call :log "AUTO-PURGE: guest disabled"
echo   [2/4] Logging off other sessions...
powershell -NoProfile -Command "$cur=(Get-Process -Id $PID).SessionId; qwinsta 2>$null | Select-Object -Skip 1 | ForEach-Object { $p=($_ -split '\s+') | Where-Object { $_ }; if ($p.Count -ge 3 -and $p[2] -match '^\d+$' -and [int]$p[2] -ne $cur) { logoff $p[2] } }"
call :log "AUTO-PURGE: remote sessions logged off"
echo   [3/4] Disabling RDP + blocking 3389...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f >nul
netsh advfirewall firewall delete rule name="CaleBlock-RDP" >nul 2>&1
netsh advfirewall firewall add rule name="CaleBlock-RDP" dir=in action=block protocol=TCP localport=3389 >nul
call :log "AUTO-PURGE: RDP disabled, 3389 blocked"
echo   [4/4] Resetting hosts file...
copy /y C:\Windows\System32\drivers\etc\hosts C:\Windows\System32\drivers\etc\hosts.bak >nul
echo # Hosts file reset by CaleBoard > C:\Windows\System32\drivers\etc\hosts
echo 127.0.0.1       localhost >> C:\Windows\System32\drivers\etc\hosts
echo ::1             localhost >> C:\Windows\System32\drivers\etc\hosts
ipconfig /flushdns >nul
call :log "AUTO-PURGE: hosts reset"
echo.
echo   ============================================================
echo   AUTO-PURGE COMPLETE - see CaleBoard_Log.txt on Desktop
echo   ============================================================
echo.
pause
goto remove

:: ============================================================
:: OPTION 4 - VIEW LOG
:: ============================================================
:viewlog
cls
if not exist "%LOG%" (
    echo [i] No log yet - run a scan first.
    pause
    goto menu
)
echo   ============================================================
echo                    CALEBOARD LOG  (%LOG%)
echo   ============================================================
type "%LOG%"
echo.
pause
goto menu