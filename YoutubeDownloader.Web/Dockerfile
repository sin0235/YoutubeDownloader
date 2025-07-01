# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy solution file và project files
COPY YoutubeDownloader.sln ./
COPY YoutubeDownloader.Web/YoutubeDownloader.Web.csproj YoutubeDownloader.Web/
COPY YoutubeDownloader.Core/YoutubeDownloader.Core.csproj YoutubeDownloader.Core/
COPY NuGet.config ./
COPY Directory.Build.props ./

# Restore dependencies
RUN dotnet restore YoutubeDownloader.Web/YoutubeDownloader.Web.csproj

# Copy source code
COPY YoutubeDownloader.Web/ YoutubeDownloader.Web/
COPY YoutubeDownloader.Core/ YoutubeDownloader.Core/

# Build application
RUN dotnet build YoutubeDownloader.Web/YoutubeDownloader.Web.csproj -c Release --no-restore

# Publish application
RUN dotnet publish YoutubeDownloader.Web/YoutubeDownloader.Web.csproj -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

# Cài đặt FFmpeg, wget và các dependencies cần thiết
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

# Expose ports
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/swagger/index.html || exit 1

# Run application
ENTRYPOINT ["dotnet", "YoutubeDownloader.Web.dll"] 