#Requires -Version 5
#Version 4.3
# 4.3 - Add External includes
# 4.2 - Add Parameter Verbose Mode
# 4.1 - Add copy subtitles
# 4.0 - Add ffmpeg

param (
    [switch]$Verbose = $false
)
#Config
$libs = @("MediaInfoclass", "mkvmergeclass", "FFMPEGclass")

#Audio
$take_audio_from_source = $false
$audio_languages = @($false, "jpn", "jpn") #@("Use manual set","track ID/default","track ID",...)
#$select_audio_by = @("all", @("jpn")) #select_audio_by:<language|trackid|all>,<list of languages|number of tracks> example1: @("all",@("jpn"))
$RecompressMethod = "Decoder"     #"AviSynth"|"Decoder"
#$RecompressMethod="AviSynth"     #"AviSynth"|"Decoder"

#Video
$video_languages = @($false, "jpn", "jpn") #@("Use manual set","track ID/default","track ID",...)
$tune = "animation" #tune:film,animation,grain,psnr,ssim,fastdecode,touhou
$DecompressSource = "Direct"	#"FFVideoSource"|"DirectShowSource"|"Direct"
$Copy_Chapters = $true
$quantanizer = 24
$preset = "medium"		#ultrafast,superfast,veryfast,faster,fast,medium,slow,slower,veryslow,placebo
#$preset = "ultrafast"
$codec = "libx265"                #libx264,libx265

#Subtitles
$Copy_Subtitles = $true
$Sub_languages = @("rus") #@("lng1","lng2","lng3",...)

#Filters
$crop = @($false, 40, 0, 40, 0) #crop:enabled,left,top,right,bottom
#$resize=@($true,1280,720,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1280,960,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
$resize = @($false, 0, 0, "lanczos", "") #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1024,768,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1280,544,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
#$pulldown=@($false,"")	#pulldown:enabled,"step,offset1[,...]"

#Advanced Config
$del_original = $true
$titles_from_json = $true  #Use title of series from json
$titles_json = "boruto.json" #[{"file": "Overlord - 01 [Beatrice-Raws].mkv","title": "End and Beginning"},{...}]
#$debug=$false
#$DebugPreference="Continue"  #Enable Debug mode
#$VerbosePreference = "continue"
$shutdown = $false
$extension = "MKV"

#General Paths
$root_path = $(Get-Location).Path
$tools_path = Join-Path $root_path "tools"
$toolsx64_path = Join-Path $root_path "tools_64"
$enctemp = Join-Path $root_path "temp"
$out = Join-Path $root_path "out"
$in = Join-Path $root_path "in"
$libs_path = Join-Path $root_path "libps"

# Init
if ($Verbose) {$VerbosePreference = "continue"}
Write-Verbose "Verbose Mode Enabled"

#Prepare base folders
if (-not $(Test-Path -LiteralPath $in)) { New-Item -Path $root_path -Name "in" -ItemType "directory" }
if (-not $(Test-Path -LiteralPath $out)) { New-Item -Path $root_path -Name "out" -ItemType "directory" }
if (-not $(Test-Path -LiteralPath $enctemp)) { New-Item -Path $root_path -Name "temp" -ItemType "directory" }

#Tools
$neroAacEnc_path = Join-Path $tools_path "neroAacEnc.exe"
$MediaInfoWrapper_path = Join-Path $toolsx64_path "MediaInfoWrapper.dll"
$mkvmerge_path = Join-Path $toolsx64_path "mkvtoolnix\mkvmerge.exe"
$mkvextract_path = Join-Path $toolsx64_path "mkvtoolnix\mkvextract.exe"
$oggdec_path = Join-Path $tools_path "oggdec.exe"
$eac3to = Join-Path $tools_path "eac3to\eac3to.exe"
$faad_path = Join-Path $tools_path "faad.exe"
$wavi = Join-Path $tools_path "Wavi.exe"
$avs2yuv_path = Join-Path $toolsx64_path "avs2yuv\avs2yuv64.exe"
$ffmpeg_path = Join-Path $toolsx64_path "ffmpeg.exe"
$title_json = Join-Path $in $titles_json

