#Version 2.5
# terminate - stop process after current file
# shutdown - shutdown when it finished

#Config

#Audio
$take_audio_from_source=$false
$audio_languages= @($false,"jpn","jpn") #@("Use manual set","track ID/default","track ID",...)
$select_audio_by=@("all",@("jpn")) #select_audio_by:<language|trackid|all>,<list of languages|number of tracks> example1: @("all",@("jpn"))
$RecompressMethod="Decoder"     #"AviSynth"|"Decoder"
#$RecompressMethod="AviSynth"     #"AviSynth"|"Decoder"

#Video
$video_languages= @($false,"jpn","jpn") #@("Use manual set","track ID/default","track ID",...)
$tune="animation" #tune:film,animation,grain,psnr,ssim,fastdecode,touhou
$DecompressSource="FFVideoSource"	#"FFVideoSource"|"DirectShowSource"
$Copy_Chapters=$true

#Filters
$crop=@($false,20,20,20,20) #crop:enabled,left,top,right,bottom
$resize=@($true,1280,720,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1280,960,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($false,0,0,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1024,768,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1280,544,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
$pulldown=@($false,"")	#pulldown:enabled,"step,offset1[,...]"

#Advanced Config
$del_original=$true
$root_path = "C:\Multimedia\Programs\Utils"
$enctemp = Join-Path $root_path "temp"
$out = $(Join-Path $root_path "out")
$in = $(Join-Path $root_path "in")
$debug=$false
$shutdown=$false
$extension="MKV"

$multimedia = "C:\Multimedia\Programs"
$meguitools = Join-Path $multimedia "MeGUI\tools"
$neroAacEnc_path = Join-Path $multimedia "NeroAAC\neroAacEnc.exe"
$x264_path = Join-Path $meguitools "x265\x265.exe"
$mkvmerge_path = Join-Path $meguitools "mkvmerge\mkvmerge.exe"
$mkvextract_path = Join-Path $meguitools "mkvmerge\mkvextract.exe"
#$mkvextract_path = "C:\Multimedia\Programs\Utils\mkvtoolnix\mkvextract.exe"
$MediaInfoWrapper_path = Join-Path $root_path "MediaInfoWrapper.dll"
$oggdec_path = Join-Path $root_path "oggdec.exe"
$eac3to = Join-Path $meguitools "eac3to\eac3to.exe"
$faad_path = Join-Path $root_path "faad.exe"
$wavi = Join-Path $root_path "Wavi.exe"

#Advanced Video
$quantanizer=22   #18
$preset="veryslow"



# Program Body
################################################
function Convert-Audio
{
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[System.IO.FileInfo]
		[ValidateScript( { ( Test-Path $_ ) } ) ]
		$SourceFile,
		
		[System.IO.DirectoryInfo]
		[ValidateScript( { ( Test-Path $_ ) } ) ]
		$OutputDir = $SourceFile.Directory
	)
	begin
	{ 
	}
	
	process 
	{
		Switch ($SourceFile.Extension)
		{
			".AAC"    {Start-Process -Wait -NoNewWindow -FilePath $faad_path -ArgumentList """$($SourceFile.FullName)"" ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).wav"""
						Start-Process -Wait -NoNewWindow -FilePath $neroAacEnc_path -ArgumentList "-if ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).wav"" -of ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a"" -ignorelength"
					}
			".PCM"    {Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a"""}
			".Vorbis" {Start-Process -Wait -NoNewWindow -FilePath $oggdec_path -ArgumentList "--wavout ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).wav"" ""$($SourceFile.FullName)"""
						Start-Process -Wait -NoNewWindow -FilePath $neroAacEnc_path -ArgumentList "-if ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).wav"" -of ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a"" -ignorelength"
					}
			".FLAC"   {Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a"""}
			".AC-3"   {Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a"""}
			".DTS"    {Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a"""}
			".MPEG Audio" {Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a"""}
			".TrueHD"     {Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a"""}
			default	{throw "Unknown Audio Codec."}
		}
		if (-not $(Test-Path -LiteralPath "$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a" )) {throw "File $($SourceFile.Name) hasn't been decompressed."}
	}
	end
	{ }

}

################################################
function Compress-Video
{
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[System.IO.FileInfo]
		[ValidateScript( { ( Test-Path $_ ) } ) ]
		$SourceFile,
		
		[System.IO.DirectoryInfo]
		[ValidateScript( { ( Test-Path $_ ) } ) ]
		$OutputDir = $SourceFile.Directory,

		[Int16]
		$quantanizer = 22,
		
		[string]
		[ValidateSet('ultrafast','superfast','veryfast','faster','fast','medium','slow','slower','veryslow','placebo')]
        $preset="medium",
		
		[string]
		[ValidateSet('film','animation','grain','stillimage','psnr','ssim','fastdecode','zerolatency')]
		$tune="film",
		
		$crop=@($false,20,20,20,20),
		$resize=@($false,1280,720,"lanczos",""),
		$pulldown=@($false,"")
	)
	begin
	{ 
	# Creating Filter
	# --video-filter <filter>:<option>=<value>,<option>=<value>/<filter>:<option>=<value>
		$filters = @()
		if ($crop[0]) {$filters += [string]::Join(",",$crop[1..4])}
		if ($resize[0]) {$filters += "resize:width=$($resize[1]),height=$($resize[2]),method=$($resize[3])$($resize[4])"}
		if ($pulldown[0]) {$filters += "select_every:"+$pulldown[1]}
		$videofilter=""
		if ($filters.Length -gt 0) {$videofilter="--video-filter "+[string]::Join("/",$filters)}
	}
	
	process 
	{
		$startInfo = New-Object System.Diagnostics.ProcessStartInfo
		$startInfo.Arguments = "--crf $quantanizer --preset $preset --tune $tune --thread-input $videofilter --output ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).mkv"" ""$($SourceFile.FullName)"""
		$startInfo.FileName = $x264_path
		$startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
		$startInfo.UseShellExecute = $false
		$process = New-Object System.Diagnostics.Process
		$process.StartInfo = $startInfo
		$process.Start() | Out-Null
		$process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle
		$process.WaitForExit()

		if ($(Get-ChildItem "$(Join-Path $OutputDir.FullName $SourceFile.BaseName).mkv").Length -eq 0) {throw "File $($SourceFile.Name) hasn't been compressed."}
	}
	end
	{
	}

}

Trap {
	$errorcount++
	"$($(Get-Date).date) $($_.Exception.Message)" | Out-File -filepath $(Join-Path $in "errors.log") -Append
}

################################### Main Program ###################################
Remove-Item $enctemp\*

$files = dir $in | where {$_.Extension -eq ".$extension"}
#if ($files -is $null){exit}
:Main Foreach ($file in $files) {
	$errorcount=0
	if (-not $(Test-Path -LiteralPath $file.FullName)){continue Main}
# Process Commands
	if ($(Test-Path -LiteralPath $(Join-Path $in "terminate"))){Remove-Item $(Join-Path $in "terminate");break}

	Start-Process -Wait -NoNewWindow -FilePath "fsutil" -ArgumentList "hardlink create ""$enctemp\temp$extension.$extension"" ""$($file.FullName)"""

# Load Media Info
	add-Type -Path $MediaInfoWrapper_path
	$medinfo = new-object MediaInfoWrapper.MediaInfo("$enctemp\temp$extension.$extension")

# Audio Encoding
#  Selecting Audio tracks
	$audiotracks = @()
	Foreach ($audiotrack in $medinfo.Audio) {
		$audiotrack = Add-Member -memberType NoteProperty -name Custom01 -value "" -PassThru -inputObject $audiotrack
		Switch ($select_audio_by[0])
		{
			"language" 	{if  ($select_audio_by[1] -contains $audiotrack.LanguageString3){$audiotracks += $audiotrack}}
			"trackid" 	{if ($select_audio_by[1] -contains $audiotrack.StreamKindID){$audiotracks += $audiotrack}}
			default	{$audiotracks += $audiotrack}
		}
	}

	Switch ($RecompressMethod)
	{
		"AviSynth"  {
						Copy-Item $(Join-Path $root_path "AviSynthtemplate.avs") "$enctemp\videofile.avs"
						"DirectShowSource(""$($file.FullName)"")" | Out-File "$enctemp\videofile.avs" -Append -Encoding Ascii
                        if ($debug){"AviSynth Command Line: $wavi ""$enctemp\videofile.avs"" ""$enctemp\temp.pcm"""}
						Start-Process -Wait -NoNewWindow -FilePath $wavi -ArgumentList """$enctemp\videofile.avs"" ""$enctemp\temp.pcm"""
						Convert-Audio $(Get-ChildItem "$enctemp\temp.pcm")
						if ($errorcount -gt 0){continue Main}
						$audiotracks[0].Custom01 = "temp.m4a"
					}
		"Decoder"   {
						Foreach ($audiotrack in $audiotracks) {
                            if ($debug){"Decoder Command Line: $mkvextract_path tracks ""$enctemp\temp$extension.$extension"" $($audiotrack.ID-1):""$enctemp\$($audiotrack.UniqueID).$($audiotrack.Format)"""}
                            Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "tracks ""$enctemp\temp$extension.$extension"" $($audiotrack.ID-1):""$enctemp\$($audiotrack.UniqueID).$($audiotrack.Format)"""
#                            if ($debug){"Decoder Command Line: $mkvextract_path tracks ""$enctemp\temp$extension.$extension"" $($audiotrack.ID):""$enctemp\$($audiotrack.UniqueID).$($audiotrack.Format)"""}
#							Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "tracks ""$enctemp\temp$extension.$extension"" $($audiotrack.ID):""$enctemp\$($audiotrack.UniqueID).$($audiotrack.Format)"""
							$audiotrack.Custom01 = "$($audiotrack.UniqueID).$($audiotrack.Format)"
							if (-not $take_audio_from_source) {
								Convert-Audio $(Get-ChildItem "$enctemp\$($audiotrack.UniqueID).$($audiotrack.Format)")
								if ($errorcount -gt 0){continue Main}
								$audiotrack.Custom01 = "$($audiotrack.UniqueID).m4a"
							}
						}

					}
		default	{throw "Unknown Recompress Method."}
	}

#	Foreach ($audiotrack in $audiotracks) {
#		Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "tracks ""$enctemp\temp$extension.$extension"" $($audiotrack.ID-1):""$enctemp\$($audiotrack.UniqueID).$($audiotrack.Format)"""
#		$audiotrack.Custom01 = "$($audiotrack.UniqueID).$($audiotrack.Format)"
#		if (-not $take_audio_from_source) {
#			Convert-Audio $(Get-ChildItem "$enctemp\$($audiotrack.UniqueID).$($audiotrack.Format)")
#			if ($errorcount -gt 0){continue Main}
#			$audiotrack.Custom01 = "$($audiotrack.UniqueID).m4a"
#		}
#	}


# Video Encoding
	$videotracks = @()
#  Extracting timecode & Chapters
	Foreach ($videotrack in $medinfo.Video) {
		$videotrack = Add-Member -memberType NoteProperty -name Custom01 -value "" -PassThru -inputObject $videotrack
		$videotracks += $videotrack
#		Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "timecodes_v2 ""$enctemp\temp$extension.$extension"" $($videotrack.ID):""$enctemp\$($videotrack.UniqueID).timecode"""
        Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "timecodes_v2 ""$enctemp\temp$extension.$extension"" $($videotrack.ID-1):""$enctemp\$($videotrack.UniqueID).timecode"""
	}

#  Extracting Chapters
	if ($Copy_Chapters){
		Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "chapters ""$enctemp\temp$extension.$extension"" -r ""$enctemp\chapters.xml"""
	}

#  Encoding
	if ($errorcount -gt 0){continue Main}
	Foreach ($videotrack in $videotracks) {
#		Start-Process -Wait -NoNewWindow -FilePath $mkvmerge_path -ArgumentList "-o ""$enctemp\$($videotrack.UniqueID).$($videotrack.Format)"" --video-tracks $($videotrack.ID) --no-audio --no-global-tags --no-subtitles --no-track-tags --no-chapters --no-cues ""$enctemp\temp$extension.$extension"""
        Start-Process -Wait -NoNewWindow -FilePath $mkvmerge_path -ArgumentList "-o ""$enctemp\$($videotrack.UniqueID).$($videotrack.Format)"" --video-tracks $($videotrack.ID-1) --no-audio --no-global-tags --no-subtitles --no-track-tags --no-chapters --no-cues ""$enctemp\temp$extension.$extension"""
		Copy-Item $(Join-Path $root_path "AviSynthtemplate.avs") "$enctemp\$($videotrack.UniqueID).avs"
		Switch ($DecompressSource)
		{
			"DirectShowSource"   {"DirectShowSource(""$($videotrack.UniqueID).$($videotrack.Format)"")" | Out-File "$enctemp\$($videotrack.UniqueID).avs" -Append -Encoding Ascii}
			"FFVideoSource"   {"FFVideoSource(""$($videotrack.UniqueID).$($videotrack.Format)"")" | Out-File "$enctemp\$($videotrack.UniqueID).avs" -Append -Encoding Ascii}
			default	{throw "Unknown Recompress Method."}
		}

		Compress-Video $(Get-ChildItem "$enctemp\$($videotrack.UniqueID).avs") -quantanizer $quantanizer -preset $preset -tune $tune -crop $crop -resize $resize -pulldown $pulldown
		$videotrack.Custom01 = "$($videotrack.UniqueID).mkv"
	}
	
# Building Result File
#	$audiotrack="--language 1:$aud_language --audio-tracks 1 --compression 1:none --no-video --no-subtitles ""$enctemp\temp.m4a"""
#	$audiotrack="--language 1:$aud_language --audio-tracks 1 --compression 1:none --no-video --no-subtitles ""$enctemp\temp$extension.$extension"""
#	$videotrack = "--language 1:$vid_language --default-track 1 --video-tracks 1 --compression 1:none --no-audio --no-subtitles --timecodes 1:""$enctemp\temp$extension.txt"" ""$enctemp\temp.mkv"""
#  --track-order 0:1,1:2

#  Check for Errors
	if ($errorscount -gt 0){continue Main}

    $track_order = "--track-order ";
    $global = "";
    $track_order_idx = 0;

  # Generate Video
    $item_n = $item - 1;
	$videotrack_cli = ""
	Foreach ($videotrack in $videotracks) {
	    $videotrack_cli += " --default-track 0";
	    $videotrack_cli += " --timecodes 0:""$enctemp\$($videotrack.UniqueID).timecode"""
		if ($video_languages[0] -or (-not $videotrack.LanguageString3)) {$videotrack_cli += " --language 0:""$($video_languages[[int]$videotrack.StreamKindID+1])"""} else {$videotrack_cli += " --language 0:""$($videotrack.LanguageString3)"""}
		$videotrack_cli += " --video-tracks 0"
		$videotrack_cli += " --compression 0:none"
		$videotrack_cli += " --no-audio --no-subtitles --no-chapters"
		$videotrack_cli += " --track-name 0:""$($videotrack.Title)"""
		$videotrack_cli += " ""$enctemp\$($videotrack.Custom01)"""
		$track_order += "$($track_order_idx):0"
		$track_order_idx = $track_order_idx + 1
	}

	$audiotrack_cli = ""
	Foreach ($audiotrack in $audiotracks) {
		$medinfo_a = new-object MediaInfoWrapper.MediaInfo("$enctemp\$($audiotrack.Custom01)")
		$audiotrack_cli += " --default-track 0";
		if ($audio_languages[0] -or (-not $audiotrack.LanguageString3)) {$audiotrack_cli += " --language 0:""$($audio_languages[[int]$audiotrack.StreamKindID+1])"""} else {$audiotrack_cli += " --language 0:""$($audiotrack.LanguageString3)"""}
		$audiotrack_cli += " --audio-tracks 0"
		$audiotrack_cli += " --compression 0:none"
		$audiotrack_cli += " --no-video --no-subtitles --no-chapters"
		$audiotrack_cli += " --track-name 0:""$($medinfo_a.Audio[0].Format) $($medinfo_a.Audio[0].ChannelsString)"""
		$audiotrack_cli += " ""$enctemp\$($audiotrack.Custom01)"""
		$track_order += ",$($track_order_idx):0"
		$track_order_idx = $track_order_idx + 1
	}

	$chapters_cli = ""
	if ($Copy_Chapters -and $($((Get-Item "$enctemp\chapters.xml").Length) -gt 0)){
		$chapters_cli = "--chapters ""$enctemp\chapters.xml"""
	}
    if ($debug) {
      "Run Command Cli: $mkvmerge_path --output ""$out\$($file.basename).mkv"" $videotrack_cli $audiotrack_cli $track_order $chapters_cli" 
	}
	Start-Process -Wait -NoNewWindow -FilePath $mkvmerge_path -ArgumentList "--output ""$out\$($file.basename).mkv"" $videotrack_cli $audiotrack_cli $track_order $chapters_cli"

# ExitCode is available when using -Wait...
#Write-Host "Starting Notepad with -Wait - return code will be available"
#$process = (Start-Process -FilePath "notepad.exe" -PassThru -Wait)
#Write-Host "Process finished with return code: " $process.ExitCode
#	if ($LASTEXITCODE -gt 0){$errorcount++}

# Removing Temp Files
	if (-not $debug) {
    	Remove-Item $enctemp\*
		if ($del_original -and $(Test-Path -LiteralPath $out\$($file.basename).mkv) -and $($errorcount -eq 0)){Remove-Item -LiteralPath $file.fullname}
	}
}

if ($(Test-Path -LiteralPath $(Join-Path $in "shutdown"))){Remove-Item $(Join-Path $in "shutdown");$shutdown=$true}
if ($debug) {
	""
	"Debug Mode Enabled: $debug"
	"Delete Original: $del_original"
	"Result File: $out\$($file.basename).mkv"
	"Result File Found: $(Test-Path -LiteralPath $out\$($file.basename).mkv)"
	"Errors Count: $errorcount"
	""
	"Video Track Cli: $videotrack_cli"
	"Audio Track Cli: $audiotrack_cli"
	"Track Order: $track_order"
	""
	"Shutdown mode enabled: $shutdown"
}
if ($shutdown){shutdown -t 60 -f -s}
