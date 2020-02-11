#Requires -Version 5

. "C:\Multimedia\Programs\Utils\test\MediaInfoclass.ps1" 
class M4A {
    hidden [string]$eac3to_path;
    [string]$SourceFile;
    [string]$DestinationFileName;

	M4A ([String]$eac3to_path) {
        if (Test-Path $eac3to_path -PathType Leaf){$this.$eac3to_path = $eac3to_path} else {throw "ERROR: Can not access eac3to.exe."}
	}

    Compress () {
    }
}

function Compress-ToM4A
{
	param
	(
		[Parameter(Mandatory = $true, Position = 0)]
		[System.IO.FileInfo]
		[ValidateScript( { ( Test-Path $_ ) } ) ]
		$SourceFile,
		
		[String]
		$DestinationFileName="$($SourceFile.FullName).m4a"
	)
	begin
	{
# Check
		if (-not $(Test-Path $eac3to)) {throw "eac3to.exe not found.";return $false}
	}
	
	process 
	{
		if (-not $(Resolve-Path ([io.fileinfo]$DestinationFileName).DirectoryName | Test-Path)) {return $false}
                if (([io.fileinfo]$DestinationFileName).Extension -eq ".m4a"){$DestinationFileExtension = ".m4a"} else {$DestinationFileExtension = "$(([io.fileinfo]$DestinationFileName).Extension).m4a"}
		$DestinationFile = "$(Join-Path ([io.fileinfo]$DestinationFileName).DirectoryName ([io.fileinfo]$DestinationFileName).BaseName)$DestinationFileExtension"

		Switch ($SourceFile.Extension)
		{
			".AAC"    	{Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile"""}
#						Start-Process -Wait -NoNewWindow -FilePath $faad_path -ArgumentList """$($SourceFile.FullName)"" ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).wav"""
#						Start-Process -Wait -NoNewWindow -FilePath $neroAacEnc_path -ArgumentList "-if ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).wav"" -of ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a"" -ignorelength"
			".PCM"    	{Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile"""}
#			".Vorbis" 	{
#						Start-Process -Wait -NoNewWindow -FilePath $oggdec_path -ArgumentList "--wavout ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).wav"" ""$($SourceFile.FullName)"""
#						Start-Process -Wait -NoNewWindow -FilePath $neroAacEnc_path -ArgumentList "-if ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).wav"" -of ""$(Join-Path $OutputDir.FullName $SourceFile.BaseName).m4a"" -ignorelength"
#					}
			".FLAC"   	{Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile"""}
			".AC-3"   	{Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile"""}
			".DTS"    	{Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile"""}
			".MPEG Audio" 	{Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile"""}
			".TrueHD"     	{Start-Process -Wait -NoNewWindow -FilePath $eac3to -ArgumentList """$($SourceFile.FullName)"" ""$DestinationFile"""}
			default	{throw "Unknown Audio Codec.";return $false}
		}
		if (-not $(Test-Path -LiteralPath $DestinationFile )) {throw "File $($SourceFile.Name) hasn't been recompressed.";return $false}
	}
	end
	{
		return $true
	}

}