#Check Prerequisite
"Checking Prerequisite..."
Write-Verbose "Checking $neroAacEnc_path"
if (-not $(Test-Path -LiteralPath $neroAacEnc_path)) { Write-Host "$neroAacEnc_path not found" -ForegroundColor Red; break }
Write-Verbose "Checking $MediaInfoWrapper_path"
if (-not $(Test-Path -LiteralPath $MediaInfoWrapper_path)) { Write-Host "$MediaInfoWrapper_path not found" -ForegroundColor Red; break }
Write-Verbose "Checking $ffmpeg_path"
if (-not $(Test-Path -LiteralPath $ffmpeg_path)) { Write-Host "$ffmpeg_path not found" -ForegroundColor Red; break }
Write-Verbose "Checking $mkvmerge_path"
if (-not $(Test-Path -LiteralPath $mkvmerge_path)) { Write-Host "$mkvmerge_path not found" -ForegroundColor Red; break }
Write-Verbose "Checking $mkvextract_path"
if (-not $(Test-Path -LiteralPath $mkvextract_path)) { Write-Host "$mkvextract_path not found" -ForegroundColor Red; break }
Write-Verbose "Checking $oggdec_path"
if (-not $(Test-Path -LiteralPath $oggdec_path)) { Write-Host "$oggdec_path not found" -ForegroundColor Red; break }
Write-Verbose "Checking $eac3to"
if (-not $(Test-Path -LiteralPath $eac3to)) { Write-Host "$eac3to not found" -ForegroundColor Red; break }
Write-Verbose "Checking $faad_path"
if (-not $(Test-Path -LiteralPath $faad_path)) { Write-Host "$faad_path not found" -ForegroundColor Red; break }
Write-Verbose "Checking $wavi"
if (-not $(Test-Path -LiteralPath $wavi)) { Write-Host "$wavi not found" -ForegroundColor Red; break }
Write-Verbose "Checking $avs2yuv_path"
if (-not $(Test-Path -LiteralPath $avs2yuv_path)) { Write-Host "$avs2yuv_path not found" -ForegroundColor Red; break }

#Check title json
if ($titles_from_json){
    Write-Verbose "Checking $title_json"
    if (-not $(Test-Path -LiteralPath $title_json)) { Write-Host "$title_json not found" -ForegroundColor Red; break }
    try {
        Write-Verbose "Converting $titles_json to JSON Object"
        $json = ConvertFrom-Json $(Get-Content -Raw $title_json)
    }
    catch {
        Write-Host "$title_json syntax error" -ForegroundColor Red; break
    }
    $files = Get-ChildItem $in | Where-Object { $_.Extension -eq ".$extension" }
    $err_count=0
    ForEach($file in $files) {
        Write-Verbose "Checking record in JSON for file $($file.name)"
        if ([string]::IsNullOrEmpty($($json | Where-Object {$_.file -eq $file.name}))) {
            Write-Host "$($file.name) not found in $titles_json" -ForegroundColor Red
            $err_count++
        }
    }
    if ($err_count -gt 0) { Write-Host "$title_json has $err_count errors" -ForegroundColor Red; break }
    "JSON File uploaded successfuly"
}

# Include
####################################################################################
###################################### Classes #####################################
####################################################################################
foreach ($lib in $libs) {
    $lib_path = $(Join-Path $libs_path "$lib.ps1")
    if (-not $(Test-Path -LiteralPath $lib_path)) { Write-Host "$lib not found" -ForegroundColor Red; break }
    Write-Verbose "Loading $lib.ps1"
    Invoke-Expression $(Get-Content -Raw $lib_path)
}

####################################################################################
##################################### Functions ####################################
####################################################################################

function Test-Debug {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$IgnorePSBoundParameters
        ,
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreDebugPreference
        ,
        [Parameter(Mandatory = $false)]
        [switch]$IgnorePSDebugContext
    )
    process {
        ((-not $IgnoreDebugPreference.IsPresent) -and ($DebugPreference -ne "SilentlyContinue")) -or
        ((-not $IgnorePSBoundParameters.IsPresent) -and $PSBoundParameters.Debug.IsPresent) -or
        ((-not $IgnorePSDebugContext.IsPresent) -and ($PSDebugContext))
    }
}

