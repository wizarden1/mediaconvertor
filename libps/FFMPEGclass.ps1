#Requires -Version 5

# Current Version 1.3.1
# 1.3.1 - add denoise presets
# 1.3 - rebuild class TCrop with get/set values, add denoise by Thqdn3d class
# 1.2 - rename vsync to fps_mode (vsync deprecated)
# 1.1 - add ffmpeg format of crop
# 1.0 - initial release

# codecs
enum codec { 
    libx264
    libx265
}

# encoder
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

enum fps_mode {
    passthrough
    cfr
    vfr
    drop
    auto
}

# filters
enum yadif_mode {
    send_frame
    send_field
    send_frame_nospatial
    send_field_nospatial
}

enum yadif_parity {
    tff
    bff
    auto
}

enum yadif_deint {
    all
    interlaced
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

enum crop_mode {
    ltrb
    custom
}

enum denoise_preset {
    default
    ultralight
    light
    medium
    strong
    weak
    custom
}

# Types
# crop
class TCrop {
    [bool]$Enabled = $false;
# ltrb, custom
    hidden $_mode   = $($this | Add-Member -Name Mode -MemberType ScriptProperty -Value { return $this._mode } -SecondValue { param($value); $this._mode = [crop_mode]$value; $this.UpdateCli() })
    hidden $_customParams = $($this | Add-Member -Name CustomParams -MemberType ScriptProperty -Value { return $this._customParams } -SecondValue { 
        param($value)
        $this._customParams = [string]$value
        if ($this.Mode -eq "ltrb") {
            if ([int]$this._customParams.Split(":").Count -ne 4) { throw "ERROR: Incorrect crop parameters" }
            $this._left = [int]$this._customParams.Split(":")[0];
            $this._top = [int]$this._customParams.Split(":")[1];
            $this._right = [int]$this._customParams.Split(":")[2];
            $this._bottom = [int]$this._customParams.Split(":")[3];
        }
        $this.UpdateCli()
    })
    hidden $_left   = $($this | Add-Member -Name Left -MemberType ScriptProperty -Value { return $this._left } -SecondValue { param($value); $this._left = [int]$value; $this.UpdateCli() })
    hidden $_top    = $($this | Add-Member -Name Top -MemberType ScriptProperty -Value { return $this._top } -SecondValue { param($value); $this._top = [int]$value; $this.UpdateCli() })
    hidden $_right  = $($this | Add-Member -Name Right -MemberType ScriptProperty -Value { return $this._right } -SecondValue { param($value); $this._right = [int]$value; $this.UpdateCli() })
    hidden $_bottom = $($this | Add-Member -Name Bottom -MemberType ScriptProperty -Value { return $this._bottom } -SecondValue { param($value); $this._bottom = [int]$value; $this.UpdateCli() })
    hidden $_cli    = $($this | Add-Member -Name cli -MemberType ScriptProperty -Value { $($this._cli) })

    # Constructor
    TCrop () {
        $this._left = 0;
        $this._top = 0;
        $this._right = 0;
        $this._bottom = 0;
        $this._customParams = "0:0:0:0";
        $this._mode = [crop_mode]::ltrb;
        $this.UpdateCli()
    }

