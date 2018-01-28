# Version 1.0
#Config

#Tags and Chapters
$BookTitle=""
$BookArtist=""
$BookGenre=""
$Recorded_Date=""
$AlbumPerformer=""
$cover="cover.jpg"
$CopyTagsfromSource=$true

#Advanced Config
$del_original=$true
#$DebugPreference="Continue"  #Enable Debug mode
$shutdown=$false

#Constants
$extension="MP3"
$multimedia = Join-Path $(Get-Location).Drive.Root "Multimedia\Programs"
$root_path = Join-Path $multimedia "Utils"
$tools_path = Join-Path $root_path "tools"
$enctemp = Join-Path $root_path "temp"
$out = Join-Path $root_path "out"
$in = Join-Path $root_path "in"

$neroAacEnc_path = Join-Path $tools_path "neroAacEnc.exe"
$MediaInfoWrapper_path = Join-Path $tools_path "MediaInfoWrapper.dll"
$sox_path = Join-Path $tools_path "sox\sox.exe"
$mp4chaps_path = Join-Path $tools_path "mp4v2\mp4chaps.exe"
$taglib_sharp_path = Join-Path $tools_path "taglib-sharp.dll"

Write-Debug "Debug Mode Enabled"

#Check Prerequisite
"Checking Prerequisite..."
if (-not $(Test-Path -LiteralPath $neroAacEnc_path)){Write-Host "$neroAacEnc_path not found" -ForegroundColor Red;break}
if (-not $(Test-Path -LiteralPath $MediaInfoWrapper_path)){Write-Host "$MediaInfoWrapper_path not found" -ForegroundColor Red;break}
if (-not $(Test-Path -LiteralPath $sox_path)){Write-Host "$sox_path not found" -ForegroundColor Red;break}
if (-not $(Test-Path -LiteralPath $mp4chaps_path)){Write-Host "$mp4chaps_path not found" -ForegroundColor Red;break}
if (-not $(Test-Path -LiteralPath $taglib_sharp_path)){Write-Host "$taglib_sharp_path not found" -ForegroundColor Red;break}

#Classes and Functions
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
        if (Test-Path $MediaInfoWrapper_path -PathType Leaf){$this.MediaInfoWrapper_path = $MediaInfoWrapper_path} else {throw "ERROR: Can not access library MediaInfoWrapper."}
		add-Type -Path $MediaInfoWrapper_path
	}

