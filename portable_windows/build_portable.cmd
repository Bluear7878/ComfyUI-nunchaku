@echo off
setlocal enabledelayedexpansion

echo ============================================
echo  ComfyUI-nunchaku Minimal Portable Builder
echo ============================================
echo.

set WORK_DIR=%CD%
set SCRIPT_DIR=%~dp0
set BUILD_DIR=%WORK_DIR%\ComfyUI_nunchaku_portable
set NUNCHAKU_VERSION=1.2.0

REM ============================================
REM  Version Configuration (CI or Interactive)
REM ============================================

REM Check if running in CI mode
if defined CI_BUILD (
    echo Running in CI mode...
    echo.
    goto :configure_versions
)

REM ============================================
REM  Interactive Version Selection
REM ============================================

:select_nunchaku
echo [Nunchaku Version]
echo   1. v1.0.2 - Stable
echo   2. v1.1.0
echo   3. v1.2.0 - Latest (Recommended)
echo.
set /p NUNCHAKU_CHOICE="Select nunchaku version (1-3) [default: 3]: "
if "!NUNCHAKU_CHOICE!"=="" set NUNCHAKU_CHOICE=3
if "!NUNCHAKU_CHOICE!"=="1" (
    set NUNCHAKU_VERSION=1.0.2
) else if "!NUNCHAKU_CHOICE!"=="2" (
    set NUNCHAKU_VERSION=1.1.0
) else if "!NUNCHAKU_CHOICE!"=="3" (
    set NUNCHAKU_VERSION=1.2.0
) else (
    echo Invalid choice. Please try again.
    goto :select_nunchaku
)
echo   Selected: nunchaku v!NUNCHAKU_VERSION!
echo.

:configure_versions
REM Set version from environment variable (CI mode) or use default
if not defined NUNCHAKU_VERSION set NUNCHAKU_VERSION=1.2.0

REM ============================================
REM  Confirm Selection (Skip in CI mode)
REM ============================================
echo ============================================
echo  Build Configuration
echo ============================================
echo   Nunchaku: v!NUNCHAKU_VERSION!
echo   Package type: Minimal (auto-installer)
echo ============================================
echo.

if not defined CI_BUILD (
    set /p CONFIRM="Proceed with this configuration? (Y/N) [default: Y]: "
    if /i "!CONFIRM!"=="N" (
        echo.
        echo Build cancelled.
        goto :end
    )
    echo.
)

REM ============================================
REM  Step 1: Create build directory
REM ============================================
echo [1/4] Creating build directory...
if exist "%BUILD_DIR%" (
    if not defined CI_BUILD (
        echo.
        echo [WARNING] Build directory already exists: %BUILD_DIR%
        echo This will DELETE all existing files.
        echo.
        set /p DELETE_CONFIRM="Delete and continue? (Y/N) [default: N]: "
        if /i not "!DELETE_CONFIRM!"=="Y" (
            echo.
            echo Build cancelled. Existing directory preserved.
            goto :end
        )
    )
    echo Removing existing directory...
    rd /s /q "%BUILD_DIR%"
)
mkdir "%BUILD_DIR%"
cd /d "%BUILD_DIR%"

REM ============================================
REM  Step 2: Clone ComfyUI
REM ============================================
echo [2/4] Cloning ComfyUI...
git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git ComfyUI
if %errorlevel% neq 0 (
    echo ERROR: Failed to clone ComfyUI
    goto :error
)

REM ============================================
REM  Step 3: Clone ComfyUI-nunchaku plugin
REM ============================================
echo [3/4] Adding ComfyUI-nunchaku plugin...
git clone --depth 1 https://github.com/nunchaku-ai/ComfyUI-nunchaku.git "ComfyUI\custom_nodes\ComfyUI-nunchaku"
if %errorlevel% neq 0 (
    echo ERROR: Failed to clone ComfyUI-nunchaku
    goto :error
)

REM ============================================
REM  Step 4: Copy installer scripts
REM ============================================
echo [4/4] Creating installer scripts...

REM Copy template files
copy "%SCRIPT_DIR%templates\install.bat" "%BUILD_DIR%\" >nul
copy "%SCRIPT_DIR%templates\run.bat" "%BUILD_DIR%\" >nul

REM Create config file with version info
(
echo NUNCHAKU_VERSION=!NUNCHAKU_VERSION!
echo PYTHON_VERSION=3.11.11
echo TORCH_VERSION=2.9.1
echo CUDA_VERSION=cu128
) > config.txt

REM Create README
(
echo ComfyUI-nunchaku Minimal Portable Package
echo ==========================================
echo.
echo This is a minimal portable package that requires initial setup.
echo.
echo FIRST TIME SETUP:
echo   1. Run install.bat to install all dependencies
echo      - This will download Python, PyTorch, and nunchaku
echo      - Internet connection required
echo      - Takes about 10-15 minutes
echo.
echo   2. After installation completes, run run.bat to start ComfyUI
echo.
echo SUBSEQUENT USAGE:
echo   - Simply run run.bat to start ComfyUI
echo.
echo Configuration:
echo   - Nunchaku: v!NUNCHAKU_VERSION!
echo   - Python: 3.11.11
echo   - PyTorch: 2.9.1+cu128
echo   - Build Date: %DATE% %TIME%
echo.
echo For more information, visit:
echo   https://github.com/nunchaku-ai/ComfyUI-nunchaku
) > README.txt

echo.
echo ============================================
echo  Build completed successfully!
echo ============================================
echo.
echo Output: %BUILD_DIR%
echo.
echo Package contents:
echo   - ComfyUI with nunchaku plugin
echo   - install.bat: First-time setup script
echo   - run.bat: Launch ComfyUI
echo   - README.txt: Usage instructions
echo.
echo Package size: ~50-100 MB
echo Installation will download an additional ~2 GB of dependencies.
echo.

cd /d "%WORK_DIR%"
goto :end

:error
echo.
echo Build failed!
cd /d "%WORK_DIR%"
exit /b 1

:end
if not defined CI_BUILD pause
