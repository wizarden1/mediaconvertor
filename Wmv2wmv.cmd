@echo off
rem Version 1.3

set quality=85
set bitrate=350000
set mode=2
set framerate=15
set keyframe=15

del /Q %enctemp%\*

dir /B in\*.wmv >list.tmp
if %ERRORLEVEL% GTR 0 (
  echo No WMV files found in IN directory
  goto end
)
call common_config.cmd
for /F "usebackq delims==" %%f IN (list.tmp) DO (
  cscript.exe "WMCmd.vbs" -input "in\%%f" -output "out\%%f" -a_codec WMSP -a_content 1 -a_setting 20_22_1 -v_framerate %framerate% -v_keydist %keyframe% -v_mode %mode% -v_bitrate %bitrate% -v_quality %quality% -v_codec WMS9
  rem -author "David Johnson" -title "" -author "" -copyright ""
  rem if del_original GTR 0 (del "in\%%f")
)
:end
del list.tmp
