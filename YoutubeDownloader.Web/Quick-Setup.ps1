# Quick Setup script cho IIS deployment
# Chạy với quyền Administrator

param(
    [string]$SiteName = "YoutubeDownloader",
    [string]$AppPoolName = "YoutubeDownloaderPool",
    [string]$Port = "80",
    [string]$PhysicalPath = "C:\inetpub\wwwroot\YoutubeDownloader"
)

Write-Host "=== Quick Setup cho IIS Deployment ===" -ForegroundColor Green

# Kiểm tra quyền Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Script này cần chạy với quyền Administrator!" -ForegroundColor Red
    Write-Host "Hãy mở PowerShell với 'Run as Administrator' và chạy lại." -ForegroundColor Yellow
    exit 1
}

# Import WebAdministration module
Import-Module WebAdministration -ErrorAction SilentlyContinue
if (-not (Get-Module WebAdministration)) {
    Write-Host "Không thể load WebAdministration module. Hãy đảm bảo IIS đã được cài đặt." -ForegroundColor Red
    exit 1
}

try {
    # 1. Tạo thư mục physical path
    Write-Host "`n1. Tạo thư mục website..." -ForegroundColor Cyan
    if (!(Test-Path $PhysicalPath)) {
        New-Item -ItemType Directory -Path $PhysicalPath -Force
        Write-Host "Đã tạo thư mục: $PhysicalPath" -ForegroundColor Green
    } else {
        Write-Host "Thư mục đã tồn tại: $PhysicalPath" -ForegroundColor Yellow
    }

    # 2. Tạo Application Pool
    Write-Host "`n2. Tạo Application Pool..." -ForegroundColor Cyan
    if (Get-IISAppPool -Name $AppPoolName -ErrorAction SilentlyContinue) {
        Write-Host "Application Pool '$AppPoolName' đã tồn tại" -ForegroundColor Yellow
        Remove-WebAppPool -Name $AppPoolName -Confirm:$false
        Write-Host "Đã xóa Application Pool cũ" -ForegroundColor Yellow
    }
    
    New-WebAppPool -Name $AppPoolName
    Set-ItemProperty -Path "IIS:\AppPools\$AppPoolName" -Name "managedRuntimeVersion" -Value ""
    Set-ItemProperty -Path "IIS:\AppPools\$AppPoolName" -Name "startMode" -Value "AlwaysRunning"
    Set-ItemProperty -Path "IIS:\AppPools\$AppPoolName" -Name "processModel.idleTimeout" -Value "00:00:00"
    Write-Host "Đã tạo Application Pool: $AppPoolName" -ForegroundColor Green

    # 3. Tạo Website
    Write-Host "`n3. Tạo Website..." -ForegroundColor Cyan
    if (Get-Website -Name $SiteName -ErrorAction SilentlyContinue) {
        Write-Host "Website '$SiteName' đã tồn tại" -ForegroundColor Yellow
        Remove-Website -Name $SiteName -Confirm:$false
        Write-Host "Đã xóa Website cũ" -ForegroundColor Yellow
    }
    
    New-Website -Name $SiteName -Port $Port -PhysicalPath $PhysicalPath -ApplicationPool $AppPoolName
    Write-Host "Đã tạo Website: $SiteName trên port $Port" -ForegroundColor Green

    # 4. Cấu hình quyền truy cập
    Write-Host "`n4. Cấu hình quyền truy cập..." -ForegroundColor Cyan
    $acl = Get-Acl $PhysicalPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl $PhysicalPath $acl
    Write-Host "Đã cấp quyền cho IIS_IUSRS" -ForegroundColor Green

    # 5. Tạo thư mục logs
    Write-Host "`n5. Tạo thư mục logs..." -ForegroundColor Cyan
    $logsPath = Join-Path $PhysicalPath "logs"
    if (!(Test-Path $logsPath)) {
        New-Item -ItemType Directory -Path $logsPath -Force
    }
    $acl = Get-Acl $logsPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl $logsPath $acl
    Write-Host "Đã tạo và cấu hình thư mục logs" -ForegroundColor Green

    Write-Host "`n=== Setup hoàn tất! ===" -ForegroundColor Green
    Write-Host "Website: $SiteName" -ForegroundColor Yellow
    Write-Host "Application Pool: $AppPoolName" -ForegroundColor Yellow
    Write-Host "Physical Path: $PhysicalPath" -ForegroundColor Yellow
    Write-Host "Port: $Port" -ForegroundColor Yellow
    Write-Host "`nBước tiếp theo:" -ForegroundColor Yellow
    Write-Host "1. Chạy script Deploy-IIS.ps1 để build và publish ứng dụng" -ForegroundColor White
    Write-Host "2. Copy files từ thư mục publish đến $PhysicalPath" -ForegroundColor White
    Write-Host "3. Truy cập http://localhost:$Port để kiểm tra" -ForegroundColor White

} catch {
    Write-Host "`nLỗi trong quá trình setup: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 