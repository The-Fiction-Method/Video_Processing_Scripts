@echo off

set rate265=3500k
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

set rate=%rate265%
CALL :VIDheight "%~1" height
REM set height=720
::	can be used with X265scale

if %height% LEQ 1080 set rate=3000k
if %height% LEQ 720 set rate=2500k
if %height% LEQ 480 set rate=1500k

:ENC
CALL :AUDchannel "%~1" CHAN
CALL :RATEopusChan rateA %CHAN% 0 0
::	for unusual channel layouts, place in command:
::		-ch_layout:0 X.Y -mapping_family:0 255
::		https://ffmpeg.org/ffmpeg-utils.html#Channel-Layout
::		https://ffmpeg.org/ffmpeg.html#Advanced-Audio-options

::	with either the stereo or mono bitrate set to 0, rateA will be blank and the defaults are used
REM set TUNE=grain
::	control if x265's film grain tuning should be used

REM set FILT=%FILT%,atadenoise
REM set FILT=%FILT%,hqdn3d=luma_spatial=1
::	effectively removes noise, but potentially detail

set AQmode=4
::	adaptive quantization mode, default 2, 4 is auto-variance with edge info, 3 is auto-variance with bias for dark scenes
REM set PSYRD=3.0
::	rate distoration. 0 to 5.0, default 2.0
REM set bFRAME=5
::	controlling b-frame number. 5 suggested for live action, CIG. 8 suggested for animation
REM if NOT "%PARAM%"=="" set PARAM=-x265-params %PARAM%

set FILTa=
REM set FILTa=-af "volume=0dB"

::	<rate> <crf> <preset>
CALL :X265process "%~1" %rate% 18
REM CALL :X265pass "%~1" %rate%

::	<scale> <rate> <crf> <preset>
REM CALL :X265scale "%~1" %height% %rate%
REM CALL :X265passscale "%~1" %height% %rate%

::	<crop> <rate> <crf> <preset>
REM CALL :X265crop "%~1" 72 %rate%
REM CALL :X265passcrop "%~1" 72 %rate%

shift

if "%~1"=="" goto end
goto start

:end

::pause
exit /B 0

CALL :VIDrate "%~1" rate
REM set /A rate=%rate% / 2
::	can be used to simply divide the original bitrate by some value

:FOLDcheck <OUTfold>
if NOT EXIST "%~1" mkdir "%~1"
exit/B 0

:FOLDname <folder name>
for %%* in (.) do set name=%%~nx*
set "%~1=%name%"
exit/B 0

:conSET <rate> <crf> <preset>
set rate=%~1
set crf=%~2
set preset=%~3
exit /B 0

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


:X265process <input> <rate> <crf> <preset>
set rate=%~2
if NOT "%rate%"=="" set rate=-maxrate %rate% -bufsize %rate%
set crf=%~3
if "%crf%"=="" set crf=18
set preset=%~4
if "%preset%"=="" set preset=medium
::	sets values to better names, checks if values have been given and sets default if necessary
::	quotes around the variable are necessary

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

ffmpeg -hide_banner -init_hw_device vulkan -i "%~1" -vf "%FILT%" %FILTa% -c:s copy ^
-c:v libx265 -pix_fmt yuv420p10le -crf %crf% %rate% -preset %preset% %X265param% %x265TUNE% ^
-ac %CHAN% -c:a libopus %opusMF% -b:a %rateA% -vbr 1 ^
-metadata comment="%preset% %crf% %rate%%X265config%" ^
"%folder%\%~n1.mkv" -n
::	necessary to indicate audio channels or libopus fails with multi-channel
exit /B 0

:X265scale <input> <scale> <rate> <crf> <preset>
set scale=%~2
if NOT "%scale%"=="" set FILT=%FILT%,scale=-4:'min(ih,%scale%)'
set rate=%~3
set crf=%~4
set preset=%~5

CALL :X265process "%~1" %rate% %crf% %preset%

exit /B 0

:X265crop <input> <crop> <rate> <crf> <preset>
set crop=%~2
if NOT "%crop%"=="" set FILT=%FILT%,crop=in_w:in_h-2*%crop%:0:%crop%
set rate=%~3
set crf=%~4
set preset=%~5

CALL :X265process "%~1" %rate% %crf% %preset%

exit /B 0


:X265pass <input> <rate> <crf> <preset>
set rate=%~2
set rateO=%~2
if NOT "%rate%"=="" set rate=-maxrate %rate% -bufsize %rate%
set crf=%~3
if "%crf%"=="" set crf=18
set preset=%~4
if "%preset%"=="" set preset=medium

if "%PSYRD%"=="" (set PSYRD=2.0)
set X265param=:psy-rd=%PSYRD%
set X265config= -PSY %PSYRD%

if not "%AQmode%"=="" (
	set X265param=%X265param%:aq-mode=%AQmode%
	set X265config=%X265config% -AQ %AQmode%
	)
if not "%bFRAME%"=="" (
	set X265param=%X265param%:b-frames=%bFRAME%
	set X265config=%X265config% -bF %bFRAME%
	)

ffmpeg -hide_banner -init_hw_device vulkan -i "%~1" -filter_complex "%FILT%" -an ^
-c:v libx265 -pix_fmt yuv420p10le -crf %crf% %rate% -preset %preset% %TUNE% ^
-x265-params pass=1:stats="%~n1.log"%X265param% -f null NUL

ffmpeg -hide_banner -init_hw_device vulkan -i "%~1" -filter_complex "%FILT%" -c:s copy ^
-c:v libx265 -pix_fmt yuv420p10le -crf %crf% %rate% -preset %preset% %TUNE% ^
-x265-params pass=2:stats="%~n1.log"%X265param% ^
-ac %CHAN% -c:a libopus %opusMF% %rateA% -vbr 1 "%folder%\%~n1.mkv"

REM del "%~n1.log.cutree"	&	del "%~n1.log"
exit /B 0

:X265passscale <input> <scale> <rate> <crf> <preset>
set scale=%~2
if NOT "%scale%"=="" set FILT=%FILT%,scale=-4:'min(ih,%scale%)'
set rate=%~3
set crf=%~4
set preset=%~5

CALL :X265pass "%~1" %rate% %crf% %preset%

exit /B 0

:X265passcrop <input> <crop> <rate> <crf> <preset>
set crop=%~2
if NOT "%crop%"=="" set FILT=%FILT%,crop=in_w:in_h-2*%crop%:0:%crop%
set rate=%~3
if "%rate%"=="" set rate=%rate265%
set crf=%~4
if "%crf%"=="" set crf=18
set preset=%~5
if "%preset%"=="" set preset=medium

CALL :X265pass "%~1" %rate% %crf% %preset%

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