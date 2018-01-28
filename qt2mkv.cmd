@echo off
rem Version 1.3

set quantanizer=26
set enctemp=temp
set extension=QT

del /Q %enctemp%\*

dir /B in\*.%extension% >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No %extension% files found in IN directory
  goto end
)
call common_config.cmd
for /F "usebackq delims==" %%f IN (list.tmp) DO (
  fsutil hardlink create "%enctemp%\temp.%extension%" "in\%%f"
  wavi.exe temp%extension%.avs "%enctemp%\temp.wav"
  C:\Multimedia\Programs\NeroAAC\neroAacEnc.exe -if "%enctemp%\temp.wav" -of "%enctemp%\temp.m4a"
  start /low /min /wait C:\Multimedia\Programs\MeGUI\tools\x264\x264.exe --crf %quantanizer% --ref 5 --mixed-refs --bframes 3 --b-pyramid --no-mbtree --direct auto --nf --trellis 1 --partitions p8x8,b8x8,i4x4,p4x4 --me umh --threads auto --thread-input --nr 100 --output "%enctemp%\temp.mkv" "temp%extension%.avs"
  "C:\Multimedia\Programs\mkvtoolnix\mkvmerge.exe" -o "out\%%~nf.mkv"  --language 1:eng --default-track 1:yes -d 1 -A -S "%enctemp%\temp.mkv" -a 1 -D -S "%enctemp%\temp.m4a" --track-order 0:1,1:1
  del /Q %enctemp%\*
  if del_original GTR 0 (del "in\%%f")
)
:end
del list.tmp

rem call C:\Tools\shutdown_local.cmd
