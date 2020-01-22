#Requires -Version 5
#Version 4.0

#Config

#Audio
$take_audio_from_source = $false
$audio_languages = @($false, "jpn", "jpn") #@("Use manual set","track ID/default","track ID",...)
$select_audio_by = @("all", @("jpn")) #select_audio_by:<language|trackid|all>,<list of languages|number of tracks> example1: @("all",@("jpn"))
$RecompressMethod = "Decoder"     #"AviSynth"|"Decoder"
#$RecompressMethod="AviSynth"     #"AviSynth"|"Decoder"

#Video
$video_languages = @($false, "jpn", "jpn") #@("Use manual set","track ID/default","track ID",...)
$tune = "animation" #tune:film,animation,grain,psnr,ssim,fastdecode,touhou
$DecompressSource = "Direct"	#"FFVideoSource"|"DirectShowSource"|"Direct"
$Copy_Chapters = $true
$quantanizer = 22
$preset = "ultrafast" #"veryslow"		#ultrafast,superfast,veryfast,faster,fast,medium,slow,slower,veryslow,placebo
$codec = "libx265"                #libx264,libx265

#Filters
$crop = @($false, 40, 0, 40, 0) #crop:enabled,left,top,right,bottom
#$resize=@($true,1280,720,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1280,960,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
$resize = @($false, 0, 0, "lanczos", "") #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1024,768,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1280,544,"lanczos","") #resize:enabled,width,height,method,", additional parametrs"
#$pulldown=@($false,"")	#pulldown:enabled,"step,offset1[,...]"

#Advanced Config
$del_original = $false
#$debug=$false
#$DebugPreference="Continue"  #Enable Debug mode
#$VerbosePreference = "continue"
$shutdown = $false
$extension = "MKV"

#General Paths
$root_path = $(Get-Location).Path
$tools_path = Join-Path $root_path "tools"
$enctemp = Join-Path $root_path "temp"
$out = Join-Path $root_path "out"
$in = Join-Path $root_path "in"

#Prepare base folders
if (-not $(Test-Path -LiteralPath $in)) { New-Item -Path $root_path -Name "in" -ItemType "directory" }
if (-not $(Test-Path -LiteralPath $out)) { New-Item -Path $root_path -Name "out" -ItemType "directory" }
if (-not $(Test-Path -LiteralPath $enctemp)) { New-Item -Path $root_path -Name "temp" -ItemType "directory" }

#Tools
$neroAacEnc_path = Join-Path $tools_path "neroAacEnc.exe"
$MediaInfoWrapper_path = Join-Path $tools_path "MediaInfoWrapper.dll"
$mkvmerge_path = Join-Path $tools_path "mkvtoolnix\mkvmerge.exe"
$mkvextract_path = Join-Path $tools_path "mkvtoolnix\mkvextract.exe"
$oggdec_path = Join-Path $tools_path "oggdec.exe"
$eac3to = Join-Path $tools_path "eac3to\eac3to.exe"
$faad_path = Join-Path $tools_path "faad.exe"
$wavi = Join-Path $tools_path "Wavi.exe"
$avs2yuv_path = Join-Path $tools_path "avs2yuv\avs2yuv64.exe"
$ffmpeg_path = Join-Path $tools_path "ffmpeg.exe"

Write-Verbose "Verbose Mode Enabled"

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

####################################################################################
###################################### Classes #####################################
####################################################################################
enum Presets {
    ultrafast
    superfast
    veryfast
    faster
    fast
    medium
    slow
    slower
    veryslow
    placebo
}

enum tune { 
    none
    psnr
    ssim
    grain
    fastdecode
    zerolatency
    animation
    film
    stillimage
}

enum ResizeMethods {
    fast_bilinear
    bilinear
    bicubic
    experimental
    neighbor
    area
    bicublin
    gauss
    sinc
    lanczos
    spline
}

enum codec { 
    libx264
    libx265
}
class TCrop {
    [bool]$Enabled = $false;
    [int]$Left = 0;
    [int]$Top = 0;
    [int]$Right = 0;
    [int]$Bottom = 0;
}