# Methods
    [void] Open () {
        $this.Close()

        if ($this.medinfo) {$this.medinfo = $null}
        if (Test-Path $this.MediaFile -PathType Leaf){} else {throw "ERROR: Media file doesn't exists."}

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

        if (Test-Path $MediaFile -PathType Leaf){$this.MediaFile = $MediaFile} else {throw "ERROR: Media file doesn't exists."}
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


#########################
# Main Program
$errorcount=0

"Cleaning Temp..."
Remove-Item $enctemp\*

$files = dir $in | where {$_.Extension -eq ".$extension"}

$medinfo = [MediaInfo]::new($MediaInfoWrapper_path)

#Building TOC
"Building TOC..."
if ($CopyTagsfromSource){

$duration = 1
:toc Foreach ($file in $files) {
    	if (-not $(Test-Path -LiteralPath $file.FullName)){continue toc}
# Process Commands
    	if ($(Test-Path -LiteralPath $(Join-Path $in "terminate"))){
	    	Remove-Item $(Join-Path $in "terminate")
		    "Terminate File Found, Exiting"
    		break
	    }
        $medinfo.open($file.fullname)
        if ($BookTitle -eq "") {$BookTitle=$medinfo.Album}
        if ($BookArtist -eq ""){$BookArtist=$medinfo.Performer}
        if ($BookGenre -eq "") {$BookGenre=$medinfo.Genre}
        if ($AlbumPerformer -eq "") {$AlbumPerformer=$medinfo.AlbumPerformer}
        if ($Recorded_Date -eq "") {$Recorded_Date=$medinfo.Recorded_Date}

        if ($($medinfo.Title)){
            $topic="$([timespan]::FromMilliseconds($duration).ToString().Remove(12)) $($medinfo.Title)"
            $topic | Out-File -FilePath "$enctemp\book.chapters.txt" -Append -Encoding utf8
            $duration = $duration + $medinfo.Duration
            Write-Debug "Chapter Record: $topic"
        }
        $medinfo.Close()
    }
}
Write-Debug "Book Title: $BookTitle"
Write-Debug "Book Artist: $BookArtist"
Write-Debug "Book Genre: $BookGenre"
Write-Debug "Book Year: $Recorded_Date"
Write-Debug "Book Performer: $AlbumPerformer"

if (Test-Path -LiteralPath $(Join-Path $in $cover)){
    Copy-Item $(Join-Path $in $cover) $(Join-Path $enctemp $cover)
# Removing Source Files
	if ($DebugPreference -eq "SilentlyContinue") {
		if ($del_original -and $(Test-Path -LiteralPath $(Join-Path $enctemp $cover)) -and $($errorcount -eq 0)){Remove-Item $(Join-Path $in $cover)}
	}
}


#Decoding Audio
"Decoding Audio..."
:decode Foreach ($file in $files) {
        if (-not $(Test-Path -LiteralPath $file.FullName)){continue decode}
        "Decoding $($file.Name)"
	if ($DebugPreference -eq "SilentlyContinue") {$silent="-V1"} else {$silent="-V3 -S"}
	Start-Process -Wait -NoNewWindow -FilePath $sox_path -ArgumentList "$silent ""$($file.FullName)"" --rate 44100 ""$enctemp\$($file.BaseName).WAV"""
	if ($DebugPreference -eq "SilentlyContinue" -and $del_original -and $(Test-Path -LiteralPath "$enctemp\$($file.BaseName).WAV") -and $($errorcount -eq 0)){Remove-Item -LiteralPath $($file.FullName)}
}


#Joining Audio files
"Joining Audio..."
if ($DebugPreference -ne "SilentlyContinue") {$silent="-V3 -S"} else {$silent=""}
Start-Process -Wait -NoNewWindow -FilePath $sox_path -ArgumentList "$silent --rate 44100 ""$enctemp\*.WAV"" ""$enctemp\joined.WAV"""

#Encoding M4b
"Encoding Audio..."
if (-not $(Test-Path -LiteralPath $enctemp\joined.WAV)){"ERROR. No file to Encode"; break}
Start-Process -Wait -NoNewWindow -FilePath $neroAacEnc_path -ArgumentList "-ignorelength -if ""$enctemp\joined.WAV"" -of ""$enctemp\book.m4b"""

#Setting TOC To Result Book
"Set TOC..."
if ($DebugPreference -ne "SilentlyContinue") {$silent="--verbose 2"} else {$silent=""}
Start-Process -Wait -NoNewWindow -FilePath $mp4chaps_path -ArgumentList "$silent -i ""$enctemp\book.m4b"""
Start-Process -Wait -NoNewWindow -FilePath $mp4chaps_path -ArgumentList "$silent -c -z -Q ""$enctemp\book.m4b"""

"Adding Cover and Tags..."
Add-Type -Path $taglib_sharp_path

$file = [TagLib.Mpeg4.File]::Create("$enctemp\book.m4b")
$newArt = New-Object TagLib.Picture("$enctemp\$cover")
$file.Tag.Pictures = $newArt
$file.Tag.Album = $BookTitle
$file.Tag.Artists = $BookArtist
$file.Tag.Genres = $BookGenre
$file.Tag.Year = $Recorded_Date
$file.Tag.AlbumArtists = $AlbumPerformer
$file.Save()
$file.Dispose()

"Coping result"
Copy-Item -Force "$enctemp\book.m4b" "$(Join-Path $out "$BookTitle.m4b")"

# Removing Temp Files
if ($DebugPreference -eq "SilentlyContinue") {
   	Remove-Item $enctemp\*
	if ($del_original -and $(Test-Path -LiteralPath "$(Join-Path $out "$BookTitle.m4b")") -and $($errorcount -eq 0)){Remove-Item -LiteralPath "$(Join-Path $in "*.$extension")"}
}
