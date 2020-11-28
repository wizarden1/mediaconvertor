@echo off
rem Version 1.2

set preset=cd
set replaygain=0
set del_original=1

del /q ".\temp\*"
dir /B in\*.aac >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No OGG files found in IN directory
  goto end
)
for /F "" %%f IN (list.tmp) DO (
  copy ".\in\%%f" .\temp
  echo Decoding %%f
  .\tools\faad.exe -w ".\temp\%%f" > ".\temp\%%f.wav"
  if %replaygain%==1 (
    .\tools\lame.exe --priority 0 -v -p --vbr-new --replaygain-accurate --preset %preset% ".\temp\%%f.wav"
  ) else (
    .\tools\lame.exe --priority 0 -v -p --vbr-new --noreplaygain --preset %preset% ".\temp\%%f.wav"
  )
  move ".\temp\%%f.mp3" ".\out\"
  if del_original GTR 0 (del ".\in\%%f")
  del /q ".\temp\*"
)
:end
del list.tmp