# resize methods: fastbilinear, bilinear, bicubic, experimental, point, area, bicublin, gauss, sinc, lanczos, spline
class TResize {
    [bool]$Enabled = $false;
    [int]$Width = 0;
    [int]$Height = 0;
    [ResizeMethods]$Method = [ResizeMethods]::lanczos;
}

#preset: ultrafast,superfast,veryfast,faster,fast,medium,slow,slower,veryslow,placebo
#	[ValidateSet('ultrafast','superfast','veryfast','faster','fast','medium','slow','slower','veryslow','placebo')]
#tune: film,animation,grain,psnr,ssim,fastdecode,touhou
#	[ValidateSet('none','film','animation','grain','stillimage','psnr','ssim','fastdecode','zerolatency')]
class ffmpeg {
    $mode = "normal" #"Dry"
    [bool]$Verbose = $false
    hidden [String]$ffmpeg_path;
    [Presets]$Preset = [Presets]::medium;
    [tune]$Tune = [tune]::none;
    [codec]$Codec = [codec]::libx265;
    [int16]$Quantanizer = 22;
    [bool]$Enable10bit = $true;
    [io.fileinfo]$SourceFileAVS;
    [ValidateSet('.mkv', '.mp4', '.hevc', '.264')]
    hidden [String]$DestinationFileExtension = ".mkv";
    [io.fileinfo]$DestinationFileName;

    #Filters
    [TCrop]$Crop = [TCrop]::new();
    [TResize]$Resize = [TResize]::new();

    [System.Diagnostics.ProcessPriorityClass]$ProcessPriority = [System.Diagnostics.ProcessPriorityClass]::Idle;

    # Constructor
    ffmpeg ([String]$ffmpeg_path) {
        if ($this.Verbose) { $VerbosePreference = "continue" }
        Write-Verbose "Check path of ffmpeg.exe"
        if (Test-Path $ffmpeg_path -PathType Leaf) { $this.ffmpeg_path = $ffmpeg_path } else { throw "ERROR: ffmpeg.exe not found." }
        Write-Verbose "ffmpeg used from: $($this.ffmpeg_path)"
    }

    [void]Compress() {
        if ($this.Verbose) { $VerbosePreference = "continue" }
        Write-Verbose "Mode: $($this.mode)"
        if (-not $(Resolve-Path ([io.fileinfo]$this.DestinationFileName).DirectoryName | Test-Path)) { throw "ERROR: Destination path is incorrect."; return }
        $this.DestinationFileExtension = $([io.fileinfo]$this.DestinationFileName).Extension
        Write-Verbose "File extension: $($this.DestinationFileExtension)"
        $DestinationFile = "$(Join-Path ([io.fileinfo]$this.DestinationFileName).DirectoryName ([io.fileinfo]$this.DestinationFileName).BaseName)$($this.DestinationFileExtension)"
        Write-Verbose "Destination File: $($DestinationFile)"
        switch ($this.DestinationFileExtension) {
            '.hevc' { $this.Codec = [codec]::libx265; }
            '.264' { $this.Codec = [codec]::libx264; }
        }
        Write-Verbose "Codec set to: $($this.Codec)"
		
        # Creating Filter
        $filters = @()
        if ($this.Crop.Enabled) { $filters += "-filter:v ""crop=w=in_w-$($this.Crop.Left)-$($this.Crop.Right):h=in_h-$($this.Crop.Top)-$($this.Crop.Bottom):x=$($this.Crop.Left):y=$($this.Crop.Top)""" }
        if ($this.Resize.Enabled) { $filters += "-vf scale=$($this.Resize.Width):$($this.Resize.Height) -sws_flags $($this.Resize.Method)" }
        if ($this.Enable10bit) { $filters += "-pix_fmt yuv420p10le" }
        if ($this.Tune -ne "none") { $filters += "-tune $($this.Tune)" }
		
        $videofilter = ""
        if ($filters.Length -gt 0) { $videofilter = [string]::Join(" ", $filters) }
        Write-Verbose "Filter CLI: $($videofilter)"

        # Encoding
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.Arguments = "-i ""$($this.SourceFileAVS.FullName)"" -c:v $($this.Codec) -crf $($this.Quantanizer) -preset $($this.Preset) $videofilter -an -sn -dn ""$DestinationFile"""
        $startInfo.FileName = $this.ffmpeg_path
        Write-Verbose "Executing: $($startInfo.FileName) $($startInfo.Arguments)"
        if ($this.mode -ne "Dry") {
            $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
            $startInfo.UseShellExecute = $false
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $startInfo
            $process.Start() | Out-Null
            $process.PriorityClass = $this.ProcessPriority
            $process.WaitForExit()
            if ($(Get-ChildItem $DestinationFile).Length -eq 0) { throw "File $($this.SourceFileAVS.Name) hasn't been compressed." }
        }
    }
}


