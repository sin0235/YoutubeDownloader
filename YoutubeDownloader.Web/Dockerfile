# Minimal Dockerfile - Giải quyết triệt để lỗi NuGet
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Thiết lập hoàn toàn environment để tránh Windows paths
ENV NUGET_PACKAGES=/tmp/nuget-packages
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
ENV HOME=/tmp
ENV DOTNET_ROOT=/usr/share/dotnet

# Tạo NuGet.config mới để override mọi settings
RUN echo '<?xml version="1.0" encoding="utf-8"?>' > /tmp/nuget.config && \
    echo '<configuration>' >> /tmp/nuget.config && \
    echo '  <config>' >> /tmp/nuget.config && \
    echo '    <add key="globalPackagesFolder" value="/tmp/nuget-packages" />' >> /tmp/nuget.config && \
    echo '  </config>' >> /tmp/nuget.config && \
    echo '  <packageSources>' >> /tmp/nuget.config && \
    echo '    <clear />' >> /tmp/nuget.config && \
    echo '    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />' >> /tmp/nuget.config && \
    echo '  </packageSources>' >> /tmp/nuget.config && \
    echo '</configuration>' >> /tmp/nuget.config

# Copy source code (loại trừ thư mục có thể chứa cache)
COPY YoutubeDownloader.sln ./
COPY Directory.Build.props ./
COPY YoutubeDownloader.Web/*.csproj YoutubeDownloader.Web/
COPY YoutubeDownloader.Core/*.csproj YoutubeDownloader.Core/

# Restore với config mới
RUN dotnet restore YoutubeDownloader.Web/YoutubeDownloader.Web.csproj \
    --configfile /tmp/nuget.config \
    --packages /tmp/nuget-packages \
    --force \
    --no-cache

# Copy rest of source code
COPY YoutubeDownloader.Web/ YoutubeDownloader.Web/
COPY YoutubeDownloader.Core/ YoutubeDownloader.Core/

# Build và publish
RUN dotnet publish YoutubeDownloader.Web/YoutubeDownloader.Web.csproj \
    -c Release \
    -o /app/publish \
    --no-restore \
    --packages /tmp/nuget-packages

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

# Cài đặt FFmpeg và wget
RUN apt-get update && \
    apt-get install -y ffmpeg wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy published application
COPY --from=build /app/publish .

# Tạo thư mục downloads
RUN mkdir -p /app/downloads && \
    chmod 777 /app/downloads

# Set environment variables
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:8080

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/swagger/index.html || exit 1

# Run application
ENTRYPOINT ["dotnet", "YoutubeDownloader.Web.dll"] 