function Compress-ToM4A {
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.IO.FileInfo]
        [ValidateScript( { ( Test-Path $_ ) } ) ]
        $SourceFile,
		
        [String]
        $DestinationFileName = "$($SourceFile.FullName).m4a"
    )
    begin {
        # Check
        if (-not $(Test-Path $eac3to)) { throw "eac3to.exe not found."; return $false }
    }
	
    process {
        if (-not $(Resolve-Path ([io.fileinfo]$DestinationFileName).DirectoryName | Test-Path)) { return $false }
        if (([io.fileinfo]$DestinationFileName).Extension -eq ".m4a") { $DestinationFileExtension = ".m4a" } else { $DestinationFileExtension = "$(([io.fileinfo]$DestinationFileName).Extension).m4a" }
        $DestinationFile = "$(Join-Path ([io.fileinfo]$DestinationFileName).DirectoryName ([io.fileinfo]$DestinationFileName).BaseName)$DestinationFileExtension"

        Switch ($SourceFile.Extension) {
            ".AAC" { Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile""" }
            #						Start-Process -Wait -NoNewWindow -FilePath $faad_path -ArgumentList """$($SourceFile.FullName)"" ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).wav"""
            #						Start-Process -Wait -NoNewWindow -FilePath $neroAacEnc_path -ArgumentList "-if ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).wav"" -of ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a"" -ignorelength"
            ".PCM" { Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile""" }
            #			".Vorbis" 	{
            #						Start-Process -Wait -NoNewWindow -FilePath $oggdec_path -ArgumentList "--wavout ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).wav"" ""$($SourceFile.FullName)"""
            #						Start-Process -Wait -NoNewWindow -FilePath $neroAacEnc_path -ArgumentList "-if ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).wav"" -of ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a"" -ignorelength"
            #					}
            ".FLAC" { Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile""" }
            ".AC-3" { Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile""" }
            ".DTS" { Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile""" }
            ".MPEG Audio" { Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile""" }
            ".TrueHD" { Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile""" }
            default	{ throw "Unknown Audio Codec."; return $false }
        }
        if (-not $(Test-Path -LiteralPath $DestinationFile )) { throw "File $($SourceFile.Name) hasn't been recompressed."; return $false }
    }
    end {
        return $true
    }

}

function Expand-TracksfromMKV {
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [ValidateScript( { ( $_ -ne $nul) } ) ]
        $mediainfo,

        [System.IO.DirectoryInfo]
        [ValidateScript( { ( Test-Path $_ ) } ) ]
        $OutputDir = $mediainfo.DirectoryName

    )
    begin { 
        if (-not $(Test-Path $mkvextract_path)) { throw "mkvextract.exe not found."; return }
    }
    process {
        # Video
        Foreach ($videotrack in $mediainfo.VideoTracks) {
            "Extracting Video track"
            Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "tracks ""$($mediainfo.FullName)"" $($videotrack.StreamOrder):""$OutputDir\$($videotrack.UniqueID).$($videotrack.Format)"""
            "Extracting Timecode for Video track"
            Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "timecodes_v2 ""$($mediainfo.FullName)"" $($videotrack.StreamOrder):""$OutputDir\$($videotrack.UniqueID).timecode"""
        }
        # Audio
        Foreach ($audiotrack in $mediainfo.AudioTracks) {
            "Extracting Audio track"
            Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "tracks ""$($mediainfo.FullName)"" $($audiotrack.StreamOrder):""$OutputDir\$($audiotrack.UniqueID).$($audiotrack.Format)"""
        }
        # Chapters
        if ($mediainfo.Chapters) {
            "Extracting Chapters"
            Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "chapters ""$($mediainfo.FullName)"" -r ""$OutputDir\chapters.xml"""
        }
    }
    end {
    }
}

####################################################################################
################################### Main Program ###################################
####################################################################################
# Clean Temp
Remove-Item $enctemp\*