class MediaInfoAudioTrack {
    [string]$ID;
    [string]$StreamOrder;
    [string]$UniqueID;
    [string]$ExtractID;
    [string]$Format;
    [string]$Title;
    [string]$StreamKindID;
    [string]$Language;
    [string]$CodecID;
    [string]$Channels;
    [string]$SamplingRate;
    [string]$Custom01 = "";
    [string]$Custom02 = "";
    [string]$Custom03 = "";
    [string]$GUID;

    MediaInfoAudioTrack () {
        $this.GUID = [guid]::NewGuid().tostring()
    }
}

class MediaInfoVideoTrack {
    [string]$ID;
    [string]$StreamOrder;
    [string]$UniqueID;
    [string]$ExtractID;
    [string]$Title;
    [string]$Format;
    [string]$StreamKindID;
    [string]$Language;
    [string]$CodecID;
    [int16]$Width;
    [int16]$Height;
    [string]$DisplayAspectRatio;
    [string]$Custom01 = "";
    [string]$Custom02 = "";
    [string]$Custom03 = "";
    [string]$GUID;

    MediaInfoVideoTrack () {
        $this.GUID = [guid]::NewGuid().tostring()
    }
}

class MediaInfoTextTrack {
    [string]$ID;
    [string]$StreamOrder;
    [string]$UniqueID;
    [string]$ExtractID;
    [string]$Title;
    [string]$Format;
    [string]$StreamKindID;
    [string]$Language;
    [string]$CodecID;
    [string]$Custom01 = "";
    [string]$Custom02 = "";
    [string]$Custom03 = "";
    [string]$GUID;

    MediaInfoTextTrack () {
        $this.GUID = [guid]::NewGuid().tostring()
    }
}

class MediaInfo {
    hidden [string]$MediaInfoWrapper_path;
    hidden [string]$MediaFile;
    hidden [PSObject]$medinfo;

    # Properties
    [string]$FullName;
    [string]$DirectoryName;
    [string]$BaseName;
    [string]$Extension;
    [MediaInfoAudioTrack[]]$Audiotracks;
    [MediaInfoVideoTrack[]]$Videotracks;
    [MediaInfoTextTrack[]]$Texttracks;
    [bool]$Chapters = $false;


    # Constructor
    MediaInfo ([String]$MediaInfoWrapper_path) {
        if (Test-Path $MediaInfoWrapper_path -PathType Leaf) { $this.MediaInfoWrapper_path = $MediaInfoWrapper_path } else { throw "ERROR: Can not access library MediaInfoWrapper." }
        add-Type -Path $MediaInfoWrapper_path
    }

