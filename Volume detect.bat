@echo off

:start
TITLE Volume Detect - %~n1

IF NOT EXIST "Volume detect.txt" echo.>"Volume detect.txt"
echo %~nx1>>"Volume detect.txt"

CALL :COUNTaudio "%~1" COUNT
set /a STREAMS=%COUNT% - 1

REM FOR /l %%S in (0,1,%STREAMS%) do (echo %%S)
FOR /l %%S in (0,1,%STREAMS%) do (
CALL :VOLUMEDETECTfile "%~1" %%S
REM CALL :COMbuild %%S
echo.>>"Volume detect.txt"
echo.>>"Volume detect.txt"
)

REM CALL :VOLUMEDETECTfile "%~1" 0
REM CALL :VOLUMEDETECTfile "%~1" 1
REM CALL :VOLUMEDETECTfile "%~1" 2
REM CALL :VOLUMEDETECTfile "%~1" 3
REM CALL :VOLUMEDETECTfile "%~1" 4

::pause

shift

if "%~1"=="" goto end
goto start

:end
::pause
exit

:VOLUMEDETECTfile <input> <STREAM>
set STREAM=%~2
if "%STREAM%"=="" set STREAM=0
if %STREAM% GEQ %COUNT% exit /B 0

echo Stream a:%STREAM%
echo Stream a:%STREAM%>>"Volume detect.txt"
ffmpeg -hide_banner -i "%~1" -vn -sn -map 0:a:%STREAM%? -af volumedetect -f null - 2>&1 | findstr "mean_volume max_volume" >> "Volume detect.txt"
REM pause
exit /B 0

:COUNTaudio <input> <variable>
for /f "tokens=*" %%I in ('ffprobe -v error -of default^=noprint_wrappers^=1:nokey^=1 -show_entries stream^=codec_type -select_streams a -i "%~1" ^| find /c /v ""') do set OUT=%%I
REM echo %OUT%
set /A "%~2=%OUT%"
exit /B 0

:COMbuild <input>
set STREAM=%~1

echo -filter:a:%STREAM% "volume=0dB" >> "Volume detect.txt"
echo CALL :AUDchannel "%%~1" CHAN%STREAM% %STREAM% >> "Volume detect.txt"
echo CALL :RATEopusChan rate%STREAM% %%CHAN%STREAM%%% 0 0 >> "Volume detect.txt"
echo -map 0:a:%STREAM%? -ac:a:%STREAM% %%CHAN%STREAM%%% -c:a:%STREAM% libopus -b:a:%STREAM% %%rate%STREAM%%% -vbr 1 -metadata:s:a:%STREAM% title="STREAM" >> "Volume detect.txt"

exit /B 0