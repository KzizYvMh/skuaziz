@echo off
setlocal EnableExtensions

rem Run a temporary copy so git pull can safely update this script on disk.
if defined BUILDPROJECT_RUNNING goto :BuildRunner

set "BUILDPROJECT_ROOT=%~dp0"
if "%~1"=="" set "BUILDPROJECT_PAUSE=1"
set "BUILDPROJECT_RUNNING=1"
set "BUILDPROJECT_TEMP=%TEMP%\BuildProject-%RANDOM%-%RANDOM%.bat"

copy /Y "%~f0" "%BUILDPROJECT_TEMP%" >nul
if errorlevel 1 (
    echo Failed to create a temporary copy of the build script.
    pause
    exit /b 1
)

call "%BUILDPROJECT_TEMP%"
set "BUILDPROJECT_EXIT=%ERRORLEVEL%"
del "%BUILDPROJECT_TEMP%" >nul 2>&1
exit /b %BUILDPROJECT_EXIT%

:BuildRunner
pushd "%BUILDPROJECT_ROOT%" || goto :Failure

echo Closing any running instances...
taskkill /IM SkuaZZ.exe /F >nul 2>&1
taskkill /IM SkuaZZ.Manager.exe /F >nul 2>&1
taskkill /IM Skua.exe /F >nul 2>&1
taskkill /IM Skua.Manager.exe /F >nul 2>&1

if not exist "Build" (
    echo Preparing Build folder...
    mkdir "Build"
    if errorlevel 1 goto :Failure
)

set "AS3_REBUILD=0"
set "AS3_TEMP_SWF=Skua.AS3\skua\bin\skua.build-%RANDOM%-%RANDOM%.tmp.swf"
if not exist "Skua.AS3\skua\bin\skua.swf" set "AS3_REBUILD=1"
git diff --quiet HEAD -- "Skua.AS3/skua/bin/skua.swf"
if errorlevel 1 set "AS3_REBUILD=1"
if "%AS3_REBUILD%"=="1" (
    echo Building AS3 Client...
    if exist "%AS3_TEMP_SWF%" del /F /Q "%AS3_TEMP_SWF%"
    powershell -NoProfile -ExecutionPolicy Bypass -File "Skua.AS3\compile-as3.ps1" -OutputPath "%AS3_TEMP_SWF%"
    if errorlevel 1 (
        if exist "%AS3_TEMP_SWF%" del /F /Q "%AS3_TEMP_SWF%"
        echo Failed to build AS3 client. The existing skua.swf was preserved.
        goto :Failure
    )
    if not exist "%AS3_TEMP_SWF%" (
        echo AS3 build completed without producing a temporary SWF. The existing skua.swf was preserved.
        goto :Failure
    )
    move /Y "%AS3_TEMP_SWF%" "Skua.AS3\skua\bin\skua.swf" >nul
    if errorlevel 1 (
        echo Failed to replace skua.swf with the successful build output.
        goto :Failure
    )
) else (
    echo Skipping AS3 build because skua.swf is unchanged.
)

echo Restoring solution once for faster project builds...
dotnet restore "Skua.sln"
if errorlevel 1 goto :Failure

call :BuildProject "Skua.App.Avalonia\Skua.App.Avalonia.csproj" "App" || goto :Failure
call :BuildProject "Skua.Manager.Avalonia\Skua.Manager.Avalonia.csproj" "Manager" || goto :Failure
call :BuildProject "Skua.Plugin.DailyTracker\Skua.Plugin.DailyTracker.csproj" "DailyTracker Plugin" || goto :Failure
call :BuildProject "Skua.Plugin.ButlerV5\Skua.Plugin.ButlerV5.csproj" "ButlerV5 Plugin" || goto :Failure
call :BuildProject "Skua.Plugin.Cosmetics\Skua.Plugin.Cosmetics.csproj" "Cosmetics Plugin" || goto :Failure

echo Packaging and organizing output to match WPF release structure...
powershell -NoProfile -ExecutionPolicy Bypass -File "package-build.ps1"
if errorlevel 1 goto :Failure
if not exist "Build\SkuaZZ.exe" (
    echo Build completed without producing Build\SkuaZZ.exe.
    goto :Failure
)

echo.
echo ==========================================================
echo Fast Build complete! The application is located in the Build folder.
echo You can run SkuaZZ.Manager.exe or SkuaZZ.exe from there.
echo ==========================================================
echo Launching SkuaZZ...
start "" "Build\SkuaZZ.exe"
if errorlevel 1 goto :Failure
set "BUILD_EXIT_CODE=0"
goto :Finish

:BuildProject
echo Building %~2 (Fast Dev Build)...
dotnet build "%~1" -c Release --no-restore
if errorlevel 1 exit /b 1
exit /b 0

:Failure
set "BUILD_EXIT_CODE=1"
echo.
echo Fast Build failed. Check the output above for details.

:Finish
if defined BUILDPROJECT_PAUSE pause
popd
exit /b %BUILD_EXIT_CODE%
