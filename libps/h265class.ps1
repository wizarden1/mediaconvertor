#Requires -Version 5

enum H265Presets {
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

enum H265tune { 
    none
    psnr
    ssim
    grain
    fastdecode
    zerolatency
    animation
}

enum H265ResizeMethods {
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

class TH265Crop {
	[bool]$Enabled = $false;
	[int]$Left = 0;
	[int]$Top = 0;
	[int]$Right = 0;
	[int]$Bottom = 0;
}

# resize methods: fastbilinear, bilinear, bicubic, experimental, point, area, bicublin, gauss, sinc, lanczos, spline
class TH265Resize {
	[bool]$Enabled = $false;
	[int]$Width = 0;
	[int]$Height = 0;
	[H265ResizeMethods]$Method = [H265ResizeMethods]::lanczos;
}

#preset: ultrafast,superfast,veryfast,faster,fast,medium,slow,slower,veryslow,placebo
#	[ValidateSet('ultrafast','superfast','veryfast','faster','fast','medium','slow','slower','veryslow','placebo')]
#tune: film,animation,grain,psnr,ssim,fastdecode,touhou
#	[ValidateSet('none','film','animation','grain','stillimage','psnr','ssim','fastdecode','zerolatency')]
class H265 {
    hidden [String]$ffmpeg_path;
    [H265Presets]$Preset = [H265Presets]::medium;
	[H265tune]$Tune = [H265tune]::none;
    [int16]$Quantanizer = 22;
    [bool]$Enable10bit = $true;
    [io.fileinfo]$SourceFileAVS;
	[ValidateSet('.mkv','.mp4','.hevc')]
    hidden [String]$DestinationFileExtension = ".mkv";
	[io.fileinfo]$DestinationFileName;

#Filters
    [TH265Crop]$Crop = [TH265Crop]::new();
    [TH265Resize]$Resize = [TH265Resize]::new();

    [System.Diagnostics.ProcessPriorityClass]$ProcessPriority = [System.Diagnostics.ProcessPriorityClass]::Idle;

# Constructor
	H265 ([String]$ffmpeg_path) {
        if (Test-Path $ffmpeg_path -PathType Leaf){$this.ffmpeg_path = $ffmpeg_path} else {throw "ERROR: ffmpeg.exe not found."}
	}

	[void]Compress() {
		if (-not $(Resolve-Path ([io.fileinfo]$this.DestinationFileName).DirectoryName | Test-Path)) {throw "ERROR: Destination path is incorrect."; return}
        $this.DestinationFileExtension = $([io.fileinfo]$this.DestinationFileName).Extension
        $DestinationFile = "$(Join-Path ([io.fileinfo]$this.DestinationFileName).DirectoryName ([io.fileinfo]$this.DestinationFileName).BaseName)$($this.DestinationFileExtension)"
		
# Creating Filter
		$filters = @()
		if ($this.Crop.Enabled) {$filters += "-filter:v ""crop=w=in_w-$($this.Crop.Left)-$($this.Crop.Right):h=in_h-$($this.Crop.Top)-$($this.Crop.Bottom):x=$($this.Crop.Left):y=$($this.Crop.Top)"""}
        if ($this.Resize.Enabled) {$filters += "-vf scale=$($this.Resize.Width):$($this.Resize.Height) -sws_flags $($this.Resize.Method)"}
        if ($this.Enable10bit) {$filters += "-pix_fmt yuv420p10le"}
        if ($this.Tune -ne "none") {$filters += "-tune $($this.Tune)"}
		
        $videofilter=""
		if ($filters.Length -gt 0) {$videofilter=[string]::Join(" ",$filters)}

# Encoding
		$startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.Arguments = "-i ""$($this.SourceFileAVS.FullName)"" -c:v libx265 -crf $($this.Quantanizer) -preset $($this.Preset) $videofilter ""$DestinationFile"""
		$startInfo.FileName = $this.ffmpeg_path
        Write-Host "$($startInfo.FileName) $($startInfo.Arguments)"
#		$startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
#		$startInfo.UseShellExecute = $false
#		$process = New-Object System.Diagnostics.Process
#		$process.StartInfo = $startInfo
#		$process.Start() | Out-Null
#		$process.PriorityClass = $this.ProcessPriority
#		$process.WaitForExit()

#		if ($(Get-ChildItem $DestinationFile).Length -eq 0) {throw "File $($this.SourceFileAVS.Name) hasn't been compressed."}
	}
}


#$res = [H265]::new("D:\1\ffmpeg_64.exe")
#$res.Tune = [H265tune]::animation
#$res.SourceFileAVS = "D:\1\1.m4v"
#$res.DestinationFileName = "D:\Multimedia\Programs\Utils\temp\test.hevc"
#$res.Compress()
