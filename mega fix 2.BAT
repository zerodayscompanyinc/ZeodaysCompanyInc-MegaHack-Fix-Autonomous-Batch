@echo off
setlocal EnableExtensions EnableDelayedExpansion
title MultiFixer X - Network / Defense / Attack Toolkit
color 0B

:: ---- Admin check ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ADMIN RIGHTS REQUIRED - right-click and Run as administrator.
    pause
    exit /b 1
)

set "LOG=%SystemDrive%\MFX_Log.txt"
echo %date% %time% - Session started >> "%LOG%"

:: ============================================================
::  MAIN MENU
:: ============================================================
:menu
cls
echo ==========================================================
echo    MULTI FIXER X - Network / Defense / Attack Toolkit
echo ==========================================================
echo   [1] Network tools           [6] Maintenance (Part 4)
echo   [2] Defense / hardening     [7] FULL FIX
echo   [3] Recon / attack (Part3)  [8] Restore point
echo   [4] Performance (Part 4)    [9] Reboot now
echo   [5] Privacy (Part 4)        [X] Exit
echo ==========================================================
set /p m="Choose: "
if "%m%"=="1" call :m_net
if "%m%"=="2" call :m_def
if "%m%"=="3" call :m_att
if "%m%"=="4" call :m_perf
if "%m%"=="5" call :m_priv
if "%m%"=="6" call :m_maint
if "%m%"=="7" call :full_fix
if "%m%"=="8" call :restore_point
if "%m%"=="9" shutdown /r /t 10 /c "MultiFixer X reboot"
if /i "%m%"=="X" exit /b
goto menu

:restore_point
echo Creating restore point...
powershell -nop -c "Checkpoint-Computer -Description 'MultiFixer X' -RestorePointType MODIFY_SETTINGS" 2>nul
if errorlevel 1 echo [!] System Protection is OFF - enable it in Control Panel first.
pause
goto :eof

:: ============================================================
::  [1] NETWORK MODULE  (19 tools)
:: ============================================================
:m_net
cls
echo ==================== NETWORK TOOLS ====================
echo  1  Ping sweep /24         11  Netstat -ano (live)
echo  2  Port scan (24 ports)   12  Reset proxy
echo  3  WiFi profiles          13  Restore clean hosts
echo  4  WiFi passwords         14  Change MAC (random)
echo  5  DNS flush + IP renew   15  Speed test (100MB)
echo  6  Set DNS 1.1.1.1/8.8.8  16  Full network reset
echo  7  Traceroute             17  Winsock + TCP-IP reset
echo  8  PathPing               18  List SMB shares
echo  9  Route table            19  ARP table
echo 10  View MAC               0   Back to main menu
echo =======================================================
set /p n="Pick: "
if "%n%"=="1"  call :net_pingsweep
if "%n%"=="2"  call :net_portscan
if "%n%"=="3"  call :net_wifiprofiles
if "%n%"=="4"  call :net_wifipass
if "%n%"=="5"  call :net_dnsflush
if "%n%"=="6"  call :net_setdns
if "%n%"=="7"  call :net_trace
if "%n%"=="8"  call :net_pathping
if "%n%"=="9"  call :net_route
if "%n%"=="10" call :net_macview
if "%n%"=="11" call :net_netstat
if "%n%"=="12" call :net_proxy
if "%n%"=="13" call :net_hosts
if "%n%"=="14" call :net_mac
if "%n%"=="15" call :net_speed
if "%n%"=="16" call :net_fullreset
if "%n%"=="17" call :net_stack
if "%n%"=="18" call :net_shares
if "%n%"=="19" call :net_arp
goto :eof

:net_pingsweep
set /p net="Network prefix (e.g. 192.168.1): "
set "sweep=%TEMP%\mfx_sweep.txt"
echo Scanning %net%.1-254 ...
(for /l %%i in (1,1,254) do @ping -n 1 -w 300 %net%.%%i >nul 2>&1 && echo ALIVE  %net%.%%i) > "%sweep%"
type "%sweep%"
echo [*] Live hosts: %TEMP%\mfx_sweep.txt
pause
goto :eof

:net_portscan
set /p h="Host: "
powershell -nop -c "$h='%h%'; $p=21,22,23,25,53,80,110,135,139,143,443,445,993,995,1433,1521,3306,3389,5432,5900,6379,8080,8443,9200; foreach($x in $p){$c=New-Object Net.Sockets.TcpClient; try{$r=$c.BeginConnect($h,$x,$null,$null); if($r.AsyncWaitHandle.WaitOne(400)){try{$c.EndConnect($r); Write-Host ('OPEN  ' + $x)}catch{}}}catch{}; $c.Close()}"
pause
goto :eof

:net_wifiprofiles
netsh wlan show profiles
pause
goto :eof

:net_wifipass
echo [*] WiFi name : password (clear text)
for /f "tokens=2 delims=:" %%p in ('netsh wlan show profiles ^| findstr ":"') do (
    set "ssid=%%p"
    set "ssid=!ssid:~1!"
    for /f "tokens=2 delims=:" %%k in ('netsh wlan show profile name="!ssid!" key^=clear ^| findstr "Key Content"') do (
        echo !ssid!  =  %%k
    )
)
pause
goto :eof

