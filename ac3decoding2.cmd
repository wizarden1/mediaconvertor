@echo off
start /low /min /wait BeSweet.exe -core( -input "%1" -output "%2" -2ch  ) -azid( -c normal -L -3db ) -ota( -hybridgain ) -profile( ~~~~~ Default Profile ~~~~~ )
