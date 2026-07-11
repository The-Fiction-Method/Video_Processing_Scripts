@echo off
::echo "%~1"

TITLE	%~n1

call :CUTcall "%~dp1" "ASD.mkv" A 00:01:14
call :CUTcall "%~dp1" "ASD.mkv" B 00:32:28
call :CUTcall "%~dp1" "ASD.mkv" C 01:10:22
call :CUTcall "%~dp1" "ASD.mkv" D 01:33:25
call :CUTcall "%~dp1" "ASD.mkv" E 02:13:03


::pause
exit
::The %~1 is a variable selecting the file dragged onto the batch file

:CUTcall <FOLD> <FILM> <ID> <START> <LENGTH>
set fold=%~1
set film=%~2
set ID=%~3
set start=%~4
set length=%~5
if "%length%"=="" set length=12

IF NOT EXIST "%fold%\%film%" exit /b 0

ffmpeg -ss %start% -i "%fold%\%film%" -t %length% -c copy -map 0 -map_metadata 0 -sn "%fold%\AV1 test %ID%.mkv" -n

exit /B 0