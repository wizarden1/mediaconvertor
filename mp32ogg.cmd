@echo off
rem Version 1.2

set quality=3

dir /B in\*.mp3 >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No MP3 files found in IN directory
  goto end
)
call common_config.cmd
for /F "" %%f IN (list.tmp) DO (
  move in\%%f .\
  lame.exe --decode "%%f"
  oggenc2.exe -q %quality% "%%f.wav"
  move "%%f.ogg" out\
  if del_original GTR 0 (move "%%f" in\) ELSE (del "%%f")
  del "%%f.wav"
)
:end
del list.tmp
