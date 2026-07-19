#Requires -Version 7
#Version 1.5.1
# 1.5.1 - Fix: rename FramRate to FrameRate, refactor Thqdn3d.UpdateCli
# 1.5.0 - Add VVC (libvvenc) codec support with preset mapping and qp/qpa params
# 1.4.0 - Add AV1 (libsvtav1) codec support with preset/tune mapping and svtav1-params
# 1.3.3 - Add ffmpeg exit code check, fix file existence check, remove dead WindowStyle
# 1.3.2 - Fix: weak denoise preset now has unique values (was duplicate of light)
# 1.3.1 - add denoise presets
# 1.3 - rebuild class TCrop with get/set values, add denoise by Thqdn3d class
# 1.2 - rename vsync to fps_mode (vsync deprecated)
# 1.1 - add ffmpeg format of crop
# 1.0 - initial release

# codecs
enum codec { 
    libx264
    libx265
    libsvtav1
    libvvenc   # requires mkvmerge 81.0+ for muxing into MKV
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
                return
            }
            "custom" {
                $this._cli = "hqdn3d=$($this._customParams)"
                return
            }
            "ultralight" {
                $this.luma_spatial = 1
                $this.chroma_spatial = 0.7
                $this.luma_tmp = 1
                $this.chroma_tmp = 2
            }
            "weak" {
                $this.luma_spatial = 1.5
                $this.chroma_spatial = 0.8
                $this.luma_tmp = 1.5
                $this.chroma_tmp = 2.5
            }
            "light" {
                $this.luma_spatial = 2
                $this.chroma_spatial = 1
                $this.luma_tmp = 2
                $this.chroma_tmp = 3
            }
            "medium" {
                $this.luma_spatial = 3
                $this.chroma_spatial = 2
                $this.luma_tmp = 2
                $this.chroma_tmp = 3
            }
            "strong" {
                $this.luma_spatial = 7
                $this.chroma_spatial = 7
                $this.luma_tmp = 5
                $this.chroma_tmp = 5
            }
            default { throw "ERROR: Unknown denoise preset" }
        }
        $this._cli = "hqdn3d=$($this.luma_spatial):$($this.chroma_spatial):$($this.luma_tmp):$($this.chroma_tmp)"
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
    [string]$FrameRate = "24";
    [codec]$Codec = [codec]::libx265;
    [int16]$Quantanizer = 22;
    [bool]$Enable10bit = $true;
    [bool]$Pulldown = $false;
    [String]$CustomFilter = "";
    [String]$CustomModifier = "";
    [io.fileinfo]$SourceFileAVS;
    [ValidateSet('.mkv', '.mp4', '.hevc', '.264', '.ivf', '.266')]
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
        if ($this.FPSMode -ne "auto") { $modifiers += "-fps_mode $($this.FPSMode)" }
        if ($this.Resize.Enabled -and $($this.Resize.Method)) { $modifiers += "-sws_flags $($this.Resize.Method)" }

        # Codec-specific: preset and tune
        $presetCli = ""
        $tuneCli = ""
        $qualityCli = "-crf $($this.Quantanizer)"
        switch ($this.Codec) {
            ([codec]::libsvtav1) {
                # SVT-AV1: preset is numeric 0-13
                $av1PresetMap = @{
                    [Presets]::ultrafast = 12; [Presets]::superfast = 10; [Presets]::veryfast = 9;
                    [Presets]::faster = 8; [Presets]::fast = 7; [Presets]::medium = 6;
                    [Presets]::slow = 5; [Presets]::slower = 4; [Presets]::veryslow = 3;
                    [Presets]::placebo = 2
                }
                $presetCli = "-preset $($av1PresetMap[$this.Preset])"
                # SVT-AV1: tune via -svtav1-params (requires SVT-AV1 2.0+ for variance-boost, 1.8+ for qm)
                $av1Params = @("enable-variance-boost=1", "enable-qm=1", "sharpness=1", "tf-strength=1")
                switch ($this.Tune) {
                    "grain"     { $av1Params += "film-grain=8" }
                    "film"      { $av1Params += "film-grain=4" }
                    "animation" { }
                    "psnr"      { $av1Params = @("tune=1") }
                    "ssim"      { $av1Params += "tune=2" }
                    default     { }
                }
                if ($av1Params.Count -gt 0) { $tuneCli = "-svtav1-params ""$([string]::Join(':', $av1Params))""" }
            }
            ([codec]::libvvenc) {
                # VVC: preset is 0-4 (faster/fast/medium/slow/slower)
                $vvcPresetMap = @{
                    [Presets]::ultrafast = 0; [Presets]::superfast = 0; [Presets]::veryfast = 0;
                    [Presets]::faster = 0; [Presets]::fast = 1; [Presets]::medium = 2;
                    [Presets]::slow = 3; [Presets]::slower = 4; [Presets]::veryslow = 4;
                    [Presets]::placebo = 4
                }
                $presetCli = "-preset $($vvcPresetMap[$this.Preset])"
                $qualityCli = "-qp $($this.Quantanizer)"
                if ($this.Tune -eq "psnr") { $tuneCli = "-qpa 0" } else { $tuneCli = "-qpa 1" }
            }
            default {
                # x264/x265: preset by name, tune by name
                $presetCli = "-preset $($this.Preset)"
                if ($this.Tune -ne "none") { $tuneCli = "-tune $($this.Tune)" }
            }
        }

        $videoModifier = ""
        $allModifiers = $modifiers + @($presetCli, $tuneCli) | Where-Object { $_ }
        if ($allModifiers.Count -gt 0) { $videoModifier = [string]::Join(" ", $allModifiers) }
        Write-Verbose "Modifiers CLI: $($videoModifier)"

        # Encoding
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
#        if ($this.FramRate -gt 0) { $FramRate = "-r $($this.FramRate)" } else { $FramRate = "" }
        $startInfo.Arguments = "-r $($this.FrameRate) -i ""$($this.SourceFileAVS.FullName)"" -c:v $($this.Codec) $qualityCli $videoModifier $($this.CustomModifier) $videofilter -an -sn -dn -r $($this.FrameRate) ""$DestinationFile"""
#        $startInfo.Arguments = "$FramRate -i ""$($this.SourceFileAVS.FullName)"" -c:v $($this.Codec) -crf $($this.Quantanizer) -preset $($this.Preset) $videoModifier $($this.CustomModifier) $videofilter -an -sn -dn $FramRate ""$DestinationFile"""
        $startInfo.FileName = $this.ffmpeg_path
        Write-Verbose "Executing: $($startInfo.FileName) $($startInfo.Arguments)"
        if (-not $this.DryMode) {
            $startInfo.UseShellExecute = $false
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $startInfo
            $process.Start() | Out-Null
            $process.PriorityClass = $this.ProcessPriority
            $this.EncProcess = $process
            $process.WaitForExit()
            if ($process.ExitCode -ne 0) { throw "ffmpeg failed with exit code $($process.ExitCode) for $($this.SourceFileAVS.Name)" }
            if (-not (Test-Path -LiteralPath $DestinationFile) -or (Get-Item -LiteralPath $DestinationFile).Length -eq 0) { throw "File $($this.SourceFileAVS.Name) hasn't been compressed." }
        }
    }
}


#$res = [ffmpeg]::new("D:\1\ffmpeg_64.exe")
#$res.Tune = [tune]::animation
#$res.Codec = [codec]::libx264;
#$res.SourceFileAVS = "D:\1\1.m4v"
#$res.DestinationFileName = "D:\Multimedia\Programs\Utils\temp\test.hevc"
#$res.Compress()
