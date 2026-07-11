@echo off

set rate265=3000k
::	fallback bit rate

set folder=Re-encode
CALL :FOLDcheck "%folder%"

:start
TITLE Re-encode x265 - %~n1

set FILT=setpts=PTS-STARTPTS
REM set FILT=%FILT%,fieldmatch=mode=pc_n_ub:combmatch=full:combpel=70
::	better detelecine approach that only affects the interlaced frames
::		apparently telecining can mix interlaced and progressive, so this checks the frame type
::		https://www.reddit.com/r/ffmpeg/comments/d3te9l/how_to_tell_if_a_source_needs_to_be_detelecined/
::	combine with some deinterlace method, such as nnedi below
REM set FILT=%FILT%,nnedi=weights=nnedi3_weights.bin:deint=interlaced
::	for nnedi de-interlacing. Weights file from: https://github.com/dubhater/vapoursynth-nnedi3/blob/master/src/nnedi3_weights.bin
::	can use "../nnedi3_weights.bin" to go up a folder
REM set FILT=%FILT%,decimate
::	in theory will convert back to 24 FPS, but it can introduce jerkiness, depending on source
REM set FILT=%FILT%,detelecine
::	undoes the 3:2 pulldown to make 24 FPS from 30 FPS on many DVDs, but not as good as decimate
REM set FILT=%FILT%, libplacebo=w=-1:h='min(ih,1080)':color_primaries=bt709:color_trc=bt709:colorspace=bt709:tonemapping=bt.2446a:downscaler=lanczos:format=yuv420p10le
::	for converting HDR to SDR and downscale to 1080p, but never up. From https://gist.github.com/goyuix/033d35846b05733d77f568b754e7c3ea
REM set FILT=%FILT%[proc],[proc][0:s:0]overlay
::	burns in Blu-ray subtitles
::	requires filter_complex

set TUNE=

CALL :VIDheight "%~1" height
REM set height=720
set rate=%rate265%

if %height% LEQ 1080 set rate=3000k
if %height% LEQ 720 set rate=2500k
if %height% LEQ 480 set rate=1500k

:ENC
REM set FILT=%FILT%,atadenoise
REM set FILT=%FILT%,hqdn3d=luma_spatial=1
::	effectively removes noise, but potentially detail
::	unconvinced photon-noise is capable of restoring it

REM set TUNE=grain
::	control if x265's film grain tuning should be used

set AQmode=4
::	adaptive quantization mode, default 2, 4 is auto-variance with edge info, 3 is auto-variance with bias for dark scenes
REM set PSYRD=3.0
::	rate distoration. 0 to 5.0, default 2.0
REM set bFRAME=5
::	controlling b-frame number. 5 suggested for live action, CIG. 8 suggested for animation

if "%PSYRD%"=="" (set PSYRD=2.0)
set X265param=-x265-params psy-rd=%PSYRD%
set X265config= -PSY %PSYRD%

if not "%AQmode%"=="" (
	set X265param=%X265param%:aq-mode=%AQmode%
	set X265config=%X265config% -AQ %AQmode%
	)
if not "%bFRAME%"=="" (
	set X265param=%X265param%:b-frames=%bFRAME%
	set X265config=%X265config% -bF %bFRAME%
	)
if not "%TUNE%"=="" (
	set X265config=%X265config% %TUNE%
	set x265TUNE=-tune %TUNE%
	)

CALL :AUDchannel "%~1" CHAN0 0
CALL :AUDchannel "%~1" CHAN1 1
CALL :AUDchannel "%~1" CHAN2 2
CALL :AUDchannel "%~1" CHAN3 3
CALL :AUDchannel "%~1" CHAN4 4

CALL :RATEopusChan rate0 %CHAN0% 0 0
CALL :RATEopusChan rate1 %CHAN1% 0 0
CALL :RATEopusChan rate2 %CHAN2% 0 0
CALL :RATEopusChan rate3 %CHAN3% 0 0
CALL :RATEopusChan rate4 %CHAN4% 0 0

::	for unusual channel layouts, place in command:
::		-ch_layout:0 X.Y -mapping_family:0 255
::		https://ffmpeg.org/ffmpeg-utils.html#Channel-Layout
::		https://ffmpeg.org/ffmpeg.html#Advanced-Audio-options

set FILTa=
REM set FILTa=-filter:a:0 "volume=0dB"

