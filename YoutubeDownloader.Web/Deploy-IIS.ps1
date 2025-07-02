# Deploy script cho IIS trên Windows Server 2025
param(
    [string]$OutputPath = ".\publish",
    [string]$Configuration = "Release"
)

Write-Host "=== YouTube Downloader Web - IIS Deployment Script ===" -ForegroundColor Green
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Output Path: $OutputPath" -ForegroundColor Yellow

# Tạo thư mục output nếu chưa có
if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

# Clean và Restore packages
Write-Host "`nRestoring NuGet packages..." -ForegroundColor Cyan
dotnet restore

# Build solution
Write-Host "`nBuilding solution..." -ForegroundColor Cyan
dotnet build --configuration $Configuration --no-restore

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

# Publish web application
Write-Host "`nPublishing web application..." -ForegroundColor Cyan
dotnet publish --configuration $Configuration --output $OutputPath --no-build --verbosity normal

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n=== Deployment files ready ===" -ForegroundColor Green
    Write-Host "Location: $OutputPath" -ForegroundColor Yellow
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Copy files từ '$OutputPath' đến thư mục IIS (ví dụ: C:\inetpub\wwwroot\YoutubeDownloader)" -ForegroundColor White
    Write-Host "2. Tạo Application Pool mới trong IIS Manager" -ForegroundColor White
    Write-Host "3. Cấu hình Application Pool với .NET CLR Version = 'No Managed Code'" -ForegroundColor White
    Write-Host "4. Tạo Website hoặc Application trong IIS" -ForegroundColor White
    Write-Host "5. Đảm bảo IIS_IUSRS có quyền truy cập thư mục" -ForegroundColor White
    Write-Host "6. Cài đặt ASP.NET Core Runtime trên server nếu chưa có" -ForegroundColor White
} else {
    Write-Host "`nPublish failed!" -ForegroundColor Red
    exit 1
} 