    # Methods
    [void] Open () {
        $this.Close()

        if ($this.medinfo) { $this.medinfo = $null }
        if (Test-Path $this.MediaFile -PathType Leaf) { } else { throw "ERROR: Media file doesn't exists." }

        $this.medinfo = new-object MediaInfoWrapper.MediaInfo($this.MediaFile)
        ## General
        $this.FullName = $this.medinfo.General[0].CompleteName;
        $this.DirectoryName = $this.medinfo.General[0].FolderName;
        $this.BaseName = $this.medinfo.General[0].FileName;
        $this.Extension = $this.medinfo.General[0].FileExtension.ToUpper();

        ## Audio
        Foreach ($audtrack in $this.medinfo.Audio) {
            $audiotrack = [MediaInfoAudioTrack]::new()
            $audiotrack.ID = $audtrack.ID;
            $audiotrack.StreamOrder = $audtrack.StreamOrder;
            $audiotrack.UniqueID = $audtrack.UniqueID;
            $audiotrack.Format = $audtrack.Format;
            $audiotrack.Title = $audtrack.Title;
            $audiotrack.StreamKindID = $audtrack.StreamKindID;
            $audiotrack.Language = $audtrack.LanguageString3;
            $audiotrack.CodecID = $audtrack.CodecID;
            $audiotrack.Channels = $audtrack.ChannelsString;
            $audiotrack.SamplingRate = $audtrack.SamplingRate;
            $this.Audiotracks += $audiotrack
        }

        ## Video
        Foreach ($vidtrack in $this.medinfo.Video) {
            $videotrack = [MediaInfoVideoTrack]::new()
            $videotrack.ID = $vidtrack.ID;
            $videotrack.StreamOrder = $vidtrack.StreamOrder;
            $videotrack.UniqueID = $vidtrack.UniqueID;
            $videotrack.Title = $vidtrack.Title;
            $videotrack.Format = $vidtrack.Format;
            $videotrack.Language = $vidtrack.LanguageString3;
            $videotrack.StreamKindID = $vidtrack.StreamKindID;
            $videotrack.Width = $vidtrack.Width;
            $videotrack.Height = $vidtrack.Height;
            $videotrack.DisplayAspectRatio = $vidtrack.DisplayAspectRatio;
            $videotrack.CodecID = $vidtrack.CodecID;
            $this.Videotracks += $videotrack
        }

        ## Text
        Foreach ($txttrack in $this.medinfo.Text) {
            $texttrack = [MediaInfoTextTrack]::new()
            $texttrack.ID = $txttrack.ID;
            $texttrack.StreamOrder = $txttrack.StreamOrder;
            $texttrack.UniqueID = $txttrack.UniqueID;
            $texttrack.Title = $txttrack.Title;
            $texttrack.Format = $txttrack.Format;
            $texttrack.Language = $txttrack.LanguageString3;
            $texttrack.StreamKindID = $txttrack.StreamKindID;
            $texttrack.CodecID = $txttrack.CodecID;
            $this.Texttracks += $texttrack
        }

        ## Chapters
        $this.Chapters = ($this.medinfo.MenuCount -gt 0)

    }

