@echo off
rem Version 1.1

dir /B in\*.mp3 >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No MP3 files found in IN directory
  goto end
)
call common_config.cmd
for /F "" %%f IN (list.tmp) DO (
  move in\%%f .\
  lame.exe --decode "%%f"
  faac.exe "%%f.wav"
  move "%%f.aac" out\
  if del_original GTR 0 (move "%%f" in\) ELSE (del "%%f")
  del "%%f.wav"
)
:end
del list.tmp
