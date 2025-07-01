using YoutubeDownloader.Core.Downloading;
using YoutubeDownloader.Core.Resolving;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add CORS policy
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder
            .AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

// Register core services
builder.Services.AddScoped<QueryResolver>();
builder.Services.AddScoped<VideoDownloader>();

// Check FFmpeg availability
if (!FFmpeg.IsAvailable())
{
    Console.WriteLine("WARNING: FFmpeg not found. Download functionality may be limited.");
}

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();
app.MapControllers();
app.MapFallbackToFile("index.html");

app.Run(); 