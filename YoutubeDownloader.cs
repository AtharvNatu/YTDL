
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media.Imaging;
using YoutubeExplode;
using YoutubeExplode.Common;
using YoutubeExplode.Playlists;
using YoutubeExplode.Videos.Streams;

namespace YTDL
{
    enum DownloadType
    {
        single,
        playlist,
        error
    };

    enum Status
    {
       success,
       invalidURL,
       fetchingVideo,
       failedToFetchVideo,
       failedToFetchPlaylist,
       failedToProcessVideo,
       downloadSucceeded,
       failedToDownloadVideo
    };

    internal class YoutubeDownloader
    {

        // Singleton Pattern
        private YoutubeDownloader() { }
        private static YoutubeDownloader _instance;
        private static readonly object _instanceLock = new object();

        private YoutubeClient yt;

        private DownloadType downloadType;

        //! Single Video
        private YoutubeExplode.Videos.Video video;

        //! Playlist
        private Playlist playlist;
        public String playlistTitle, playlistAuthor;
        public int playlistCount;
        public List<PlaylistVideo> playlistVideos;
        public List<List<String>> playlistAudioOptions, playlistVideoOptions;

        // Audio
        public List<String> audioOptions;
        public String selectedAudioQuality, outputFileName, audioFilePath;

        private List<int> audioQualities, audioSize;
        public List<String> selectedAudioQualities;
        private List<AudioOnlyStreamInfo> audioOnlyStreamInfo;
        private AudioOnlyStreamInfo audioTrack;

        // Video
        public List<String> videoOptions;
        public String selectedVideoQuality, videoFilePath;

        private List<double> videoSize;
        public List<String> videoQualities, selectedVideoQualities;
        private List<VideoOnlyStreamInfo> videoOnlyStreamInfo;
        private VideoOnlyStreamInfo videoTrack;

        public Status status;
        public String alertMessage;

        public static YoutubeDownloader GetInstance()
        {
            if (_instance == null)
            {
                lock (_instanceLock)
                {
                    if (_instance == null)
                    {
                        _instance = new YoutubeDownloader
                        {
                            yt = new YoutubeClient(),

                            playlistVideos = new List<PlaylistVideo>(),
                            playlistAudioOptions = new List<List<String>>(),
                            playlistVideoOptions = new List<List<String>>(),

                            audioQualities = new List<int>(),
                            audioSize = new List<int>(),
                            audioOptions = new List<String>(),
                            selectedAudioQualities = new List<String>(),
                            audioOnlyStreamInfo = new List<AudioOnlyStreamInfo>(),

                            videoOptions = new List<String>(),
                            videoSize = new List<double>(),
                            videoQualities = new List<String>(),
                            selectedVideoQualities = new List<String>()
                        };
                    }
                }
            }

            return _instance;
        }

        public async Task<DownloadType> SearchVideo(string url)
        {
            if (url.Contains("playlist"))
            {
                downloadType = DownloadType.playlist;
                await GetVideos(url);
            }
            else
            {
                downloadType = DownloadType.single;
                if (await GetVideo(url))
                    return downloadType;
                else
                    return DownloadType.error;
            }

            return downloadType;
        }

        public async Task<bool> GetVideo(String url)
        {
            try
            {
                this.video = await yt.Videos.GetAsync(url);
                StreamManifest streamManifest = await yt.Videos.Streams.GetManifestAsync(url);
                ClearCollections();
                GetAudioStream(streamManifest);
                GetVideoStream(streamManifest);
            }
            catch (Exception e)
            {
                this.SetStatus(Status.failedToFetchVideo);
                new AlertDialog().ShowDialog();
                return false;
            }

            return true;
        }

        public async Task GetVideos(String url)
        {
            playlist = await yt.Playlists.GetAsync(url);
            playlistAuthor = playlist.Author.ChannelTitle;
            playlistTitle = playlist.Title;
            playlistCount = (int)playlist.Count;

            var videos = await yt.Playlists.GetVideosAsync(url);
            foreach (var video in videos)
            {
                playlistVideos.Add(video);
                StreamManifest streamManifest = await yt.Videos.Streams.GetManifestAsync(video.Url);
                GetAudioStream(streamManifest);
                GetVideoStream(streamManifest);
                playlistAudioOptions.Add(audioOptions.ToList());
                playlistVideoOptions.Add(videoOptions.ToList());
                ClearCollections();
            }
        }

