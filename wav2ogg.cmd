@echo off
rem Version 1.3

set quality=6
set enctemp=temp
set extension=WAV

del /Q %enctemp%\*

dir /B in\*.%extension% >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No %extension% files found in IN directory
  goto end
)
call common_config.cmd
for /F "usebackq delims==" %%f IN (list.tmp) DO (
  fsutil hardlink create "%enctemp%\temp.%extension%" "in\%%f"
  oggenc2.exe -q %quality% "%enctemp%\temp.%extension%" -o "temp\temp.ogg"
  move "temp\temp.ogg" "out\%%~nf.ogg"
  del /Q %enctemp%\*
  if del_original GTR 0 (del "in\%%f")
)
:end
del list.tmp

rem call C:\Tools\shutdown_local.cmd 
