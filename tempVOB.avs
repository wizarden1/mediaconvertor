Import("C:\Multimedia\Programs\AviSynth\plugins\global.avs")
#MPEG2Source("temp\temp.vob",idct=6)
DirectShowSource("temp\temp.vob")
#KillAudio()
#ConvertToYV12()
#SmoothDeinterlace(blend=true)
#tdeint()
#ConvertToMono()
#ConvertToMono()
#ResampleAudio(22050)
#ChangeFPS(15)
#AssumeFPS(5)
#DupMC(log="blah.dup.txt")

# 16:9
#Lanczos4Resize(720,400)
#Lanczos4Resize(704,396)
# 4:3
Lanczos4Resize(640,480)