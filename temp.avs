Import("C:\Multimedia\Programs\AviSynth\plugins\global.avs")
DirectShowSource("temp\2790894510.aac")
#Trim(0,100)
#KillAudio()
#ChangeFPS(15)
#ConvertToYV12()
#ConvertToMono()
#ResampleAudio(22050)
