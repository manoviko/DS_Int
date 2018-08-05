	echo %date% %time%
	echo off

:check_ping
	set PingLog=C:\Dev_Env\_LOGS\ping.log

	FOR %%A IN (10.106.59.90) DO (
		ping %%A > %PingLog% 2>&1
		find "Request timed out" %PingLog% /C /I 
		echo %ERRORLEVEL%
		IF NOT ERRORLEVEL 1 (perl mail_ping.pl %%A)
		IF NOT ERRORLEVEL 1 goto ping_error_end
		)

subst G: /D
subst G: \\rd-filer1\ums_cm


subst M: /D
subst M: \\rd-filer1\CGM



:settings
	set view=%1
	set version=%2
	set stf=%3
	set ip=%4

	set project=%5
	set proj_ver=%6
	set VIEW_USER=%7
	set cust=%8
	set rmps_dir=G:\CM\temp_rpms
	set user=um_bld1
	set component=full_clean

rem set FATAL=g:\CM\NightlyBuild\LOGS\MW\mw_fatal_%version%_swim.txt
	set scripts_dir=C:\Dev_Env\CGM_CM_SCRIPTS_INTEG_%VIEW_USER%_SNP\CGM\CM\Nightly\Middleware
	set LABEL_SCRIPT=M:\CM\NightlyBuild\Scripts\apply_label_scripts\MIDDLEWARE\INTEG\MIDDLEWARE_SWIM_int.bat
	set temp_location=G:\CM\NightlyBuild\temp
rem 	del /Q %FATAL%
	del /Q \\rd-filer1\home\log\mw*.log

	set FileCounter=0

:DateFormat

	set DateFormat=%date:~7,2%%date:~4,2%%date:~12,2%-%FileCounter%
	set /a FileCounter= (%FileCounter + 1)
	set Log=g:\CM\NightlyBuild\LOGS\MW\SWIM_%version%_%stf%_%DateFormat%.log
	if not exist g:\CM\NightlyBuild\LOGS\MW mkdir g:\CM\NightlyBuild\LOGS\MW
	if exist %Log% goto DateFormat
	


echo *******************************************************************
echo			BUILD %date% %time%  
echo *******************************************************************

set version=%2

rem goto swim_rpms
:full_clean
	
	set folder=G:\CM\swim_kits
	cd /d %folder%
	rem for /F "delims=" %%i in ('dir /b') do (rmdir "%%i" /s/q || del "%%i" /s/q)  >> %Log% 2>&1
	IF EXIST %folder% rmdir /s/q %folder% >> %Log% 2>&1
	IF EXIST %rmps_dir%\*.rpm del %rmps_dir%\*.rpm /s/q %Log% 2>&1

rem goto end
	perl %scripts_dir%\telnet_swim.pl %view% %ip% %component% %version% %stf% %user% %Log% 

	cleartool startview %view%
rem goto end

if not %cust%=="" goto SEM-FTM-CUST

:SEM-UTILS

set component=SEM-UTILS

	perl %scripts_dir%\telnet_swim.pl %view% %ip% %component% %version% %stf% %user% %Log% %cust%
	rem IF EXIST %rmps_dir%\SEM-UTILS*.rpm xcopy /D/E/Y/R/H/Q %rmps_dir%\SEM-UTILS*.rpm %temp_location%\.	>> %Log% 2>&1
	rem IF EXIST %rmps_dir%\SEM-UTILS*.rpm del %rmps_dir%\SEM-UTILS*.rpm /s/q >> %Log% 2>&1


if %version%==6.5.20.0 goto change_version
if %version%==6.5.10.0 goto change_version


:SEM-FTM-CUST
set component=SEM-FTM-CUST
rem if not %cust%=="" set component=SEM-FTM-CUST-%cust%

	perl %scripts_dir%\telnet_swim.pl %view% %ip% %component% %version% %stf% %user% %Log% %cust%

rem goto end

:change_version

