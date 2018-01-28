@echo off
rem Version 1.4

rem Config
set enctemp=temp
set extension=WMV
set debug=0
set noaudioextract=0

rem Video
set quantanizer=22
set preset=veryslow
rem tune - film,animation,grain,psnr,ssim,fastdecode,touhou
set tune=animation

del /Q %enctemp%\*

dir /B in\*.%extension% >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No %extension% files found in IN directory
  goto end
)
call common_config.cmd
for /F "usebackq delims==" %%f IN (list.tmp) DO (
  fsutil hardlink create "%enctemp%\temp%extension%.%extension%" "in\%%f"
  if %noaudioextract%==0 (
    wavi.exe temp%extension%.avs "%enctemp%\temp.wav"
    C:\Multimedia\Programs\NeroAAC\neroAacEnc.exe -if "%enctemp%\temp.wav" -of "%enctemp%\temp.m4a"
  )
  start /low /min /wait C:\Multimedia\Programs\MeGUI\tools\x264\x264.exe --crf %quantanizer% --preset %preset% --tune %tune% --thread-input --output "%enctemp%\temp.mkv" "temp%extension%.avs"
  "C:\Multimedia\Programs\mkvtoolnix\mkvmerge.exe" -o "out\%%~nf.mkv"  "--language" "0:eng" "--default-track" "0:yes" "--forced-track" "0:no" "-d" "0" "-A" "-S" "-T" "--no-global-tags" "--no-chapters" "%enctemp%\temp.mkv" "--forced-track" "0:no" "-a" "0" "-D" "-S" "-T" "--no-global-tags" "%enctemp%\temp.m4a" "--track-order" "0:0,1:0"
  if %debug%==0 (del /Q %enctemp%\*)
  if %debug%==0 (if del_original GTR 0 (del "in\%%f"))
)
:end
del list.tmp

rem call C:\Tools\shutdown_local.cmd
