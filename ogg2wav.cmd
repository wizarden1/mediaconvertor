@echo off
rem Version 1.1

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
  move "%%f.wav" out\
  if del_original GTR 0 (move "%%f" in\) ELSE (del "%%f")
)
:end
del list.tmp
