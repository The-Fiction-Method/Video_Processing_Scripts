@echo off
::echo "%~1"

TITLE	%~n1

call :CUTcall "%~dp1" "Frieren - S01E01.mkv" 1 00:00:00 92
call :CUTcall "%~dp1" "Frieren - S01E01.mkv" A 00:03:48
call :CUTcall "%~dp1" "Frieren - S01E01.mkv" B 00:13:14
call :CUTcall "%~dp1" "Frieren - S01E15.mkv" C 00:08:09
call :CUTcall "%~dp1" "Frieren - S01E21.mkv" D 00:05:15
call :CUTcall "%~dp1" "Frieren - S01E28.mkv" E 00:17:14


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