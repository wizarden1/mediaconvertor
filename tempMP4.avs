#Import("C:\Multimedia\Programs\AviSynth\plugins\global.avs")
DirectShowSource("temp\tempmp4.mp4")
#Trim(0,100)
#KillAudio()
#ChangeFPS(15)
#ConvertToYV12()
ConvertToYUY2()
#ConvertToMono()
#ResampleAudio(22050)
Trim(067740,314733)

#067740
#314733-378321