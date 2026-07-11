@echo off

set PATH=C:\Program Files\ffmpeg\SVT-AV1-HDR\bin;%PATH%
::	necessary to point to new FFmpeg build
::	source	https://github.com/juliobbv-p/svt-av1-hdr

pushd %~dp1
set folder=Re-encode
CALL :FOLDcheck "%folder%"

:start
TITLE Re-encode AV1 - %~n1

set FILT=setpts=PTS-STARTPTS
REM set FILT=%FILT%,fieldmatch=mode=pc_n_ub:combmatch=full:combpel=70
::	better detelecine approach that only affects the interlaced frames
::		apparently telecining can mix interlaced and progressive, so this checks the frame type
::		https://www.reddit.com/r/ffmpeg/comments/d3te9l/how_to_tell_if_a_source_needs_to_be_detelecined/
::	combine with some deinterlace method, such as nnedi below
REM set FILT=%FILT%,nnedi=weights=nnedi3_weights.bin:deint=interlaced
::	for nnedi de-interlacing
::	weights file from: https://github.com/dubhater/vapoursynth-nnedi3/blob/master/src/nnedi3_weights.bin
::	can use "../nnedi3_weights.bin" to go up a folder
REM set FILT=%FILT%,decimate
::	in theory will convert back to 24 FPS, but it can introduce jerkiness, depending on source
REM set FILT=%FILT%,detelecine
::	undoes the 3:2 pulldown to make 24 FPS from 30 FPS on many DVDs, but not as good as decimate
::	may require "-max_interleave_delta 0" added ahead of AV.mkv output
REM set FILT=%FILT%, libplacebo=w=-1:h=1080:color_primaries=bt709:color_trc=bt709:colorspace=bt709:tonemapping=bt.2446a:downscaler=lanczos:format=yuv420p
::	for converting HDR to SDR. From https://gist.github.com/goyuix/033d35846b05733d77f568b754e7c3ea
REM set FILT=%FILT%[proc],[proc][0:s:0]overlay
::	burns in Blu-ray subtitles
::	requires filter_complex

CALL :VIDheight "%~1" height
REM set height=720
::	can be used with AV1svtscale

set rate=3000
if %height% LEQ 1080 set rate=2500

REM if %height% LEQ 720 set rate=2000k
if %height% LEQ 720 set rate=1750

REM if %height% LEQ 480 set rate=2000k
if %height% LEQ 480 set rate=1000

REM set FILT=%FILT%,atadenoise
REM set FILT=%FILT%,hqdn3d=luma_spatial=1
::	effectively removes noise, but potentially detail
::	unconvinced photon-noise is capable of restoring it

set cHVS=1
::	whether to use a more complex Human Visual System model. Default 0 but likely 1 will be better. May be bad for grain retention.
REM set QPscale=0
::	increases consistency but lowers average quality. 0-3 with 3 being the strongest. 3 can be best for high CRF values
REM set QPlum=0
::	improves quality of dark scenes by adjusting QP based on frame luminance
set NAF=1
::	controls noise detection and can impact fidelity with tune 0 default now 0 for off, with 1 being on and 2 being default behavior
REM set CDEFscl=15
::	CDEF scaling for controlling the feature's strength. Lower values improve sharpness, risk haloing. 1-30, (15 default). Only SVT-AV1 HDR 4.0.1+.
REM set VBS=3
::	boosts the bit allocation for low-contrast areas. Options are 1, 2 (default), 3, 4
REM set VO=4
::	--variance-octile is 1-8 (default 5) with lower preserving more detail
REM set GRAIN=25
::	Uses grain synthesis to add photon noise to the resulting encode. Takes a strength value 0-50
set PHOTON=40
::	add photon noise. finer than film-grain but no compute involved. 0-200.
REM set PHOSIZ=13
::	set size of noise grain. -1 auto. 0-13.
REM set PHOCHR=0
::	enable chroma noise table. -1 on and default. 0-200 for a strength independent of PHOTON
REM set DNR=1
::	enable the denoising filter
set NOISENORM=4
::	boosts high frequency detail to preserve detail. 1 is default, 4 is max. 3 is recommended for tunes 0 and 3.
set PSYRD=1.0
::	psychovisual rate distortion intended to preserve high-frequency detail. 1.0 is default, 8.0 is max. >=0.6 enables a high-quality mode.
REM set SPYRD=1
::	alternate psychovisual rate distortion with greater potential and risk of artifacts, with 0 off, 1 aggressive, 2 transform-size only, and 3 is less aggressive
::		renamed to tx-bias
set HQ=Y
::	applies hbd-mds=1:enable-dlf=2, slower but higher quality
set	TQ=Y
::	applies enable-tf=0:enable-restoration=0:enable-cdef=0 from TUNE 4
::	TUNE 5 also applies tune 0, PSYRD 4.0, and SPYRD 1

set MISC=

set TUNE=0
::	tune 5 is a Film Grain Tune, but use toggles instead

set SVTparam=
set SVTconfig=
if not "%cHVS%"=="" set SVTparam=%SVTparam%:complex-hvs=%cHVS%
if not "%NOISENORM%"=="" set SVTparam=%SVTparam%:noise-norm-strength=%NOISENORM%
if not "%PSYRD%"=="" set SVTparam=%SVTparam%:ac-bias=%PSYRD%
if not "%TUNE%"=="" (
	set SVTparam=%SVTparam%:tune=%TUNE%
	set SVTconfig=%SVTconfig% %TUNE%
	)
