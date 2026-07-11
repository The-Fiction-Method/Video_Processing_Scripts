@echo off

set PATH=C:\Program Files\ffmpeg\SVT-AV1-HDR\bin;%PATH%
::	necessary to point to new FFmpeg build
::	source	https://github.com/juliobbv-p/svt-av1-hdr

pushd %~dp1
set folder=Re-encode SVT-AV1 HDR
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
::	for nnedi de-interlacing. Weights file from: https://github.com/dubhater/vapoursynth-nnedi3/blob/master/src/nnedi3_weights.bin
::	can use "../nnedi3_weights.bin" to go up a folder
REM set FILT=%FILT%,decimate
::	in theory will convert back to 24 FPS, but it can introduce jerkiness, depending on source
REM set FILT=%FILT%,detelecine
::	undoes the 3:2 pulldown to make 24 FPS from 30 FPS on many DVDs, but not as good as decimate
REM set FILT=%FILT%, libplacebo=w=-1:h='min(ih,1080)':color_primaries=bt709:color_trc=bt709:colorspace=bt709:tonemapping=bt.2446a:downscaler=lanczos:format=yuv420p10le
::	for converting HDR to SDR and downscale to 1080p, but never up. From https://gist.github.com/goyuix/033d35846b05733d77f568b754e7c3ea

CALL :VIDheight "%~1" height
REM set height=720
::	can be used with AV1svtVBRscale

set rateO=3000
if %height% LEQ 1080 set rateO=2500
if %height% LEQ 720 set rateO=1750
if %height% LEQ 480 set rateO=1000

REM set FILT=%FILT%,atadenoise
REM set FILT=%FILT%,hqdn3d=luma_spatial=1
::	effectively removes noise, but potentially detail

::	https://github.com/juliobbv-p/svt-av1-hdr/blob/main/Docs/Parameters.md
set HQ=Y
::	applies hbd-mds=1:enable-dlf=2, slower but higher quality
set	TQ=Y
::	applies enable-tf=0:enable-restoration=0:enable-cdef=0 from film-grain TUNE
::	film-grain TUNE also applies tune 0, PSYRD 4.0, and SPYRD 1
set cHVS=1
::	whether to use a more complex Human Visual System model. Default 0 but likely 1 will be better. May be bad for grain retention.
set NAF=1
::	controls noise detection and can impact fidelity with tune 0 default now 0 for off, with 1 being on and 2 being default behavior, 3 to impact CDEF only, 4 for restoration only which should help preserve lines
REM set QPscale=0
::	increases consistency but lowers average quality. 0-3 with 3 being the strongest. 3 can be better for high CRF values
REM set CDEFscl=15
::	CDEF scaling for controlling the feature's strength. Lower values improve sharpness, risk haloing. 1-30, (15 default). Only SVT-AV1 HDR 4.0.1+.
REM set VBC=3
::	variance boost curve adjusts bit allocation. 3 is a custom SVT-AV1-HDR curve for perceptual quality. Improves image, but noticable increase to bitrate.
REM set VBS=3
::	boosts the bit allocation for low-contrast areas. Options are 1, 2 (default), 3, 4
REM set VO=4
::	--variance-octile is 1-8 (default 5) with lower preserving more detail
REM set QPlum=0
::	improves quality of dark scenes by adjusting QP based on frame luminance. 0-100.
set GRAIN=25
::	Uses grain synthesis to add photon noise to the resulting encode. Takes a strength value 0-50
REM set PHOTON=100
::	add photon noise. finer than film-grain but no compute involved. 0-200.
REM set PHOSIZ=13
::	set size of noise grain. -1 auto. 0-13.
REM set PHOCHR=0
::	enable chroma noise table. -1 on and default. 0-200 for a strength independent of PHOTON
REM set DNR=1
::	enable the built-in denoising filter
set NOISENORM=2
::	boosts high frequency detail to preserve detail. 1 is default, 4 is max. 0-4.
set PSYRD=1.0
::	psychovisual rate distortion intended to preserve high-frequency detail. 1.0 is default, 8.0 is max. film-grain TUNE overrides this, setting it to 4.0.
REM set SPYRD=1
::	alternate psychovisual rate distortion with greater potential and risk of artifacts, with 0 off, 1 aggressive, 2 transform-size only, and 3 is less aggressive
::		renamed to tx-bias

REM set FILT=%FILT%;volume=0dB

CALL :AUDchannel "%~1" CHAN
CALL :RATEopusChan rateA %CHAN% 0 0

set TUNE=0
::	tune 0 for Visual Quality
::	tune 5 is a Film Grain Tune, but use toggles instead
::	0 = VQ, 1 = PSNR, 2 = SSIM, 3 = IQ (Image Quality), 4 = MS_SSIM, 5 = Film Grain

set MISC=
set MISCconfig=
::	for other random configuration controls
set CONFIG=

::			34		4			3000
::	?scale?	<crf>	<preset>	<rate>
REM CALL :AV1svt "%~1" 34 4
CALL :AV1svt "%~1" 37 4
CALL :AV1svt "%~1" 40 4
REM CALL :AV1svtVBRscale "%~1" 480 40 4
REM CALL :AV1svtMBR "%~1" 34 4 4000
REM CALL :AV1svtMBR "%~1" 37 4 4000
REM CALL :AV1svtMBR "%~1" 40 4 4000
REM CALL :AV1svtMBRscale "%~1" 480 40 4 1000

::	?scale? <rate> <crf> <preset>
::	out of date, do not use
REM CALL :AV1svtpass "%~1" %rate%
REM CALL :AV1svtpassscale "%~1" 1080 %rate%

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

