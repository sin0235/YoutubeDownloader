# Simple Dockerfile for .NET 8.0
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Set environment variables
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1

# Copy all source code
COPY . .

# Clean, restore, and build
RUN dotnet clean && \
    dotnet restore YoutubeDownloader.Web/YoutubeDownloader.Web.csproj --force --no-cache && \
    dotnet publish YoutubeDownloader.Web/YoutubeDownloader.Web.csproj \
    -c Release \
    -o /app/publish \
    --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Install FFmpeg và wget
RUN apt-get update && \
    apt-get install -y ffmpeg wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy published application
COPY --from=build /app/publish .

# Create downloads directory
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