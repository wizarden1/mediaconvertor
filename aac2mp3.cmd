@echo off
rem Version 1.2

set preset=cd
set replaygain=0

dir /B in\*.aac >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No OGG files found in IN directory
  goto end
)
call common_config.cmd
for /F "" %%f IN (list.tmp) DO (
  move in\%%f .\
  echo Decoding %%f
  faad.exe -w "%%f" > "%%f.wav"
  if %replaygain%==1 (
    lame.exe --priority 0 -v -p --vbr-new --replaygain-accurate --preset %preset% "%%f.wav"
  ) else (
    lame.exe --priority 0 -v -p --vbr-new --noreplaygain --preset %preset% "%%f.wav"
  )
  move "%%f.wav.mp3" out\
  if del_original GTR 0 (move "%%f" in\) ELSE (del "%%f")
  del "%%f.wav"
)
:end
del list.tmp
