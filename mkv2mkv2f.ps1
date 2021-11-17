#Requires -Version 5
#Version 4.11.1
# 4.11.1 - Add VobSub Subtitles usage
# 4.11.0 - Add pulldown
# 4.10.1 - Add Title to mkvmerge library
# 4.10.0 - Add Video from source
# 4.9.0 - Add async audio encoding
# 4.8.2 - Fix name of track with " sign
# 4.8.1 - Add Selection audio languages
# 4.8 - Full rebuild process of recompress
# 4.7.1 - Add error cheking
# 4.7 - Add Custom Filter and Modifier
# 4.6 - Add Deinterlace Filter
# 4.5 - Use External subtitles with JSON source
# 4.4.7 - BugFix with vfr input video
# 4.4.6 - Add Colors to output
# 4.4.5 - Add removing Read Only Attribute
# 4.4.4 - Add Opus audio format
# 4.4.3 - Remove JSON Duplicates
# 4.4.2 - Add new audio format as source
# 4.4.1 - Fixing if source file type the same as destination produce error
# 4.4 - Add Import multiple JSON files
# 4.3 - Add External includes
# 4.2 - Add Parameter Verbose Mode
# 4.1 - Add copy subtitles
# 4.0 - Add ffmpeg

param (
    [switch]$Verbose = $false,
    [switch]$Debug = $false
)
#Config
$libs = @("MediaInfoclass", "mkvmergeclass", "FFMPEGclass", "EAC3class")

#Audio
$take_audio_from_source = $false
#$take_audio_from_source = $true
$take_audio_track_name_from_source = $false
$set_audio_languages = @($false, "jpn", "jpn") #@("Use manual set","track ID/default","track ID",...)
$select_audio_by = @("all", @("jpn"))     #select_audio_by:<language|trackid|all>,<list of languages|number of tracks> example1: @("all",@("jpn"))
$RecompressMethod = "Decoder"                  #"AviSynth"|"Decoder"
$DecodeAutoMode = "Pattern"                    #"Auto"|"Pattern"|"FFMpeg"|"Eac3to"
$AsyncEncoding = $true

#Video
$take_video_from_source = $false
$video_languages = @($false, "jpn", "jpn") #@("Use manual set","track ID/default","track ID",...)
$use_timecode_file = $true
$tune = "grain"
#$tune = "grain"                            #tune(x265):animation,grain,psnr,ssim,fastdecode,zerolatency tune(x264):film,animation,grain,stillimage,fastdecode,zerolatency
$DecompressSource = "Direct"	           #"FFVideoSource"|"DirectShowSource"|"Direct"
$Copy_Chapters = $true
$quantanizer = 24
$preset = "medium"		           #ultrafast,superfast,veryfast,faster,fast,medium,slow,slower,veryslow,placebo
#$preset = "ultrafast"
$codec = "libx265"                         #libx264,libx265

#Subtitles
$Copy_Subtitles = $true
$Sub_languages = @("rus")                  #@("lng1","lng2","lng3",...)

#Filters
$crop = @($false,"ltrb","",240,0,240,0)    #crop:enabled,mode("ltrb","ffmpeg"),ffmpeg_crop_string,left,top,right,bottom  
#$resize=@($true,1280,720,"lanczos","")    #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1280,960,"lanczos","")    #resize:enabled,width,height,method,", additional parametrs"
$resize = @($false, 0, 0, "lanczos", "")   #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1024,768,"lanczos","")    #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1280,544,"lanczos","")    #resize:enabled,width,height,method,", additional parametrs"
$pulldown=$false
$deinterlace = @($false, "send_frame", "auto", "all") #(send_frame, send_field, send_frame_nospatial, send_field_nospatial), (tff, bff, auto), (all, interlaced)
$CustomFilter = ""

#Modifiers
#$vsync = "passthrough"                     #passthrough, cfr, vfr, drop, auto     #Required for vfr video
$vsync = "auto"                     #passthrough, cfr, vfr, drop, auto     #Required for vfr video
$CustomModifier = ""

#Advanced Config
$del_original = $true
$use_json = $false                         #Use title of series from json
$json_file = ""                            #"title.json" #[{"file": "Overlord - 01 [Beatrice-Raws].mkv","subtitle_file": "Overlord - 01 [Beatrice-Raws].ass","title": "End and Beginning"},{...}]
#$VerbosePreference = "Continue"            #Enable Verbose mode
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
if ($Debug) {Write-Host "Debug mode Enabled" -ForegroundColor Red}

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
$title_json = Join-Path $in $json_file

