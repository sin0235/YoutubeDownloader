# YouTube Downloader - Setup Tool
param(
    [ValidateSet("check", "deploy", "status", "help")]
    [string]$Action = "help",
    [string]$SiteName = "YoutubeDownloader-Production",
    [string]$AppPoolName = "YoutubeDownloaderPool-Prod",
    [string]$Port = "80",
    [string]$PhysicalPath = "C:\inetpub\wwwroot\YoutubeDownloader"
)

function Write-ColoredText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-Help {
    Write-ColoredText "=== YOUTUBE DOWNLOADER - SETUP TOOL ===" "Green"
    Write-ColoredText ""
    Write-ColoredText "CACH SU DUNG:" "Yellow"
    Write-ColoredText "  .\Setup.ps1 -Action <action>" "White"
    Write-ColoredText ""
    Write-ColoredText "CAC HANH DONG:" "Yellow"
    Write-ColoredText "  check   - Kiem tra he thong" "White"
    Write-ColoredText "  deploy  - Deploy website" "White"
    Write-ColoredText "  status  - Kiem tra trang thai" "White"
    Write-ColoredText "  help    - Huong dan" "White"
    Write-ColoredText ""
    Write-ColoredText "VI DU:" "Yellow"
    Write-ColoredText "  .\Setup.ps1 -Action check" "Cyan"
    Write-ColoredText "  .\Setup.ps1 -Action deploy" "Cyan"
    Write-ColoredText "  .\Setup.ps1 -Action deploy -Port 9000" "Cyan"
    Write-ColoredText "  .\Setup.ps1 -Action status" "Cyan"
}

function Check-System {
    Write-ColoredText "=== KIEM TRA HE THONG ===" "Green"
    Write-ColoredText ""

    Write-ColoredText "1. KIEM TRA QUYEN:" "Yellow"
    if (Test-AdminRights) {
        Write-ColoredText "[OK] Quyen Administrator" "Green"
    } else {
        Write-ColoredText "[ERROR] Can quyen Administrator!" "Red"
        Write-ColoredText "Giai phap: Chuot phai PowerShell -> Run as Administrator" "Cyan"
        return
    }

    Write-ColoredText ""
    Write-ColoredText "2. KIEM TRA IIS:" "Yellow"
    try {
        $iisFeature = Get-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
        if ($iisFeature.State -eq "Enabled") {
            Write-ColoredText "[OK] IIS WebServer Role" "Green"
        } else {
            Write-ColoredText "[ERROR] IIS chua duoc cai dat!" "Red"
            Write-ColoredText "Giai phap: Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All" "Cyan"
        }
    } catch {
        Write-ColoredText "[ERROR] Loi kiem tra IIS" "Red"
    }

    Write-ColoredText ""
    Write-ColoredText "3. KIEM TRA WEBADMINISTRATION:" "Yellow"
    try {
        Import-Module WebAdministration -ErrorAction Stop
        Write-ColoredText "[OK] WebAdministration Module" "Green"
    } catch {
        Write-ColoredText "[ERROR] WebAdministration khong kha dung!" "Red"
        Write-ColoredText "Giai phap: Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole" "Cyan"
    }

    Write-ColoredText ""
    Write-ColoredText "4. KIEM TRA .NET:" "Yellow"
    try {
        $dotnetInfo = dotnet --info 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColoredText "[OK] .NET SDK/Runtime" "Green"
        } else {
            Write-ColoredText "[ERROR] .NET Runtime khong tim thay!" "Red"
        }
    } catch {
        Write-ColoredText "[ERROR] Loi kiem tra .NET" "Red"
    }

    Write-ColoredText ""
    Write-ColoredText "5. KIEM TRA FILES BUILD:" "Yellow"
    $publishPath = ".\publish"
    if (Test-Path $publishPath) {
        $exeFile = Join-Path $publishPath "YoutubeDownloader.Web.exe"
        $dllFile = Join-Path $publishPath "YoutubeDownloader.Web.dll"
        $webConfig = Join-Path $publishPath "web.config"
        
        if (Test-Path $exeFile) { Write-ColoredText "[OK] YoutubeDownloader.Web.exe" "Green" }
        else { Write-ColoredText "[ERROR] YoutubeDownloader.Web.exe khong tim thay" "Red" }
        
        if (Test-Path $dllFile) { Write-ColoredText "[OK] YoutubeDownloader.Web.dll" "Green" }
        else { Write-ColoredText "[ERROR] YoutubeDownloader.Web.dll khong tim thay" "Red" }
        
        if (Test-Path $webConfig) { Write-ColoredText "[OK] web.config" "Green" }
        else { Write-ColoredText "[ERROR] web.config khong tim thay" "Red" }
    } else {
        Write-ColoredText "[ERROR] Thu muc publish khong ton tai!" "Red"
        Write-ColoredText "Giai phap: Chay dotnet publish --configuration Release --output .\publish" "Cyan"
    }

    Write-ColoredText ""
    Write-ColoredText "BUOC TIEP THEO: .\Setup.ps1 -Action deploy" "Green"
}

