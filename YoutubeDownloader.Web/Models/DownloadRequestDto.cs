namespace YoutubeDownloader.Web.Models;

public class DownloadRequestDto
{
    public string VideoId { get; set; } = string.Empty;
    public string Container { get; set; } = "mp4";
    public string? Quality { get; set; }
    public bool IncludeSubtitles { get; set; } = true;
} 