#Check Prerequisite
Write-Host "Checking Prerequisite..." -ForegroundColor Green
Write-Verbose "Checking $neroAacEnc_path"
if (-not $(Test-Path -LiteralPath $neroAacEnc_path)) { Write-Error "$neroAacEnc_path not found"; break }
Write-Verbose "Checking $MediaInfoWrapper_path"
if (-not $(Test-Path -LiteralPath $MediaInfoWrapper_path)) { Write-Error "$MediaInfoWrapper_path not found"; break }
Write-Verbose "Checking $ffmpeg_path"
if (-not $(Test-Path -LiteralPath $ffmpeg_path)) { Write-Error "$ffmpeg_path not found"; break }
Write-Verbose "Checking $mkvmerge_path"
if (-not $(Test-Path -LiteralPath $mkvmerge_path)) { Write-Error "$mkvmerge_path not found"; break }
Write-Verbose "Checking $mkvextract_path"
if (-not $(Test-Path -LiteralPath $mkvextract_path)) { Write-Error "$mkvextract_path not found"; break }
Write-Verbose "Checking $oggdec_path"
if (-not $(Test-Path -LiteralPath $oggdec_path)) { Write-Error "$oggdec_path not found"; break }
Write-Verbose "Checking $eac3to"
if (-not $(Test-Path -LiteralPath $eac3to)) { Write-Error "$eac3to not found"; break }
Write-Verbose "Checking $faad_path"
if (-not $(Test-Path -LiteralPath $faad_path)) { Write-Error "$faad_path not found"; break }
Write-Verbose "Checking $wavi"
if (-not $(Test-Path -LiteralPath $wavi)) { Write-Error "$wavi not found"; break }
Write-Verbose "Checking $avs2yuv_path"
if (-not $(Test-Path -LiteralPath $avs2yuv_path)) { Write-Error "$avs2yuv_path not found"; break }

#Check title json
if ($use_json){
    Write-Verbose "Checking $title_json"
    if (-not $(Test-Path -LiteralPath $title_json)) { Write-Error "$title_json not found"; break }
    if ($json_file) {
        try {
Write-Host "Converting $json_file to JSON Object"
            $json = ConvertFrom-Json $(Get-Content -Raw $title_json)
        }
        catch {
            Write-Error "$title_json syntax error"; break
        }
    } else {
        $json = @()
        Get-ChildItem -Path "$title_json*" -Include "*.json" | ForEach-Object {
            try {
                Write-Host "Converting $($_.FullName) to JSON Object"
                $json += ConvertFrom-Json $(Get-Content -Raw $_.FullName)
            }
            catch {
                Write-Error "Syntax error in file"; break
            }
        }
    }
    $json = $($json | Select-Object file,title,subtitle_file,chapter_file,crop_ffmpeg -Unique)

    $files = Get-ChildItem $in | Where-Object { $_.Extension -eq ".$extension" }
    $err_count=0
    ForEach($file in $files) {
        Write-Verbose "Checking record in JSON for file $($file.name)"
        $index = [Array]::IndexOf($json.file, $file.name)
        if ($index -ge 0) {
            if ($json[$index].subtitle_file) {
                Write-Verbose "Subtitles for $($file.name) will be used from $($json[$index].subtitle_file)"
                if (Test-Path -LiteralPath $(Join-Path -Path $file.DirectoryName -ChildPath $json[$index].subtitle_file)) {
                    $subtitle_file = Get-Item -LiteralPath $(Join-Path -Path $file.DirectoryName -ChildPath $json[$index].subtitle_file)
                    if ($subtitle_file.IsReadOnly) {
                        $subtitle_file.Set_IsReadOnly($False)
                        Write-Warning "Removing ReadOnly Attribute from $($subtitle_file.Name)"
                    }
                } else {
                    Write-Error "$($json[$index].subtitle_file) not found in $($file.DirectoryName)"
                    $err_count++
                }               
            }
            if ($json[$index].chapter_file) {
                Write-Verbose "Subtitles for $($file.name) will be used from $($json[$index].chapter_file)"
                if (Test-Path -LiteralPath $(Join-Path -Path $file.DirectoryName -ChildPath $json[$index].chapter_file)) {
                    $chapter_file = Get-Item -LiteralPath $(Join-Path -Path $file.DirectoryName -ChildPath $json[$index].chapter_file)
                    if ($chapter_file.IsReadOnly) {
                        $chapter_file.Set_IsReadOnly($False)
                        Write-Warning "Removing ReadOnly Attribute from $($chapter_file.Name)"
                    }
                } else {
                    Write-Error "$($json[$index].chapter_file) not found in $($file.DirectoryName)"
                    $err_count++
                }               
            }
        } else {
            Write-Error "$($file.name) not found in $json_file"
            $err_count++
        }
    }
    if ($err_count -gt 0) { Write-Error "$title_json has $err_count errors"; break }
    Write-Host "JSON File uploaded successfuly" -ForegroundColor Green
}

# Include
####################################################################################
###################################### Classes #####################################
####################################################################################
foreach ($lib in $libs) {
    $lib_path = $(Join-Path $libs_path "$lib.ps1")
    if (-not $(Test-Path -LiteralPath $lib_path)) { Write-Error "$lib not found"; break }
    Write-Verbose "Loading $lib.ps1"
    Invoke-Expression $(Get-Content -Raw $lib_path)
}

####################################################################################
################################### Main Program ###################################
####################################################################################
# Clean Temp
Remove-Item $enctemp\* -Force

