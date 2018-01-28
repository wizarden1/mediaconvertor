$mkvmerge = "C:\Multimedia\Programs\mkvtoolnix\mkvmerge.exe"
$debugmode = $false

dir .\in | where {$_.Extension -eq ".mp4"} | foreach-object {
	&$mkvmerge -o $(".\out\" + $($_.BaseName) + ".mkv") "--forced-track" "0:no" "--forced-track" "1:no" "-a" "1" "-d" "0" "-S" "-T" "--no-global-tags" "--no-chapters" "(" $($_.FullName) ")" "--track-order" "0:0,0:1"
}