    [void] Open ([string]$MediaFile) {
        $this.Close()

        if (Test-Path $MediaFile -PathType Leaf) { $this.MediaFile = $MediaFile } else { throw "ERROR: Media file doesn't exists." }
        $this.medinfo = new-object MediaInfoWrapper.MediaInfo($MediaFile)
        ## General
        $this.FullName = $this.medinfo.General[0].CompleteName;
        $this.DirectoryName = $this.medinfo.General[0].FolderName;
        $this.BaseName = $this.medinfo.General[0].FileName;
        $this.Extension = $this.medinfo.General[0].FileExtension.ToUpper();

        ## Audio
        Foreach ($audtrack in $this.medinfo.Audio) {
            $audiotrack = [MediaInfoAudioTrack]::new()
            $audiotrack.ID = $audtrack.ID;
            $audiotrack.StreamOrder = $audtrack.StreamOrder;
            $audiotrack.UniqueID = $audtrack.UniqueID;
            $audiotrack.Format = $audtrack.Format;
            $audiotrack.Title = $audtrack.Title;
            $audiotrack.StreamKindID = $audtrack.StreamKindID;
            $audiotrack.Language = $audtrack.LanguageString3;
            $audiotrack.CodecID = $audtrack.CodecID;
            $audiotrack.Channels = $audtrack.ChannelsString;
            $audiotrack.SamplingRate = $audtrack.SamplingRate;
            $this.Audiotracks += $audiotrack
        }

        ## Video
        Foreach ($vidtrack in $this.medinfo.Video) {
            $videotrack = [MediaInfoVideoTrack]::new()
            $videotrack.ID = $vidtrack.ID;
            $videotrack.StreamOrder = $vidtrack.StreamOrder;
            $videotrack.UniqueID = $vidtrack.UniqueID;
            $videotrack.Title = $vidtrack.Title;
            $videotrack.Format = $vidtrack.Format;
            $videotrack.Language = $vidtrack.LanguageString3;
            $videotrack.StreamKindID = $vidtrack.StreamKindID;
            $videotrack.Width = $vidtrack.Width;
            $videotrack.Height = $vidtrack.Height;
            $videotrack.DisplayAspectRatio = $vidtrack.DisplayAspectRatio;
            $videotrack.CodecID = $vidtrack.CodecID;
            $this.Videotracks += $videotrack
        }

        ## Text
        Foreach ($txttrack in $this.medinfo.Text) {
            $texttrack = [MediaInfoTextTrack]::new()
            $texttrack.ID = $txttrack.ID;
            $texttrack.StreamOrder = $txttrack.StreamOrder;
            $texttrack.UniqueID = $txttrack.UniqueID;
            $texttrack.Title = $txttrack.Title;
            $texttrack.Format = $txttrack.Format;
            $texttrack.Language = $txttrack.LanguageString3;
            $texttrack.StreamKindID = $txttrack.StreamKindID;
            $texttrack.CodecID = $txttrack.CodecID;
            $this.Texttracks += $texttrack
        }

        ## Chapters
        $this.Chapters = ($this.medinfo.MenuCount -gt 0)

    }

    [void] Close () {
        $this.medinfo = $null;
        $this.FullName = "";
        $this.DirectoryName = "";
        $this.BaseName = "";
        $this.Extension = "";
        $this.Videotracks = $null;
        $this.Audiotracks = $null;
        $this.Chapters = $false;
    }

}


class TVideoTrack {
    hidden [string]$videotrack_cli = "";

    [string]$Format;
    [string]$FileName;
    [string]$Title;
    [string]$Language;
    [string]$Width;
    [string]$Height;
    [string]$TimeCodeFile;

    [string] MakeCommand () {
        $this.videotrack_cli = "";
        #	    $this.videotrack_cli += " --default-track 0";
        if ($this.TimeCodeFile) {
            if (Test-Path $this.TimeCodeFile -PathType Leaf) { $this.videotrack_cli += " --timecodes 0:""$($this.TimeCodeFile)""" } else { throw "ERROR: Timecode file $($this.TimeCodeFile) can't be accessed." }
        }
        if ($this.Language) { $this.videotrack_cli += " --language 0:""$($this.Language)""" };
        #		$this.videotrack_cli += " --video-tracks 0";
        #		$this.videotrack_cli += " --compression 0:none";
        #		$this.videotrack_cli += " --no-audio --no-global-tags --no-chapters";
        if ($this.Title) { $this.videotrack_cli += " --track-name 0:""$($this.Title)""" };
        if (Test-Path -LiteralPath $this.FileName -PathType Leaf) { $this.videotrack_cli += " ""$($this.FileName)""" } else { throw "ERROR: Video File $($this.FileName) doesn't accessible." }
        return $this.videotrack_cli;
    }
}

class TAudioTrack {
    hidden [string]$audiotrack_cli = "";

    [string]$Format;
    [string]$FileName;
    [string]$Title;
    [string]$Language;

    [string] MakeCommand () {
        $this.audiotrack_cli = "";
        #		$this.audiotrack_cli += " --default-track 0";
        if ($this.Language) { $this.audiotrack_cli += " --language 0:""$($this.Language)""" };
        #		$this.audiotrack_cli += " --audio-tracks 0"
        #		$this.audiotrack_cli += " --compression 0:none"
        $this.audiotrack_cli += " --no-video --no-global-tags --no-chapters"
        $this.audiotrack_cli += " --track-name 0:""$($this.Title)"""
        if (Test-Path -LiteralPath $this.FileName -PathType Leaf) { $this.audiotrack_cli += " ""$($this.FileName)""" } else { throw "ERROR: Audio File $($this.FileName) doesn't accessible." }
        return $this.audiotrack_cli;
    }
}

