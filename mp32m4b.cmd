@echo off
rem Version 1.3

set enctemp=temp
set extension=MP3

del /Q %enctemp%\*

dir /B in\*.%extension% >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No %extension% files found in IN directory
  goto end
)
call common_config.cmd
for /F "usebackq delims==" %%f IN (list.tmp) DO (
  fsutil hardlink create "%enctemp%\temp.%extension%" "in\%%f"
  lame.exe --decode "%enctemp%\temp.%extension%" "%enctemp%\temp.wav"
  C:\Multimedia\Programs\NeroAAC\neroAacEnc.exe -if "%enctemp%\temp.wav" -of "out\%%~nf.m4a"
  del /Q %enctemp%\*
  if del_original GTR 0 (del "in\%%f")
)
:end
del list.tmp

rem call C:\Tools\shutdown_local.cmd
