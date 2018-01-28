#Version 1.0

#Config


#Advanced Config
$root_path = "C:\Multimedia\Programs\Utils"
$enctemp = Join-Path $root_path "temp"
$out = $(Join-Path $root_path "out")
$in = $(Join-Path $root_path "in")
$debug=$false
$extension="MKV"

$multimedia = "C:\Multimedia\Programs\mkvtoolnix"
$mkvmerge_path = Join-Path $multimedia "mkvmerge.exe"
$mkvextract_path = Join-Path $multimedia "mkvextract.exe"

$files = dir ".\" | where {$_.Extension -eq ".$extension"}
if ($files.count -eq 0){exit}
if (-not $(Test-Path -LiteralPath ".\out")){md ".\out"}
:Main Foreach ($file in $files) {
  $sourcefile = "$($file.FullName)"
  $destfile = "$($file.Directory)\out\$($file.Name)"
  $chapfile = "$($file.FullName).xml"

  Write-Output "Adding Chapters To: $($file.Name)"
#  echo $mkvmerge_path "-o ""$destfile"" ""--no-chapters"" ""$sourcefile"" ""--chapter-language"" ""eng"" ""--chapters"" ""$chapfile"""
  Start-Process -Wait -NoNewWindow -FilePath $mkvmerge_path -ArgumentList "-o ""$destfile"" ""--no-chapters"" ""$sourcefile"" ""--chapter-language"" ""eng"" ""--chapters"" ""$chapfile"""
#  "C:\Multimedia\Programs\mkvtoolnix\mkvmerge.exe" -o "[Yousei-raws] Robotics;Notes 01 [BDrip 1920x1080 x264 FLAC] (1).mkv"  "--no-chapters" "("  "--track-order" "0:0,0:1" "--chapter-language" "eng" "--chapters" "T:\\3\\[Yousei-raws] Robotics;Notes 01 [BDrip 1920x1080 x264 FLAC].mkv.xml"
}