$files = Get-ChildItem $in | Where-Object { $_.Extension -eq ".$extension" }
Write-Host "Files will be converted:" -ForegroundColor Green
if ($null -eq $files) { Write-Host "No files to convert" } else { $files | ForEach-Object { Write-Host $_.BaseName } }
$files | ForEach-Object {
  if ($_.IsReadOnly) {
    $_.Set_IsReadOnly($False)
    Write-Warning "Removing ReadOnly Attribute from $($_.Name)"
  }
}
$totalErrorsCount = 0
$FilesWithErrors = @()
$counter = 0
:Main Foreach ($file in $files) {
    $counter++
    $errorcount = 0
    if ($use_json) {
      $index = [Array]::IndexOf($json.file, $file.name)
      Write-Verbose "JSON Configuration: $($json[$index])"
    }
    if (-not $(Test-Path -LiteralPath $file.FullName)) { continue Main }
    # Process Commands
    if ($(Test-Path -LiteralPath $(Join-Path $in "terminate"))) {
        Remove-Item $(Join-Path $in "terminate")
        Write-Host "Terminate File Found, Exiting" -ForegroundColor Green
        break
    }

    if ($(Get-ChildItem $enctemp).Count -gt 0) { Write-Verbose "Cleaning $enctemp"; Remove-Item $enctemp\* }

#    Write-Progress -Id 0 -Activity "Encoding File $counter/$($files.count-1)" -Status "$($file.Name)"
    Write-Host "Encoding File $counter/$($files.count)" -ForegroundColor Green
    Write-Host "Use Title form JSON: $use_json" -ForegroundColor Green
    Write-Host "$($file.Name)" -ForegroundColor Cyan
    Write-Host "Step 1-1: Copying file $($file.Name)" -ForegroundColor Green
#    Write-Progress -Id 1 -ParentId 0 "Step 1: Copying file $($file.Name)"
    Write-Verbose "File Source: $($file.fullname)"
    Write-Verbose "File Destination: $enctemp\temp$extension.$extension"
    $file | Copy-Item -destination "$enctemp\temp$extension.$extension"
    if ($(Test-Path -LiteralPath "$enctemp\temp$extension.$extension")) { Write-Host "File copied succesfully" } else { Write-Error "File copy failed"; $errorcount++ }

# Crop
    if ($use_json) { $cropf = $json[$index].crop_ffmpeg }

# Subtitle
    if ($use_json) {
        $subtitle_file = $json[$index].subtitle_file
        if ($($index -ge 0) -and $subtitle_file) {
            Write-Host "Step 1-2: Copying Subtitle file $($json[$index].subtitle_file)" -ForegroundColor Green
            $subtitle_file_src = Get-Item -LiteralPath $(Join-Path -Path $file.DirectoryName -ChildPath $json[$index].subtitle_file)
            $subtitle_file = "$([guid]::NewGuid().guid)$($subtitle_file_src.Extension)"
            Write-Verbose "File Source: $($subtitle_file_src.fullname)"
            Write-Verbose "File Destination: $(Join-Path -Path $enctemp -ChildPath $subtitle_file)"
            $subtitle_file_src | Copy-Item -Destination "$enctemp\$subtitle_file"
            if ($(Test-Path -LiteralPath $(Join-Path -Path $enctemp -ChildPath $subtitle_file))) { Write-Host "Subtitle file copied succesfully" } else { Write-Error "Subtitle file copy failed"; $errorcount++ }
        }
    }

# Chapters
    if ($use_json) {
        $chapter_file = $json[$index].chapter_file
        if ($($index -ge 0) -and $chapter_file) {
            Write-Host "Step 1-3: Copying Chapter file $($json[$index].chapter_file)" -ForegroundColor Green
            $chapter_file_src = Get-Item -LiteralPath $(Join-Path -Path $file.DirectoryName -ChildPath $json[$index].chapter_file)
            $chapter_file = "$([guid]::NewGuid().guid)$($chapter_file_src.Extension)"
            Write-Verbose "File Source: $($chapter_file_src.fullname)"
            Write-Verbose "File Destination: $(Join-Path -Path $enctemp -ChildPath $chapter_file)"
            $chapter_file_src | Copy-Item -Destination "$enctemp\$chapter_file"
            if ($(Test-Path -LiteralPath $(Join-Path -Path $enctemp -ChildPath $chapter_file))) { Write-Host "Chapter file copied succesfully" } else { Write-Error "Chapter file copy failed"; $errorcount++ }
        }
    }

    # Load Media Info
    $medinfo = [MediaInfo]::new($MediaInfoWrapper_path)
    $medinfo.open("$enctemp\temp$extension.$extension")
    Write-Verbose "MediaInfo: $(ConvertTo-Json $medinfo -Depth 100)"

# Extracting
    #  Extracting Video
    if (($DecompressSource -eq "FFVideoSource") -or ($DecompressSource -eq "DirectShowSource")) {
        Write-Host "Step 2-1: Extracting Videotrack... Skipped, Decompress method $DecompressSource is Used" -ForegroundColor Green
    } else {
        $counterInternal = 0
        Foreach ($videotrack in $medinfo.Videotracks) {
            $counterInternal++
#            Write-Progress -Id 1 -ParentId 0 "Step 2-1: Extracting Videotrack... $counterInternal/$($medinfo.Videotracks.Count)"
            Write-Host "Step 2-1: Extracting Videotrack... $counterInternal/$($medinfo.Videotracks.Count)" -ForegroundColor Green
#            Write-Verbose "mkvextract Command Line: $mkvmerge_path -o ""$enctemp\$($videotrack.GUID).$($videotrack.Format)"" --video-tracks $($videotrack.ID-1) --no-audio --no-global-tags --no-subtitles --no-track-tags --no-chapters --no-cues ""$enctemp\temp$extension.$extension"""
#            Start-Process -Wait -NoNewWindow -FilePath $mkvmerge_path -ArgumentList "-o ""$enctemp\$($videotrack.GUID).$($videotrack.Format).src"" --video-tracks $($videotrack.ID-1) --no-audio --no-global-tags --no-subtitles --no-track-tags --no-chapters --no-cues ""$enctemp\temp$extension.$extension"""
            Write-Verbose "mkvextract Command Line: $mkvmerge_path -o ""$enctemp\$($videotrack.GUID).$($videotrack.Format)"" --video-tracks $($videotrack.StreamOrder) --no-audio --no-global-tags --no-subtitles --no-track-tags --no-chapters --no-cues ""$enctemp\temp$extension.$extension"""
            Start-Process -Wait -NoNewWindow -FilePath $mkvmerge_path -ArgumentList "-o ""$enctemp\$($videotrack.GUID).$($videotrack.Format).src"" --video-tracks $($videotrack.StreamOrder) --no-audio --no-global-tags --no-subtitles --no-track-tags --no-chapters --no-cues ""$enctemp\temp$extension.$extension"""
            if (-not $(Test-Path -LiteralPath "$enctemp\$($videotrack.GUID).$($videotrack.Format).src")) { Write-Error "Step 2-1: Extracting Videotrack file $($videotrack.GUID).$($videotrack.Format).src failed"; $errorcount++ }
        }
    }

    #  Extracting Audio
    if ($RecompressMethod -eq "AviSynth") {
        Write-Host "Step 2-2: Extracting Audiotrack... Skipped, Recompress method AviSynth is Used" -ForegroundColor Green
    } else {
        $counterInternal = 0
        Foreach ($audiotrack in $medinfo.Audiotracks) {
            $counterInternal++
#            Write-Progress -Id 1 -ParentId 0 "Step 2-2: Extracting Audiotrack... $counterInternal/$($medinfo.Audiotracks.Count)"
            Write-Host "Step 2-2: Extracting Audiotrack... $counterInternal/$($medinfo.Audiotracks.Count)" -ForegroundColor Green
#            Write-Verbose "mkvextract Command Line: $mkvextract_path tracks ""$enctemp\temp$extension.$extension"" $($audiotrack.ID-1):""$enctemp\$($audiotrack.GUID).$($audiotrack.Format)"""
#            Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "tracks ""$enctemp\temp$extension.$extension"" $($audiotrack.ID-1):""$enctemp\$($audiotrack.GUID).$($audiotrack.Format)"""
            Write-Verbose "mkvextract Command Line: $mkvextract_path tracks ""$enctemp\temp$extension.$extension"" $($audiotrack.StreamOrder):""$enctemp\$($audiotrack.GUID).$($audiotrack.Format)"""
            Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "tracks ""$enctemp\temp$extension.$extension"" $($audiotrack.StreamOrder):""$enctemp\$($audiotrack.GUID).$($audiotrack.Format)"""
            if (-not $(Test-Path -LiteralPath "$enctemp\$($audiotrack.GUID).$($audiotrack.Format)")) { Write-Error "Step 2-2: Extracting Audiotrack file $($audiotrack.GUID).$($audiotrack.Format) failed"; $errorcount++ }
        }
    }

    #  Extracting Timecode
    $counterInternal = 0
    Foreach ($videotrack in $medinfo.Videotracks) {
        $counterInternal++
#        Write-Progress -Id 1 -ParentId 0 "Step 2-3: Extracting timecodes... $counterInternal/$($medinfo.Videotracks.Count)"
        Write-Host "Step 2-3: Extracting timecodes... $counterInternal/$($medinfo.Videotracks.Count)" -ForegroundColor Green
#        Write-Verbose "mkvextract Command Line: $mkvextract_path timecodes_v2 ""$enctemp\temp$extension.$extension"" $($videotrack.ID-1):""$enctemp\$($videotrack.GUID).timecode"""
#        Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "timecodes_v2 ""$enctemp\temp$extension.$extension"" $($videotrack.ID-1):""$enctemp\$($videotrack.GUID).timecode"""
        Write-Verbose "mkvextract Command Line: $mkvextract_path timecodes_v2 ""$enctemp\temp$extension.$extension"" $($videotrack.StreamOrder):""$enctemp\$($videotrack.GUID).timecode"""
        Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "timecodes_v2 ""$enctemp\temp$extension.$extension"" $($videotrack.StreamOrder):""$enctemp\$($videotrack.GUID).timecode"""
        if (-not $(Test-Path -LiteralPath "$enctemp\$($videotrack.GUID).timecode")) { Write-Error "Step 2-3: Extracting timecode file $($videotrack.GUID).timecode failed"; $errorcount++ }
    # Replace Title
        if ($use_json) {
            Write-Verbose "Title looking for in JSON: $($file.Name)"
            Write-Host "Step 2-3: Replace title from JSON for $($file.Name): $($($json | Where-Object {$_.file -eq $($file.Name)}).title)"
            $videotrack.Title = $($json | Where-Object {$_.file -eq $($file.Name)}).title
            $medinfo.Title = $($json | Where-Object {$_.file -eq $($file.Name)}).title
        } else {
            $videotrack.Title = $medinfo.Title
        }
    }

    #  Extracting Chapters
#    if ($Copy_Chapters -and $medinfo.Chapters) {
    if ($medinfo.Chapters) {
#        Write-Progress -Id 1 -ParentId 0 "Step 2-4: Extracting chapters..."
        Write-Host "Step 2-4: Extracting chapters..." -ForegroundColor Green
        Write-Verbose "mkvextract Command Line: $mkvextract_path chapters ""$enctemp\temp$extension.$extension"" -r ""$enctemp\chapters.xml"""
        Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "chapters ""$enctemp\temp$extension.$extension"" -r ""$enctemp\chapters.xml"""
        if (-not $(Test-Path -LiteralPath "$enctemp\chapters.xml")) { Write-Error "Step 2-4: Extracting chapter file chapters.xml failed"; $errorcount++ }
    } else {
#        Write-Progress -Id 1 -ParentId 0 "Step 2-4: Extracting chapters..."
        Write-Host "Step 2-4: Extracting chapters... Skipped, No Chapters found" -ForegroundColor Green
    }

    #  Extract Subtitles
#    if ($Copy_Subtitles -and $medinfo.Texttracks) {
    if ($medinfo.Texttracks -and $Copy_Subtitles) {
        $counterInternal = 0
        Foreach ($texttrack in $medinfo.Texttracks) {
            $counterInternal++
            Write-Host "Step 2-5: Extracting Subtitles... $counterInternal/$($medinfo.Texttracks.Count)" -ForegroundColor Green
#            Write-Verbose "mkvextract Command Line: $mkvextract_path tracks ""$enctemp\temp$extension.$extension"" $($texttrack.ID-1):""$enctemp\$($texttrack.GUID).$($texttrack.Format)"""
#            Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "tracks ""$enctemp\temp$extension.$extension"" $($texttrack.ID-1):""$enctemp\$($texttrack.GUID).$($texttrack.Format)"""
            Write-Verbose "mkvextract Command Line: $mkvextract_path tracks ""$enctemp\temp$extension.$extension"" $($texttrack.StreamOrder):""$enctemp\$($texttrack.GUID).$($texttrack.Format)"""
            Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "tracks ""$enctemp\temp$extension.$extension"" $($texttrack.StreamOrder):""$enctemp\$($texttrack.GUID).$($texttrack.Format)"""
            switch ($texttrack.Format) {
              "VobSub" {
                         if (-not $($(Test-Path -LiteralPath "$enctemp\$($texttrack.GUID).sub") -and $(Test-Path -LiteralPath "$enctemp\$($texttrack.GUID).idx"))) { Write-Error "Step 2-5: Extracting subtitle file $($texttrack.GUID).$($texttrack.Format) failed"; $errorcount++ } 
                         $texttrack.Custom01 = "$($texttrack.GUID).idx"
                       }
               default { 
                         if (-not $(Test-Path -LiteralPath "$enctemp\$($texttrack.GUID).$($texttrack.Format)")) { Write-Error "Step 2-5: Extracting subtitle file $($texttrack.GUID).$($texttrack.Format) failed"; $errorcount++ }
                         $texttrack.Custom01 = "$($texttrack.GUID).$($texttrack.Format)"
                       }
            }
#            Write-Progress -Id 1 -ParentId 0 "Step 2-5: Extracting Subtitles... $counterInternal/$($medinfo.Texttracks.Count)"
#            if ($([string]::IsNullOrEmpty($Sub_languages)) -or $($texttrack.Language -in $Sub_languages)) {
#            }
        }
    } else {
      Write-Host "Step 2-5: Extracting Subtitles... Skipped, No Subtitles found" -ForegroundColor Green
#     Write-Progress -Id 1 -ParentId 0 "Step 5: Extracting Subtitles... $counterInternal/$($medinfo.Texttracks.Count)"
    }

# Encoding
    # Audio Encoding
    Switch ($RecompressMethod) {
        "AviSynth" {
            Copy-Item $(Join-Path $root_path "AviSynthtemplate.avs") "$enctemp\videofile.avs"
            "DirectShowSource(""$($file.FullName)"")" | Out-File "$enctemp\videofile.avs" -Append -Encoding Ascii
            Write-Verbose "AviSynth Command Line: $wavi ""$enctemp\videofile.avs"" ""$enctemp\$($medinfo.Audiotracks[0].GUID).pcm"""
            Start-Process -Wait -NoNewWindow -FilePath $wavi -ArgumentList """$enctemp\videofile.avs"" ""$enctemp\$($medinfo.Audiotracks[0].GUID).pcm"""
            $eac3 = [EAC3]::new($eac3to, $ffmpeg_path)
            $eac3.SourceFileName = "$enctemp\$($medinfo.Audiotracks[0].GUID).pcm"
            $eac3.DestinationFileName = "$enctemp\$($audiotrack.GUID).m4a"
            $eac3.Compress()
            if (($eac3.EncProcess.ExitCode -gt 0) -or $(-not $(Test-Path -LiteralPath "$enctemp\$($audiotrack.GUID).m4a"))) { Write-Error "Step 3-1: Audio Encoding File $($audiotrack.GUID).m4a failed"; $errorcount++ }
            $medinfo.Audiotracks[0].Custom01 = "$($medinfo.Audiotracks[0].GUID).m4a"
            $medinfoAud = [MediaInfo]::new($MediaInfoWrapper_path)
            $medinfoAud.open("$enctemp\$($audiotrack.GUID).m4a")
            $audiotrack.Format = $medinfoAud.Audiotracks[0].Format
            $medinfoAud.Close()
            $eac3 = $null
        }
        "Decoder" {
            $counterInternal = 0
            $audio_enc_processes = @()
            Write-Verbose "Audiotracks Count: $($medinfo.Audiotracks.Count)"
            Write-Verbose "Async Mode Set to: $($AsyncEncoding -and ($medinfo.Audiotracks.Count -gt 1))"
            Foreach ($audiotrack in $medinfo.Audiotracks) {
                $counterInternal++
#                Write-Progress -Id 1 -ParentId 0 "Step 3-1: Audio Encoding File $counterInternal/$($medinfo.Audiotracks.Count)"
                Write-Host "Step 3-1: Audio Encoding File $counterInternal/$($medinfo.Audiotracks.Count): $($audiotrack.GUID).$($audiotrack.Format)" -ForegroundColor Green
                $audiotrack.Custom01 = "$($audiotrack.GUID).$($audiotrack.Format)"
                if (-not $take_audio_from_source) {
                    $eac3 = [EAC3]::new($eac3to, $ffmpeg_path)
                    $eac3.DecodeAutoMode = $DecodeAutoMode
                    $eac3.SourceFileName = "$enctemp\$($audiotrack.GUID).$($audiotrack.Format)"
                    $eac3.DestinationFileName = "$enctemp\$($audiotrack.GUID).m4a"
                    $eac3.Async = $AsyncEncoding -and ($medinfo.Audiotracks.Count -gt 1)
                    $eac3.Compress()
                    $audio_enc_processes += $eac3
                    $eac3 = $null
                } else {Write-Host "Selected Take Audio From Source - Skipped" -ForegroundColor Green}
            }
            if (-not $take_audio_from_source) {
                Write-Verbose "Process List:"
                $audio_enc_processes | ForEach-Object {
                    Write-Verbose "Process Id: $($_.EncProcess.id) for encoding file $($_.SourceFileName.Name)"
                }
                Try {
                    Wait-Process -InputObject $audio_enc_processes.EncProcess
                }
                Finally {
                    Get-Process -InputObject  $audio_enc_processes.EncProcess | Stop-Process
                }
                $audio_enc_processes | ForEach-Object {
                    Write-Verbose "Process Id: $($_.EncProcess.id) exit code $($_.EncProcess.ExitCode)"
                    if ($_.EncProcess.ExitCode -gt 0) { Write-Error "Step 3-1: Audio Encoding File $($_.SourceFileName.Name) failed"; $errorcount++ }
                }
                if ($errorcount -gt 0) { $totalErrorsCount = $totalErrorsCount + $errorcount; $FilesWithErrors += $file.name; continue Main }
                Foreach ($audiotrack in $medinfo.Audiotracks) {
                    if (-not $(Test-Path -LiteralPath "$enctemp\$($audiotrack.GUID).m4a")) { Write-Error "Step 3-1: Audio Encoding File $($audiotrack.GUID).m4a failed"; $errorcount++ } else {
                        $audiotrack.Custom01 = "$($audiotrack.GUID).m4a"
                        $medinfoAud = [MediaInfo]::new($MediaInfoWrapper_path)
                        $medinfoAud.open("$enctemp\$($audiotrack.GUID).m4a")
                        $audiotrack.Format = $medinfoAud.Audiotracks[0].Format
                        $medinfoAud.Close()
                    }
                }
                Write-Host "Encoding finished succesfuly"
            } else {Write-Host "Selected Take Audio From Source - Skipped" -ForegroundColor Green}
        }
        default	{ throw "Unknown Recompress Method." }
    }

    if ($errorcount -gt 0) { $totalErrorsCount = $totalErrorsCount + $errorcount; $FilesWithErrors += $file.name; continue Main }

    #  Video Encoding
    $counterInternal = 0
    Foreach ($videotrack in $medinfo.Videotracks) {
        $counterInternal++
        Write-Host "Step 3-2: Video Encoding... $counterInternal/$($medinfo.Videotracks.Count)" -ForegroundColor Green
#        Write-Progress -Id 1 -ParentId 0 "Step 3-2: Video Encoding... $counterInternal/$($medinfo.Videotracks.Count)"
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
                if ($cropf) {
                  $Encode.Crop.Enabled = $true;
                  $Encode.Crop.Mode = "ffmpeg";
                  $Encode.Crop.FFMPEG = $cropf;
                } else {
                  $Encode.Crop.Enabled = $crop[0];
                  $Encode.Crop.Mode = $crop[1];
                  $Encode.Crop.FFMPEG = $crop[2];
                  $Encode.Crop.Left = $crop[3];
                  $Encode.Crop.Top = $crop[4];
                  $Encode.Crop.Right = $crop[5];
                  $Encode.Crop.Bottom = $crop[6];
                }
                $Encode.Deinterlace.Enabled = $deinterlace[0];
                $Encode.Deinterlace.Mode = $deinterlace[1];
                $Encode.Deinterlace.Parity = $deinterlace[2];
                $Encode.Deinterlace.Deint = $deinterlace[3];
                $Encode.VSync = $vsync;
                $Encode.Pulldown = $pulldown; 
                $Encode.CustomFilter = $CustomFilter;
                $Encode.CustomModifier = $CustomModifier;
                $videotrack.Custom01 = "$($videotrack.GUID).hevc"
                Write-Verbose "Encode config: $(ConvertTo-Json $Encode -Depth 100)"
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
                if ($cropf) {
                  $Encode.Crop.Enabled = $true;
                  $Encode.Crop.Mode = "ffmpeg";
                  $Encode.Crop.FFMPEG = $cropf;
                } else {
                  $Encode.Crop.Enabled = $crop[0];
                  $Encode.Crop.Mode = $crop[1];
                  $Encode.Crop.FFMPEG = $crop[2];
                  $Encode.Crop.Left = $crop[3];
                  $Encode.Crop.Top = $crop[4];
                  $Encode.Crop.Right = $crop[5];
                  $Encode.Crop.Bottom = $crop[6];
                }
                $Encode.Deinterlace.Enabled = $deinterlace[0];
                $Encode.Deinterlace.Mode = $deinterlace[1];
                $Encode.Deinterlace.Parity = $deinterlace[2];
                $Encode.Deinterlace.Deint = $deinterlace[3];
                $Encode.VSync = $vsync;
                $Encode.Pulldown = $pulldown; 
                $Encode.CustomFilter = $CustomFilter;
                $Encode.CustomModifier = $CustomModifier;
                $videotrack.Custom01 = "$($videotrack.GUID).hevc"
                Write-Verbose "Encode config: $(ConvertTo-Json $Encode -Depth 100)"
                $Encode.Compress();
                $Encode = $null;
            }
            "Direct" {
                Write-Verbose "Direct Selected"
                $videotrack.Custom01 = "$($videotrack.GUID).$($videotrack.Format).src"
                if (-not $take_video_from_source) {
                    Write-Host "Source File: $($videotrack.Custom01)" -ForegroundColor Green
                    $videotrack.Custom01 = "$($videotrack.GUID).hevc"
                    Write-Host "Destination File: $($videotrack.Custom01)" -ForegroundColor Green
                    $Encode = [ffmpeg]::new($ffmpeg_path);
                    $Encode.SourceFileAVS = "$enctemp\$($videotrack.GUID).$($videotrack.Format).src";
                    $Encode.DestinationFileName = "$enctemp\$($videotrack.GUID).hevc";
                    $Encode.Quantanizer = $quantanizer;
                    $Encode.Preset = $preset;
                    $Encode.Tune = $tune;
                    $Encode.Codec = $codec;
                    $Encode.Resize.Enabled = $resize[0];
                    $Encode.Resize.Width = $resize[1];
                    $Encode.Resize.Height = $resize[2];
                    $Encode.Resize.Method = $resize[3];
                    if ($cropf) {
                      $Encode.Crop.Enabled = $true;
                      $Encode.Crop.Mode = "ffmpeg";
                      $Encode.Crop.FFMPEG = $cropf;
                    } else {
                      $Encode.Crop.Enabled = $crop[0];
                      $Encode.Crop.Mode = $crop[1];
                      $Encode.Crop.FFMPEG = $crop[2];
                      $Encode.Crop.Left = $crop[3];
                      $Encode.Crop.Top = $crop[4];
                      $Encode.Crop.Right = $crop[5];
                      $Encode.Crop.Bottom = $crop[6];
                    }
                    $Encode.Deinterlace.Enabled = $deinterlace[0];
                    $Encode.Deinterlace.Mode = $deinterlace[1];
                    $Encode.Deinterlace.Parity = $deinterlace[2];
                    $Encode.Deinterlace.Deint = $deinterlace[3];
                    $Encode.VSync = $vsync;
                    $Encode.Pulldown = $pulldown; 
                    $Encode.CustomFilter = $CustomFilter;
                    $Encode.CustomModifier = $CustomModifier;
                    Write-Verbose "Encode config: $(ConvertTo-Json $Encode -Depth 100)"
                    $Encode.Compress();
                    if ($Encode.EncProcess.ExitCode -gt 0) { Write-Error "Step 3-2: Video Encoding $($videotrack.GUID).hevc failed"; $errorcount++ }
                    $Encode = $null;
                } else {
                    Write-Host "Selected Take Video From Source. Encoding - Skipped" -ForegroundColor Green
                    Write-Host "Video File: $($videotrack.Custom01)" -ForegroundColor Green
                }
            }
            default { throw "Unknown Recompress Method." }
        }
        if (-not $(Test-Path -LiteralPath "$enctemp\$($videotrack.Custom01)")) { Write-Error "Step 3-2: Video Encoding $($videotrack.Custom01) failed"; $errorcount++ }
    }

    #  Check for Errors
    if ($errorscount -gt 0) { $totalErrorsCount = $totalErrorsCount + $errorcount; $FilesWithErrors += $file.name; continue Main }