class TSubtitleTrack {
    hidden [string]$subtitle_cli = "";

    [string]$Format;
    [string]$FileName;
    [string]$Title;
    [string]$Language;

    [string] MakeCommand () {
        $this.subtitle_cli = "";
        #		$this.subtitle_cli += " --default-track 0";
        if ($this.Language) { $this.subtitle_cli += " --language 0:""$($this.Language)""" };
        #		$this.subtitle_cli += " --subtitle-tracks 0";
        #		$this.subtitle_cli += " --no-video --no-audio --no-track-tags --no-global-tags --no-chapters"
        $this.subtitle_cli += " --track-name 0:""$($this.Title)"""
        if (Test-Path -LiteralPath $this.FileName -PathType Leaf) { $this.subtitle_cli += " ""$($this.FileName)""" } else { throw "ERROR: Subtitle File $($this.FileName) doesn't accessible." }
        return $this.subtitle_cli;
    }
}

class MKVMerge {
    hidden [string]$MKVMerge_path;

    [string]$DestinationFile;

    [TVideoTrack[]]$VideoTracks;
    [TAudioTrack[]]$AudioTracks;
    [TSubtitleTrack[]]$SubtitleTracks;
    [string]$ChaptersFile;

    # Constructor
    MKVMerge ([String]$MKVMerge_path) {
        if (Test-Path $MKVMerge_path -PathType Leaf) { $this.MKVMerge_path = $MKVMerge_path } else { throw "ERROR: Can not access executable mkvmerge.exe." }
    }

