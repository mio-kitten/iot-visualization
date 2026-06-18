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
    echo [ERROR] 未找到Node.js，请先安装Node.js
    echo 下载地址: https://nodejs.org/
    pause
    exit /b 1
)

echo [OK] Node.js已安装
node --version
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