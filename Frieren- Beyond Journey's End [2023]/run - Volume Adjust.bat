@echo off

::	dir /b /a-d > list.txt
::		writes a list of files in a directory

REM set SKIP=TRUE
::	skip files when no amplification to be applied

::	the FLAC version is best when there is still video processing to do, minimizing generational loss
REM call :VOLcallOPUS "M:\MakeMKV\ASD" "ASD.mkv" AMP1 AMP2 ...
REM call :VOLcallFLAC "M:\MakeMKV\ASD" "ASD.mkv" AMP1 AMP2 ...

TITLE	Volume Adjust Sequence

set dir=%~dp0
set dir=M:\MakeMKV\@zFuture\Frieren- Beyond Journey's End [2023]

goto S01

:S01
set dirS=%dir%\Season 01
set serieS=Frieren - S01
call :VOLcallFLAC "%dirS%" "%serieS%E01.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E02.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E03.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E04.mkv" 3 3
call :VOLcallFLAC "%dirS%" "%serieS%E05.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E06.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E07.mkv" 3 2
call :VOLcallFLAC "%dirS%" "%serieS%E08.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E09.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E10.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E11.mkv" 3 2
call :VOLcallFLAC "%dirS%" "%serieS%E12.mkv" 1 0
call :VOLcallFLAC "%dirS%" "%serieS%E13.mkv" 3 3
call :VOLcallFLAC "%dirS%" "%serieS%E14.mkv" 3 2
call :VOLcallFLAC "%dirS%" "%serieS%E15.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E16.mkv" 3 2
call :VOLcallFLAC "%dirS%" "%serieS%E17.mkv" 3 3
call :VOLcallFLAC "%dirS%" "%serieS%E18.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E19.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E20.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E21.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E22.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E23.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E24.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E25.mkv" 3 0
call :VOLcallFLAC "%dirS%" "%serieS%E26.mkv" 1 0
call :VOLcallFLAC "%dirS%" "%serieS%E27.mkv" 3 5
call :VOLcallFLAC "%dirS%" "%serieS%E28.mkv" 3 0

exit


:PROCcall <FOLD> <FILM> <BATCH>
set fold=%~1
set film=%~n2
set batch=%~3

IF NOT EXIST "%fold%\%film%" exit /b 0

pushd "%fold%"
call "%fold%\%batch%" "%fold%\%film%"

exit /B 0

:VOLcallOPUS <FOLD> <FILM> <AMP>
set fold=%~1
set film=%~2

IF NOT EXIST "%fold%\%film%" exit /b 0

TITLE	Volume Adjust Sequence - %film%

set AMP=
set /a Asum=0
set /a sID=0
CALL :COUNTaudio "%fold%\%film%" COUNT

:loopOPUS
set /a Asum+=%~3
CALL :AUDchannel "%fold%\%film%" CHAN %sID%
CALL :RATEopusChan rate %CHAN% 0 0
if NOT %~3==0 (
	set AMP=%AMP%-filter:a:%sID% "volume=%~3dB" -ac:a:%sID% %CHAN% -c:a:%sID% libopus -b:a:%sID% %rate% -vbr 1 
) ELSE (
	set AMP=%AMP%-ac:a:%sID% %CHAN% -c:a:%sID% copy 
)
set /a sID+=1

shift
if %sID%==%COUNT% goto endOPUS
if "%~3"=="" (
	set AMP=%AMP%-ac:a:%sID% %CHAN% -c:a:%sID% copy
	goto endOPUS
)
goto :loopOPUS
:endOPUS

REM echo %Asum%
if "%SKIP%"=="TRUE" (if %Asum%==0 exit /B 0)

pushd "%fold%"

set FOLDER=@original Volume
if NOT EXIST "%FOLDER%" mkdir "%FOLDER%"
set FOLDER=Volume
if NOT EXIST "%FOLDER%" mkdir "%FOLDER%"

ffmpeg -hide_banner -i "%fold%\%film%" -filter:a:0 "volume=%AMP%dB" ^
-map 0:v? -c:v copy ^
-map 0:a -c:a copy ^
%AMP% ^
-map 0:s? -c:s copy -map_metadata 0 "%FOLDER%\%film%" -n

exit /B 0