if not "%SPYRD%"=="" (
	set SVTparam=%SVTparam%:tx-bias=%SPYRD%
	set SVTconfig=%SVTconfig% -SPY %SPYRD%
	)
if not "%NAF%"=="" (
	set SVTparam=%SVTparam%:noise-adaptive-filtering=%NAF%
	set SVTconfig=%SVTconfig% -NAF %NAF%
	)
if not "%QPscale%"=="" (
	set SVTparam=%SVTparam%:qp-scale-compress-strength=%QPscale%
	set SVTconfig=%SVTconfig% -QPscale %QPscale%
	)
if not "%QPlum%"=="" (
	set SVTparam=%SVTparam%:luminance-qp-bias=%QPlum%
	set SVTconfig=%SVTconfig% -QPlum %QPlum%
	)
if not "%CDEFscl%"=="" (
	set SVTparam=%SVTparam%:cdef-scaling=%CDEFscl%
	set SVTconfig=%SVTconfig% -CDEFscl %CDEFscl%
	)
if not "%VBS%"=="" (
	set SVTparam=%SVTparam%:variance-boost-strength=%VBS%
	set SVTconfig=%SVTconfig% -VBS %VBS%
	)
if not "%VO%"=="" (
	set SVTparam=%SVTparam%:variance-octile=%VO%
	set SVTconfig=%SVTconfig% -VO %VO%
	)
if not "%GRAIN%"=="" (
	set SVTparam=%SVTparam%:film-grain=%GRAIN%
	set SVTconfig=%SVTconfig% -FG %GRAIN%
	)
if not "%PHOTON%"=="" (
	set SVTparam=%SVTparam%:noise=%PHOTON%
	set SVTconfig=%SVTconfig% -PN %PHOTON%
	)
if not "%PHOSIZ%"=="" (
	set SVTparam=%SVTparam%:noise-size=%PHOSIZ%
	set SVTconfig=%SVTconfig% -PS %PHOSIZ%
	)
if not "%PHOCHR%"=="" (
	set SVTparam=%SVTparam%:noise-chroma=%PHOCHR%
	set SVTconfig=%SVTconfig% -PNc %PHOCHR%
	)
if "%DNR%"=="1" (
	set SVTparam=%SVTparam%:film-grain-denoise=1
	set SVTconfig=%SVTconfig% DNR
	)
if "%HQ%"=="Y" (
	set SVTparam=%SVTparam%:hbd-mds=1:enable-dlf=2
	set SVTconfig=%SVTconfig% HQ
	)
if "%TQ%"=="Y" (
	set SVTparam=%SVTparam%:enable-tf=0:enable-restoration=0:enable-cdef=0
	set SVTconfig=%SVTconfig% TQ
	)
if not "%MISC%"=="" (
	set SVTparam=%SVTparam%:%MISC%
	set SVTconfig=%SVTconfig% %MISCconfig%
	)


CALL :AUDchannel "%~1" CHAN0 0
CALL :AUDchannel "%~1" CHAN1 1

CALL :RATEopusChan rate0 %CHAN0% 0 0
CALL :RATEopusChan rate1 %CHAN1% 0 0

::	for unusual channel layouts, place in command:
::		-ch_layout:0 X.Y -mapping_family:0 255
::		https://ffmpeg.org/ffmpeg-utils.html#Channel-Layout
::		https://ffmpeg.org/ffmpeg.html#Advanced-Audio-options

set FILTa=
REM set FILTa=-filter:a:0 "volume=0dB"

REM set rate=2500
REM set SVTparam=%SVTparam%:mbr=%rate%
REM set rateOVER=50
REM set SVTparam=%SVTparam%:mbr-overshoot-pct=%rateOVER%
set crf=40
set preset=2
REM set FILT=%FILT%,scale=-4:'min(ih,%scale%)'

ffmpeg -hide_banner -init_hw_device vulkan -i "%~1" -vf "%FILT%" %FILTa% -map 0:v ^
-c:v libsvtav1 -pix_fmt yuv420p10le -crf %crf% -preset %preset% -svtav1-params scd=1%SVTparam% ^
-map 0:a:0 -ac:a:0 %CHAN0% -c:a:0 libopus -b:a:0 %rate0% -vbr 1 -metadata:s:a:0 title="English Dub" ^
-map 0:a:1? -ac:a:1 %CHAN1% -c:a:1 libopus -b:a:1 %rate1% -vbr 1 -metadata:s:a:1 title="Japanese" ^
-map 0:s:1? -metadata:s:s:0 title="Translation - Original" ^
-map 0:s:0? -metadata:s:s:1 title="English - Original" ^
-c:s copy ^
-metadata comment="%preset% %crf% VBR %NOISENORM% %PSYRD%%SVTconfig%%CONFIG%" ^
-disposition:a:0 default "%folder%\%~n1.mkv" -n


shift

if "%~1"=="" goto end
goto start

:end

::pause
exit /B 0

:FOLDcheck <OUTfold>
if NOT EXIST "%~1" mkdir "%~1"
exit/B 0

:FOLDname <folder name>
for %%* in (.) do set name=%%~nx*
set "%~1=%name%"
exit/B 0

:VIDheight <input> <variable>
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=height -select_streams v -i "%~1"') do set OUT=%%I
set /A "%~2=%OUT%"
exit /B 0

:AUDchannel <input> <variable> <stream>
set stream=%~3
if "%stream%"=="" set stream=0
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=channels -select_streams a:%stream% -i "%~1"') do set OUT=%%I
set /A "%~2=%OUT%"
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