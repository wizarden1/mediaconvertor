@echo off
rem Version 1.4

rem Config
set enctemp=temp
set extension=FLV
set debug=1
set noaudioextract=0

rem Video
set quantanizer=22
set preset=veryslow
rem tune - film,animation,grain,psnr,ssim,fastdecode,zerolatency
set tune=animation

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
  if %noaudioextract%==0 (
    wavi.exe temp%extension%.avs "%enctemp%\temp.wav"
    C:\Multimedia\Programs\NeroAAC\neroAacEnc.exe -if "%enctemp%\temp.wav" -of "%enctemp%\temp.m4a"
  )
  start /low /min /wait C:\Multimedia\Programs\MeGUI\tools\x264\avs4x264.exe --crf %quantanizer% --preset %preset% --tune %tune% --thread-input --output "%enctemp%\temp.mkv" "temp%extension%.avs"
  "C:\Multimedia\Programs\mkvtoolnix\mkvmerge.exe" -o "out\%%~nf.mkv"  --language 1:eng --default-track 1:yes -d 1 -A -S "%enctemp%\temp.mkv" -a 1 -D -S "%enctemp%\temp.m4a" --track-order 0:1,1:1
  if %debug%==0 (del /Q %enctemp%\*)
  if %debug%==0 (if del_original GTR 0 (del "in\%%f"))
)
:end
del list.tmp

rem call C:\Tools\shutdown_local.cmd 
