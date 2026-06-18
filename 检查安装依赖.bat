@echo off
chcp 65001 >nul
title IoT可视化面板启动器

echo.
echo ================================================
echo        IoT可视化面板 - 一键启动器
echo ================================================
echo.

set "NODE_VERSION=20.11.0"
set "NPM_REGISTRY=https://registry.npmmirror.com"
set "NODE_LOCAL_DIR=F:\日常\VS Code代码文件\串口显示\node-v24.16.0-x64"

set "WORK_DIR="
for %%d in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
    if not defined WORK_DIR (
        if exist "%%d:\" (
            set "WORK_DIR=%%d:\IoT_Visualization_Server"
        )
    )
)

if not defined WORK_DIR (
    set "WORK_DIR=%USERPROFILE%\IoT_Visualization_Server"
)

echo 工作目录: %WORK_DIR%
echo.

if not exist "%WORK_DIR%" (
    echo 创建工作目录...
    mkdir "%WORK_DIR%"
)

cd /d "%WORK_DIR%"

where node >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Node.js 已安装
    node --version
) else (
    echo [WARNING] Node.js 未安装

    set "NODE_LOCAL_SOURCE=%NODE_LOCAL_DIR%"
    set "NODE_DIR=%WORK_DIR%\node"
    set "NODE_MSI=%~dp0node-v24.16.0-x64.msi"

    if exist "%NODE_MSI%" (
        echo 检测到本地 Node.js 安装包，正在启动安装程序...
        echo 请按照安装向导完成 Node.js 的安装
        echo 安装完成后请重新运行此启动器
        start "" "%NODE_MSI%"
        pause
        exit /b
    ) else if exist "%NODE_LOCAL_SOURCE%\node.exe" (
        echo 使用本地 Node 安装包: %NODE_LOCAL_SOURCE%
        if not exist "%NODE_DIR%" (
            xcopy /E /I /Y "%NODE_LOCAL_SOURCE%" "%NODE_DIR%" >nul
        )
    ) else (
        echo 本地 Node 安装包不存在，正在下载 Node.js %NODE_VERSION%...
        set "NODE_URL=https://npmmirror.com/mirrors/node/v%NODE_VERSION%/node-v%NODE_VERSION%-win-x64.zip"
        set "NODE_ZIP=%WORK_DIR%\node.zip"

        if not exist "%NODE_DIR%" (
            echo 下载 Node.js %NODE_VERSION%...
            powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%NODE_URL%', '%NODE_ZIP%')"
            
            echo 解压 Node.js...
            powershell -Command "Expand-Archive -Path '%NODE_ZIP%' -DestinationPath '%WORK_DIR%' -Force"
            rename "%WORK_DIR%\node-v%NODE_VERSION%-win-x64" "node"
            del "%NODE_ZIP%"
        )
    )

    set "PATH=%NODE_DIR%;%NODE_DIR%\node_modules\.bin;%PATH%"
    echo [OK] Node.js 已准备就绪
)

echo.
echo 检查项目文件...
set "PROJECT_DIR=%WORK_DIR%\project"

if not exist "%PROJECT_DIR%" (
    echo 初始化项目...
    mkdir "%PROJECT_DIR%"
    cd /d "%PROJECT_DIR%"
    
    echo 设置 npm 镜像...
    npm config set registry %NPM_REGISTRY%
    
    echo 初始化 Vue 项目...
    npm create vite@6.5.0 . -- --template vue-ts
    
    echo 安装依赖...
    npm install
    
    echo 安装额外依赖...
    npm install chart.js vue-chartjs mqtt
    
    echo 复制应用文件...
    xcopy /E /Y "%~dp0src" "%PROJECT_DIR%\src\"
    xcopy /E /Y "%~dp0electron" "%PROJECT_DIR%\electron\" 2>nul
    copy "%~dp0index.html" "%PROJECT_DIR%\"
    copy "%~dp0package.json" "%PROJECT_DIR%\"
    copy "%~dp0vite.config.ts" "%PROJECT_DIR%\"
    copy "%~dp0tsconfig.json" "%PROJECT_DIR%\"
    copy "%~dp0tsconfig.node.json" "%PROJECT_DIR%\"
)

cd /d "%PROJECT_DIR%"

echo.
echo 构建项目...
npm run build

echo.
echo 启动开发服务器...
start cmd /k "cd /d ""%PROJECT_DIR%"" && npm run dev"

echo.
echo 等待服务器启动...
timeout /t 3 /nobreak >nul

echo 打开浏览器...
start http://localhost:5173

echo.
echo ================================================
echo              启动完成！
echo ================================================
echo 浏览器将自动打开，请稍候...
echo.
echo 如果浏览器没有自动打开，请手动访问:
echo http://localhost:5173
echo.
pause