#Requires -Version 5

enum DecodeMode {
    Auto
    Pattern
    FFMpeg
    Eac3to
}

# resample audio to "44100", "48000" or "96000" Hz
enum Resample {
    none
    to44100Hz
    to48000Hz
    to96000Hz
}

# downmix to 6 channels, Dolby Pro Logic II, Stereo
enum Downmix {
    none
    to6
    toDpl
    toStereo
}

enum Format {
    raw
    wav
    ac3
    dts
    aac
    flac
}

class EAC3 {
    [bool]$Verbose = $false
    [bool]$DryMode = $false
    [bool]$Async = $false
    $EncProcess = $null
    [System.Diagnostics.ProcessPriorityClass]$ProcessPriority = [System.Diagnostics.ProcessPriorityClass]::Idle;

# Formats that EAC3 can accept directly
    hidden $inFormats = @(".AAC",".PCM",".FLAC",".AC-3",".E-AC-3",".MLP FBA",".DTS",".MPEG Audio",".TrueHD");
# Formats that EAC3 can accept trough flac
    hidden $inFormatsPattern = @(".OPUS",".WavPack");

    hidden [string]$eac3to_path;
    hidden [String]$ffmpeg_path;

    [DecodeMode]$DecodeAutoMode = [DecodeMode]::Pattern;

    [Resample]$Resample = [Resample]::none;
    [Downmix]$Downmix = [Downmix]::none;
    [int16]$Delay = 0;  # +/-100 in ms
    [int16]$Gain = 0; # +/-3 in dB
    [string]$Remap; # "0,1,2,3,4,5" remap the channels

    [Format]$Format = [Format]::aac;

    [ValidateRange(0,1)]
    [Double]$Quality = 0.5; # Nero AAC encoding quality (0.00 = lowest; 1.00 = highest)

    [io.fileinfo]$SourceFileName;

    [ValidateSet('.wav', '.ac3', '.dts', '.m4a', '.flac')]
    hidden [String]$DestinationFileExtension = ".m4a";
    [io.fileinfo]$DestinationFileName;

    # Constructor
    EAC3 ([String]$eac3to_path) {
        if ($this.Verbose) { $VerbosePreference = "continue" }
        Write-Verbose "Check path of eac3to.exe"
        if (Test-Path $eac3to_path -PathType Leaf) { $this.eac3to_path = $eac3to_path } else { throw "ERROR: eac3to.exe not found." }
        Write-Verbose "eac3to used from: $($this.eac3to_path)"
    }

    EAC3 ([String]$eac3to_path, $ffmpeg_path) {
        if ($this.Verbose) { $VerbosePreference = "continue" }
        Write-Verbose "Check path of eac3to.exe"
        if (Test-Path $eac3to_path -PathType Leaf) { $this.eac3to_path = $eac3to_path } else { throw "ERROR: eac3to.exe not found." }
        Write-Verbose "eac3to used from: $($this.eac3to_path)"
        Write-Verbose "Check path of ffmpeg.exe"
        if (Test-Path $ffmpeg_path -PathType Leaf) { $this.ffmpeg_path = $ffmpeg_path } else { throw "ERROR: ffmpeg.exe not found." }
        Write-Verbose "ffmpeg used from: $($this.ffmpeg_path)"
    }

