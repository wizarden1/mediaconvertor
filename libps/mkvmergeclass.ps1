#requires -version 5

class TVideoTrack {
    hidden [string]$videotrack_cli = "";

    [string]$Format;
    [string]$FileName;
    [string]$Title;
    [string]$Language;
    [string]$Width;
    [string]$Height;
    [string]$TimeCodeFile;
    [bool]$UseTimeCodeFile = $true;

    [string] MakeCommand () {
        $this.videotrack_cli = "";
        #	    $this.videotrack_cli += " --default-track 0";
        if ($this.TimeCodeFile -and $this.UseTimeCodeFile) {
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
    [string]$Title;
    $EncProcess = $null;
    [TVideoTrack[]]$VideoTracks;
    [TAudioTrack[]]$AudioTracks;
    [TSubtitleTrack[]]$SubtitleTracks;
    [string]$ChaptersFile;

    # Constructor
    MKVMerge ([String]$MKVMerge_path) {
        if (Test-Path $MKVMerge_path -PathType Leaf) { $this.MKVMerge_path = $MKVMerge_path } else { throw "ERROR: Can not access executable mkvmerge.exe." }
    }

    [void]MakeFile () {
        if (-not $this.title) {$this.title = $this.DestinationFile.Split("\")[-1];}
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

        Write-Verbose "Run Command Cli: $($this.MKVMerge_path) --output ""$($this.DestinationFile)"" --title ""$($this.Title)"" $videotrack_cli $audiotrack_cli $chapters_cli $subtitle_cli"
        $proc = Start-Process -Wait -NoNewWindow -PassThru -FilePath $this.MKVMerge_path -ArgumentList "--output ""$($this.DestinationFile)"" --title ""$($this.Title)"" $videotrack_cli $audiotrack_cli $chapters_cli $subtitle_cli"
        $this.EncProcess = $proc
    }
}

#$res = [MKVMerge]::new("C:\Multimedia\Programs\mkvtoolnix\mkvmerge.exe")
#$res.DestinationFile = "H:\Multimedia\Programs\Utils\temp\The.Secret.mkv"
#$res.VideoTracks += [TVideoTrack]::new()
#$res.AudioTracks += [TAudioTrack]::new()
#$res.AudioTracks += [TAudioTrack]::new()
#$res.SubtitleTracks += [TSubtitleTrack]::new()
#$res.ChaptersFile = "H:\Multimedia\Programs\Utils\temp\The.Secret.DVDRip.x264.AAC.-[tRuAVC]_chapters.xml" 
#$res.VideoTracks[0].FileName = "H:\Multimedia\Programs\Utils\temp\The.Secret.DVDRip.x264.AAC.-[tRuAVC]_track1_eng.h264" 
#$res.VideoTracks[0].Language = "eng"
#$res.VideoTracks[0].Title = "The Secret"

#$res.AudioTracks[0].FileName = "H:\Multimedia\Programs\Utils\temp\The.Secret.DVDRip.x264.AAC.-[tRuAVC]_track2_rus.aac"
#$res.AudioTracks[0].Title = "AAC Rus"
#$res.AudioTracks[0].Language = "rus"

#$res.AudioTracks[1].Language = "eng"
#$res.AudioTracks[1].Title = "AAC Eng"
#$res.AudioTracks[1].FileName = "H:\Multimedia\Programs\Utils\temp\The.Secret.DVDRip.x264.AAC.-[tRuAVC]_track3_eng.aac" 

#$res.SubtitleTracks[0].FileName = "H:\Multimedia\Programs\Utils\temp\The.Secret.DVDRip.x264.AAC.-[tRuAVC]_track4_rus.srt" 
#$res.SubtitleTracks[0].Title = "Sub RUS"
#$res.SubtitleTracks[0].Language = "rus"

#$res