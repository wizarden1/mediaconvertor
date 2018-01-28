@echo off
rem Version 1.4

rem Config
set enctemp=temp
set extension=WAV
set debug=0

rem Audio
rem preset - medium,[fast] standard,[fast] extreme,insane,<bitrate>,cbr <bitrate>,phone,voice,fm/radio/tape,hifi,cd,studio
set preset=cd

del /Q %enctemp%\*

dir /B in\*.%extension% >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No %extension% files found in IN directory
  goto end
)
call common_config.cmd
for /F "usebackq delims==" %%f IN (list.tmp) DO (
  if %debug%==0 (del /Q %enctemp%\*)
  fsutil hardlink create "%enctemp%\temp%extension%.%extension%" "in\%%f"
  start /low /min /wait lame.exe --priority 0 -v -p --vbr-new --noreplaygain --preset %preset% "%enctemp%\temp%extension%.%extension%" "%enctemp%\temp%extension%.%extension%.MP3"

  move "%enctemp%\temp%extension%.%extension%.MP3" "out\%%~nf.MP3"

  if %debug%==0 (del /Q %enctemp%\*)
  if %debug%==0 (if del_original GTR 0 (del "in\%%f"))
)
:end
del list.tmp

rem call C:\Tools\shutdown_local.cmd 
