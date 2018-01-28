rem ffmpeg -i "concat:input0.mp3|input1.mp3|input2.mp3" -f wav - | neroAacEnc -if - -ignorelength output.m4b
ffmpeg -i "001.mp3" -f wav - | neroAacEnc -if - -ignorelength output.m4b