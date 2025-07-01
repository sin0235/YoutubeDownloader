# 🐳 YouTube Downloader - Docker Setup (.NET 8.0)

## ✅ Đã chuyển sang .NET 8.0 và sẵn sàng sử dụng!

## 🚀 Quick Start

### Windows:
```cmd
build-docker.bat
```

### Linux/Mac:
```bash
chmod +x build-docker.sh
./build-docker.sh
```

### Hoặc Docker Compose:
```bash
docker-compose up -d
```

**Truy cập**: http://localhost:8080

---

## Yêu cầu
- Docker Desktop
- Docker Compose (thường đi kèm với Docker Desktop)

## Cách sử dụng chi tiết

### 1. Build Image

#### Windows:
```cmd
build-docker.bat
```

#### Linux/Mac:
```bash
chmod +x build-docker.sh
./build-docker.sh
```

### 2. Chạy ứng dụng

#### Option 1: Docker Compose (Khuyến nghị)
```bash
docker-compose up -d
```

#### Option 2: Docker run trực tiếp
```bash
docker run -d \
  -p 8080:8080 \
  -v $(pwd)/downloads:/app/downloads \
  --name youtube-downloader \
  youtube-downloader-web:latest
```

### 3. Truy cập ứng dụng

- **Web Interface**: http://localhost:8080
- **API Documentation**: http://localhost:8080/swagger
- **API Base URL**: http://localhost:8080/api

### 4. Quản lý Container

#### Xem logs:
```bash
docker-compose logs -f youtube-downloader-web
```

#### Dừng ứng dụng:
```bash
docker-compose down
```

#### Khởi động lại:
```bash
docker-compose restart
```

#### Xóa container và volume:
```bash
docker-compose down -v
```

## Cấu hình

### Environment Variables
Bạn có thể tùy chỉnh các biến môi trường trong `docker-compose.yml`:

```yaml
environment:
  - ASPNETCORE_ENVIRONMENT=Production
  - ASPNETCORE_URLS=http://+:8080
```

### Volume Mapping
File đã download sẽ được lưu trong thư mục `./downloads` trên host machine:

```yaml
volumes:
  - ./downloads:/app/downloads
```

### Ports
Ứng dụng chạy trên port 8080. Để thay đổi port:

```yaml
ports:
  - "9000:8080"  # Truy cập qua port 9000
```

## Dockerfile

**`YoutubeDownloader.Web/Dockerfile`** - Dockerfile cho .NET 8.0:
- ✅ Target Framework: .NET 8.0 (LTS)
- ✅ Giải quyết lỗi NuGet Windows paths
- ✅ Multi-stage build cho kích thước image nhỏ
- ✅ Cài đặt sẵn FFmpeg và wget
- ✅ Simple và ổn định trên mọi môi trường

## Troubleshooting

### 1. Lỗi NuGet packages path (Windows paths trong Linux container)
Nếu gặp lỗi `Unable to find fallback package folder 'C:\Program Files (x86)\Microsoft Visual Studio\Shared\NuGetPackages'`:

#### Giải pháp: Build với force clean
```bash
docker build --no-cache -f YoutubeDownloader.Web/Dockerfile -t youtube-downloader-web:latest .
```

Hoặc sử dụng script có sẵn:
```bash
# Windows
build-docker.bat

# Linux/Mac
./build-docker.sh
```

### 2. Port đã được sử dụng
Nếu port 8080 đã được sử dụng, thay đổi port mapping trong `docker-compose.yml`:
```yaml
ports:
  - "8081:8080"
```

### 3. Permission issues với downloads folder
```bash
sudo chmod 777 downloads
```

### 4. FFmpeg không hoạt động
FFmpeg đã được cài đặt trong Docker image. Nếu vẫn có lỗi, kiểm tra logs:
```bash
docker-compose logs youtube-downloader-web
```

### 5. Health check failed
Đợi khoảng 40 giây để ứng dụng khởi động hoàn toàn. Nếu vẫn lỗi, kiểm tra:
```bash
docker-compose ps
docker-compose logs youtube-downloader-web
```

## API Usage

### Download a video:
```bash
curl -X POST "http://localhost:8080/api/videos/download" \
     -H "Content-Type: application/json" \
     -d '{
       "url": "https://www.youtube.com/watch?v=VIDEO_ID",
       "quality": "best"
     }'
```

### Get video info:
```bash
curl "http://localhost:8080/api/videos/info?url=https://www.youtube.com/watch?v=VIDEO_ID"
```

## ⚡ Lệnh hữu ích

```bash
# Xem logs
docker-compose logs -f

# Dừng ứng dụng  
docker-compose down

# Khởi động lại
docker-compose restart

# Rebuild từ đầu
docker-compose build --no-cache
docker-compose up -d
```

## 🔧 Đã giải quyết

- ✅ **Migrated to .NET 8.0 LTS** - Stable long-term support
- ✅ Lỗi NuGet packages path trong Docker
- ✅ FFmpeg được cài đặt sẵn  
- ✅ Health check tự động
- ✅ Volume mapping cho downloads
- ✅ Environment variables optimized

**YouTube Downloader hoạt động ổn định với .NET 8.0 trong Docker!** 🎉 