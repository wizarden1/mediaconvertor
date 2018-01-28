#Version 1.0
$lame_path = "C:\Multimedia\Programs\Utils\lame.exe"
$flac_path = "C:\Multimedia\Programs\Utils\flac.exe"
Add-Type -Path C:\Multimedia\Programs\Utils\taglib-sharp.dll

#Config
$del_original=$true
$enctemp="temp"
$debug=$false
$extension="FLAC"

#Audio
#preset - medium,[fast] standard,[fast] extreme,insane,<bitrate>,cbr <bitrate>,phone,voice,fm/radio/tape,hifi,cd,studio
$preset="cd"

dir .\in\ | where {$_.Extension -eq ".$extension"} | foreach-object {
    Remove-Item .\$enctemp\*
	Start-Process -Wait -NoNewWindow -FilePath "fsutil" -ArgumentList "hardlink create ""$enctemp\temp$extension.$extension"" ""$($_.FullName)"""
# Audio Decoding
	Start-Process -Wait -NoNewWindow -FilePath $flac_path -ArgumentList "-d ""$enctemp\temp$extension.$extension"""
# Audio Encoding
	Start-Process -Wait -NoNewWindow -FilePath $lame_path -ArgumentList "--priority 0 -v -p --vbr-new --noreplaygain --preset $preset ""$enctemp\temp$extension.WAV"" ""$enctemp\temp.MP3"""
# Copy Tags
	$fileold = [TagLib.File]::Create("$enctemp\temp$extension.$extension")
	$filenew = [TagLib.File]::Create("$enctemp\temp.MP3")
# Copy Tag Id3v1
	[TagLib.Tag]::Duplicate($fileold.GetTag([TagLib.TagTypes]::Id3v1, $true), $filenew.GetTag([TagLib.TagTypes]::Id3v1, $true), $true)
# Copy Tag Id3v2
	[TagLib.Tag]::Duplicate($fileold.GetTag([TagLib.TagTypes]::Id3v2, $true), $filenew.GetTag([TagLib.TagTypes]::Id3v2, $true), $true)
	$filenew.Save()
    Start-Sleep -s 2
# Building Result File
	Move-Item -Path "$enctemp\temp.MP3" -Destination "out\$($_.basename).mp3"
# Removing Temp Files
	if (-not $debug) {
    	Remove-Item .\$enctemp\*
		if ($del_original){Remove-Item -LiteralPath $_.fullname}
	}
}

#Stop-Computer