REM set rate=3000k
set crf=18
set preset=medium
REM set FILT=%FILT%,scale=-4:'min(ih,%scale%)'

::	uncomment for 2-pass encoding
::		doesn't immediately work with new PARAMS control
REM ffmpeg -hide_banner -init_hw_device vulkan -i "%~1" -vf "%FILT%" -an ^
REM -c:v libx265 -pix_fmt yuv420p10le -crf %crf% -maxrate %rate% -bufsize %rate% -preset %preset% ^
REM -x265-params pass=1:stats="%~n1.log" -f null NUL
::	move to after line 45 (beginning -map 0:v) and uncomment
REM -x265-params pass=2:stats="%~n1.log" ^
ffmpeg -hide_banner -init_hw_device vulkan -i "%~1" -vf "%FILT%" %FILTa% ^
-map 0:v -c:v libx265 -pix_fmt yuv420p10le -crf %crf% -maxrate %rate% -bufsize %rate% -preset %preset% %X265param% %x265TUNE% ^
-map 0:a:0 -ac:a:0 %CHAN0% -c:a:0 libopus -b:a:0 %rate0% -vbr 1 ^
-map 0:a:1? -ac:a:1 %CHAN1% -c:a:1 libopus -b:a:1 %rate1% -vbr 1 -metadata:s:a:1 title="Commentary - Philosophers" ^
-map 0:a:2? -ac:a:2 %CHAN2% -c:a:2 libopus -b:a:2 %rate2% -vbr 1 -metadata:s:a:2 title="Commentary - Critics" ^
-map 0:a:3? -ac:a:3 %CHAN3% -c:a:3 libopus -b:a:3 %rate3% -vbr 1 -metadata:s:a:3 title="Commentary - Cast and Crew" ^
-map 0:a:4? -ac:a:4 %CHAN4% -c:a:4 libopus -b:a:4 %rate4% -vbr 1 -metadata:s:a:4 title="Commentary - Composer Music Only" ^
-map 0:s? -c:s copy ^
-metadata comment="%preset% %crf% %rate%%X265config%" ^
-disposition:a:0 default "%folder%\%~n1.mkv" -n
REM -map 0:v -map 0:a -map 1:a -map 0:s -c:s copy -map_metadata 0 -map_metadata 1 ^

REM del "%~n1.log.cutree" & del "%~n1.log"
shift

if "%~1"=="" goto end
goto start

:end

::pause
exit/B 0

CALL :VIDrate "%~1" rate
REM set /A rate=%rate% / 2

:FOLDcheck <OUTfold>
if NOT EXIST "%~1" mkdir "%~1"
exit/B 0

:FOLDname <folder name>
for %%* in (.) do set name=%%~nx*
set "%~1=%name%"
exit/B 0

:RATEopusChan <variable> <tracks> <pair> <mono>
::	96 per stereo pair, 64 per mono channel (center, subwoofer)
set CHANS=%~2
if "%CHANS%"=="" set CHANS=%CHAN%
set MF=
REM if %CHANS% GTR 2 set MF=-mapping_family 1
::	FFmpeg should handle this automatically in most cases
set pair=%~3
if "%pair%"=="0" set /A pair=96
if "%pair%"=="" set /A pair=96
set mono=%~4
if "%mono%"=="0" set /A mono=64
if "%mono%"=="" set /A mono=64

if %CHANS% LEQ 8 set /A OUT=%pair%*3 + %mono%*2
if %CHANS% LEQ 6 set /A OUT=%pair%*2 + %mono%*2
if %CHANS% LEQ 2 set /A OUT=%pair%

if %OUT% GEQ 512 set OUT=512
::	libopus has a maximum bitrate
set "%~1=%OUT%k%MF%"
if %pair%==0 set "%~1=%MF%" & if %mono%==0 set "%~1=%MF%"
::	can be used to let libopus use its defaults
exit /B 0

:VIDheight <input> <heigh>
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=height -select_streams v -i "%~1"') do set OUT=%%I
set /A "%~2=%OUT%"
exit /B 0

:VIDrate <input> <heigh>
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=bit_rate -select_streams v -i "%~1"') do set OUT=%%I
set /A "%~2=%OUT%"
exit /B 0

:AUDchannel <input> <variable> <stream>
set stream=%~3
if "%stream%"=="" set stream=0
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=channels -select_streams a:%stream% -i "%~1"') do set OUT=%%I
set /A "%~2=%OUT%"
exit /B 0