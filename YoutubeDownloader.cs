using AngleSharp.Media.Dom;
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Packaging;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
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
        playlist
    };

    enum LoadingState 
    { 
        initial, 
        audio, 
        video, 
        mux 
    };

    internal class YoutubeDownloader
    {

        // Singleton Pattern
        private YoutubeDownloader() { }
        private static YoutubeDownloader _instance;
        private static readonly object _instanceLock = new object();


        private YoutubeClient yt;

        private DownloadType downloadType;

        private StreamManifest streamManifest;
        private YoutubeExplode.Videos.Video video;

        // Audio
        public List<String> audioOptions;
        public String selectedAudioQuality;

        private List<int> audioQualities, audioSize;
        private List<String> selectedAudioQualities;
        private List<AudioOnlyStreamInfo> audioOnlyStreamInfo;
        private AudioOnlyStreamInfo audioTrack;

        // Video
        public List<String> videoOptions;
        public String selectedVideoQuality;

        private List<double> videoSize;
        private List<String> videoQualities, selectedVideoQualities;

        public static YoutubeDownloader GetInstance()
        {
            if (_instance == null)
            {
                lock(_instanceLock)
                {
                    if (_instance == null)
                    {
                        _instance = new YoutubeDownloader
                        {
                            yt = new YoutubeClient(),

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

        public async Task<bool> SearchVideo(string url)
        {
            if (url.Contains("playlist"))
            {
                downloadType = DownloadType.playlist;
                await GetVideos(url);
            }
            else
            {
                downloadType = DownloadType.single;
                await GetVideo(url);
            }

            return true;
        }

        public async Task GetVideo(String url)
        {
            this.video = await yt.Videos.GetAsync(url);
            this.streamManifest = await yt.Videos.Streams.GetManifestAsync(url);
            ClearCollections();
            GetAudioStream();
            GetVideoStream();
        }

        public async Task GetVideos(String url)
        {
            var youtube = new YoutubeClient();

            var playlistUrl = "https://www.youtube.com/playlist?list=PLPwbI_iIX3aR_rqjogPSCGdjx8cOrTC_-";
            var playlist = await youtube.Playlists.GetAsync(playlistUrl);

            //titleLbl.Content = playlist.Title;
            //authorNameLbl.Content = playlist.Author.ChannelTitle;
            //videoCountLbl.Content = playlist.Count;

            //var videos = await youtube.Playlists.GetVideosAsync(playlistUrl);
            //foreach (var video in videos)
            //{
            //    listView.Items.Add(video.Title);
            //}
        }

        public void GetAudioStream()
        {
            this.audioOptions.Clear();
            this.audioSize.Clear();
            this.audioQualities.Clear();

            audioOnlyStreamInfo = this.streamManifest.GetAudioOnlyStreams()
                .Where(s => s.Container.Name != "webm")
                .ToList();

            foreach(var stream in audioOnlyStreamInfo)
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

        public void GetVideoStream()
        {
            this.videoOptions.Clear();
            this.videoQualities.Clear();
            this.videoSize.Clear();

            var streamInfo = this.streamManifest.GetVideoOnlyStreams()
                .Where(s => s.Container.Name != "webm" && s.VideoQuality.Label != "144p")
                .ToList();

            foreach (var stream in streamInfo)
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

        public async void DownloadAndProcessVideo(String selectedAudio, String selectedVideo, String path, ProgressBar progressBar, Label statusLbl)
        {
            await DownloadAudioTrack(selectedAudio, path, progressBar, statusLbl);
            await DownloadVideoTrack(selectedAudio, path, progressBar, statusLbl);
        }

        private async Task DownloadAudioTrack(String selectedAudio, String path, ProgressBar progressBar, Label statusLbl)
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

            var audioStream = await yt.Videos.Streams.GetAsync(audioTrack);

            var audioFileName = $"{video.Title}_audio_.{audioTrack.Container.Name}"
                .Replace('\\', '_')
                .Replace('/', '_')
                .Replace('*', '_')
                .Replace('?', '_')
                .Replace('"', '_')
                .Replace('<', '_')
                .Replace('>', '_')
                .Replace(':', '_')
                .Replace('|', '_');

            var outputFileName = $"{video.Title}.{audioTrack.Container.Name}"
                .Replace('\\', '_')
                .Replace('/', '_')
                .Replace('*', '_')
                .Replace('?', '_')
                .Replace('"', '_')
                .Replace('<', '_')
                .Replace('>', '_')
                .Replace(':', '_')
                .Replace('|', '_');

            var audioFilePath = Path.Combine(path, audioFileName);
            FileInfo audioFile = new FileInfo(audioFilePath);
            if (!audioFile.Exists)
                File.Create(audioFilePath).Dispose();

            var progress = new DelegateProgress<double>(p =>
            {
                progressBar.Dispatcher.Invoke(() =>
                {
                    progressBar.Value = p * 100;
                });
            });

            statusLbl.Dispatcher.Invoke(() =>
            {
                statusLbl.Content = "Downloading Audio ...";
            });

            await yt.Videos.Streams.DownloadAsync(audioTrack, audioFilePath, progress);
        }

        private async Task DownloadVideoTrack(String selectedAudio, String path, ProgressBar progressBar, Label statusLbl)
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

            var audioStream = await yt.Videos.Streams.GetAsync(audioTrack);

            var audioFileName = $"{video.Title}_audio_.{audioTrack.Container.Name}"
                .Replace('\\', '_')
                .Replace('/', '_')
                .Replace('*', '_')
                .Replace('?', '_')
                .Replace('"', '_')
                .Replace('<', '_')
                .Replace('>', '_')
                .Replace(':', '_')
                .Replace('|', '_');

            var outputFileName = $"{video.Title}.{audioTrack.Container.Name}"
                .Replace('\\', '_')
                .Replace('/', '_')
                .Replace('*', '_')
                .Replace('?', '_')
                .Replace('"', '_')
                .Replace('<', '_')
                .Replace('>', '_')
                .Replace(':', '_')
                .Replace('|', '_');

            var audioFilePath = Path.Combine(path, audioFileName);
            FileInfo audioFile = new FileInfo(audioFilePath);
            if (!audioFile.Exists)
                File.Create(audioFilePath).Dispose();

            var progress = new DelegateProgress<double>(p =>
            {
                progressBar.Dispatcher.Invoke(() =>
                {
                    progressBar.Value = p * 100;
                });
            });

            statusLbl.Dispatcher.Invoke(() =>
            {
                statusLbl.Content = "Downloading Audio ...";
            });

            await yt.Videos.Streams.DownloadAsync(audioTrack, audioFilePath, progress);
        }

        public BitmapImage GetThumbnail()
        {
            BitmapImage bitmap = new BitmapImage();
            bitmap.BeginInit();
            bitmap.UriSource = new Uri(video.Thumbnails.TryGetWithHighestResolution().Url);
            bitmap.CacheOption = BitmapCacheOption.Default;
            bitmap.EndInit();

            return bitmap;
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