set component=SWIM

	perl %scripts_dir%\telnet_swim.pl %view% %ip% %component% %version% %stf% %user% %Log% %cust%
	
	IF EXIST %folder%\SEM-UTILS_%version%_%stf% xcopy /D/E/Y/R/H/Q %rmps_dir%\SEM-UTILS-%version%-%stf%.x86_64.rpm %folder%\SEM-UTILS_%version%_%stf%\.		>> %Log% 2>&1
	IF EXIST %folder%\OMU-FTM-CUST_%version%_%stf% xcopy /D/E/Y/R/H/Q %rmps_dir%\SEM-FTM-CUST-%version%-%stf%.x86_64.rpm %folder%\OMU-FTM-CUST_%version%_%stf%\.	>> %Log% 2>&1
	rem IF EXIST %temp_location%\*.rpm del %temp_location%\*.rpm /s/q >> %Log% 2>&1

	IF EXIST %folder%\OMU-FTM-CUST_%version%_%stf% cd /d %folder%\OMU-FTM-CUST_%version%_%stf%
	IF EXIST %folder%\OMU-FTM-CUST_%version%_%stf% (for /F "delims=" %%i in ('dir /b') do (rmdir "%%i" /s/q) ) >> %Log% 2>&1
	IF EXIST %folder%\OMU-FTM-CUST_%version%_%stf%\build rmdir /s/q %folder%\OMU-FTM-CUST_%version%_%stf%\build >> %Log% 2>&1

	IF EXIST %folder%\SEM-UTILS_%version%_%stf% cd /d %folder%\SEM-UTILS_%version%_%stf%
	IF EXIST %folder%\SEM-UTILS_%version%_%stf% (for /F "delims=" %%i in ('dir /b') do (rmdir "%%i" /s/q) ) >> %Log% 2>&1
	IF EXIST %folder%\SEM-UTILS_%version%_%stf%\build rmdir /s/q %folder%\SEM-UTILS_%version%_%stf%\build >> %Log% 2>&1


:end
:must_kits
	mkdir %folder%\__MUST_KITS

	IF EXIST %folder%\UPDATE-VERSION_%version%_%stf% mkdir %folder%\__MUST_KITS\UPDATE-VERSION_%version%_%stf%
	IF EXIST %folder%\UPDATE-VERSION_%version%_%stf% xcopy /D/E/Y/R/H/Q/I %folder%\UPDATE-VERSION_%version%_%stf% %folder%\__MUST_KITS\UPDATE-VERSION_%version%_%stf%\.
	IF EXIST %folder%\Reboot-KIT_%version%_%stf% mkdir %folder%\__MUST_KITS\Reboot-KIT_%version%_%stf%
	IF EXIST %folder%\Reboot-KIT_%version%_%stf% xcopy /D/E/Y/R/H/Q/I %folder%\Reboot-KIT_%version%_%stf% %folder%\__MUST_KITS\Reboot-KIT_%version%_%stf%\.
	IF EXIST %folder%\SSU_PreUpgradeOrRollback_%version%_%stf% mkdir %folder%\__MUST_KITS\SSU_PreUpgradeOrRollback_%version%_%stf%
	IF EXIST %folder%\SSU_PreUpgradeOrRollback_%version%_%stf% xcopy /D/E/Y/R/H/Q/I %folder%\SSU_PreUpgradeOrRollback_%version%_%stf% %folder%\__MUST_KITS\SSU_PreUpgradeOrRollback_%version%_%stf%.
	IF EXIST %folder%\PreUpgradeOrRollback_%version%_%stf% mkdir %folder%\__MUST_KITS\PreUpgradeOrRollback_%version%_%stf%
	IF EXIST %folder%\PreUpgradeOrRollback_%version%_%stf% xcopy /D/E/Y/R/H/Q/I %folder%\PreUpgradeOrRollback_%version%_%stf% %folder%\__MUST_KITS\PreUpgradeOrRollback_%version%_%stf%.

	echo on
	echo %date% %time% >> %Log% 2>&1

	echo "I'm going to apply STF label on dynamic integration view %view%"  
	pause

:apply_label

echo **********************************************************************
echo           		Apply STF label on SWIM view 
echo				%view%      
echo *********************************************************************
	
	call %LABEL_SCRIPT% %view% %version% %stf% %project% %proj_ver% %cust%  > g:\CM\NightlyBuild\LOGS\MW\swim_label_%version%_%stf%.log 2>&1 
	
