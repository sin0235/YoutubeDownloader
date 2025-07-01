using YoutubeExplode.Videos;

namespace YoutubeDownloader.Web.Models;

public class VideoInfoDto
{
    public string Id { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Author { get; set; } = string.Empty;
    public string? Thumbnail { get; set; }
    public TimeSpan Duration { get; set; }
    public string Url { get; set; } = string.Empty;
    
    public static VideoInfoDto FromVideo(IVideo video)
    {
        return new VideoInfoDto
        {
            Id = video.Id,
            Title = video.Title,
            Author = video.Author.ChannelTitle,
            Thumbnail = video.Thumbnails.MaxBy(t => t.Resolution.Area)?.Url,
            Duration = video.Duration ?? TimeSpan.Zero,
            Url = video.Url
        };
    }
} 