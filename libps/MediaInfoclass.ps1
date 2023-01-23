#requires -version 5
#Version 1.0.1
# 1.0.1 - Audio channels to integer
# 1.0.0 - initial relese

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
    [int16]$Channels;
    [string]$SamplingRate;
    [string]$Custom01 = "";
    [string]$Custom02 = "";
    [string]$Custom03 = "";
    [string]$GUID;
    [bool]$Default = $false;

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
    [int16]$BitDepth;
    [string]$DisplayAspectRatio;
    [string]$Custom01 = "";
    [string]$Custom02 = "";
    [string]$Custom03 = "";
    [string]$GUID;
    [bool]$Default = $false;
    [string]$FrameRate;
    [string]$FrameRateMode;

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
    [bool]$Default = $false;

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
    [long] $Duration;
    [long] $StreamSize;
    [string] $Title;
    [string] $Album;
    [string] $AlbumPerformer;
    [string] $Track;
    [string] $Genre;
    [string] $ContentType;
    [string] $Composer;
    [string] $Performer;
    [string] $Format;
    [string] $Codec;
    [long] $TrackPosition;
    [long] $TrackPosition_Total;
    [string] $Chapter;
    [string] $Publisher;
    [string] $Recorded_Date;
    [string] $Copyright;
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
        $this.Duration = $this.medinfo.General[0].Duration;
        $this.StreamSize = $this.medinfo.General[0].StreamSize;
        $this.Title = $this.medinfo.General[0].Title;
        $this.Album = $this.medinfo.General[0].Album;
        $this.Track = $this.medinfo.General[0].Track;
        $this.Genre = $this.medinfo.General[0].Genre;
        $this.ContentType = $this.medinfo.General[0].ContentType;
        $this.Composer = $this.medinfo.General[0].Composer;
        $this.AlbumPerformer = $this.medinfo.General[0].AlbumPerformer;
        $this.Performer = $this.medinfo.General[0].Performer;
        $this.Format = $this.medinfo.General[0].Format;
        $this.Codec = $this.medinfo.General[0].Codec;
        $this.TrackPosition = $this.medinfo.General[0].TrackPosition;
        $this.TrackPosition_Total = $this.medinfo.General[0].TrackPosition_Total;
        $this.Chapter = $this.medinfo.General[0].Chapter;
        $this.Publisher = $this.medinfo.General[0].Publisher;
        $this.Recorded_Date = $this.medinfo.General[0].Recorded_Date;
        $this.Copyright = $this.medinfo.General[0].Copyright;

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
            $audiotrack.Channels = $audtrack.Channels;
            $audiotrack.SamplingRate = $audtrack.SamplingRate;
            $audiotrack.Default = $audtrack.Default -eq "Yes";
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
            $videotrack.BitDepth = $vidtrack.BitDepth;
            $videotrack.DisplayAspectRatio = $vidtrack.DisplayAspectRatio;
            $videotrack.CodecID = $vidtrack.CodecID;
            $videotrack.Default = $vidtrack.Default -eq "Yes";
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
            $texttrack.Default = $txttrack.Default -eq "Yes";
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
        $this.Duration = $this.medinfo.General[0].Duration;
        $this.StreamSize = $this.medinfo.General[0].StreamSize;
        $this.Title = $this.medinfo.General[0].Title;
        $this.Album = $this.medinfo.General[0].Album;
        $this.Track = $this.medinfo.General[0].Track;
        $this.Genre = $this.medinfo.General[0].Genre;
        $this.ContentType = $this.medinfo.General[0].ContentType;
        $this.Composer = $this.medinfo.General[0].Composer;
        $this.AlbumPerformer = $this.medinfo.General[0].AlbumPerformer;
        $this.Performer = $this.medinfo.General[0].Performer;
        $this.Format = $this.medinfo.General[0].Format;
        $this.Codec = $this.medinfo.General[0].Codec;
        $this.TrackPosition = $this.medinfo.General[0].TrackPosition;
        $this.TrackPosition_Total = $this.medinfo.General[0].TrackPosition_Total;
        $this.Chapter = $this.medinfo.General[0].Chapter;
        $this.Publisher = $this.medinfo.General[0].Publisher;
        $this.Recorded_Date = $this.medinfo.General[0].Recorded_Date;
        $this.Copyright = $this.medinfo.General[0].Copyright;

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
            $audiotrack.Channels = $audtrack.Channels;
            $audiotrack.SamplingRate = $audtrack.SamplingRate;
            $audiotrack.Default = $audtrack.Default -eq "Yes";
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
            $videotrack.BitDepth = $vidtrack.BitDepth;
            $videotrack.DisplayAspectRatio = $vidtrack.DisplayAspectRatio;
            $videotrack.CodecID = $vidtrack.CodecID;
            $videotrack.Default = $vidtrack.Default -eq "Yes";
            $videotrack.FrameRate = $vidtrack.FrameRate;
            $videotrack.FrameRateMode = $vidtrack.FrameRate_Mode;
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
            $texttrack.Default = $txttrack.Default -eq "Yes";
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

#$MediaInfoWrapper_path = "D:\Multimedia\Programs\Utils\tools\MediaInfoWrapper.dll"
#$res = [MediaInfo]::new($MediaInfoWrapper_path)
#$res.Open("D:\Multimedia\Programs\Utils\in\13.mkv")
