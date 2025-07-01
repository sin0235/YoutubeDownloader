#!/bin/bash

echo "🐳 Building YouTube Downloader Docker Image..."

# Tạo thư mục downloads nếu chưa có
mkdir -p downloads

# Build Docker image
docker build -f YoutubeDownloader.Web/Dockerfile -t youtube-downloader-web:latest .

if [ $? -eq 0 ]; then
    echo "✅ Build thành công!"
    echo ""
    echo "🚀 Để chạy ứng dụng, sử dụng một trong các lệnh sau:"
    echo ""
    echo "1. Chạy với Docker:"
    echo "   docker run -d -p 8080:8080 -v \$(pwd)/downloads:/app/downloads --name youtube-downloader youtube-downloader-web:latest"
    echo ""
    echo "2. Chạy với Docker Compose:"
    echo "   docker-compose up -d"
    echo ""
    echo "📖 Sau khi chạy, truy cập:"
    echo "   - API Documentation: http://localhost:8080/swagger"
    echo "   - Web Interface: http://localhost:8080"
else
    echo "❌ Build thất bại!"
    exit 1
fi 