function Deploy-Website {
    Write-ColoredText "=== DEPLOY YOUTUBE DOWNLOADER ===" "Green"
    Write-ColoredText "Site: $SiteName - Port: $Port" "Yellow"
    Write-ColoredText "Path: $PhysicalPath" "Yellow"
    Write-ColoredText ""

    if (-NOT (Test-AdminRights)) {
        Write-ColoredText "[ERROR] Can quyen Administrator!" "Red"
        return
    }

    Import-Module WebAdministration

    try {
        # Stop Default Web Site neu dung port 80
        if ($Port -eq "80") {
            Write-ColoredText "1. Stop Default Web Site..." "Cyan"
            try {
                Stop-Website -Name "Default Web Site" -ErrorAction SilentlyContinue
                Write-ColoredText "[OK] Default Web Site stopped" "Green"
            } catch {
                Write-ColoredText "[INFO] Default Web Site da stop" "Yellow"
            }
        }

        # Tao thu muc
        Write-ColoredText ""
        Write-ColoredText "2. Tao thu muc..." "Cyan"
        if (!(Test-Path $PhysicalPath)) {
            New-Item -ItemType Directory -Path $PhysicalPath -Force | Out-Null
        }
        Write-ColoredText "[OK] Thu muc ready: $PhysicalPath" "Green"

        # Xoa site cu neu co
        Write-ColoredText ""
        Write-ColoredText "3. Clean up sites cu..." "Cyan"
        if (Get-Website -Name $SiteName -ErrorAction SilentlyContinue) {
            Remove-Website -Name $SiteName -Confirm:$false
            Write-ColoredText "[OK] Da xoa $SiteName cu" "Green"
        }

        # Xoa app pools cu
        if (Get-IISAppPool -Name $AppPoolName -ErrorAction SilentlyContinue) {
            Remove-WebAppPool -Name $AppPoolName -Confirm:$false
            Write-ColoredText "[OK] Da xoa $AppPoolName cu" "Green"
        }

        # Tao App Pool moi
        Write-ColoredText ""
        Write-ColoredText "4. Tao Application Pool..." "Cyan"
        New-WebAppPool -Name $AppPoolName
        Set-ItemProperty -Path "IIS:\AppPools\$AppPoolName" -Name "managedRuntimeVersion" -Value ""
        Set-ItemProperty -Path "IIS:\AppPools\$AppPoolName" -Name "startMode" -Value "AlwaysRunning"
        Set-ItemProperty -Path "IIS:\AppPools\$AppPoolName" -Name "processModel.idleTimeout" -Value "00:00:00"
        Write-ColoredText "[OK] App Pool created: $AppPoolName" "Green"

        # Tao Website
        Write-ColoredText ""
        Write-ColoredText "5. Tao Website..." "Cyan"
        New-Website -Name $SiteName -Port $Port -PhysicalPath $PhysicalPath -ApplicationPool $AppPoolName
        Write-ColoredText "[OK] Website created: $SiteName on port $Port" "Green"

        # Kiem tra va build files
        Write-ColoredText ""
        Write-ColoredText "6. Kiem tra files build..." "Cyan"
        $publishPath = ".\publish"
        if (!(Test-Path $publishPath)) {
            Write-ColoredText "[WARNING] Thu muc publish khong ton tai - tu dong build..." "Yellow"
            Write-ColoredText "Chay: dotnet publish --configuration Release --output .\publish" "Cyan"
            
            try {
                dotnet publish --configuration Release --output ".\publish"
                if ($LASTEXITCODE -eq 0) {
                    Write-ColoredText "[OK] Build thanh cong" "Green"
                } else {
                    Write-ColoredText "[ERROR] Build that bai!" "Red"
                    return
                }
            } catch {
                Write-ColoredText "[ERROR] Loi khi build: $($_.Exception.Message)" "Red"
                return
            }
        }

        # Copy files
        Write-ColoredText ""
        Write-ColoredText "7. Copy files..." "Cyan"
        Copy-Item -Path ".\publish\*" -Destination $PhysicalPath -Recurse -Force
        Write-ColoredText "[OK] Files copied to $PhysicalPath" "Green"

        # Set permissions
        Write-ColoredText ""
        Write-ColoredText "8. Set permissions..." "Cyan"
        $acl = Get-Acl $PhysicalPath
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS","FullControl","ContainerInherit,ObjectInherit","None","Allow")
        $acl.SetAccessRule($rule)
        Set-Acl $PhysicalPath $acl
        Write-ColoredText "[OK] Permissions set" "Green"

        # Cau hinh Windows Firewall
        Write-ColoredText ""
        Write-ColoredText "9. Cau hinh Windows Firewall..." "Cyan"
        try {
            New-NetFirewallRule -DisplayName "YouTubeDownloader-HTTP-$Port" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -ErrorAction SilentlyContinue
            Write-ColoredText "[OK] Firewall rule added for port $Port" "Green"
        } catch {
            Write-ColoredText "[WARNING] Khong the tu dong cau hinh firewall" "Yellow"
        }

        Write-ColoredText ""
        Write-ColoredText "=== DEPLOY THANH CONG! ===" "Green"
        $localIP = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty IPAddress
        Write-ColoredText "Local URL: http://localhost:$Port" "Yellow"
        if ($localIP) {
            Write-ColoredText "LAN URL: http://$localIP`:$Port" "Yellow"
        }

    } catch {
        Write-ColoredText ""
        Write-ColoredText "[ERROR] Deploy that bai: $($_.Exception.Message)" "Red"
    }
}

