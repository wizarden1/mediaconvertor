#Version 1.0
$wavi_path = "C:\Multimedia\Programs\Utils\wavi.exe"
$neroAacEnc_path = "C:\Multimedia\Programs\NeroAAC\neroAacEnc.exe"
$x264_path = "C:\Multimedia\Programs\MeGUI\tools\x264\x264.exe"
$mkvmerge_path = "C:\Multimedia\Programs\mkvtoolnix\mkvmerge.exe"

#Config
$del_original=$true
$enctemp="temp"
$debug=$false
$extension="WMV"

#Audio
$aud_language="eng"
$RecompressAudio=$true

#Video
$vid_language="eng"
$quantanizer=22
$preset="veryslow"
#tune - film,animation,grain,psnr,ssim,fastdecode,touhou
$tune="animation"
#Filters
$crop=$false
$resize=$false
$select_every=$false

#Filter Parametrs
#================
# --video-filter <filter>:<option>=<value>,<option>=<value>/<filter>:<option>=<value>
#Crop
#   crop:left,top,right,bottom
$cropParametrs="20,20,20,20"
#Resize
#   resize:[width,height][,sar][,fittobox][,csp][,method=(fastbilinear, bilinear, bicubic, experimental, point, area, bicublin, gauss, sinc, lanczos, spline)]
$resize_size=@(1280,720)
$resize_mode="lanczos"
#Add adition parametrs ",1:1"
$resize_other=""
# Select Custom Frames (Pulldown)
#   select_every:step,offset1[,...]
$select_every_Parametrs=""















#Creating commandline
#Creating Filter
$filters = @()
if ($crop) {$filters += "crop:"+$cropParametrs}
if ($resize) {$filters += "resize:width="+$resize_size[0]+",height="+$resize_size[1]+",method="+$resize_mode+$resize_other}
if ($select_every) {$filters += "select_every:"+$select_every_Parametrs}
if ($filters.Length -gt 0) {$videofilter="--video-filter "+[string]::Join("/",$filters)} else {$videofilter=""}

Remove-Item .\$enctemp\*

dir .\in\ | where {$_.Extension -eq ".$extension"} | foreach-object {
	Start-Process -Wait -NoNewWindow -FilePath "fsutil" -ArgumentList "hardlink create ""$enctemp\temp$extension.$extension"" ""$($_.FullName)"""
# Audio Encoding
	if ($RecompressAudio) {
		Start-Process -Wait -NoNewWindow -FilePath $wavi_path -ArgumentList "temp$extension.avs ""$enctemp\temp.wav"""
		Start-Process -Wait -NoNewWindow -FilePath $neroAacEnc_path -ArgumentList "-if ""$enctemp\temp.wav"" -of ""$enctemp\temp.m4a"""
		$audiotrack="--language 0:$aud_language --audio-tracks 0 --compression 0:none --no-video --no-subtitles --no-chapters ""$enctemp\temp.m4a"""
	} else {
		$audiotrack="--language 0:$aud_language --audio-tracks 0 --compression 0:none --no-video --no-subtitles --no-chapters ""$enctemp\temp$extension.$extension"""
	}
# Video Encoding
	$startInfo = New-Object System.Diagnostics.ProcessStartInfo
	$startInfo.Arguments = "--crf $quantanizer --preset $preset --tune $tune --thread-input $videofilter --output ""$enctemp\temp.mkv"" ""temp$extension.avs"""
	$startInfo.FileName = $x264_path
	$startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
#	$startInfo.CreateNoWindow = $true
	$startInfo.UseShellExecute = $false
	$process = New-Object System.Diagnostics.Process
	$process.StartInfo = $startInfo
	$process.Start() | Out-Null
	$process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle
	$process.WaitForExit()
#  Start-Process -Wait -NoNewWindow -FilePath $x264_path -ArgumentList "--crf $quantanizer --preset $preset --tune $tune --thread-input $videofilter --output ""$enctemp\temp.mkv"" ""temp$extension.avs"""
	$videotrack = "--language 0:$vid_language --default-track 0 --video-tracks 0 --compression 0:none --no-audio --no-subtitles --no-chapters ""$enctemp\temp.mkv"""
# Building Result File
	Start-Process -Wait -NoNewWindow -FilePath $mkvmerge_path -ArgumentList "-o ""out\$($_.basename).mkv"" $videotrack $audiotrack"
  #  --track-order 0:1,1:1
# Removing Temp Files
	if (-not $debug) {
    	Remove-Item .\$enctemp\*
		if ($del_original){Remove-Item -LiteralPath $_.fullname}
	}
}

#Stop-Computer
