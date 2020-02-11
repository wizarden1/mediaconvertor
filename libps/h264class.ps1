#Requires -Version 5

enum H264Presets {
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

enum H264tune {
    none
    film
    animation
    grain
    stillimage
    psnr
    ssim
    fastdecode
    zerolatency
}

enum H264ResizeMethods {
    fastbilinear
    bilinear
    bicubic
    experimental
    point
    area
    bicublin
    gauss
    sinc
    lanczos
    spline
}

class TH264Crop {
	[bool]$Enabled = $false;
	[int]$Left = 0;
	[int]$Top = 0;
	[int]$Right = 0;
	[int]$Bottom = 0;
}

class TH264Resize {
	[bool]$Enabled = $false;
	[int]$Width = 0;
	[int]$Height = 0;
# resize methods: fastbilinear, bilinear, bicubic, experimental, point, area, bicublin, gauss, sinc, lanczos, spline
	[H264ResizeMethods]$Method = [H264ResizeMethods]::lanczos;
}


class H264 {
    hidden [String]$x264_path;
    hidden [String]$ffmpeg_path;

#preset: ultrafast,superfast,veryfast,faster,fast,medium,slow,slower,veryslow,placebo
#	[ValidateSet('ultrafast','superfast','veryfast','faster','fast','medium','slow','slower','veryslow','placebo')]
    [H264Presets]$Preset = [H264Presets]::medium;

#tune: film,animation,grain,psnr,ssim,fastdecode,touhou
#	[ValidateSet('none','film','animation','grain','stillimage','psnr','ssim','fastdecode','zerolatency')]
	[H264tune]$Tune = [H264tune]::none;
	[int16]$Quantanizer = 22;
    [io.fileinfo]$SourceFileAVS;
	[ValidateSet('.mkv','.264','.flv','.mp4')]
    hidden [String]$DestinationFileExtension = ".mkv";
	[io.fileinfo]$DestinationFileName;

#Filters
    [TH264Crop]$Crop = [TH264Crop]::new();
    [TH264Resize]$Resize = [TH264Resize]::new();

    [System.Diagnostics.ProcessPriorityClass]$ProcessPriority = [System.Diagnostics.ProcessPriorityClass]::Idle;

#	[bool]$Pulldown = $false;
#      pulldown_pattern = step,offset1[,...]
#            apply a selection pattern to input frames
#            step: the number of frames in the pattern
#            offsets: the offset into the step to select a frame
#            see: http://avisynth.nl/index.php/Select#SelectEvery
#	[String]$Pulldown_Pattern = "";

# Constructor
	H264 ([String]$x264_path, $ffmpeg_path) {
        if (Test-Path $x264_path -PathType Leaf){$this.x264_path = $x264_path} else {throw "ERROR: x264.exe not found."}
        if (Test-Path $ffmpeg_path -PathType Leaf){$this.ffmpeg_path = $ffmpeg_path} else {throw "ERROR: ffmpeg.exe not found."}
	}

	H264 ([String]$x264_path) {
        if (Test-Path $x264_path -PathType Leaf){$this.x264_path = $x264_path} else {throw "ERROR: x264.exe not found."}
	}

	[void]Compress() {
		if (-not $(Resolve-Path ([io.fileinfo]$this.DestinationFileName).DirectoryName | Test-Path)) {throw "ERROR: Destination path is incorrect."; return}
        if (([io.fileinfo]$this.DestinationFileName).Extension -eq ".mkv"){$this.DestinationFileExtension = ".mkv"} else {$this.DestinationFileExtension = "$(([io.fileinfo]$this.DestinationFileName).Extension).mkv"}
		$DestinationFile = "$(Join-Path ([io.fileinfo]$this.DestinationFileName).DirectoryName ([io.fileinfo]$this.DestinationFileName).BaseName)$($this.DestinationFileExtension)"
		
        if ($this.Tune -ne "none") {$TuneCommand = "--tune $($this.Tune)"} else {$TuneCommand = ""}
# Creating Filter
# --video-filter <filter>:<option>=<value>,<option>=<value>/<filter>:<option>=<value>
		$filters = @()
		if ($this.Crop.Enabled) {$filters += "$(crop:$this.Crop.Left),$($this.Crop.Top),$($this.Crop.Right),$($this.Crop.Bottom)"}
		if ($this.Resize.Enabled) {$filters += "resize:width=$($this.Resize.Width),height=$($this.Resize.Height),method=$($this.Resize.Method)"}
#		if ($this.Pulldown) {$filters += "select_every:"+$($this.Pulldown_Pattern)}
		
        $videofilter=""
		if ($filters.Length -gt 0) {$videofilter="--video-filter "+[string]::Join("/",$filters)}

#ffmpeg -i test.avi -f yuv4mpegpipe -pix_fmt yuv420p - | x264-r2705-3f5ed56_64.exe --demuxer y4m -o encoded.264 -

# Encoding
		$startInfo = New-Object System.Diagnostics.ProcessStartInfo
		$startInfo.Arguments = "--crf $($this.Quantanizer) --preset $($this.Preset) $TuneCommand --thread-input $videofilter --output ""$DestinationFile"" ""$($this.SourceFileAVS.FullName)"""
		$startInfo.FileName = $this.x264_path
		$startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
		$startInfo.UseShellExecute = $false
		$process = New-Object System.Diagnostics.Process
		$process.StartInfo = $startInfo
		$process.Start() | Out-Null
		$process.PriorityClass = $this.ProcessPriority
		$process.WaitForExit()

		if ($(Get-ChildItem $DestinationFile).Length -eq 0) {throw "File $($this.SourceFileAVS.Name) hasn't been compressed."}

	}
}


#$res = [H264]::new("C:\Multimedia\Programs\x264\x264_64.exe")
#$res = [H264]::new()