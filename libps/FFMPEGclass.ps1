#Requires -Version 5

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
        $processing = "-vf "
        $processinglist = @()
        if ($this.Crop.Enabled) { $processinglist += "crop=w=in_w-$($this.Crop.Left)-$($this.Crop.Right):h=in_h-$($this.Crop.Top)-$($this.Crop.Bottom):x=$($this.Crop.Left):y=$($this.Crop.Top)" }
        if ($this.Resize.Enabled) { $processinglist += "scale=$($this.Resize.Width):$($this.Resize.Height)" }
        if ($processinglist) { $filters += $processing + [string]::Join(",", $processinglist)}
        if ($this.Resize.Enabled -and $($this.Resize.Method)) { $filters += "-sws_flags $($this.Resize.Method)" }
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


#$res = [ffmpeg]::new("D:\1\ffmpeg_64.exe")
#$res.Tune = [tune]::animation
#$res.Codec = [codec]::libx264;
#$res.SourceFileAVS = "D:\1\1.m4v"
#$res.DestinationFileName = "D:\Multimedia\Programs\Utils\temp\test.hevc"
#$res.Compress()
