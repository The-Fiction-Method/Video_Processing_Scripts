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

set dir=M:\MakeMKV\Frieren- Beyond Journey's End [2023]
set script=Re-encode - SVT-AV1-HDR + Opus - multi.bat
REM set script=Re-encode - SVT-AV1-HDR + Opus.bat
REM set script=Re-encode - x265 + Opus - multi.bat
REM set script=Re-encode - x265 + Opus.bat

goto S01
goto extras

:S01
set dirS=%dir%\Season 01
set serieS=Frieren - S01

REM call :PROCcall "%dirS%" "%serieS%E00.mkv" "..\%script%"
REM call :TITLcall "%dirS%\Re-encode\%film%" ""
REM call :nameAUDcall "%dirS%\Re-encode\%film%" "" "Commentary"
call :PROCcall "%dirS%" "%serieS%E01.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E02.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E03.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E04.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E05.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E06.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E07.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E08.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E09.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E10.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E11.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E12.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E13.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E14.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E15.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E16.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E17.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E18.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E19.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E20.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E21.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E22.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E23.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E24.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E25.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E26.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E27.mkv" "..\%script%"
call :PROCcall "%dirS%" "%serieS%E28.mkv" "..\%script%"


:extras
set dirS=%dir%\extras
set script="Re-encode - SVT-AV1-HDR + Opus - extras.bat"

call :PROCcall "%dirS%" "Character Promo Videos.mkv" "..\%script%"
call :PROCcall "%dirS%" "First Class Mage Exam.mkv" "..\%script%"
call :PROCcall "%dirS%" "Frieren- Journey's Memory.mkv" "..\%script%"
call :PROCcall "%dirS%" "Mini Anime.mkv" "..\%script%"
call :PROCcall "%dirS%" "Next Episode Previews 1.mkv" "..\%script%"
call :PROCcall "%dirS%" "Next Episode Previews 2.mkv" "..\%script%"
call :PROCcall "%dirS%" "Promo Videos.mkv" "..\%script%"
call :PROCcall "%dirS%" "Textless Ending Song 1 - Broadcast.mkv" "..\%script%"
call :PROCcall "%dirS%" "Textless Ending Song 1.mkv" "..\%script%"
call :PROCcall "%dirS%" "Textless Ending Song 2.mkv" "..\%script%"
call :PROCcall "%dirS%" "Textless Opening Song 1.mkv" "..\%script%"
call :PROCcall "%dirS%" "Textless Opening Song 2.mkv" "..\%script%"
call :PROCcall "%dirS%" "Web Previews.mkv" "..\%script%"

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
if "%MKVmux%"=="TRUE" (
	CALL :FOLDcheck "%folder%\EXT Change"
	IF NOT EXIST "%folder%\EXT Change\%film%" (
		mkvmerge "%fold%\%folder%\%film%" -o "%folder%\EXT Change\%film%"
		)
	)

exit /B 0

:TITLcall <FILE> <NAME>
set file=%~1
set name=%~2
if "%name%"=="" set name=%~n1

IF NOT EXIST "%file%" exit /b 0

mkvpropedit "%file%" --edit info --set "title=%name%"

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