:VOLcallFLAC <FOLD> <FILM> <AMP>
set fold=%~1
set film=%~2

IF NOT EXIST "%fold%\%film%" exit /b 0

TITLE	Volume Adjust Sequence - %film%

set AMP=
set /a Asum=0
set /a sID=0
CALL :COUNTaudio "%fold%\%film%" COUNT
:loopFLAC
set /a Asum+=%~3
CALL :AUDchannel "%fold%\%film%" CHAN %sID%
if NOT %~3==0 (
	set AMP=%AMP%-filter:a:%sID% "volume=%~3dB" -ac:a:%sID% %CHAN% -c:a:%sID% flac 
) ELSE (
	set AMP=%AMP%-ac:a:%sID% %CHAN% -c:a:%sID% copy 
)
set /a sID+=1

shift
if %sID%==%COUNT% goto endFLAC
if "%~3"=="" (
	set AMP=%AMP%-ac:a:%sID% %CHAN% -c:a:%sID% copy
	goto endFLAC
)
goto :loopFLAC
:endFLAC

REM echo %Asum%
if "%SKIP%"=="TRUE" (if %Asum%==0 exit /B 0)

pushd "%fold%"

set FOLDER=@original Volume
if NOT EXIST "%FOLDER%" mkdir "%FOLDER%"
set FOLDER=Volume
if NOT EXIST "%FOLDER%" mkdir "%FOLDER%"


ffmpeg -hide_banner -i "%fold%\%film%" ^
-map 0:v? -c:v copy ^
-map 0:a -c:a copy ^
%AMP% ^
-map 0:s? -c:s copy -map_metadata 0 "%FOLDER%\%film%" -n

exit /B 0

:AUDchannel <input> <variable> <stream>
set stream=%~3
if "%stream%"=="" set stream=0
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=channels -select_streams a:%stream% -i "%~1"') do set OUT=%%I
set /A "%~2=%OUT%"
exit /B 0

:COUNTaudio <input> <variable>
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=codec_type -select_streams a -i "%~1" ^| find /c /v ""') do set OUT=%%I
REM echo %OUT%
set /A "%~2=%OUT%"
exit /B 0

:RATEopusChan <variable> <tracks> <pair> <mono>
::	96 per stereo pair, 64 per mono channel (center, subwoofer)
set CHANS=%~2
if "%CHANS%"=="" set CHANS=%CHAN%
set MF=
if %CHANS% GTR 2 set MF=-mapping_family 1
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
set "%~1=%OUT%k %MF%"
if %pair%==0 set "%~1=%MF%" & if %mono%==0 set "%~1=%MF%"
::	can be used to let libopus use its defaults
exit /B 0

:NAMEcall <FILE> <TRACK1> <TRACK2>...
set PATH=C:\Program Files\MKVToolNix;%PATH%
set file=%~1

IF NOT EXIST "%file%" exit /b 0

set TAG=
set /a sID=0
CALL :COUNTaudio "%FILE%" COUNT
REM set /a COUNT+=1
:loopNAME
set NAME="%~2"
IF %NAME%=="" call :CHANNELaudio "%file%" NAME %sID%
set /a sID+=1
set TAG=%TAG%--edit track:a%sID% --set name=%NAME% 

REM echo %TAG%
REM pause

shift
if %sID%==%COUNT% goto endNAME
goto :loopNAME

:endNAME

REM mkvpropedit "%~1" --edit track:a1 --set name="test"
mkvpropedit "%file%" %TAG%

exit /B 0

:CHANNELaudio <input> <variable> <stream>
set stream=%~3
if "%stream%"=="" set stream=0
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=channel_layout -select_streams a:%stream% -i "%~1"') do set OUT=%%I

set upper=
set "str=%OUT:~0,1%"
for /f "skip=2 delims=" %%I in ('tree "\%str%"') do if not defined upper set "upper=%%~I"
set "upper=%upper:~3%"

REM echo %OUT%
REM set "%~2=%OUT%"
REM set "%~2="%upper%%OUT:~1%""
set hold="%upper%%OUT:~1%"
if %hold%=="7.1" set hold="Surround 7.1"
if %hold%=="5.1" set hold="Surround 5.1"
set "%~2=%hold%"
exit /B 0
