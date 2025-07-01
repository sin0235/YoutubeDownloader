// State management
let currentVideo = null;
let selectedOption = null;

// DOM elements
const searchInput = document.getElementById('searchInput');
const searchBtn = document.getElementById('searchBtn');
const loading = document.getElementById('loading');
const results = document.getElementById('results');
const resultTitle = document.getElementById('resultTitle');
const videoList = document.getElementById('videoList');
const selectedVideoSection = document.getElementById('selectedVideo');
const videoThumbnail = document.getElementById('videoThumbnail');
const videoTitle = document.getElementById('videoTitle');
const videoAuthor = document.getElementById('videoAuthor');
const videoDuration = document.getElementById('videoDuration');
const downloadOptions = document.getElementById('downloadOptions');
const downloadBtn = document.getElementById('downloadBtn');
const toast = document.getElementById('toast');

// API base URL
const API_URL = '/api/videos';

// Event listeners
searchBtn.addEventListener('click', handleSearch);
searchInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') handleSearch();
});
downloadBtn.addEventListener('click', handleDownload);

// Functions
async function handleSearch() {
    const query = searchInput.value.trim();
    if (!query) {
        showToast('Vui lòng nhập URL video hoặc từ khóa tìm kiếm', 'error');
        return;
    }

    showLoading(true);
    hideResults();
    hideSelectedVideo();

    try {
        const response = await fetch(`${API_URL}/search?query=${encodeURIComponent(query)}`);
        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || 'Có lỗi xảy ra');
        }

        displayResults(data);
    } catch (error) {
        showToast(error.message, 'error');
    } finally {
        showLoading(false);
    }
}

function displayResults(data) {
    resultTitle.textContent = data.title;
    videoList.innerHTML = '';

    if (data.videos.length === 0) {
        videoList.innerHTML = '<p>Không tìm thấy video nào</p>';
        results.classList.remove('hidden');
        return;
    }

    data.videos.forEach(video => {
        const card = createVideoCard(video);
        videoList.appendChild(card);
    });

    results.classList.remove('hidden');
}

function createVideoCard(video) {
    const card = document.createElement('div');
    card.className = 'video-card';
    const placeholderImg = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='320' height='180' viewBox='0 0 320 180'%3E%3Crect fill='%23ddd' width='320' height='180'/%3E%3Ctext fill='%23999' font-family='sans-serif' font-size='20' x='50%25' y='50%25' text-anchor='middle' dy='.3em'%3ENo Thumbnail%3C/text%3E%3C/svg%3E";
    card.innerHTML = `
        <img src="${video.thumbnail || placeholderImg}" alt="${video.title}">
        <div class="video-card-info">
            <h3>${video.title}</h3>
            <p><i class="fas fa-user"></i> ${video.author}</p>
            <p><i class="fas fa-clock"></i> ${formatDuration(video.duration)}</p>
        </div>
    `;
    card.addEventListener('click', () => selectVideo(video));
    return card;
}

async function selectVideo(video) {
    currentVideo = video;
    showSelectedVideo(video);
    
    // Load download options
    showLoading(true);
    try {
        const response = await fetch(`${API_URL}/${video.id}/download-options`);
        const options = await response.json();
        
        if (!response.ok) {
            throw new Error(options.error || 'Không thể tải tùy chọn download');
        }
        
        displayDownloadOptions(options);
    } catch (error) {
        showToast(error.message, 'error');
    } finally {
        showLoading(false);
    }
}

function showSelectedVideo(video) {
    const placeholderImg = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='320' height='180' viewBox='0 0 320 180'%3E%3Crect fill='%23ddd' width='320' height='180'/%3E%3Ctext fill='%23999' font-family='sans-serif' font-size='20' x='50%25' y='50%25' text-anchor='middle' dy='.3em'%3ENo Thumbnail%3C/text%3E%3C/svg%3E";
    videoThumbnail.src = video.thumbnail || placeholderImg;
    videoTitle.textContent = video.title;
    videoAuthor.innerHTML = `<i class="fas fa-user"></i> ${video.author}`;
    videoDuration.innerHTML = `<i class="fas fa-clock"></i> ${formatDuration(video.duration)}`;
    selectedVideoSection.classList.remove('hidden');
}

function displayDownloadOptions(options) {
    downloadOptions.innerHTML = '';
    selectedOption = null;

    // Group options by container
    const groupedOptions = {};
    options.forEach(opt => {
        if (!groupedOptions[opt.container]) {
            groupedOptions[opt.container] = [];
        }
        groupedOptions[opt.container].push(opt);
    });

    // Display options
    Object.entries(groupedOptions).forEach(([container, opts]) => {
        opts.forEach(opt => {
            const card = document.createElement('div');
            card.className = 'option-card';
            card.innerHTML = `
                <h4>${container.toUpperCase()}</h4>
                <p>${opt.videoQuality || (opt.isAudioOnly ? 'Chỉ âm thanh' : 'Video')}</p>
            `;
            card.addEventListener('click', () => {
                document.querySelectorAll('.option-card').forEach(c => c.classList.remove('selected'));
                card.classList.add('selected');
                selectedOption = opt;
            });
            downloadOptions.appendChild(card);
        });
    });

    // Select first option by default
    if (downloadOptions.firstChild) {
        downloadOptions.firstChild.click();
    }
}

async function handleDownload() {
    if (!currentVideo || !selectedOption) {
        showToast('Vui lòng chọn video và định dạng tải xuống', 'error');
        return;
    }

    showLoading(true);
    showToast('Đang chuẩn bị tải xuống...', 'success');

    try {
        const quality = selectedOption.videoQuality?.replace(/[^0-9]/g, '') || '720';
        const response = await fetch(
            `${API_URL}/${currentVideo.id}/download?container=${selectedOption.container}&quality=${quality}p`,
            { method: 'POST' }
        );

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || 'Có lỗi xảy ra khi tải xuống');
        }

        // Get filename from Content-Disposition header
        const contentDisposition = response.headers.get('Content-Disposition');
        const fileName = contentDisposition
            ? contentDisposition.split('filename=')[1].replace(/"/g, '')
            : `${currentVideo.title}.${selectedOption.container}`;

        // Download file
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.style.display = 'none';
        a.href = url;
        a.download = fileName;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);

        showToast('Tải xuống thành công!', 'success');
    } catch (error) {
        showToast(error.message, 'error');
    } finally {
        showLoading(false);
    }
}

// Helper functions
function formatDuration(duration) {
    const parts = duration.split(':');
    if (parts.length === 3) {
        const [hours, minutes, seconds] = parts;
        return hours === '00' ? `${minutes}:${seconds}` : `${hours}:${minutes}:${seconds}`;
    }
    return duration;
}

function showLoading(show) {
    if (show) {
        loading.classList.remove('hidden');
    } else {
        loading.classList.add('hidden');
    }
}

function hideResults() {
    results.classList.add('hidden');
}

function hideSelectedVideo() {
    selectedVideoSection.classList.add('hidden');
}

function showToast(message, type = 'info') {
    toast.textContent = message;
    toast.className = `toast ${type} show`;
    
    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    // Check if URL contains a video ID
    const urlParams = new URLSearchParams(window.location.search);
    const videoUrl = urlParams.get('v');
    if (videoUrl) {
        searchInput.value = `https://youtube.com/watch?v=${videoUrl}`;
        handleSearch();
    }
}); 