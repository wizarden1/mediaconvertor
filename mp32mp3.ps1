#Version 1.0
$lame_path = "C:\Multimedia\Programs\Utils\lame.exe"
Add-Type -Path C:\Multimedia\Programs\Utils\taglib-sharp.dll

#Config
$del_original=$true
$enctemp="temp"
$debug=$false
$extension="MP3"

#Audio
#preset - medium,[fast] standard,[fast] extreme,insane,<bitrate>,cbr <bitrate>,phone,voice,fm/radio/tape,hifi,cd,studio
$preset="voice"

Remove-Item .\$enctemp\*

dir .\in\ | where {$_.Extension -eq ".$extension"} | foreach-object {
	Start-Process -Wait -NoNewWindow -FilePath "fsutil" -ArgumentList "hardlink create ""$enctemp\temp$extension.$extension"" ""$($_.FullName)"""
# Audio Encoding
	Start-Process -Wait -NoNewWindow -FilePath $lame_path -ArgumentList "--priority 0 -v -p --vbr-new --noreplaygain --preset $preset ""$enctemp\temp$extension.$extension"" ""$enctemp\temp.$extension"""
# Copy Tags
	$fileold = [TagLib.File]::Create("$enctemp\temp$extension.$extension")
	$filenew = [TagLib.File]::Create("$enctemp\temp.$extension")
# Copy Tag Id3v1
	[TagLib.Tag]::Duplicate($fileold.GetTag([TagLib.TagTypes]::Id3v1, $true), $filenew.GetTag([TagLib.TagTypes]::Id3v1, $true), $true)
# Copy Tag Id3v2
	[TagLib.Tag]::Duplicate($fileold.GetTag([TagLib.TagTypes]::Id3v2, $true), $filenew.GetTag([TagLib.TagTypes]::Id3v2, $true), $true)
	$filenew.Save()
# Building Result File
	Move-Item -Path "$enctemp\temp.$extension" -Destination "out\$($_.basename).mp3"
# Removing Temp Files
	if (-not $debug) {
    	Remove-Item .\$enctemp\*
		if ($del_original){Remove-Item -LiteralPath $_.fullname}
	}
}

#Stop-Computer