        public void GetAudioStream(StreamManifest streamManifest)
        {
            this.audioOptions.Clear();
            this.audioSize.Clear();
            this.audioQualities.Clear();

            audioOnlyStreamInfo = streamManifest.GetAudioOnlyStreams()
                .Where(s => s.Container.Name != "webm")
                .ToList();

            foreach (var stream in audioOnlyStreamInfo)
            {
                audioQualities.Add((int)Math.Ceiling(stream.Bitrate.KiloBitsPerSecond));
                audioSize.Add((int)Math.Ceiling(stream.Size.MegaBytes));
            }

            for (int i = 0; i < audioSize.Count; i++)
                audioOptions.Add($"{audioQualities[i]} Kbps : {audioSize[i]} MB");

            if (audioQualities.Any())
            {
                var optimalAudio = audioOptions[audioQualities.IndexOf(audioQualities.Max())];
                if (downloadType == DownloadType.single)
                    selectedAudioQuality = optimalAudio;
                else
                    selectedAudioQualities.Add(optimalAudio);
            }
        }

        public void GetVideoStream(StreamManifest streamManifest)
        {
            this.videoOptions.Clear();
            this.videoQualities.Clear();
            this.videoSize.Clear();

            videoOnlyStreamInfo = streamManifest.GetVideoOnlyStreams()
                .Where(s => s.Container.Name != "webm" && s.VideoQuality.Label != "144p")
                .ToList();

            foreach (var stream in videoOnlyStreamInfo)
            {
                videoQualities.Add(stream.VideoQuality.Label);
                videoSize.Add(stream.Size.MegaBytes);
                videoOptions.Add($"{stream.VideoQuality.Label} : {stream.Size}");
            }

            var optimalVideo = videoOptions
                .Where(v => v.Contains("1080p"))
                .OrderBy(v => videoSize[videoOptions.IndexOf(v)])
                .FirstOrDefault();

            if (!string.IsNullOrEmpty(optimalVideo))
            {
                if (downloadType == DownloadType.single)
                    selectedVideoQuality = optimalVideo;
                else
                    selectedVideoQualities.Add(optimalVideo);
            }
        }

        public async Task<bool> DownloadAudioTrack(String selectedAudio, String path)
        {
            var selectedAudioAttributes = selectedAudio.Split(':');
            var selectedAudioBitrateList = selectedAudioAttributes.ElementAt(0).Split(' ');
            var selectedAudioSizeList = selectedAudioAttributes.ElementAt(1).Split(' ');

            int selectedAudioBitrate = int.Parse(selectedAudioBitrateList.ElementAt(0));
            int selectedAudioSize = int.Parse(selectedAudioSizeList.ElementAt(1));

            foreach (var audioStreamOption in audioOnlyStreamInfo)
            {
                int streamBitrate = (int)Math.Ceiling(audioStreamOption.Bitrate.KiloBitsPerSecond);
                int streamSize = (int)Math.Ceiling(audioStreamOption.Size.MegaBytes);
                if (selectedAudioBitrate == streamBitrate && selectedAudioSize == streamSize)
                {
                    audioTrack = audioStreamOption;
                    break;
                }
            }

            var audioFileName = $"{video.Title}-audio.{audioTrack.Container.Name}"
                .Replace('\\', '-')
                .Replace('/', '-')
                .Replace('*', '-')
                .Replace('?', '-')
                .Replace('"', '-')
                .Replace('<', '-')
                .Replace('>', '-')
                .Replace(':', '-')
                .Replace('|', '-');

            outputFileName = $"{video.Title}.{audioTrack.Container.Name}"
                .Replace('\\', '-')
                .Replace('/', '-')
                .Replace('*', '-')
                .Replace('?', '-')
                .Replace('"', '-')
                .Replace('<', '-')
                .Replace('>', '-')
                .Replace(':', '-')
                .Replace('|', '-');

            audioFilePath = System.IO.Path.Combine(path, audioFileName);
            FileInfo audioFile = new FileInfo(audioFilePath);
            if (!audioFile.Exists)
                File.Create(audioFilePath).Dispose();

            await yt.Videos.Streams.DownloadAsync(audioTrack, audioFilePath);

            return true;
        }