    hidden [void]UpdateCli() {
         switch ($this.Mode) {
              "ltrb"   { $this._cli = "crop=w=in_w-$($this.Left)-$($this.Right):h=in_h-$($this.Top)-$($this.Bottom):x=$($this.Left):y=$($this.Top)" }
              "custom" { $this._cli = "crop=$($this._customParams)" }
              default { throw "ERROR: Unknown Crop Mode" }
         }
    }
}

# deinterlace
class TYadif {
    [bool]$Enabled = $false;
    [string]$Mode = [yadif_mode]::send_frame;
    [string]$Parity = [yadif_parity]::auto;
    [string]$Deint = [yadif_deint]::all;
}

# resize methods: fastbilinear, bilinear, bicubic, experimental, point, area, bicublin, gauss, sinc, lanczos, spline
class TResize {
    [bool]$Enabled = $false;
    [int]$Width = 0;
    [int]$Height = 0;
    [ResizeMethods]$Method = [ResizeMethods]::lanczos;
}

# denoise
class Thqdn3d {
    [bool]$Enabled = $false;
    hidden [float]$luma_spatial = 4.0;                                                      # A non-negative floating point number which specifies spatial luma strength. It defaults to 4.0.
    hidden [float]$chroma_spatial = 3.0 * $this.luma_spatial / 4.0;                         # A non-negative floating point number which specifies spatial chroma strength. It defaults to 3.0*luma_spatial/4.0.
    hidden [float]$luma_tmp = 6.0 * $this.luma_spatial / 4.0;                               # A floating point number which specifies luma temporal strength. It defaults to 6.0*luma_spatial/4.0.
    hidden [float]$chroma_tmp = $this.luma_tmp * $this.chroma_spatial / $this.luma_spatial; # A floating point number which specifies chroma temporal strength. It defaults to luma_tmp*chroma_spatial/luma_spatial. 

    hidden $_preset       = $($this | Add-Member -Name Preset -MemberType ScriptProperty -Value { return $this._preset } -SecondValue { param($value); $this._preset = [denoise_preset]$value; $this.UpdateCli() })
    hidden $_customParams = $($this | Add-Member -Name CustomParams -MemberType ScriptProperty -Value { return $this._customParams } -SecondValue { param($value); $this._customParams = [string]$value; $this.UpdateCli() })
    hidden $_cli          = $($this | Add-Member -Name cli -MemberType ScriptProperty -Value { $($this._cli) })

    # Constructor
    Thqdn3d () {
        $this._preset = [denoise_preset]::default;
        $this._customParams = "4:3:6:4.5";
        $this.UpdateCli()
    }

    # Functions
    hidden [void]UpdateCli() {
        Switch ($this._preset) {
            "default" {
                $this._cli = "hqdn3d"
            }
            "ultralight" {
                $this.luma_spatial = 1
                $this.chroma_spatial = 0.7
                $this.luma_tmp = 1
                $this.chroma_tmp = 2
                $this._cli = "hqdn3d=$($this.luma_spatial):$($this.chroma_spatial):$($this.luma_tmp):$($this.chroma_tmp)"
            }
            "light" {
                $this.luma_spatial = 2
                $this.chroma_spatial = 1
                $this.luma_tmp = 2
                $this.chroma_tmp = 3
                $this._cli = "hqdn3d=$($this.luma_spatial):$($this.chroma_spatial):$($this.luma_tmp):$($this.chroma_tmp)"
            }
            "medium" {
                $this.luma_spatial = 3
                $this.chroma_spatial = 2
                $this.luma_tmp = 2
                $this.chroma_tmp = 3
                $this._cli = "hqdn3d=$($this.luma_spatial):$($this.chroma_spatial):$($this.luma_tmp):$($this.chroma_tmp)"
            }
            "strong" {
                $this.luma_spatial = 7
                $this.chroma_spatial = 7
                $this.luma_tmp = 5
                $this.chroma_tmp = 5
                $this._cli = "hqdn3d=$($this.luma_spatial):$($this.chroma_spatial):$($this.luma_tmp):$($this.chroma_tmp)"
            }
            "weak" {
                $this.luma_spatial = 2
                $this.chroma_spatial = 1
                $this.luma_tmp = 2
                $this.chroma_tmp = 3
                $this._cli = "hqdn3d=$($this.luma_spatial):$($this.chroma_spatial):$($this.luma_tmp):$($this.chroma_tmp)"
            }
            "custom" {
                $this._cli = "hqdn3d=$($this._customParams)"
            }
            default { throw "ERROR: Unknown denoise preset" }
        }
    }
}

#preset: ultrafast,superfast,veryfast,faster,fast,medium,slow,slower,veryslow,placebo
#	[ValidateSet('ultrafast','superfast','veryfast','faster','fast','medium','slow','slower','veryslow','placebo')]
#tune: film,animation,grain,psnr,ssim,fastdecode,touhou
#	[ValidateSet('none','film','animation','grain','stillimage','psnr','ssim','fastdecode','zerolatency')]
class ffmpeg {
    [bool]$DryMode = $false
    [bool]$Verbose = $false
    $EncProcess = $null
    hidden [String]$ffmpeg_path;
    [Presets]$Preset = [Presets]::medium;
    [tune]$Tune = [tune]::none;
    [fps_mode]$FPSMode = [fps_mode]::auto;
    [string]$FramRate = "24";
    [codec]$Codec = [codec]::libx265;
    [int16]$Quantanizer = 22;
    [bool]$Enable10bit = $true;
    [bool]$Pulldown = $false;
    [String]$CustomFilter = "";
    [String]$CustomModifier = "";
    [io.fileinfo]$SourceFileAVS;
    [ValidateSet('.mkv', '.mp4', '.hevc', '.264')]
    hidden [String]$DestinationFileExtension = ".mkv";
    [io.fileinfo]$DestinationFileName;

