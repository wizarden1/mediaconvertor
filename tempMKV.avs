#Import("C:\Multimedia\Programs\AviSynth\plugins\global.avs")
#A = FFAudioSource("temp\tempMKV.mkv")
#V = FFVideoSource("temp\tempMKV.mkv")
#AudioDub(V, A)
#FFIndex("temp\tempMKV.mkv")
#AudioDub(FFmpegSource2("temp\tempMKV.mkv", vtrack = -1, atrack = -2, timecodes="temp\tempMKV.txt"), FFAudioSource("temp\tempMKV.mkv"))
DirectShowSource("temp\tempMKV.mkv")
#, convertfps=true
#FFVideoSource("temp\tempMKV.mkv")
#Trim(0,100)
KillAudio()
#ChangeFPS(15)
ConvertToYV12()
#ConvertToMono()
#ResampleAudio(22050)

#SmoothDeinterlace()
# 16:9
#Lanczos4Resize(720,400)
#Lanczos4Resize(704,396)
# 4:3
#Lanczos4Resize(1280,720)