        public async Task<bool> DownloadVideoTrack(String selectedVideo, String path)
        {
            var selectedVideoAttributes = selectedVideo.Split(':');
            var selectedVideoPixels = selectedVideoAttributes.ElementAt(0).Trim();
            var selectedVideoSize = selectedVideoAttributes.ElementAt(1).Trim();

            foreach (var videoStreamOption in videoOnlyStreamInfo)
            {
                if (selectedVideoPixels == videoStreamOption.VideoQuality.Label
                    &&
                    selectedVideoSize == videoStreamOption.Size.ToString())
                {
                    videoTrack = videoStreamOption;
                    break;
                }
            }

            var videoFileName = $"{video.Title}-video.{videoTrack.Container.Name}"
                .Replace('\\', '-')
                .Replace('/', '-')
                .Replace('*', '-')
                .Replace('?', '-')
                .Replace('"', '-')
                .Replace('<', '-')
                .Replace('>', '-')
                .Replace(':', '-')
                .Replace('|', '-');

            videoFilePath = System.IO.Path.Combine(path, videoFileName);
            FileInfo videoFile = new FileInfo(videoFilePath);
            if (!videoFile.Exists)
                File.Create(videoFilePath).Dispose();

            await yt.Videos.Streams.DownloadAsync(videoTrack, videoFilePath);

            return true;
        }

        public async Task<bool> ProcessTracks(String path)
        {
            return await Task.Run(() => ProcessMedia(path));
        }

        private bool ProcessMedia(String path)
        {
            var outputFilePath = System.IO.Path.Combine(path, outputFileName);
            FileInfo outputFile = new FileInfo(outputFilePath);
            if (!outputFile.Exists)
            {
                File.Create(outputFilePath).Dispose();
            }

            string exePath = @"ffmpeg.exe";
            string command = $"-i \"{videoFilePath}\" -i \"{audioFilePath} \" -c:v copy -c:a aac -y \"{outputFilePath}\"";

            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = exePath,
                Arguments = command,
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden,
            };

            using (Process process = new Process())
            {
                process.StartInfo = startInfo;
                process.Start();
                process.WaitForExit();
                int exitCode = process.ExitCode;
                if (exitCode == 0)
                    return true;
                else
                    return false;
            }
        }

        public bool DeleteRawFiles()
        {
            File.Delete(audioFilePath);
            File.Delete(videoFilePath);
            return true;
        }

        public BitmapImage GetThumbnail(int index)
        {
            BitmapImage bitmap = new BitmapImage();
            bitmap.BeginInit();

            if (downloadType == DownloadType.single)
                bitmap.UriSource = new Uri(video.Thumbnails.TryGetWithHighestResolution().Url);
            else
                bitmap.UriSource = new Uri(playlistVideos.ElementAt(index).Thumbnails.TryGetWithHighestResolution().Url);

            bitmap.CacheOption = BitmapCacheOption.Default;
            bitmap.EndInit();

            return bitmap;
        }

        public String GetVideoTitle()
        {
            return video.Title;
        }

        private void ClearCollections()
        {
            this.audioOptions.Clear();
            this.audioSize.Clear();
            this.audioQualities.Clear();
            this.videoOptions.Clear();
            this.videoQualities.Clear();
            this.videoSize.Clear();
        }

        public bool IsValidUrl(string url)
        {
            return Uri.TryCreate(url, UriKind.Absolute, out Uri uriResult)
                   && (uriResult.Scheme == Uri.UriSchemeHttp || uriResult.Scheme == Uri.UriSchemeHttps);
        }

        public void SetStatus(Status status)
        { 
            this.status = status;
            switch ((int)GetStatus())
            {
                case 1: alertMessage = "Please Enter Valid URL !!!"; break;
                case 2: alertMessage = "Please Wait"; break;
                case 3: alertMessage = "Failed To Get The Video You Requested 😞 ... Please Try Again Later"; break;
                case 4: alertMessage = "Failed To Get The Playlist You Requested 😞 ... Please Try Again Later"; break;
                case 5: alertMessage = "Failed To Process The Video You Requested 😞 ... Please Try Again Later"; break;
                case 6: alertMessage = "Video Downloaded Successfully 😁"; break;
                case 7: alertMessage = "Failed To Download The Video You Requested 😞"; break;
            }
        }

        public Status GetStatus() { return this.status; }
    }

    internal class DelegateProgress<T> : IProgress<T>
    {
        private readonly Action<T> _report;

        public DelegateProgress(Action<T> report)
        {
            _report = report ?? throw new ArgumentNullException(nameof(report));
        }

        public void Report(T value) => _report(value);
    }
}