:net_dnsflush
ipconfig /flushdns
ipconfig /registerdns
nbtstat -R
arp -d *
ipconfig /release >nul 2>&1
ipconfig /renew
echo [*] DNS flushed, DHCP lease renewed.
pause
goto :eof

:net_setdns
set /p iface="Interface name (from ipconfig): "
netsh interface ip set dns name="%iface%" static 1.1.1.1
netsh interface ip add dns name="%iface%" 8.8.8.8 index=2
echo [*] DNS set: 1.1.1.1 primary, 8.8.8.8 secondary.
pause
goto :eof

:net_trace
set /p h="Host: "
tracert %h%
pause
goto :eof

:net_pathping
set /p h="Host: "
pathping %h%
pause
goto :eof

:net_route
route print
pause
goto :eof

:net_macview
getmac /v
pause
goto :eof

:net_netstat
netstat -ano | findstr "LISTENING ESTABLISHED"
pause
goto :eof

:net_proxy
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
netsh winhttp reset proxy
echo [*] Proxy disabled.
pause
goto :eof

:net_hosts
attrib -r -s -h "%SystemRoot%\System32\drivers\etc\hosts" >nul 2>&1
if exist "%SystemRoot%\System32\drivers\etc\hosts" copy /y "%SystemRoot%\System32\drivers\etc\hosts" "%SystemRoot%\System32\drivers\etc\hosts.bak" >nul 2>&1
(
echo # Hosts restored by MultiFixer X
echo 127.0.0.1 localhost
echo ::1 localhost
) > "%SystemRoot%\System32\drivers\etc\hosts"
echo [*] Hosts file restored. Backup: hosts.bak
pause
goto :eof

:net_mac
set /p iface="Interface name (from ipconfig): "
powershell -nop -c "$bytes=1..6 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }; $bytes[0]=$bytes[0] -band 0xFE -bor 0x02; $mac=($bytes | ForEach-Object { $_.ToString('X2') }) -join '-'; Set-NetAdapterAdvancedProperty -Name '%iface%' -RegistryKeyword NetworkAddress -RegistryValue ($mac -replace '-','') -NoRestart; Write-Host ('New MAC: ' + $mac + '  (restart the adapter to apply)')"
pause
goto :eof

:net_speed
echo [*] Downloading 100MB test file...
powershell -nop -c "$u='http://speedtest.tele2.net/100MB.zip'; $sw=[Diagnostics.Stopwatch]::StartNew(); (New-Object Net.WebClient).DownloadFile($u,\"$env:temp\spd.bin\"); $sw.Stop(); Write-Host ('{0:N2} Mbps' -f ((100*8)/$sw.Elapsed.TotalSeconds))"
pause
goto :eof

:net_fullreset
echo [*] Resetting IP stack, Winsock, HTTP proxy...
netsh int ip reset "%SystemDrive%\netreset.log"
netsh winsock reset
netsh winhttp reset proxy
ipconfig /flushdns
echo [*] Done - REBOOT REQUIRED.
pause
goto :eof

:net_stack
netsh winsock reset
netsh int ip reset
echo [*] Winsock + TCP-IP reset - REBOOT REQUIRED.
pause
goto :eof

:net_shares
net view
pause
goto :eof

:net_arp
arp -a
pause
goto :eof

:: ============================================================
::  [2] DEFENSE / HARDENING MODULE  (21 tools)
:: ============================================================
:m_def
cls
echo ================== DEFENSE / HARDENING ==================
echo  1  Firewall status          12  Disable Guest account
echo  2  Enable firewall          13  Enable RDP (with NLA)
echo  3  Disable firewall         14  Disable RDP
echo  4  Block ALL inbound        15  Enable logon auditing
echo  5  Defender quick scan      16  Account lockout policy
echo  6  Defender full scan       17  Password policy
echo  7  Update Defender          18  Disable TLS 1.0 / 1.1
echo  8  Kill telemetry           19  Harden LM / NTLM
echo  9  Enable UAC (max)         20  Require SMB signing
echo 10  UAC low (silent)         21  List startup entries
echo 11  Disable SMBv1            0   Back to main menu
echo =========================================================
set /p n="Pick: "
if "%n%"=="1"  call :def_fwstate
if "%n%"=="2"  call :def_fwon
if "%n%"=="3"  call :def_fwoff
if "%n%"=="4"  call :def_blockin
if "%n%"=="5"  call :def_mpquick
if "%n%"=="6"  call :def_mpfull
if "%n%"=="7"  call :def_mpupdate
if "%n%"=="8"  call :def_telemetry
if "%n%"=="9"  call :def_uac_on
if "%n%"=="10" call :def_uac_low
if "%n%"=="11" call :def_smb1
if "%n%"=="12" call :def_guest
if "%n%"=="13" call :def_rdp_on
if "%n%"=="14" call :def_rdp_off
if "%n%"=="15" call :def_audit
if "%n%"=="16" call :def_lockout
if "%n%"=="17" call :def_passpol
if "%n%"=="18" call :def_tls
if "%n%"=="19" call :def_lm
if "%n%"=="20" call :def_smbsign
if "%n%"=="21" call :def_startup
goto :eof

