@echo off
echo 🐳 Building YouTube Downloader Docker Image...

REM Tạo thư mục downloads nếu chưa có
if not exist "downloads" mkdir downloads

REM Build Docker image
docker build -f YoutubeDownloader.Web/Dockerfile -t youtube-downloader-web:latest .

if %ERRORLEVEL% EQU 0 (
    echo ✅ Build thành công!
    echo.
    echo 🚀 Để chạy ứng dụng, sử dụng một trong các lệnh sau:
    echo.
    echo 1. Chạy với Docker:
    echo    docker run -d -p 8080:8080 -v "%cd%/downloads:/app/downloads" --name youtube-downloader youtube-downloader-web:latest
    echo.
    echo 2. Chạy với Docker Compose:
    echo    docker-compose up -d
    echo.
    echo 📖 Sau khi chạy, truy cập:
    echo    - API Documentation: http://localhost:8080/swagger
    echo    - Web Interface: http://localhost:8080
) else (
    echo ❌ Build thất bại!
    exit /b 1
) 