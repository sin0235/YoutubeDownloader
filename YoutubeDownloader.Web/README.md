# YouTube Downloader Web

Ứng dụng web để tải video từ YouTube, được xây dựng dựa trên YoutubeDownloader.Core.

## Tính năng

- 🔍 Tìm kiếm video theo URL hoặc từ khóa
- 📥 Tải video với nhiều định dạng và chất lượng khác nhau
- 🎵 Hỗ trợ tải chỉ âm thanh (MP3, OGG)
- 📱 Giao diện responsive, hoạt động tốt trên mọi thiết bị
- ⚡ Xử lý nhanh với YoutubeExplode

## Yêu cầu

- .NET 8.0 hoặc cao hơn
- FFmpeg (để chuyển đổi và merge video/audio)

## Cài đặt và chạy

1. Clone repository
2. Cài đặt FFmpeg:
   - Windows: Tải từ https://ffmpeg.org/download.html và thêm vào PATH
   - Linux: `sudo apt install ffmpeg`
   - macOS: `brew install ffmpeg`

3. Chạy ứng dụng:
```bash
cd YoutubeDownloader.Web
dotnet run
```

4. Mở trình duyệt và truy cập:
   - http://localhost:5000 (HTTP)
   - https://localhost:5001 (HTTPS)

## API Endpoints

- `GET /api/videos/search?query={query}` - Tìm kiếm video
- `GET /api/videos/{videoId}/info` - Lấy thông tin video
- `GET /api/videos/{videoId}/download-options` - Lấy các tùy chọn tải xuống
- `POST /api/videos/{videoId}/download?container={container}&quality={quality}` - Tải video

## Cấu trúc dự án

- `/Controllers` - API controllers
- `/Models` - Data transfer objects (DTOs)
- `/wwwroot` - Static files (HTML, CSS, JS)
- Sử dụng `YoutubeDownloader.Core` cho logic xử lý

## Lưu ý

- Ứng dụng này chỉ dành cho mục đích cá nhân
- Vui lòng tuân thủ điều khoản sử dụng của YouTube
- Một số video có thể không thể tải do giới hạn bản quyền 