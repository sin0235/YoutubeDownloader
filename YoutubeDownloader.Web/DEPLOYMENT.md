# Hướng dẫn triển khai YouTube Downloader Web trên IIS - Windows Server 2025

## Yêu cầu hệ thống

### Server Requirements
- Windows Server 2025
- IIS 10.0 trở lên với ASP.NET Core Module v2
- .NET 9.0 Runtime
- FFmpeg (tùy chọn, để hỗ trợ download video)

### Cài đặt Prerequisites

1. **Cài đặt IIS**
   ```powershell
   # Chạy PowerShell với quyền Administrator
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionDynamic
   ```

2. **Cài đặt ASP.NET Core Runtime**
   - Tải về từ: https://dotnet.microsoft.com/download/dotnet/9.0
   - Chọn "ASP.NET Core Runtime 9.x.x - Windows Hosting Bundle"
   - Chạy installer và restart server

3. **Cài đặt ASP.NET Core Module v2**
   ```powershell
   # Kiểm tra module đã được cài đặt
   Get-WindowsFeature -Name IIS-ASPNET* | Where-Object {$_.InstallState -eq "Installed"}
   ```

## Build và Deploy

### Bước 1: Build Application
```powershell
# Từ thư mục YoutubeDownloader.Web
.\Deploy-IIS.ps1 -OutputPath "C:\Deploy\YoutubeDownloader" -Configuration "Release"
```

### Bước 2: Cấu hình IIS

1. **Tạo Application Pool**
   ```powershell
   # Mở IIS Manager hoặc dùng PowerShell
   Import-Module WebAdministration
   New-WebAppPool -Name "YoutubeDownloaderPool"
   Set-ItemProperty -Path "IIS:\AppPools\YoutubeDownloaderPool" -Name "managedRuntimeVersion" -Value ""
   Set-ItemProperty -Path "IIS:\AppPools\YoutubeDownloaderPool" -Name "startMode" -Value "AlwaysRunning"
   Set-ItemProperty -Path "IIS:\AppPools\YoutubeDownloaderPool" -Name "processModel.idleTimeout" -Value "00:00:00"
   ```

2. **Tạo Website**
   ```powershell
   New-Website -Name "YoutubeDownloader" -Port 80 -PhysicalPath "C:\Deploy\YoutubeDownloader" -ApplicationPool "YoutubeDownloaderPool"
   ```

### Bước 3: Cấu hình Permissions
```powershell
# Cấp quyền cho IIS_IUSRS
$acl = Get-Acl "C:\Deploy\YoutubeDownloader"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($accessRule)
Set-Acl "C:\Deploy\YoutubeDownloader" $acl

# Tạo thư mục logs
New-Item -ItemType Directory -Path "C:\Deploy\YoutubeDownloader\logs" -Force
$acl = Get-Acl "C:\Deploy\YoutubeDownloader\logs"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($accessRule)
Set-Acl "C:\Deploy\YoutubeDownloader\logs" $acl
```

## Cấu hình FFmpeg (Tùy chọn)

1. **Tải FFmpeg**
   - Tải từ: https://ffmpeg.org/download.html
   - Giải nén đến `C:\FFmpeg`

2. **Cập nhật đường dẫn trong appsettings.Production.json**
   ```json
   {
     "FFmpeg": {
       "Path": "C:\\FFmpeg\\bin\\ffmpeg.exe"
     }
   }
   ```

## SSL/HTTPS Configuration

### Cài đặt SSL Certificate
```powershell
# Bind certificate đến website
New-WebBinding -Name "YoutubeDownloader" -Protocol "https" -Port 443
# Sau đó assign certificate trong IIS Manager
```

## Kiểm tra Deployment

1. **Kiểm tra website**
   - Truy cập: `http://your-server-ip`
   - API docs: `http://your-server-ip/api-docs`

2. **Kiểm tra logs**
   ```powershell
   Get-Content "C:\Deploy\YoutubeDownloader\logs\stdout*.log" -Tail 50
   ```

3. **Kiểm tra Windows Event Log**
   ```powershell
   Get-EventLog -LogName Application -Source "IIS AspNetCore Module V2" -Newest 10
   ```

## Troubleshooting

### Lỗi thường gặp

1. **500.19 Error**
   - Kiểm tra ASP.NET Core Module đã được cài đặt
   - Kiểm tra quyền truy cập file web.config

2. **500.30 Error**
   - Kiểm tra .NET Runtime đã được cài đặt
   - Kiểm tra Application Pool settings

3. **500.31 Error**
   - Kiểm tra đường dẫn trong web.config
   - Kiểm tra quyền truy cập thư mục

### Debug Commands
```powershell
# Kiểm tra process
Get-Process -Name "dotnet" | Select-Object Id,ProcessName,StartTime

# Kiểm tra Application Pool
Get-IISAppPool "YoutubeDownloaderPool"

# Test endpoint
Invoke-WebRequest -Uri "http://localhost/api/videos" -Method GET
```

## Performance Tuning

### IIS Settings
```xml
<!-- Thêm vào web.config -->
<system.webServer>
  <httpCompression directory="%SystemDrive%\inetpub\temp\IIS Temporary Compressed Files">
    <scheme name="gzip" dll="%Windir%\system32\inetsrv\gzip.dll" />
    <dynamicTypes>
      <add mimeType="text/*" enabled="true" />
      <add mimeType="message/*" enabled="true" />
      <add mimeType="application/javascript" enabled="true" />
      <add mimeType="application/json" enabled="true" />
    </dynamicTypes>
  </httpCompression>
</system.webServer>
```

### Monitoring
```powershell
# Theo dõi performance
Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 5 -MaxSamples 12
Get-Counter "\Memory\Available MBytes" -SampleInterval 5 -MaxSamples 12
``` 