function Check-Status {
    Write-ColoredText "=== KIEM TRA TRANG THAI WEBSITE ===" "Green"
    Write-ColoredText ""

    # Kiem tra Local
    Write-ColoredText "1. KIEM TRA LOCAL:" "Yellow"
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $Port
        if ($connection.TcpTestSucceeded) {
            Write-ColoredText "[OK] Port $Port hoat dong" "Green"
            Write-ColoredText "    URL: http://localhost:$Port" "Cyan"
        } else {
            Write-ColoredText "[ERROR] Port $Port khong hoat dong" "Red"
        }
    } catch {
        Write-ColoredText "[ERROR] Khong the kiem tra port $Port" "Red"
    }

    # Kiem tra LAN
    Write-ColoredText ""
    Write-ColoredText "2. KIEM TRA LAN:" "Yellow"
    try {
        $localIP = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1 -ExpandProperty IPAddress
        Write-ColoredText "Local IP: $localIP" "Cyan"
        Write-ColoredText "LAN URL: http://$localIP`:$Port" "Cyan"
    } catch {
        Write-ColoredText "[WARNING] Khong lay duoc Local IP" "Yellow"
    }

    # Kiem tra IIS
    Write-ColoredText ""
    Write-ColoredText "3. KIEM TRA IIS:" "Yellow"
    try {
        $website = Get-Website -Name $SiteName -ErrorAction SilentlyContinue
        if ($website) {
            Write-ColoredText "[OK] Website: $($website.Name)" "Green"
            Write-ColoredText "    State: $($website.State)" "Cyan"
        } else {
            Write-ColoredText "[WARNING] Website $SiteName khong tim thay" "Yellow"
        }
        
        $appPool = Get-IISAppPool -Name $AppPoolName -ErrorAction SilentlyContinue  
        if ($appPool) {
            Write-ColoredText "[OK] App Pool: $($appPool.Name) - $($appPool.State)" "Green"
        } else {
            Write-ColoredText "[WARNING] App Pool khong tim thay" "Yellow"
        }
    } catch {
        Write-ColoredText "[ERROR] Loi kiem tra IIS" "Red"
    }
}

switch ($Action.ToLower()) {
    "check" { Check-System }
    "deploy" { Deploy-Website }
    "status" { Check-Status }
    "help" { Show-Help }
    default { Show-Help }
}
