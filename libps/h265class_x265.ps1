#Requires -Version 5

# ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow, or placebo
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

# psnr, ssim, grain, zerolatency, fastdecode, animation
enum tune { 
    none
    psnr
    ssim
    grain
    fastdecode
    zerolatency
    animation
}

# -vf scale=504:376 -sws_flags bilinear
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

# Originally Posted by Sviests View Post
# I need to crop: left:342,top:206,right:286,bottom:176
# It's just a little simple math: After cropping the remaining width of the image is in_w - left_crop - right_crop, the remaining height of the image is in_h - top_crop - bottom_crop, and you want the top left corner of the crop at left_crop, top_crop:

# Code:

# -filter:v "crop=w=in_w-${left}-${right}:h=in_h-${top}-${bottom}:x=${left}:y=${top}"
class TCrop {
    [bool]$Enabled = $false;
    [int]$Left = 0;
    [int]$Top = 0;
    [int]$Right = 0;
    [int]$Bottom = 0;
    [string]$arg;

    # Metods
    [void]BuildArgs() {
        if ($this.Enabled) {
          $this.arg = "-filter:v ""crop=w=in_w-$($this.Left)-$($this.Right):h=in_h-$($this.Top)-$($this.Bottom):x=$($this.Left):y=$($this.Top)"""
        } else {$this.arg = ""}
    }
}

# -vf scale=504:376 -sws_flags bilinear
class TResize {
    [bool]$Enabled = $false;
    [int]$Width = 0;
    [int]$Height = 0;
    # resize methods: fastbilinear, bilinear, bicubic, experimental, point, area, bicublin, gauss, sinc, lanczos, spline
    [ResizeMethods]$Method = [ResizeMethods]::lanczos;

    [string]$arg;

    # Metods
    [void]BuildArgs() {
        if ($this.Enabled) {
          $this.arg = "-vf scale=$($this.Width):$($this.Height) -sws_flags $($this.Method)"
        } else {$this.arg = ""}
    }
}

class TH265 {
    # Properties
    hidden [String]$x265_path;
    hidden [String]$ffmpeg_path;

    [Presets]$Preset = [Presets]::medium;
    [tune]$Tune = [tune]::none;

    [String]$Arguments;

    [int16]$Quantanizer = 22;
    [string]$fps; #"23.976" "24000/1001"
    [string]$Resolution; #"1920x1080"
    [ValidateSet('8','10','12')]
    [string]$Bitdepth = '8'; #8,10,12

    [io.fileinfo]$SourceFileAVS;

    [ValidateSet('.hvec')]
    hidden [String]$DestinationFileExtension = ".hvec";
    [io.fileinfo]$DestinationFileName;

    #Filters
    [TCrop]$Crop = [TCrop]::new();
    [TResize]$Resize = [TResize]::new();

    [System.Diagnostics.ProcessPriorityClass]$ProcessPriority = [System.Diagnostics.ProcessPriorityClass]::Idle;

    #	[bool]$Pulldown = $false;
    #      pulldown_pattern = step,offset1[,...]
    #            apply a selection pattern to input frames
    #            step: the number of frames in the pattern
    #            offsets: the offset into the step to select a frame
    #            see: http://avisynth.nl/index.php/Select#SelectEvery
    #	[String]$Pulldown_Pattern = "";

    # Constructor
    H265 ([String]$x265_path, $ffmpeg_path) {
        if (Test-Path $x265_path -PathType Leaf) { $this.x265_path = $x265_path } else { throw "ERROR: x265.exe not found." }
        if (Test-Path $ffmpeg_path -PathType Leaf) { $this.ffmpeg_path = $ffmpeg_path } else { throw "ERROR: ffmpeg.exe not found." }
    }

    [void]Compress() {
        # Check required parameters
        if (-not $(Resolve-Path ([io.fileinfo]$this.DestinationFileName).DirectoryName | Test-Path)) { throw "ERROR: Destination path is incorrect."; return }
        if (([io.fileinfo]$this.DestinationFileName).Extension -eq ".hvec") { $this.DestinationFileExtension = ".hvec" } else { $this.DestinationFileExtension = "$(([io.fileinfo]$this.DestinationFileName).Extension).hvec" }
        if (-not $this.fps) {throw "ERROR: Input FPS not set."; return}
        if (-not $this.Resolution) {throw "ERROR: Input resolution is not set."; return}
        
        $DestinationFile = "$(Join-Path ([io.fileinfo]$this.DestinationFileName).DirectoryName ([io.fileinfo]$this.DestinationFileName).BaseName)$($this.DestinationFileExtension)"
		
        if ($this.Tune -ne "none") { $TuneCommand = "--tune $($this.Tune)" } else { $TuneCommand = "" }
        # Creating Filter
        # -filter:v "crop=w=in_w-342-286:h=in_h-206-176:x=342:y=206"
        # -vf scale=504:376 -sws_flags bilinear
        # --video-filter <filter>:<option>=<value>,<option>=<value>/<filter>:<option>=<value>
        #--input-depth <integer>       Bit-depth of input file. Default 8
        $filters = @()
        $filters += $this.Crop.arg;
        $filters += $this.Resize.arg;
        #		if ($this.Pulldown) {$filters += "select_every:"+$($this.Pulldown_Pattern)}
		
        $videofilter = ""
        if ($filters.Length -gt 0) { $videofilter = [string]::Join(" ", $filters) }

        #ffmpeg -i test.avi -f yuv4mpegpipe -pix_fmt yuv420p - | x265-r2705-3f5ed56_64.exe --demuxer y4m -o encoded.264 -
        #Invoke-Expression -Command "cmd /c ""ffmpeg_64.exe -i test-1080p.mkv -f rawvideo - | x265-64bit-10bit-latest.exe - --input-res 1920x1080 --fps 23.976 --output 1080p.hevc --crf 20 --preset fast"""

        #$startInfo.FileName = "cmd.exe"
        #$startInfo.Arguments = "/c ""ffmpeg_64.exe -i test-1080p.mkv -f rawvideo - | x265-64bit-10bit-latest.exe - --input-res 1920x1080 --fps 23.976 --output 1080p.hevc --crf 20 --preset fast"""
        #$startInfo.WorkingDirectory = "D:\1"

        # Encoding
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.Arguments = "/c ""$($this.ffmpeg_path) -i $($this.SourceFileAVS.FullName) -f rawvideo - | $($this.x265_path) - $videofilter --input-res $($this.Resolution) --fps $($this.fps) --input-depth $($this.cdepth) --output '$DestinationFile' --crf $($this.Quantanizer) --preset $($this.Preset) $TuneCommand"""
        #"--crf $($this.Quantanizer) --preset $($this.Preset) $TuneCommand --thread-input $videofilter --output ""$DestinationFile"" ""$($this.SourceFileAVS.FullName)"""
        $startInfo.FileName = "cmd.exe"
        #        $startInfo.FileName = $this.x265_path
        #        $startInfo.WorkingDirectory = "D:\1"
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

#$res = [H264]::new("C:\Multimedia\Programs\x265\x265_64.exe")
#$res = [H264]::new()