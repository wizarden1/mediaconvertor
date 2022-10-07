#Requires -Version 5
#Version 1.0
# 1.0 - Separate config from main program

param (
    [switch]$Verbose = $false,
    [switch]$Debug = $false
)
#Config

#Audio
$take_audio_from_source = $false
#$take_audio_from_source = $true
$take_audio_track_name_from_source = $false
$set_audio_default_by = @("source", "jpn")     #set_audio_default_by:<source|remove|language|trackid>,<language|number of track> example1: @("language","rus")
$set_audio_languages = @($false, "jpn", "jpn") #@("Use manual set","track ID/default","track ID",...)
$select_audio_by = @("language", @("jpn"))     #select_audio_by:<language|trackid|all>,<list of languages|number of tracks> example1: @("all",@("jpn"))
$RecompressMethod = "Decoder"                  #"AviSynth"|"Decoder"
$DecodeAutoMode = "Pattern"                    #"Auto"|"Pattern"|"FFMpeg"|"Eac3to"
$AsyncEncoding = $true

#Video
$take_video_from_source = $false
$video_languages = @($false, "jpn", "jpn") #@("Use manual set","track ID/default","track ID",...)
$set_video_default_by = @("source", "jpn") #set_video_default_by:<source|remove|language|trackid>,<language|number of track> example1: @("language","rus")
$use_timecode_file = $true
$tune = "animation"
#$tune = "grain"                            #tune(x265):animation,grain,psnr,ssim,fastdecode,zerolatency tune(x264):film,animation,grain,stillimage,fastdecode,zerolatency
$DecompressSource = "Direct"	           #"FFVideoSource"|"DirectShowSource"|"Direct"
$Copy_Chapters = $true
$quantanizer = 24
$preset = "medium"		           #ultrafast,superfast,veryfast,faster,fast,medium,slow,slower,veryslow,placebo
#$preset = "ultrafast"
$codec = "libx265"                         #libx264,libx265

#Subtitles
$Copy_Subtitles = $true
$Copy_Subtitles_Name = $false
$set_sub_default_by = @("language", "rus")   #set_sub_default_by:<source|remove|language|trackid>,<language|number of track> example1: @("language","rus")
$Sub_languages = @("rus")                  #@("lng1","lng2","lng3",...)

#Filters
#$crop = @($false,"custom","1424:1070:248:6")    #crop:enabled,mode("ltrb","custom"),(ffmpeg_crop_string|left:top:right:bottom)
$crop = @($false,"ltrb","240:0:240:0")     #crop:enabled,mode("ltrb","custom"),(ffmpeg_crop_string|left:top:right:bottom)
#$resize=@($true,1280,720,"lanczos","")    #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1280,960,"lanczos","")    #resize:enabled,width,height,method,", additional parametrs"
$resize = @($false, 0, 0, "lanczos", "")   #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1024,768,"lanczos","")    #resize:enabled,width,height,method,", additional parametrs"
#$resize=@($true,1280,544,"lanczos","")    #resize:enabled,width,height,method,", additional parametrs"
$pulldown=$false
$deinterlace = @($false, "send_frame", "auto", "all") #(send_frame, send_field, send_frame_nospatial, send_field_nospatial), (tff, bff, auto), (all, interlaced)
$denoise = @($false, "default", "4:3:6:4.5") # denoiser hqdn3d (enable, preset, "custom values") presets = custom, ultralight, light, medium, strong, weak, default
$CustomFilter = ""

#Modifiers
#$fps_mode = "passthrough"                     #passthrough, cfr, vfr, drop, auto     #Required for vfr video
$fps_mode = "auto"                     #passthrough, cfr, vfr, drop, auto     #Required for vfr video
$CustomModifier = ""

#Advanced Config
$del_original = $true
$use_json = $false                         #Use title of series from json
$json_file = ""                            #"title.json" #[{"file": "Overlord - 01 [Beatrice-Raws].mkv","subtitle_file": "Overlord - 01 [Beatrice-Raws].ass","title": "End and Beginning"},{...}]
#$VerbosePreference = "Continue"            #Enable Verbose mode
$shutdown = $false

##############################################################################################################################################
# Start Main Program
$mainprg = "EncoderPrg"
$mainprg_path = Join-Path $(Get-Location).Path "libps\$mainprg.ps1"
if (-not $(Test-Path -LiteralPath $mainprg_path)) { Write-Error "$mainprg not found"; break }
Write-Verbose "Loading $mainprg.ps1"
Invoke-Expression $(Get-Content -Raw $mainprg_path)
