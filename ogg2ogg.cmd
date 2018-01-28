@echo off
rem Version 1.2

set quality=3

dir /B in\*.ogg >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No OGG files found in IN directory
  goto end
)
call common_config.cmd
for /F "" %%f IN (list.tmp) DO (
  move in\%%f .\
  echo Decoding %%f
  oggdec.exe %%f -o %%f.wav
  oggenc2.exe -q %quality% "%%f.wav"
  move "%%f.ogg" out\
  if del_original GTR 0 (move "%%f" in\) ELSE (del "%%f")
  del "%%f.wav"
)
:end
del list.tmp
