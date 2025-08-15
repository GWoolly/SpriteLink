@echo off
REM Point ASEPRITE_EXE to the install location of Aseprite in quotation marks.
set ASEPRITE_EXE="C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe"

set SCRIPT="gm_spr_import.lua"

REM Check if a file was provided
if "%~1"=="" (
    echo No file provided.
    echo Usage: run.bat path\to\image.png
    pause
    exit /b
)

REM Launch Aseprite with the provided file and script
%ASEPRITE_EXE% "%~1" --script %SCRIPT%
pause