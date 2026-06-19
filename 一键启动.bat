@echo off
chcp 65001 >nul
title IoT可视化面板 - 一键启动

echo.
echo ================================================
echo        IoT可视化面板 - 一键启动
echo ================================================
echo.

cd /d "%~dp0"

echo 检查Node.js...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] 未检测到 Node.js
    echo 正在打开安装程序...
    start "" "%~dp0检查安装依赖.bat"
    echo.
    echo 请等待安装完成后，重新运行"一键启动"
    echo.
    echo 本窗口将在 5 秒后自动关闭...
    timeout /t 5 /nobreak >nul
    exit /b
)

echo [OK] Node.js已安装
node --version
echo.

echo 安装项目依赖...
call npm install

echo.
echo 启动开发服务器...
start "IoT可视化面板-服务器" cmd /k "cd /d ""%~dp0"" && npm run dev"

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
echo 按任意键关闭此窗口...
pause >nul