    [void]Compress() {
        if ($this.Verbose) { $VerbosePreference = "continue" }
        Write-Verbose "Dry Mode Enabled: $($this.DryMode)"
        Write-Verbose "Format: $($this.Format)"
        if (-not $(Test-Path $this.SourceFileName -PathType Leaf)) { throw "ERROR: $($this.SourceFileName.FullName) not found." }
        if (-not $(Resolve-Path ([io.fileinfo]$this.DestinationFileName).DirectoryName | Test-Path)) { throw "ERROR: Destination path is incorrect."; return }
        switch ($this.Format) {
            raw { $this.DestinationFileExtension = '.raw'; }
            wav { $this.DestinationFileExtension = '.wav'; }
            ac3 { $this.DestinationFileExtension = '.ac3'; }
            dts { $this.DestinationFileExtension = '.dts'; }
            aac { $this.DestinationFileExtension = '.m4a'; }
            flac { $this.DestinationFileExtension = '.flac'; }
        }
        Write-Verbose "File extension: $($this.DestinationFileExtension)"
        $DestinationFile = "$(Join-Path ([io.fileinfo]$this.DestinationFileName).DirectoryName ([io.fileinfo]$this.DestinationFileName).BaseName)$($this.DestinationFileExtension)"
        Write-Verbose "Destination File: $($DestinationFile)"
		
        # Creating Filter
        $filters = @("")
        if ($this.Resample -ne [Resample]::none) {
            switch ($this.Resample) {
                to44100Hz { $filters += $filters + '-resampleTo44100'; }
                to48000Hz { $filters += $filters + '-resampleTo48000'; }
                to96000Hz { $filters += $filters + '-resampleTo96000'; }
            }
        }
        if ($this.Downmix -ne [Downmix]::none) {
            switch ($this.Downmix) {
                to6 { $filters += $filters + '-down6'; }
                toDpl { $filters += $filters + '-downDpl'; }
                toStereo { $filters += $filters + '-downStereo'; }
            }
        }
        if ($this.Delay -ne 0) {if ($this.Delay -gt 0) { $filters += $filters + "+$($this.Delay)ms"; } else { $filters += $filters + "$($this.Delay)ms"; }}
        if ($this.Gain -ne 0) {if ($this.Gain -gt 0) { $filters += $filters + "+$($this.Gain)dB"; } else { $filters += $filters + "$($this.Gain)dB"; }}
        if ($this.Remap) { $filters += $filters + "-$($this.Remap)" }
        if ($this.Quality -ne 0.5) { $filters += $filters + "-quality=$($this.Quality)" }

        $filterLine = ""
        if ($filters.Length -gt 0) { $filterLine = [string]::Join(" ", $filters) }
        Write-Verbose "Filter CLI: $($filterLine)"

        # Decoding
        $tempfile = ""
        switch ($this.DecodeAutoMode) {
            Auto {
                if ($this.inFormats -contains $this.SourceFileName.Extension) {
                    $tempfile = """$($this.SourceFileName.FullName)"""
                } else {
                    $tempfile = """$($this.SourceFileName.FullName).flac"""
                    Write-Verbose "Executing: $($this.ffmpeg_path) -y -i ""$($this.SourceFileName.FullName)"" $tempfile"
                    if (-not $this.DryMode) {
                        Start-Process -FilePath $this.ffmpeg_path -ArgumentList @("-y -i", $($this.SourceFileName.FullName), $tempfile) -NoNewWindow -Wait 
                        if ($(Get-ChildItem $($this.SourceFileName.FullName).flac).Length -eq 0) { throw "File $($this.SourceFileName.Name) hasn't been compressed." }
                    }
                }
            }
            Pattern {
                if ($this.inFormats -contains $this.SourceFileName.Extension) {
                    $tempfile = """$($this.SourceFileName.FullName)"""
                } elseif ($this.inFormatsPattern -contains $this.SourceFileName.Extension) {
                    $tempfile = """$($this.SourceFileName.FullName).flac"""
                    Write-Verbose "Executing: $($this.ffmpeg_path) -y -i ""$($this.SourceFileName.FullName)"" $tempfile"
                    if (-not $this.DryMode) {
                        Start-Process -FilePath $this.ffmpeg_path -ArgumentList @("-y -i", $($this.SourceFileName.FullName), $tempfile) -NoNewWindow -Wait 
                        if ($(Get-ChildItem $($this.SourceFileName.FullName).flac).Length -eq 0) { throw "File $($this.SourceFileName.Name) hasn't been compressed." }
                    }
                } else { throw "Unsupported File format. Use FFMpeg for Decode." }
            }
            FFMpeg {
                $tempfile = """$($this.SourceFileName.FullName).flac"""
                Write-Verbose "Executing: $($this.ffmpeg_path) -y -i ""$($this.SourceFileName.FullName)"" $tempfile"
                if (-not $this.DryMode) {
                    Start-Process -FilePath $this.ffmpeg_path -ArgumentList @("-y -i", $($this.SourceFileName.FullName), $tempfile) -NoNewWindow -Wait 
                    if ($(Get-ChildItem $($this.SourceFileName.FullName).flac).Length -eq 0) { throw "File $($this.SourceFileName.Name) hasn't been compressed." }
                }
            }
            Eac3to { 
                if ($this.inFormats -notcontains $this.SourceFileName.Extension) { throw "Unsupported File format. Use FFMpeg for Decode." }
                $tempfile = """$($this.SourceFileName.FullName)"""
            }
        }

        # Encoding
        if (-not $this.DryMode) {
            if ($this.Async) {
                Write-Verbose "Executing: $($this.eac3to_path) $tempfile ""$DestinationFile"" -lowPriority $filterLine"
                $proc = Start-Process -FilePath $this.eac3to_path -ArgumentList @($tempfile, """$DestinationFile""", "-lowPriority $filterLine") -NoNewWindow -PassThru -RedirectStandardOutput "nul"
                $this.EncProcess = $proc
            } else {
                Write-Verbose "Executing: $($this.eac3to_path) $tempfile ""$DestinationFile"" -lowPriority $filterLine"
                $proc = Start-Process -FilePath $this.eac3to_path -ArgumentList @($tempfile, """$DestinationFile""", "-lowPriority $filterLine") -NoNewWindow -PassThru -Wait
                $this.EncProcess = $proc
                if ($(Get-ChildItem $DestinationFile).Length -eq 0) { throw "File $($this.SourceFileName.Name) hasn't been compressed." }
            }
        }
    }
}

#$res = [EAC3]::new("D:\Multimedia\Programs\Utils\tools\eac3to\eac3to.exe", "D:\Multimedia\Programs\Utils\tools_64\ffmpeg.exe")
#$res.Verbose = $true
#$res.OpenSrcFile("D:\Multimedia\Programs\Utils\temp\e46b38c2-fe85-4a43-880b-3e8041175b1d.ogg")
#$res.OpenSrcFile("D:\Multimedia\Programs\Utils\temp\e46b38c2-fe85-4a43-880b-3e8041175b1d.Opus")
#$res.OpenSrcFile("D:\Multimedia\Programs\Utils\temp\e46b38c2-fe85-4a43-880b-3e8041175b1d.flac")
#$res.Drymode = $true
#$res.DecodeAutoMode = [DecodeMode]::Auto
#$res.Resample = [Resample]::to44100Hz
#$res.Downmix = [Downmix]::toStereo
#$res.Delay = -500  # +/-100 in ms
#$res.Gain = 3 # +/-3 in dB
#$res.Remap = "1,0,2,3,4,5" # "0,1,2,3,4,5" remap the channels
#$res.Format = [Format]::flac;
#$res.Quality = 0.6; # Nero AAC encoding quality (0.00 = lowest; 1.00 = highest)

#$res.DestinationFileName = "D:\Multimedia\Programs\Utils\temp\e46b38c2-fe85-4a43-880b-3e8041175b1d.m4a"
#$res.Compress()
