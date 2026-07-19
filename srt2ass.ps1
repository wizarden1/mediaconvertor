$sfiles = Get-ChildItem .\in | Where-Object { $_.Extension -eq ".srt" }

$root_path = $(Get-Location).Path
$ffmpeg_path = Join-Path $root_path "tools_64\ffmpeg.exe"

foreach ($sfile in $sfiles)
{
    $dfile = "$($sfile.BaseName).ass"
    & $ffmpeg_path -i "$($sfile.FullName)" ".\out\$dfile"
}

