#Requires -Version 5

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
    [string]$mode = "normal" #"Dry"
    [System.Diagnostics.ProcessPriorityClass]$ProcessPriority = [System.Diagnostics.ProcessPriorityClass]::Idle;

    hidden $inFormats = @(".AAC",".PCM",".FLAC",".AC-3",".E-AC-3",".MLP FBA",".DTS",".MPEG Audio",".TrueHD");

    hidden [string]$eac3to_path;
    hidden [String]$ffmpeg_path;

    [bool]$UseFFMpegforDecode = $false;

    [Resample]$Resample = [Resample]::none;
    [Downmix]$Downmix = [Downmix]::none;
    [int16]$Delay = 0;  # +/-100 in ms
    [int16]$Gain = 0; # +/-3 in dB
    [string]$Remap; # "0,1,2,3,4,5" remap the channels

    [Format]$Format = [Format]::aac;

    [ValidateRange(0,1)]
    [Double]$Quality = 0.5; # Nero AAC encoding quality (0.00 = lowest; 1.00 = highest)

    hidden [io.fileinfo]$SourceFile;

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

    [void]OpenSrcFile ([string]$FileName) {
        if ($this.Verbose) { $VerbosePreference = "continue" }
        Write-Verbose "Open File"
        if (Test-Path $FileName -PathType Leaf) { $this.SourceFile = $FileName; } else { throw "ERROR: $FileName not found." }
    }

    [void]Compress() {
        if ($this.Verbose) { $VerbosePreference = "continue" }
        Write-Verbose "Mode: $($this.mode)"
        Write-Verbose "Format: $($this.Format)"
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
        $filters = @()
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

        # Encoding
        if ($this.UseFFMpegforDecode) {
            # Decode file
            $startInfo = New-Object System.Diagnostics.ProcessStartInfo
            $startInfo.Arguments = "-i ""$($this.SourceFile.FullName)"" ""$($this.SourceFile.FullName).flac"""
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
                if ($(Get-ChildItem $DestinationFile).Length -eq 0) { throw "File $($this.SourceFile.Name) hasn't been compressed." }
            }
            # Encode file
            $startInfo = New-Object System.Diagnostics.ProcessStartInfo
            $startInfo.Arguments = """$($this.SourceFile.FullName).flac"" ""$($DestinationFile)"" $filterLine"
            $startInfo.FileName = $this.eac3to_path
            Write-Verbose "Executing: $($startInfo.FileName) $($startInfo.Arguments)"
            if ($this.mode -ne "Dry") {
                $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
                $startInfo.UseShellExecute = $false
                $process = New-Object System.Diagnostics.Process
                $process.StartInfo = $startInfo
                $process.Start() | Out-Null
                $process.PriorityClass = $this.ProcessPriority
                $process.WaitForExit()
                if ($(Get-ChildItem $DestinationFile).Length -eq 0) { throw "File $($this.SourceFile.Name) hasn't been compressed." }
            }
        } else {
            if ($this.inFormats -notcontains $this.SourceFile.Extension) { throw "Unsupported File format. Use FFMpeg for Decode." }
            $startInfo = New-Object System.Diagnostics.ProcessStartInfo
            $startInfo.Arguments = """$($this.SourceFile.FullName)"" ""$($DestinationFile)"" $filterLine"
            $startInfo.FileName = $this.eac3to_path
            Write-Verbose "Executing: $($startInfo.FileName) $($startInfo.Arguments)"
            if ($this.mode -ne "Dry") {
                $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
                $startInfo.UseShellExecute = $false
                $process = New-Object System.Diagnostics.Process
                $process.StartInfo = $startInfo
                $process.Start() | Out-Null
                $process.PriorityClass = $this.ProcessPriority
                $process.WaitForExit()
                if ($(Get-ChildItem $DestinationFile).Length -eq 0) { throw "File $($this.SourceFile.Name) hasn't been compressed." }
            }
        }
    }
}

#$res = [EAC3]::new("D:\Multimedia\Programs\Utils\tools\eac3to\eac3to.exe", "D:\Multimedia\Programs\Utils\tools_64\ffmpeg.exe")
#$res.Verbose = $true
#$res.OpenSrcFile("D:\1\2\audio.flac")
#$res.mode = "Dry"
#$res.UseFFMpegforDecode = $true;
#$res.Resample = [Resample]::to44100Hz
#$res.Downmix = [Downmix]::toStereo
#$res.Delay = -500  # +/-100 in ms
#$res.Gain = 3 # +/-3 in dB
#$res.Remap = "1,0,2,3,4,5" # "0,1,2,3,4,5" remap the channels
#$res.Format = [Format]::flac;
#$res.Quality = 0.6; # Nero AAC encoding quality (0.00 = lowest; 1.00 = highest)

#$res.DestinationFileName = "D:\1\2\test.m4a"
#$res.Compress()