:AV1svt <input> <crf> <preset>
set crf=%~2
if "%crf%"=="" set crf=20
set preset=%~3
if "%preset%"=="" set preset=4
set SVTparam=
set SVTconfig=
set MBRconfig=VBR
if not "%rate%"=="" (
	set SVTparam=%SVTparam%:mbr=%rate%
	set MBRconfig=%rate%
	)
if not "%NOISENORM%"=="" set SVTparam=%SVTparam%:noise-norm-strength=%NOISENORM%
if not "%PSYRD%"=="" set SVTparam=%SVTparam%:ac-bias=%PSYRD%
if not "%cHVS%"=="" (
	set SVTparam=%SVTparam%:complex-hvs=%cHVS%
	if not %cHVS%==1 set SVTconfig=%SVTconfig% -cHVS %cHVS%
	)
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
if not "%VBC%"=="" (
	set SVTparam=%SVTparam%:variance-boost-curve=%VBC%
	set SVTconfig=%SVTconfig% -VBC %VBC%
	)
if not "%rateOVER%"=="" (
	set SVTparam=%SVTparam%:mbr-overshoot-pct=%rateOVER%
	set SVTconfig=%SVTconfig% -OVS %rateOVER%
	)
if not "%MISC%"=="" (
	set SVTparam=%SVTparam%:%MISC%
	set SVTconfig=%SVTconfig% %MISCconfig%
	)

set OUTname=%~n1 - SVT %preset% %crf% %MBRconfig% %NOISENORM% %PSYRD%%SVTconfig%%CONFIG%.mkv

IF EXIST "%folder%\%OUTname%" exit /b 0

ffmpeg -hide_banner -init_hw_device vulkan -i "%~1" -vf "%FILT%" -map 0:v -map 0:s? -c:s copy ^
-c:v libsvtav1 -pix_fmt yuv420p10le -crf %crf% -preset %preset% -svtav1-params scd=1%SVTparam% ^
-metadata comment="%preset% %crf% %MBRconfig% %NOISENORM% %PSYRD%%SVTconfig%%CONFIG%" ^
-an -sn "%folder%\%OUTname%"

exit /B 0


:AV1svtMBR <input> <crf> <preset> <rate> <rateOVER>
set crf=%~2
if "%crf%"=="" set crf=20
set preset=%~3
if "%preset%"=="" set preset=4
set rate=%~4
REM if NOT "%rate%"=="" set rateCMD=--mbr %rate%
set rateOVER=50
if NOT "%~5"=="" set rateOVER=%~5
::	MBR overshot limit, default is 50%

call :AV1svt "%~1" %crf% %preset%

exit /B 0

:AV1svtVBRscale <input> <scale> <crf> <preset>
set scale=%~2
if NOT "%scale%"=="" set FILT=%FILT%,scale=-4:'min(ih,%scale%)'
set crf=%~3
if "%crf%"=="" set crf=34
set preset=%~4
if "%preset%"=="" set preset=4
SET CONFIG= %scale%

call :AV1svt "%~1" %crf% %preset%

exit /B 0

:AV1svtMBRscale <input> <scale> <crf> <preset> <rate> <rateOVER>
set scale=%~2
if NOT "%scale%"=="" set FILT=%FILT%,scale=-4:'min(ih,%scale%)'
SET CONFIG= %scale%

set crf=%~3
if "%crf%"=="" set crf=34
set preset=%~4
if "%preset%"=="" set preset=4
set rate=%~5
REM if NOT "%rate%"=="" set rateCMD=--mbr %rate%
set rateOVER=50
if NOT "%~6"=="" set rateOVER=%~6
::	MBR overshot limit, default is 50%

call :AV1svt "%~1" %crf% %preset%

exit /B 0

:AV1svtpass <input> <rate> <crf> <preset> <pass>
set rate=%~2
REM if NOT "%rate%"=="" set rate=--mbr %rate%
set crf=%~3
if "%crf%"=="" set crf=20
set preset=%~4
if "%preset%"=="" set preset=4

ffmpeg -hide_banner -i "%~1" -filter_complex "%FILT%" -pix_fmt yuv420p10le -f yuv4mpegpipe -strict -1 - | ^
SvtAv1EncApp --input - --preset %preset% --crf %crf% %rate% --fast-decode 1 --film-grain-denoise 0 %GRAIN% --pass 1

ffmpeg -hide_banner -i "%~1" -filter_complex "%FILT%" -pix_fmt yuv420p10le -f yuv4mpegpipe -strict -1 - | ^
SvtAv1EncApp --input - --preset %preset% --crf %crf% %rate% --fast-decode 1 --film-grain-denoise 0 %GRAIN% --pass 2 --output - | ^
ffmpeg -hide_banner -i - -i "%~1" -map 0:v -c:v copy -map 1:s? -c:s copy -map 1:a -ac %CHAN% -c:a libopus %rateA% -vbr 1 -map_metadata 1 "%folder%\%~n1 - SVT %preset% %crf% %rate% %NOISENORM% %PSYRD%.mkv"

REM del svtav1_2pass.log

exit /B 0

:AV1svtpassscale <input> <scale> <rate> <crf> <preset> <pass>
set scale=%~2
if NOT "%scale%"=="" set FILT=%FILT%,scale=-4:'min(ih,%scale%)'
set rate=%~3
set crf=%~4
set preset=%~5
set pass=2

call :AV1svtpass "%~1" %rate% %crf% %preset% %pass%

exit /B 0

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
set "%~1=%OUT%k"
if %pair%==0 set "%~1=" & if %mono%==0 set "%~1=0"
::	can be used to let libopus use its defaults
exit /B 0