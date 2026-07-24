@echo off
set PATH=C:\Program Files\MKVToolNix;%PATH%
::	https://mkvtoolnix.download/doc/mkvpropedit.html

::	dir /b /a-d > list.txt
::		writes a list of files in a directory
REM set MKVmux=TRUE

REM call :TITLcall "M:\MakeMKV\ASD\Re-encode\ASD.mkv" ""

::	call :nameAUDcall "M:\MakeMKV\ASD\Re-encode\ASD.mkv" "" "Audio_2" "Audio_3"
::		if blank, "", it will write the channel layout (Mono, Stereo, Surround 5.1)
::	RegEx to find files with multiple audio tracks in "run - Volume Adjust"
::		.*" \d+ \d+.*
REM call :nameAUDcall "M:\MakeMKV\ASD\Re-encode\ASD.mkv" "" ""
REM call :nameSUBcall "M:\MakeMKV\ASD\Re-encode\ASD.mkv" "" ""

set dir=SERIES
set script=Re-encode - SVT-AV1-HDR + Opus - multi.bat
REM set script=Re-encode - SVT-AV1-HDR + Opus.bat
REM set script=Re-encode - x265 + Opus - multi.bat
REM set script=Re-encode - x265 + Opus.bat

goto S01

:S01
set dirS=%dir%\Season 01
set serieS=SERIES - S01

call :PROCcall "%dirS%" "%serieS%E01.mkv" "..\%script%"
REM call :TITLcall "%dirS%\Re-encode\%film%" ""
REM call :nameAUDcall "%dirS%\Re-encode\%film%" "" "Commentary"

::pause
exit

:PROCcall <FOLD> <FILM> <BATCH>
set fold=%~1
set film=%~2
set batch=%~3

IF NOT EXIST "%fold%\%film%" exit /b 0

pushd "%fold%"
call "%fold%\%batch%" "%fold%\%film%"

::	pulls %folder% from Batch script
if "%MKVmux%"=="TRUE" set foldMKV=EXT Change
if "%MKVmux%"=="TRUE" (
	CALL :FOLDcheck "%folder%\%foldMKV%"

	IF NOT EXIST "%folder%\%foldMKV%\%film%" (
		mkvmerge "%fold%\%folder%\%film%" -o "%folder%\%foldMKV%\%film%"
		)
	)

exit /B 0

:TITLcall <FILE> <NAME>
set file=%~1
set name=%~2
if "%name%"=="" set name=%~n1

IF NOT EXIST "%file%" exit /b 0

mkvpropedit "%file%" --edit info --set "title=%name%"

::	for some reason it does not want to work with parantheses
if "%MKVmux%"=="TRUE" call set fileMKV=%%file:%folder%=%folder%\%foldMKV%%%
if "%MKVmux%"=="TRUE" mkvpropedit "%fileMKV%" --edit info --set "title=%name%"

exit /B 0


:nameAUDcall <FILE> <TRACK1> <TRACK2>...
set file=%~1

IF NOT EXIST "%file%" exit /b 0

set TAG=
set /a sID=0
CALL :COUNTaudio "%FILE%" COUNT
REM set /a COUNT+=1
:AUDloopNAME
set NAME="%~2"
IF %NAME%=="" call :CHANNELaudio "%file%" NAME %sID%
set /a sID+=1
set TAG=%TAG%--edit track:a%sID% --set name=%NAME% 

REM echo %TAG%
REM pause

shift
if %sID%==%COUNT% goto AUDendNAME
goto :AUDloopNAME

:AUDendNAME

REM mkvpropedit "%~1" --edit track:a1 --set name="test"

mkvpropedit "%file%" %TAG%

::	for some reason it does not want to work with parantheses
if "%MKVmux%"=="TRUE" call set fileMKV=%%file:%folder%=%folder%\%foldMKV%%%
if "%MKVmux%"=="TRUE" mkvpropedit "%fileMKV%" %TAG%

exit /B 0


:nameSUBcall <FILE> <TRACK1> <TRACK2>...
set file=%~1

IF NOT EXIST "%file%" exit /b 0

set TAG=
set /a sID=0
CALL :COUNTsubs "%FILE%" COUNT
REM set /a COUNT+=1
:SUBloopNAME
set NAME="%~2"
set /a sID+=1
IF %NAME%=="" goto :SUBloopEND
set TAG=%TAG%--edit track:s%sID% --set name=%NAME% 

REM echo %TAG%
REM pause

:SUBloopEND
shift
if %sID%==%COUNT% goto SUBendNAME
goto :SUBloopNAME

:SUBendNAME

REM mkvpropedit "%~1" --edit track:s1 --set name="test"

mkvpropedit "%file%" %TAG%

::	for some reason it does not want to work with parantheses
if "%MKVmux%"=="TRUE" call set fileMKV=%%file:%folder%=%folder%\%foldMKV%%%
if "%MKVmux%"=="TRUE" mkvpropedit "%fileMKV%" %TAG%

exit /B 0

:COUNTaudio <input> <variable>
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=codec_type -select_streams a -i "%~1" ^| find /c /v ""') do set OUT=%%I
REM echo %OUT%
set /A "%~2=%OUT%"
exit /B 0

:COUNTsubs <input> <variable>
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=index -select_streams s -i "%~1" ^| find /c /v ""') do set OUT=%%I
REM echo %OUT%
set /A "%~2=%OUT%"
exit /B 0

:CHANNELaudio <input> <variable> <stream>
set stream=%~3
if "%stream%"=="" set stream=0
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=channel_layout -select_streams a:%stream% -i "%~1"') do set OUT=%%I

IF "%OUT%"=="5.1" SET OUT=Surround %OUT%
IF "%OUT%"=="7.1" SET OUT=Surround %OUT%

set upper=
set "str=%OUT:~0,1%"
for /f "skip=2 delims=" %%I in ('tree "\%str%"') do if not defined upper set "upper=%%~I"
set "upper=%upper:~3%"

REM echo %OUT%
REM set "%~2=%OUT%"
set "%~2="%upper%%OUT:~1%""
exit /B 0

:SUBlanguage <input> <variable> <stream>
set stream=%~3
if "%stream%"=="" set stream=0
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream_tags^=language -select_streams s:%stream% -i "%~1"') do set OUT=%%I

set upper=
set "str=%OUT:~0,1%"
for /f "skip=2 delims=" %%I in ('tree "\%str%"') do if not defined upper set "upper=%%~I"
set "upper=%upper:~3%"

REM echo %OUT%
REM set "%~2=%OUT%"
set "%~2="%upper%%OUT:~1%""
exit /B 0

:FOLDcheck <OUTfold>
if NOT EXIST "%~1" mkdir "%~1"
exit/B 0
