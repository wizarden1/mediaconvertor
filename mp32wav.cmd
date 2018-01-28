@echo off
rem Version 1.5

rem Config
set enctemp=temp
set srcextension=MP3
set dstextension=WAV
set debug=1

del /Q %enctemp%\*

dir /B in\*.%srcextension% >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No %srcextension% files found in IN directory
  goto end
)
call common_config.cmd
for /F "usebackq delims==" %%f IN (list.tmp) DO (
  if %debug%==0 (del /Q %enctemp%\*)
  fsutil hardlink create "%enctemp%\temp%srcextension%.%srcextension%" "in\%%f"

  lame.exe --decode "%enctemp%\temp%srcextension%.%srcextension%" "%enctemp%\temp%srcextension%.%srcextension%.%dstextension%"

  move "%enctemp%\temp%srcextension%.%srcextension%.%dstextension%" "out\%%~nf.%dstextension%"

  if %debug%==0 (del /Q %enctemp%\*)
  if %debug%==0 (if del_original GTR 0 (del "in\%%f"))
)
:end
del list.tmp

rem call C:\Tools\shutdown_local.cmd 
