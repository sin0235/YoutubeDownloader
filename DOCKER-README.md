# YouTube Downloader - Docker Setup

## Yêu cầu
- Docker Desktop
- Docker Compose (thường đi kèm với Docker Desktop)

## Cách sử dụng

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

## Troubleshooting

### 1. Port đã được sử dụng
Nếu port 8080 đã được sử dụng, thay đổi port mapping trong `docker-compose.yml`:
```yaml
ports:
  - "8081:8080"
```

### 2. Permission issues với downloads folder
```bash
sudo chmod 777 downloads
```

### 3. FFmpeg không hoạt động
FFmpeg đã được cài đặt trong Docker image. Nếu vẫn có lỗi, kiểm tra logs:
```bash
docker-compose logs youtube-downloader-web
```

### 4. Health check failed
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

## Development

Để rebuild image sau khi thay đổi code:
```bash
docker-compose build --no-cache
docker-compose up -d
``` 