# Combine MKV
    Write-Host "Step 4: Merge Files" -ForegroundColor Green
#    Write-Progress -Id 1 -ParentId 0 "Step 7: Merge Files"
    Write-Verbose "Merging result to $out\$($file.basename).mkv"
    $mkvmerge = [MKVMerge]::new($mkvmerge_path);
    $mkvmerge.DestinationFile = "$out\$($file.basename).mkv";
    $mkvmerge.Title = $medinfo.Title.Replace('"','\"');

    Foreach ($videotrack in $medinfo.Videotracks) {
        $videotrk = [TVideoTrack]::new()
        $videotrk.FileName = "$enctemp\$($videotrack.Custom01)";
        if ($video_languages[0] -or (-not $videotrack.Language)) { $videotrk.Language = $video_languages[[int]$videotrack.StreamKindID + 1] } else { $videotrk.Language = $($videotrack.Language) }
        $videotrk.Title = $videotrack.Title.Replace('"','\"');
        $videotrk.TimeCodeFile = "$enctemp\$($videotrack.GUID).timecode";
        $videotrk.UseTimeCodeFile = $use_timecode_file -and -not $pulldown;
        $mkvmerge.VideoTracks += $videotrk;
    }

    Foreach ($audiotrack in $medinfo.Audiotracks) {
        $audiotrk = [TAudioTrack]::new()
        $audiotrk.FileName = "$enctemp\$($audiotrack.Custom01)";
        if ($set_audio_languages[0] -or (-not $audiotrack.Language)) { $audiotrk.Language = $set_audio_languages[[int]$audiotrack.StreamKindID + 1] } else { $audiotrk.Language = $($audiotrack.Language) }
        if (-not $take_audio_track_name_from_source) { $audiotrk.Title = "$($audiotrack.Format) $($audiotrack.Channels)" } else { $audiotrk.Title = $audiotrack.Title }
	Switch ($select_audio_by[0])
	{
		"language" 	{if ($audiotrk.Language -in $select_audio_by[1]){$mkvmerge.AudioTracks += $audiotrk} else {$audiotrk = $null}}
		"trackid" 	{if ($audiotrk.StreamKindID -in $select_audio_by[1]){$mkvmerge.AudioTracks += $audiotrk} else {$audiotrk = $null}}
		default	{$mkvmerge.AudioTracks += $audiotrk}
	}
    }

    if ($($index -ge 0) -and $chapter_file) {
        $mkvmerge.ChaptersFile = "$enctemp\$chapter_file"
    } else {
        if ($Copy_Chapters -and $(Test-Path -LiteralPath "$enctemp\chapters.xml") -and $($((Get-Item "$enctemp\chapters.xml").Length) -gt 0)) {
            $mkvmerge.ChaptersFile = "$enctemp\chapters.xml"
        }
    }

    if ($($index -ge 0) -and $subtitle_file) {
        $texttrk = [TSubtitleTrack]::new()
        $texttrk.FileName = "$enctemp\$subtitle_file"
        $texttrk.Language = $Sub_languages[0]
        $texttrk.Title = ""
        $mkvmerge.SubtitleTracks = $texttrk;
    } else {
        if ($Copy_Subtitles -and $medinfo.Texttracks) {
            Foreach ($texttrack in $medinfo.Texttracks) {
                if ($([string]::IsNullOrEmpty($Sub_languages)) -or $($texttrack.Language -in $Sub_languages)) {
                    $texttrk = [TSubtitleTrack]::new()
                    $texttrk.FileName = "$enctemp\$($texttrack.Custom01)"
                    $texttrk.Language = "$($texttrack.Language)"
                    $texttrk.Title = "$($texttrack.Title)"
                    $mkvmerge.SubtitleTracks += $texttrk;
                }
            }
        }
    }
    Write-Verbose "Merge config: $(ConvertTo-Json $mkvmerge)"

    $mkvmerge.MakeFile();
    Write-Verbose "Merge Exit Code: $($mkvmerge.EncProcess.ExitCode)"
    if (-not $(Test-Path -LiteralPath "$out\$($file.basename).mkv")) { Write-Error "Merge video file $($file.basename).mkv failed"; $errorcount++ }

    # Removing Temp Files
    Write-Verbose "Cleaning $enctemp"
    if ($($errorcount -eq 0) -and $(-not $Debug)) { Remove-Item $enctemp\* } else { Write-Verbose "Cleaning Skipped because of $errorcount error(s)" }
    
    if ($del_original -and $($errorcount -eq 0) -and $(-not $Debug)) { 
        Write-Verbose "Removing files from source"
        if (Test-Path -LiteralPath $file.fullname) {
            Write-Verbose "Remove $($file.fullname)"
            Remove-Item -LiteralPath $file.fullname
        }
        if ($use_json -and ($index -ge 0)) {
            if ($json[$index].subtitle_file -and $(Test-Path -LiteralPath $(Join-Path -Path $file.DirectoryName -ChildPath $json[$index].subtitle_file))) {
                Write-Verbose "Remove subtitle file $($json[$index].subtitle_file)"
                Remove-Item -LiteralPath $(Join-Path -Path $file.DirectoryName -ChildPath $json[$index].subtitle_file)
            }
            if ($json[$index].chapter_file -and $(Test-Path -LiteralPath $(Join-Path -Path $file.DirectoryName -ChildPath $json[$index].chapter_file))) {
                Write-Verbose "Remove subtitle file $($json[$index].chapter_file)"
                Remove-Item -LiteralPath $(Join-Path -Path $file.DirectoryName -ChildPath $json[$index].chapter_file)
            }
        }
    }
    $totalErrorsCount += $errorcount
    if ($errorcount) { $FilesWithErrors += $file.name }
    if ($Debug) { break }
}

# Last Task
if ($(Test-Path -LiteralPath $(Join-Path $in "shutdown"))) { Remove-Item $(Join-Path $in "shutdown"); $shutdown = $true }
Write-Verbose "============================================"
Write-Verbose "Delete Original: $del_original"
Write-Verbose "Result File: $out\$($file.basename).mkv"
Write-Verbose "Result File Found: $(Test-Path -LiteralPath $out\$($file.basename).mkv)"
Write-Verbose "Shutdown mode enabled: $shutdown"
Write-Verbose "============================================"
if ($totalErrorsCount) {
  Write-Host "Errors Count: $totalErrorsCount" -ForegroundColor Red
  Write-Host "Errors in Files:" -ForegroundColor Red
  $FilesWithErrors
} else {
  Write-Host "Errors Count: $totalErrorsCount" -ForegroundColor Green
}
Write-Host "Process completed" -ForegroundColor Green
if ($shutdown) { shutdown -t 60 -f -s }