    [string] MakeFile () {
        $chapters_cli = "";
        if ($this.ChaptersFile) {
            if (Test-Path -LiteralPath $this.ChaptersFile -PathType Leaf) { $chapters_cli = " --chapters ""$($this.ChaptersFile)""" } else { throw "ERROR: Chapters XML file $($this.ChaptersFile) can't be accessed." }
        }
        $videotrack_cli = "";
        if ($this.VideoTracks) { $this.VideoTracks | ForEach-Object { $videotrack_cli += $_.MakeCommand() } }

        $audiotrack_cli = "";
        if ($this.AudioTracks) { $this.AudioTracks | ForEach-Object { $audiotrack_cli += $_.MakeCommand() } }

        $subtitle_cli = "";
        if ($this.SubtitleTracks) { $this.SubtitleTracks | ForEach-Object { $subtitle_cli += $_.MakeCommand() } }

        Start-Process -Wait -NoNewWindow -FilePath $this.MKVMerge_path -ArgumentList "--output ""$($this.DestinationFile)"" $videotrack_cli $audiotrack_cli $chapters_cli $subtitle_cli"
        return "$($this.MKVMerge_path) --output ""$($this.DestinationFile)"" $videotrack_cli $audiotrack_cli $chapters_cli $subtitle_cli";
    }


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

# Not Finished
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
    }

    #  Extracting Chapters
    if ($Copy_Chapters -and $medinfo.Chapters) {
        "Extracting chapters..."
        Write-Verbose "mkvextract Command Line: $mkvextract_path chapters ""$enctemp\temp$extension.$extension"" -r ""$enctemp\chapters.xml"""
        Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "chapters ""$enctemp\temp$extension.$extension"" -r ""$enctemp\chapters.xml"""
    }

    #  Encoding
    if ($errorcount -gt 0) { continue Main }
    Foreach ($videotrack in $medinfo.Videotracks) {
        #		Start-Process -Wait -NoNewWindow -FilePath $mkvmerge_path -ArgumentList "-o ""$enctemp\$($videotrack.GUID).$($videotrack.Format)"" --video-tracks $($videotrack.ID) --no-audio --no-global-tags --no-subtitles --no-track-tags --no-chapters --no-cues ""$enctemp\temp$extension.$extension"""
        Write-Verbose "mkvextract Command Line: $mkvextract_path -o ""$enctemp\$($videotrack.GUID).$($videotrack.Format)"" --video-tracks $($videotrack.ID-1) --no-audio --no-global-tags --no-subtitles --no-track-tags --no-chapters --no-cues ""$enctemp\temp$extension.$extension"""
        Start-Process -Wait -NoNewWindow -FilePath $mkvmerge_path -ArgumentList "-o ""$enctemp\$($videotrack.GUID).$($videotrack.Format)"" --video-tracks $($videotrack.ID-1) --no-audio --no-global-tags --no-subtitles --no-track-tags --no-chapters --no-cues ""$enctemp\temp$extension.$extension"""
        Switch ($DecompressSource) {
            "DirectShowSource" {
                Copy-Item $(Join-Path $root_path "AviSynthtemplate.avs") "$enctemp\$($videotrack.GUID).avs"
                "DirectShowSource(""$($videotrack.GUID).$($videotrack.Format)"")" | Out-File "$enctemp\$($videotrack.GUID).avs" -Append -Encoding Ascii
                $Encode = [ffmpeg]::new($ffmpeg_path);
                $Encode.SourceFileAVS = "$enctemp\$($videotrack.GUID).avs";
                $Encode.DestinationFileName = "$enctemp\$($videotrack.GUID).mkv";
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
                $videotrack.Custom01 = "$($videotrack.GUID).mkv"
                $Encode.Compress();
                $Encode = $null;

            }
            "FFVideoSource" {
                Copy-Item $(Join-Path $root_path "AviSynthtemplate.avs") "$enctemp\$($videotrack.GUID).avs"
                "FFVideoSource(""$($videotrack.GUID).$($videotrack.Format)"")" | Out-File "$enctemp\$($videotrack.GUID).avs" -Append -Encoding Ascii
                $Encode = [ffmpeg]::new($ffmpeg_path);
                $Encode.SourceFileAVS = "$enctemp\$($videotrack.GUID).avs";
                $Encode.DestinationFileName = "$enctemp\$($videotrack.GUID).mkv";
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
                $videotrack.Custom01 = "$($videotrack.GUID).mkv"
                $Encode.Compress();
                $Encode = $null;
            }
            "Direct" {
                "$($videotrack.GUID).$($videotrack.Format)"
                $Encode = [ffmpeg]::new($ffmpeg_path);
                $Encode.SourceFileAVS = "$enctemp\$($videotrack.GUID).$($videotrack.Format)";
                $Encode.DestinationFileName = "$enctemp\$($videotrack.GUID).mkv";
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
                $videotrack.Custom01 = "$($videotrack.GUID).mkv"
                $Encode.Compress();
                $Encode = $null;
            }
            default	{ throw "Unknown Recompress Method." }
        }

    }

    #  Check for Errors
    if ($errorscount -gt 0) { continue Main }
    
    $mkvmerge = [MKVMerge]::new($mkvmerge_path);
    $mkvmerge.DestinationFile = "$out\$($file.basename).mkv";

    # Combine MKV
    Foreach ($videotrack in $medinfo.Videotracks) {
        $videotrk = [TVideoTrack]::new()
        $videotrk.FileName = "$enctemp\$($videotrack.Custom01)";
        if ($video_languages[0] -or (-not $videotrack.Language)) { $videotrk.Language = $video_languages[[int]$videotrack.StreamKindID + 1] } else { $videotrk.Language = $($videotrack.Language) }
        $videotrk.Title = $videotrack.Title
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
    $res = $mkvmerge.MakeFile()
    Write-Verbose "Run Command Cli: $res"

    # Removing Temp Files
    if (-not $(Test-Debug)) {
        Remove-Item $enctemp\*
        if ($del_original -and $(Test-Path -LiteralPath $out\$($file.basename).mkv) -and $($errorcount -eq 0)) { Remove-Item -LiteralPath $file.fullname }
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
