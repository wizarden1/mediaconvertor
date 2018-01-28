@echo off
rem Version 1.1

dir /B in\*.wav >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No WAV files found in IN directory
  goto end
)
call common_config.cmd
for /F "" %%f IN (list.tmp) DO (
  move in\%%f .\
  start /min /low /wait faac.exe -q 50 "%%f" -o "%%f.mp4"
  move "%%f.mp4" out\
  if del_original GTR 0 (move "%%f" in\) ELSE (del "%%f")
)
:end
del list.tmp
