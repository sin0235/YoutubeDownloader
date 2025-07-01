using Microsoft.AspNetCore.Mvc;
using YoutubeDownloader.Core.Downloading;
using YoutubeDownloader.Core.Resolving;
using YoutubeDownloader.Web.Models;
using YoutubeExplode.Videos;

namespace YoutubeDownloader.Web.Controllers;

[ApiController]
[Route("api/[controller]")]
public class VideosController : ControllerBase
{
    private readonly QueryResolver _queryResolver;
    private readonly VideoDownloader _videoDownloader;
    private readonly IWebHostEnvironment _environment;

    public VideosController(
        QueryResolver queryResolver,
        VideoDownloader videoDownloader,
        IWebHostEnvironment environment)
    {
        _queryResolver = queryResolver;
        _videoDownloader = videoDownloader;
        _environment = environment;
    }

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] string query)
    {
        try
        {
            var result = await _queryResolver.ResolveAsync(query);
            var videos = result.Videos.Select(VideoInfoDto.FromVideo).ToList();
            
            return Ok(new
            {
                kind = result.Kind.ToString(),
                title = result.Title,
                videos = videos
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("{videoId}/info")]
    public async Task<IActionResult> GetVideoInfo(string videoId)
    {
        try
        {
            var result = await _queryResolver.ResolveAsync($"https://youtube.com/watch?v={videoId}");
            var video = result.Videos.FirstOrDefault();
            
            if (video == null)
                return NotFound(new { error = "Video not found" });
                
            return Ok(VideoInfoDto.FromVideo(video));
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("{videoId}/download-options")]
    public async Task<IActionResult> GetDownloadOptions(string videoId)
    {
        try
        {
            var options = await _videoDownloader.GetDownloadOptionsAsync(videoId);
            
            var result = options.Select(opt => new
            {
                container = opt.Container.Name,
                isAudioOnly = opt.IsAudioOnly,
                videoQuality = opt.VideoQuality?.Label
            });
            
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("{videoId}/download")]
    public async Task<IActionResult> DownloadVideo(
        string videoId,
        [FromQuery] string container = "mp4",
        [FromQuery] string quality = "720p")
    {
        try
        {
            // Get video info
            var result = await _queryResolver.ResolveAsync($"https://youtube.com/watch?v={videoId}");
            var video = result.Videos.FirstOrDefault();
            
            if (video == null)
                return NotFound(new { error = "Video not found" });

            // Get download options
            var options = await _videoDownloader.GetDownloadOptionsAsync(videoId);
            
            // Find matching option
            var downloadOption = options.FirstOrDefault(opt =>
                opt.Container.Name.Equals(container, StringComparison.OrdinalIgnoreCase) &&
                (opt.VideoQuality?.Label.Contains(quality) ?? false))
                ?? options.FirstOrDefault(opt => opt.Container.Name.Equals(container, StringComparison.OrdinalIgnoreCase))
                ?? options.First();

            // Create temp file
            var fileName = $"{video.Title}.{downloadOption.Container.Name}";
            fileName = string.Concat(fileName.Split(Path.GetInvalidFileNameChars()));
            var tempPath = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}_{fileName}");

            // Download video
            await _videoDownloader.DownloadVideoAsync(
                tempPath,
                video,
                downloadOption,
                includeSubtitles: true
            );

            // Return file
            var fileBytes = await System.IO.File.ReadAllBytesAsync(tempPath);
            System.IO.File.Delete(tempPath);
            
            return File(fileBytes, $"video/{downloadOption.Container.Name}", fileName);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
} 