    #Filters
    [TCrop]$Crop = [TCrop]::new();
    [TResize]$Resize = [TResize]::new();
    [TYadif]$Deinterlace = [TYadif]::new();
    [Thqdn3d]$Denoise = [Thqdn3d]::new();

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
        Write-Verbose "Dry Mode Enabled: $($this.DryMode)"
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
        if ($this.Crop.Enabled) { $filters += $this.Crop.cli }
        if ($this.Resize.Enabled) { $filters += "scale=$($this.Resize.Width):$($this.Resize.Height)" }
        if ($this.Deinterlace.Enabled) { $filters += "yadif=$($this.Deinterlace.Mode):$($this.Deinterlace.Parity):$($this.Deinterlace.Deint)" }
        if ($this.Denoise.Enabled) { $filters += $this.Denoise.cli }
        if ($this.Pulldown) {
          $filters += "fieldmatch"
          $filters += "decimate" 
          if (-not $this.Deinterlace.Enabled) {$filters += "yadif" }
        }
        if ($this.CustomFilter) { $filters += $this.CustomFilter }

        $videofilter = ""
        if ($filters.Length -gt 0) { $videofilter = "-vf " + [string]::Join(",", $filters) }
        Write-Verbose "Filter CLI: $($videofilter)"

        $modifiers = @()
        if ($this.Enable10bit) { $modifiers += "-pix_fmt yuv420p10le" }
        if ($this.Tune -ne "none") { $modifiers += "-tune $($this.Tune)" }
        if ($this.FPSMode -ne "auto") { $modifiers += "-fps_mode $($this.FPSMode)" }
        if ($this.Resize.Enabled -and $($this.Resize.Method)) { $modifiers += "-sws_flags $($this.Resize.Method)" }

        $videoModifier = ""
        if ($modifiers.Length -gt 0) { $videoModifier = [string]::Join(" ", $modifiers) }
        Write-Verbose "Modifiers CLI: $($videoModifier)"

        # Encoding
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
#        if ($this.FramRate -gt 0) { $FramRate = "-r $($this.FramRate)" } else { $FramRate = "" }
        $startInfo.Arguments = "-r $($this.FramRate) -i ""$($this.SourceFileAVS.FullName)"" -c:v $($this.Codec) -crf $($this.Quantanizer) -preset $($this.Preset) $videoModifier $($this.CustomModifier) $videofilter -an -sn -dn -r $($this.FramRate) ""$DestinationFile"""
#        $startInfo.Arguments = "$FramRate -i ""$($this.SourceFileAVS.FullName)"" -c:v $($this.Codec) -crf $($this.Quantanizer) -preset $($this.Preset) $videoModifier $($this.CustomModifier) $videofilter -an -sn -dn $FramRate ""$DestinationFile"""
        $startInfo.FileName = $this.ffmpeg_path
        Write-Verbose "Executing: $($startInfo.FileName) $($startInfo.Arguments)"
        if (-not $this.DryMode) {
            $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
            $startInfo.UseShellExecute = $false
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $startInfo
            $process.Start() | Out-Null
            $process.PriorityClass = $this.ProcessPriority
            $this.EncProcess = $process
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
