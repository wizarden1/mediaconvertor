@echo off
rem Version 1.1

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
  C:\Multimedia\Programs\NeroAAC\neroAacEnc.exe -if "in\%%f" -of "out\%%~nf.m4a"
  del /Q %enctemp%\*
  if del_original GTR 0 (del "in\%%f")
)
:end
del list.tmp