$files = Get-ChildItem $in | Where-Object { $_.Extension -eq ".$extension" }
Write-Output "Files will be converted:"
if ($null -eq $files) { Write-Output "No files to convert" } else { $files | ForEach-Object { Write-Output $_.BaseName } }
:Main Foreach ($file in $files) {
    $errorcount = 0
    if (-not $(Test-Path -LiteralPath $file.FullName)) { continue Main }
    # Process Commands
    if ($(Test-Path -LiteralPath $(Join-Path $in "terminate"))) {
        Remove-Item $(Join-Path $in "terminate")
        "Terminate File Found, Exiting"
        break
    }
    # Method 1
    #	New-HardLink $enctemp\temp$extension.$extension $($file.FullName)
    #	Start-Process -Wait -NoNewWindow -FilePath "fsutil" -ArgumentList "hardlink create ""$enctemp\temp$extension.$extension"" ""$($file.FullName)"""

    # Method 2
    "Copying file $($file.Name)"
    $file | Copy-Item -destination "$enctemp\temp$extension.$extension"
    if ($(Test-Path -LiteralPath "$enctemp\temp$extension.$extension")) { "File copied succesfully" } else { break }

    # Load Media Info
    $medinfo = [MediaInfo]::new($MediaInfoWrapper_path)
    $medinfo.open("$enctemp\temp$extension.$extension")
    Write-Verbose "MediaInfo: $(ConvertTo-Json $medinfo)"

    # Audio Encoding
    #  Selecting Audio tracks
    #	Foreach ($audiotrack in $medinfo.Audiotracks) {
    #		Switch ($select_audio_by[0])
    #		{
    #			"language" 	{if ($select_audio_by[1] -contains $audiotrack.Language){$audiotracks += $audiotrack}}
    #			"trackid" 	{if ($select_audio_by[1] -contains $audiotrack.StreamKindID){$audiotracks += $audiotrack}}
    #			default	{$audiotracks += $audiotrack}
    #		}
    #	}

    # Audio Encoding
    Switch ($RecompressMethod) {
        "AviSynth" {
            Copy-Item $(Join-Path $root_path "AviSynthtemplate.avs") "$enctemp\videofile.avs"
            "DirectShowSource(""$($file.FullName)"")" | Out-File "$enctemp\videofile.avs" -Append -Encoding Ascii
            Write-Verbose "AviSynth Command Line: $wavi ""$enctemp\videofile.avs"" ""$enctemp\$($medinfo.Audiotracks[0].GUID).pcm"""
            Start-Process -Wait -NoNewWindow -FilePath $wavi -ArgumentList """$enctemp\videofile.avs"" ""$enctemp\$($medinfo.Audiotracks[0].GUID).pcm"""
            Compress-ToM4A -SourceFile "$enctemp\$($medinfo.Audiotracks[0].GUID).pcm" -DestinationFileName "$enctemp\$($audiotrack.GUID).m4a"
            if ($errorcount -gt 0) { continue Main }
            $medinfo.Audiotracks[0].Custom01 = "$($medinfo.Audiotracks[0].GUID).m4a"
            $medinfoAud = [MediaInfo]::new($MediaInfoWrapper_path)
            $medinfoAud.open("$enctemp\$($audiotrack.GUID).m4a")
            $audiotrack.Format = $medinfoAud.Audiotracks[0].Format
            $medinfoAud.Close()
        }
        "Decoder" {
            Foreach ($audiotrack in $medinfo.Audiotracks) {
                Write-Verbose "Decoder Command Line: $mkvextract_path tracks ""$enctemp\temp$extension.$extension"" $($audiotrack.ID-1):""$enctemp\$($audiotrack.GUID).$($audiotrack.Format)"""
                Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "tracks ""$enctemp\temp$extension.$extension"" $($audiotrack.ID-1):""$enctemp\$($audiotrack.GUID).$($audiotrack.Format)"""
                $audiotrack.Custom01 = "$($audiotrack.GUID).$($audiotrack.Format)"
                if (-not $take_audio_from_source) {
                    Compress-ToM4A -SourceFile "$enctemp\$($audiotrack.GUID).$($audiotrack.Format)" -DestinationFileName "$enctemp\$($audiotrack.GUID).m4a"
                    if ($errorcount -gt 0) { continue Main }
                    $audiotrack.Custom01 = "$($audiotrack.GUID).m4a"
                    $medinfoAud = [MediaInfo]::new($MediaInfoWrapper_path)
                    $medinfoAud.open("$enctemp\$($audiotrack.GUID).m4a")
                    $audiotrack.Format = $medinfoAud.Audiotracks[0].Format
                    $medinfoAud.Close()
                }
            }
        }
        default	{ throw "Unknown Recompress Method." }
    }

    # Video Encoding
    #  Extracting timecode
    Foreach ($videotrack in $medinfo.Videotracks) {
        "Extracting timecodes..."
        Write-Verbose "mkvextract Command Line: $mkvextract_path timecodes_v2 ""$enctemp\temp$extension.$extension"" $($videotrack.ID-1):""$enctemp\$($videotrack.GUID).timecode"""
        Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "timecodes_v2 ""$enctemp\temp$extension.$extension"" $($videotrack.ID-1):""$enctemp\$($videotrack.GUID).timecode"""
        # Replace Title
        if ($titles_from_json) {
            "Use Title Source: $titles_from_json"
            Write-Verbose "Title looking for in JSON: $($file.Name)"
            "Title for $($file.Name): $($($json | Where-Object {$_.file -eq $($file.Name)}).title)"
            $videotrack.Title = $($json | Where-Object {$_.file -eq $($file.Name)}).title
        }
    }

    #  Extracting Chapters
    if ($Copy_Chapters -and $medinfo.Chapters) {
        "Extracting chapters..."
        Write-Verbose "mkvextract Command Line: $mkvextract_path chapters ""$enctemp\temp$extension.$extension"" -r ""$enctemp\chapters.xml"""
        Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "chapters ""$enctemp\temp$extension.$extension"" -r ""$enctemp\chapters.xml"""
    }

    #  Extract Subtitles
    if ($Copy_Subtitles -and $medinfo.Texttracks) {
        "Extracting Subtitles..."
        Foreach ($texttrack in $medinfo.Texttracks) {
            if ($([string]::IsNullOrEmpty($Sub_languages)) -or $($texttrack.Language -in $Sub_languages)) {
                Write-Verbose "mkvextract Command Line: $mkvextract_path tracks ""$enctemp\temp$extension.$extension"" $($texttrack.ID-1):""$enctemp\$($texttrack.GUID).$($($texttrack.Format))"""
                Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "tracks ""$enctemp\temp$extension.$extension"" $($texttrack.ID-1):""$enctemp\$($texttrack.GUID).$($($texttrack.Format))"""
                $texttrack.Custom01 = "$($texttrack.GUID).$($($texttrack.Format))"
            }
        }
    }

    #  Encoding
    if ($errorcount -gt 0) { continue Main }
    Foreach ($videotrack in $medinfo.Videotracks) {
        #		Start-Process -Wait -NoNewWindow -FilePath $mkvmerge_path -ArgumentList "-o ""$enctemp\$($videotrack.GUID).$($videotrack.Format)"" --video-tracks $($videotrack.ID) --no-audio --no-global-tags --no-subtitles --no-track-tags --no-chapters --no-cues ""$enctemp\temp$extension.$extension"""
        Write-Verbose "mkvextract Command Line: $mkvmerge_path -o ""$enctemp\$($videotrack.GUID).$($videotrack.Format)"" --video-tracks $($videotrack.ID-1) --no-audio --no-global-tags --no-subtitles --no-track-tags --no-chapters --no-cues ""$enctemp\temp$extension.$extension"""
        Start-Process -Wait -NoNewWindow -FilePath $mkvmerge_path -ArgumentList "-o ""$enctemp\$($videotrack.GUID).$($videotrack.Format)"" --video-tracks $($videotrack.ID-1) --no-audio --no-global-tags --no-subtitles --no-track-tags --no-chapters --no-cues ""$enctemp\temp$extension.$extension"""
        Switch ($DecompressSource) {
            "DirectShowSource" {
                Write-Verbose "DirectShowSource Selected"
                Copy-Item $(Join-Path $root_path "AviSynthtemplate.avs") "$enctemp\$($videotrack.GUID).avs"
                "DirectShowSource(""$($videotrack.GUID).$($videotrack.Format)"")" | Out-File "$enctemp\$($videotrack.GUID).avs" -Append -Encoding Ascii
                $Encode = [ffmpeg]::new($ffmpeg_path);
                $Encode.SourceFileAVS = "$enctemp\$($videotrack.GUID).avs";
                $Encode.DestinationFileName = "$enctemp\$($videotrack.GUID).hevc";
                $Encode.Quantanizer = $quantanizer;
                $Encode.Preset = $preset;
                $Encode.Tune = $tune;
                $Encode.Codec = $codec;
                $Encode.Resize.Enabled = $resize[0];
                $Encode.Resize.Width = $resize[1];
                $Encode.Resize.Height = $resize[2];
                $Encode.Resize.Method = $resize[3];
                $Encode.Crop.Enabled = $crop[0];
                $Encode.Crop.Left = $crop[1];
                $Encode.Crop.Top = $crop[2];
                $Encode.Crop.Right = $crop[3];
                $Encode.Crop.Bottom = $crop[4];
                $videotrack.Custom01 = "$($videotrack.GUID).hevc"
                Write-Verbose "Encode config: $(ConvertTo-Json $Encode)"
                $Encode.Compress();
                $Encode = $null;

            }
            "FFVideoSource" {
                Write-Verbose "FFVideoSource Selected"
                Copy-Item $(Join-Path $root_path "AviSynthtemplate.avs") "$enctemp\$($videotrack.GUID).avs"
                "FFVideoSource(""$($videotrack.GUID).$($videotrack.Format)"")" | Out-File "$enctemp\$($videotrack.GUID).avs" -Append -Encoding Ascii
                $Encode = [ffmpeg]::new($ffmpeg_path);
                $Encode.SourceFileAVS = "$enctemp\$($videotrack.GUID).avs";
                $Encode.DestinationFileName = "$enctemp\$($videotrack.GUID).hevc";
                $Encode.Quantanizer = $quantanizer;
                $Encode.Preset = $preset;
                $Encode.Tune = $tune;
                $Encode.Codec = $codec;
                $Encode.Resize.Enabled = $resize[0];
                $Encode.Resize.Width = $resize[1];
                $Encode.Resize.Height = $resize[2];
                $Encode.Resize.Method = $resize[3];
                $Encode.Crop.Enabled = $crop[0];
                $Encode.Crop.Left = $crop[1];
                $Encode.Crop.Top = $crop[2];
                $Encode.Crop.Right = $crop[3];
                $Encode.Crop.Bottom = $crop[4];
                $videotrack.Custom01 = "$($videotrack.GUID).hevc"
                Write-Verbose "Encode config: $(ConvertTo-Json $Encode)"
                $Encode.Compress();
                $Encode = $null;
            }
            "Direct" {
                Write-Verbose "Direct Selected"
                "$($videotrack.GUID).$($videotrack.Format)"
                $Encode = [ffmpeg]::new($ffmpeg_path);
                $Encode.SourceFileAVS = "$enctemp\$($videotrack.GUID).$($videotrack.Format)";
                $Encode.DestinationFileName = "$enctemp\$($videotrack.GUID).hevc";
                $Encode.Quantanizer = $quantanizer;
                $Encode.Preset = $preset;
                $Encode.Tune = $tune;
                $Encode.Codec = $codec;
                $Encode.Resize.Enabled = $resize[0];
                $Encode.Resize.Width = $resize[1];
                $Encode.Resize.Height = $resize[2];
                $Encode.Resize.Method = $resize[3];
                $Encode.Crop.Enabled = $crop[0];
                $Encode.Crop.Left = $crop[1];
                $Encode.Crop.Top = $crop[2];
                $Encode.Crop.Right = $crop[3];
                $Encode.Crop.Bottom = $crop[4];
                $videotrack.Custom01 = "$($videotrack.GUID).hevc"
                Write-Verbose "Encode config: $(ConvertTo-Json $Encode)"
                $Encode.Compress();
                $Encode = $null;
            }
            default	{ throw "Unknown Recompress Method." }
        }
    #  Extracting timecode
    #    Write-Verbose "mkvextract Command Line: $mkvextract_path timecodes_v2 ""$($Encode.DestinationFileName)"" $($videotrack.ID-1):""$enctemp\$($videotrack.GUID).timecode"""
    #    Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "timecodes_v2 ""$($Encode.DestinationFileName)"" $($videotrack.ID-1):""$enctemp\$($videotrack.GUID).timecode"""
    }

    #  Check for Errors
    if ($errorscount -gt 0) { continue Main }
    
    Write-Verbose "Merging result to $out\$($file.basename).mkv"
    $mkvmerge = [MKVMerge]::new($mkvmerge_path);
    $mkvmerge.DestinationFile = "$out\$($file.basename).mkv";

    # Combine MKV
    Foreach ($videotrack in $medinfo.Videotracks) {
        $videotrk = [TVideoTrack]::new()
        $videotrk.FileName = "$enctemp\$($videotrack.Custom01)";
        if ($video_languages[0] -or (-not $videotrack.Language)) { $videotrk.Language = $video_languages[[int]$videotrack.StreamKindID + 1] } else { $videotrk.Language = $($videotrack.Language) }
        $videotrk.Title = $videotrack.Title;
        $videotrk.TimeCodeFile = "$enctemp\$($videotrack.GUID).timecode";
        $mkvmerge.VideoTracks += $videotrk;
    }

    Foreach ($audiotrack in $medinfo.Audiotracks) {
        $audiotrk = [TAudioTrack]::new()
        $audiotrk.FileName = "$enctemp\$($audiotrack.Custom01)";
        if ($audio_languages[0] -or (-not $audiotrack.Language)) { $audiotrk.Language = $audio_languages[[int]$audiotrack.StreamKindID + 1] } else { $audiotrk.Language = $($audiotrack.Language) }
        $audiotrk.Title = "$($audiotrack.Format) $($audiotrack.Channels)";
        $mkvmerge.AudioTracks += $audiotrk;
    }

    if ($Copy_Chapters -and $(Test-Path -LiteralPath "$enctemp\chapters.xml") -and $($((Get-Item "$enctemp\chapters.xml").Length) -gt 0)) {
        $mkvmerge.ChaptersFile = "$enctemp\chapters.xml"
    }

    if ($Copy_Subtitles -and $medinfo.Texttracks) {
        Foreach ($texttrack in $medinfo.Texttracks) {
            if ($([string]::IsNullOrEmpty($Sub_languages)) -or $($texttrack.Language -in $Sub_languages)) {
                $texttrk = [TSubtitleTrack]::new()
                $texttrk.FileName = "$enctemp\$($texttrack.Custom01)";
                $texttrk.Language = "$($texttrack.Language)"
                $texttrk.Title = "$($texttrack.Title)"
                $mkvmerge.SubtitleTracks += $texttrk;
            }
        }
    }
    Write-Verbose "Merge config: $(ConvertTo-Json $mkvmerge)"

    $res = $mkvmerge.MakeFile()
    Write-Verbose "Run Command Cli: $res"

    # Removing Temp Files
    if (-not $(Test-Debug)) {
        Write-Verbose "Cleaning $enctemp"
        Remove-Item $enctemp\*
        
        if ($del_original -and $(Test-Path -LiteralPath $out\$($file.basename).mkv) -and $($errorcount -eq 0)) { 
            Write-Verbose "Remove $($file.fullname)"
            Remove-Item -LiteralPath $file.fullname
        }
    }
}

# Last Task
if ($(Test-Path -LiteralPath $(Join-Path $in "shutdown"))) { Remove-Item $(Join-Path $in "shutdown"); $shutdown = $true }
Write-Verbose ""
Write-Verbose "Verbose Mode Enabled: $true"
Write-Verbose "Delete Original: $del_original"
Write-Verbose "Result File: $out\$($file.basename).mkv"
Write-Verbose "Result File Found: $(Test-Path -LiteralPath $out\$($file.basename).mkv)"
Write-Verbose "Errors Count: $errorcount"
Write-Verbose ""
Write-Verbose "Shutdown mode enabled: $shutdown"
Write-Verbose "Press any key to Continue"
if (Test-Debug) { $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL }
Write-Output "Process completed"
if ($shutdown) { shutdown -t 60 -f -s }
