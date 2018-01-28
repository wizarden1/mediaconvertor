@echo off
rem Version 1.4

rem Config
set enctemp=temp
set extension=AVI
set debug=0
set noaudioextract=0

rem Video
set quantanizer=24
set preset=veryslow

rem tune - film,animation,grain,psnr,ssim,fastdecode,touhou
set tune=animation

rem --video-filter <filter>:<option>=<value>
rem   crop:left,top,right,bottom
rem   resize:[width,height][,sar][,fittobox][,csp][,method=(fastbilinear, bilinear, bicubic, experimental, point, area, bicublin, gauss, sinc, lanczos, spline)]
rem   select_every:step,offset1[,...]
set videofilter=--video-filter resize:width=1280,height=720,method=lanczos

del /Q %enctemp%\*

dir /B in\*.%extension% >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No %extension% files found in IN directory
  goto end
)
call common_config.cmd
for /F "usebackq delims==" %%f IN (list.tmp) DO (
  cscript.exe "WMCmd.vbs" -input "in\%%f" -output "out\%%~nf.wmv" -a_codec WMSP -a_content 1 -a_setting 20_22_1 -v_framerate %framerate% -v_keydist %keyframe% -v_mode %mode% -v_bitrate %bitrate% -v_quality %quality% -v_codec WMS9
  rem -author "David Johnson" -title "" -author "" -copyright ""
  if %debug%==0 (if del_original GTR 0 (del "in\%%f"))
)
:end
del list.tmp

rem call C:\Tools\shutdown_local.cmd 
