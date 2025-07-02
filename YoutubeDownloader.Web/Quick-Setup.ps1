# Quick Setup script cho IIS deployment
# Chay voi quyen Administrator

param(
    [string]$SiteName = "YoutubeDownloader",
    [string]$AppPoolName = "YoutubeDownloaderPool",
    [string]$Port = "80",
    [string]$PhysicalPath = "C:\inetpub\wwwroot\YoutubeDownloader"
)

Write-Host "=== Quick Setup cho IIS Deployment ===" -ForegroundColor Green

# Kiem tra quyen Administrator
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-NOT $isAdmin) {
    Write-Host "Script nay can chay voi quyen Administrator!" -ForegroundColor Red
    Write-Host "Hay mo PowerShell voi 'Run as Administrator' va chay lai." -ForegroundColor Yellow
    exit 1
}

# Import WebAdministration module
try {
    Import-Module WebAdministration -ErrorAction Stop
} catch {
    Write-Host "Khong the load WebAdministration module." -ForegroundColor Red
    Write-Host "Hay dam bao IIS da duoc cai dat." -ForegroundColor Red
    Write-Host "Chay lenh: Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All" -ForegroundColor Yellow
    exit 1
}

try {
    # 1. Tao thu muc physical path
    Write-Host ""
    Write-Host "1. Tao thu muc website..." -ForegroundColor Cyan
    if (!(Test-Path $PhysicalPath)) {
        New-Item -ItemType Directory -Path $PhysicalPath -Force | Out-Null
        Write-Host "Da tao thu muc: $PhysicalPath" -ForegroundColor Green
    } else {
        Write-Host "Thu muc da ton tai: $PhysicalPath" -ForegroundColor Yellow
    }

    # 2. Tao Application Pool
    Write-Host ""
    Write-Host "2. Tao Application Pool..." -ForegroundColor Cyan
    if (Get-IISAppPool -Name $AppPoolName -ErrorAction SilentlyContinue) {
        Write-Host "Application Pool '$AppPoolName' da ton tai" -ForegroundColor Yellow
        Remove-WebAppPool -Name $AppPoolName -Confirm:$false
        Write-Host "Da xoa Application Pool cu" -ForegroundColor Yellow
    }
    
    New-WebAppPool -Name $AppPoolName
    Set-ItemProperty -Path "IIS:\AppPools\$AppPoolName" -Name "managedRuntimeVersion" -Value ""
    Set-ItemProperty -Path "IIS:\AppPools\$AppPoolName" -Name "startMode" -Value "AlwaysRunning"
    Set-ItemProperty -Path "IIS:\AppPools\$AppPoolName" -Name "processModel.idleTimeout" -Value "00:00:00"
    Write-Host "Da tao Application Pool: $AppPoolName" -ForegroundColor Green

    # 3. Tao Website
    Write-Host ""
    Write-Host "3. Tao Website..." -ForegroundColor Cyan
    if (Get-Website -Name $SiteName -ErrorAction SilentlyContinue) {
        Write-Host "Website '$SiteName' da ton tai" -ForegroundColor Yellow
        Remove-Website -Name $SiteName -Confirm:$false
        Write-Host "Da xoa Website cu" -ForegroundColor Yellow
    }
    
    New-Website -Name $SiteName -Port $Port -PhysicalPath $PhysicalPath -ApplicationPool $AppPoolName
    Write-Host "Da tao Website: $SiteName tren port $Port" -ForegroundColor Green

    # 4. Cau hinh quyen truy cap
    Write-Host ""
    Write-Host "4. Cau hinh quyen truy cap..." -ForegroundColor Cyan
    $acl = Get-Acl $PhysicalPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl $PhysicalPath $acl
    Write-Host "Da cap quyen cho IIS_IUSRS" -ForegroundColor Green

    # 5. Tao thu muc logs
    Write-Host ""
    Write-Host "5. Tao thu muc logs..." -ForegroundColor Cyan
    $logsPath = Join-Path $PhysicalPath "logs"
    if (!(Test-Path $logsPath)) {
        New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
    }
    $acl = Get-Acl $logsPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $acl.SetAccessRule($accessRule)
    Set-Acl $logsPath $acl
    Write-Host "Da tao va cau hinh thu muc logs" -ForegroundColor Green

    Write-Host ""
    Write-Host "=== Setup hoan tat! ===" -ForegroundColor Green
    Write-Host "Website: $SiteName" -ForegroundColor Yellow
    Write-Host "Application Pool: $AppPoolName" -ForegroundColor Yellow
    Write-Host "Physical Path: $PhysicalPath" -ForegroundColor Yellow
    Write-Host "Port: $Port" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Buoc tiep theo:" -ForegroundColor Yellow
    Write-Host "1. Chay script Deploy-IIS.ps1 de build va publish ung dung" -ForegroundColor White
    Write-Host "2. Copy files tu thu muc publish den $PhysicalPath" -ForegroundColor White
    Write-Host "3. Truy cap http://localhost:$Port de kiem tra" -ForegroundColor White

} catch {
    Write-Host ""
    Write-Host "Loi trong qua trinh setup: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} 