:def_fwstate
netsh advfirewall show allprofiles state
pause
goto :eof

:def_fwon
netsh advfirewall set allprofiles state on
echo [*] Firewall ON for all profiles.
pause
goto :eof

:def_fwoff
netsh advfirewall set allprofiles state off
echo [*] Firewall OFF for all profiles.
pause
goto :eof

:def_blockin
netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound
echo [*] Inbound blocked by default on all profiles.
pause
goto :eof

:def_mpquick
if exist "%ProgramFiles%\Windows Defender\MpCmdRun.exe" (
    "%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -ScanType 1
) else (
    powershell -nop -c "Start-MpScan -ScanType QuickScan"
)
echo [*] Quick scan finished.
pause
goto :eof

:def_mpfull
if exist "%ProgramFiles%\Windows Defender\MpCmdRun.exe" (
    "%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2
) else (
    powershell -nop -c "Start-MpScan -ScanType FullScan"
)
echo [*] Full scan finished.
pause
goto :eof

:def_mpupdate
if exist "%ProgramFiles%\Windows Defender\MpCmdRun.exe" (
    "%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate
) else (
    powershell -nop -c "Update-MpSignature"
)
pause
goto :eof

:def_telemetry
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
echo [*] Telemetry level 0. Reboot to apply.
pause
goto :eof

:def_uac_on
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f
echo [*] UAC enabled, prompts for admins. Reboot to apply.
pause
goto :eof

:def_uac_low
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f
echo [*] UAC silent elevation for admins. Reboot to apply.
pause
goto :eof

:def_smb1
echo [*] Disabling SMBv1...
dism /online /disable-feature /featurename:SMB1Protocol /norestart >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v SMB1 /t REG_DWORD /d 0 /f
echo [*] SMBv1 disabled. Reboot recommended.
pause
goto :eof

:def_guest
net user guest /active:no
echo [*] Guest account disabled.
pause
goto :eof

:def_rdp_on
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 1 /f
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul 2>&1
echo [*] RDP enabled with NLA.
pause
goto :eof

:def_rdp_off
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f
netsh advfirewall firewall set rule group="remote desktop" new enable=No >nul 2>&1
echo [*] RDP disabled.
pause
goto :eof

:def_audit
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
echo [*] Logon auditing enabled.
pause
goto :eof

:def_lockout
net accounts /lockoutthreshold:5 /lockoutduration:15 /lockoutwindow:15
echo [*] Lockout: 5 attempts, locked 15 min.
pause
goto :eof

:def_passpol
net accounts /minpwlen:8 /maxpwage:90 /uniquepw:5
echo [*] Password policy applied.
pause
goto :eof

:def_tls
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" /v Enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" /v Enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" /v Enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v Enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v Enabled /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v Enabled /t REG_DWORD /d 1 /f
echo [*] TLS 1.0/1.1 disabled, TLS 1.2 on. Reboot.
pause
goto :eof

:def_lm
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel /t REG_DWORD /d 5 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 1 /f
echo [*] NTLMv2 only; remote blank-password logons blocked. Reboot.
pause
goto :eof

:def_smbsign
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v RequireSecuritySignature /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v RequireSecuritySignature /t REG_DWORD /d 1 /f
echo [*] SMB signing required. Reboot.
pause
goto :eof

:def_startup
powershell -nop -c "Get-CimInstance Win32_StartupCommand | Select-Object Name,Command,Location | Format-Table -AutoSize"
pause
goto :eof

:: ============================================================
::  FULL FIX  (core repair sequence)
:: ============================================================
:full_fix
echo ============================================
echo   FULL FIX - running core repair sequence
echo   (press a key between stages)
echo ============================================
call :net_dnsflush
call :net_stack
call :def_fwon
call :def_mpquick
call :def_telemetry
call :def_smb1
call :def_uac_on
call :def_tls
echo.
echo  FULL FIX finished. REBOOT strongly recommended.
pause
goto :eof

:: ============================================================
::  PLACEHOLDERS - delivered in next parts
:: ============================================================
:m_att
cls
echo ================ RECON / ATTACK (Part 3) ================
echo   Coming next: banner grab, SNMP enum, brute-force lab,
echo   MITM / ARP poison, packet crafting, pivoting helpers.
pause
goto :eof

:m_perf
cls
echo ================ PERFORMANCE (Part 4) ==================
echo   Coming next: startup manager, RAM booster, disk defrag,
echo   power plans, visual effects, driver updates.
pause
goto :eof

:m_priv
cls
echo ================== PRIVACY (Part 4) ====================
echo   Coming next: privacy cleanup, browser tracker wipe,
echo   OneDrive disable, app telemetry, activity history.
pause
goto :eof

:m_maint
cls
echo ================= MAINTENANCE (Part 4) =================
echo   Coming next: disk cleanup, SFC, DISM, CHKDSK,
echo   update repair, restore points, scheduled tasks.
pause
goto :eof