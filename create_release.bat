@echo off
setlocal enabledelayedexpansion

:: Configuration - Edit these variables as needed
set "RELEASE_NAME=SpriteLink"
set "OUTPUT_ZIP=%RELEASE_NAME%.zip"

:: Files and folders to ignore (space-separated)
:: Add any files or folders you want to exclude from the release
set "IGNORE_LIST=create_release.bat .git .gitignore .DS_Store Thumbs.db *.zip .gitattributes .vscode"

echo Creating %OUTPUT_ZIP% release artifact...
echo.

:: Remove existing zip and temp folder if they exist
if exist "%OUTPUT_ZIP%" (
    echo Removing existing %OUTPUT_ZIP%...
    del "%OUTPUT_ZIP%"
)
if exist "%RELEASE_NAME%" (
    echo Removing existing %RELEASE_NAME% folder...
    rmdir /s /q "%RELEASE_NAME%"
)

:: Create release folder
echo Creating folder structure...
mkdir "%RELEASE_NAME%"

:: Copy all files except those in ignore list
echo Copying files...
set "copied_count=0"
set "ignored_count=0"

:: Process files
for %%f in (*) do (
    set "should_ignore=0"
    set "current_file=%%f"
    
    :: Check against ignore list
    for %%i in (%IGNORE_LIST%) do (
        if /i "!current_file!"=="%%i" set "should_ignore=1"
        if "%%i"=="*.tmp" if /i "!current_file:~-4!"==".tmp" set "should_ignore=1"
        if "%%i"=="*.log" if /i "!current_file:~-4!"==".log" set "should_ignore=1"
        if "%%i"=="*.bak" if /i "!current_file:~-4!"==".bak" set "should_ignore=1"
    )
    
    if !should_ignore! equ 0 (
        if exist "%%f" (
            echo   + %%f
            copy "%%f" "%RELEASE_NAME%\" >nul 2>&1
            if !errorlevel! equ 0 set /a copied_count+=1
        )
    ) else (
        echo   - %%f ^(ignored^)
        set /a ignored_count+=1
    )
)

:: Process directories
for /d %%d in (*) do (
    set "should_ignore=0"
    set "current_dir=%%d"
    
    :: Check against ignore list
    for %%i in (%IGNORE_LIST%) do (
        if /i "!current_dir!"=="%%i" set "should_ignore=1"
        if /i "!current_dir!"=="%RELEASE_NAME%" set "should_ignore=1"
    )
    
    if !should_ignore! equ 0 (
        echo   + %%d\ ^(folder^)
        xcopy "%%d" "%RELEASE_NAME%\%%d" /E /I /Q >nul 2>&1
        if !errorlevel! equ 0 set /a copied_count+=1
    ) else (
        echo   - %%d\ ^(ignored^)
        set /a ignored_count+=1
    )
)

echo.
echo Files copied: !copied_count!
echo Files ignored: !ignored_count!
echo.

:: Check if we have any files to compress
if !copied_count! equ 0 (
    echo ERROR: No files were copied! Check your ignore list.
    echo Current directory contents:
    dir /b
    echo.
    echo Ignore list: %IGNORE_LIST%
    goto :cleanup
)

:: Try different compression methods in order of preference
echo Compressing files...

:: Method 1: Try tar (available in Windows 10 1803+)
tar -a -cf "%OUTPUT_ZIP%" "%RELEASE_NAME%" >nul 2>&1
if !errorlevel! equ 0 (
    echo SUCCESS: %OUTPUT_ZIP% created using tar!
    goto :cleanup
)

:: Method 2: Try 7-Zip if available
where 7z >nul 2>&1
if !errorlevel! equ 0 (
    7z a "%OUTPUT_ZIP%" "%RELEASE_NAME%" >nul
    if !errorlevel! equ 0 (
        echo SUCCESS: %OUTPUT_ZIP% created using 7-Zip!
        goto :cleanup
    )
)

:: Method 3: Fallback to PowerShell
echo Trying PowerShell method...
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::CreateFromDirectory('%CD%\%RELEASE_NAME%', '%CD%\%OUTPUT_ZIP%')" 2>nul

if exist "%OUTPUT_ZIP%" (
    echo SUCCESS: %OUTPUT_ZIP% created using PowerShell!
    goto :cleanup
) else (
    echo ERROR: Failed to create %OUTPUT_ZIP% with all methods
    echo Please install 7-Zip or ensure you have Windows 10 version 1803 or later
    goto :cleanup
)

:cleanup
:: Clean up temporary folder
echo Cleaning up...
if exist "%RELEASE_NAME%" rmdir /s /q "%RELEASE_NAME%"

if exist "%OUTPUT_ZIP%" (
    echo.
    echo SUCCESS: Release archive created!
    echo File: %OUTPUT_ZIP%
    echo Structure: %RELEASE_NAME%\^<your files^>
    
    :: Show archive size
    for %%A in ("%OUTPUT_ZIP%") do (
        echo Size: %%~zA bytes
    )
) else (
    echo.
    echo ERROR: Failed to create release archive!
)

echo.
echo === Configuration ===
echo Release name: %RELEASE_NAME%
echo Output file: %OUTPUT_ZIP%
echo Ignore list: %IGNORE_LIST%
echo.
echo To modify what gets included, edit the IGNORE_LIST variable at the top of this script.
echo.
pause