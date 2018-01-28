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
:Main Foreach ($file in $files) {
  $sourcefile = "$($file.FullName)"
  $destfile = "$($file.FullName).xml"

  Write-Output "Extracting Chapters from: $($file.Name)"
#echo $mkvextract_path "chapters ""$sourcefile"" -r ""$destfile"""
  Start-Process -Wait -NoNewWindow -FilePath $mkvextract_path -ArgumentList "chapters ""$sourcefile"" -r ""$destfile"""
}
