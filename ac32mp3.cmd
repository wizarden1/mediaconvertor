@echo off
rem Version 1.4

rem Config
set enctemp=temp
set extension=AC3
set debug=0

rem Audio
set preset=128
set replaygain=0

del /Q %enctemp%\*

dir /B in\*.%extension% >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No %extension% files found in IN directory
  goto end
)
call common_config.cmd
for /F "usebackq delims==" %%f IN (list.tmp) DO (
  if %debug%==0 (del /Q %enctemp%\*)
  fsutil hardlink create "%enctemp%\temp.%extension%" "in\%%f"

  ac3fix.exe "%enctemp%\temp.%extension%" nul
  if %ERRORLEVEL%==0 (
    ac3decoding2.cmd "%enctemp%\temp.%extension%" "%enctemp%\temp.wav"
    if %replaygain%==1 (
      lame.exe --priority 0 -v -p --vbr-new --replaygain-accurate --preset %preset% "%enctemp%\temp.wav" "%enctemp%\temp.mp3"
    ) else (
      lame.exe --priority 0 -v -p --vbr-new --noreplaygain --preset %preset% "%enctemp%\temp.wav" "%enctemp%\temp.mp3"
    )
    move "%enctemp%\temp.mp3" "out\%%~nf.mp3"
    if %debug%==0 (del /Q %enctemp%\*)
    if %debug%==0 (if del_original GTR 0 (del "in\%%f"))
  ) ELSE (echo Error in %%f)
)
:end
del list.tmp

rem call C:\Tools\shutdown_local.cmd 
