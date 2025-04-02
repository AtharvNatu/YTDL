using System;
using System.Windows;
using YoutubeExplode.Common;

namespace YTDL
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private readonly YoutubeDownloader ytdl;

        public MainWindow()
        {
            InitializeComponent();

            ytdl = YoutubeDownloader.GetInstance();

            this.FontFamily = new System.Windows.Media.FontFamily("Poppins");

            ToggleWaitControls(false);
        }

        private async void SearchEventHandler(object sender, RoutedEventArgs e)
        {
            String url = urlTextBox.Text;
            if (ytdl.IsValidUrl(url))
            {
                ytdl.SetStatus(Status.fetchingVideo);
                ToggleWaitControls(true);

                DownloadType downloadType = await ytdl.SearchVideo(url);
                if (downloadType == DownloadType.error)
                    System.Windows.Application.Current.Shutdown();
                else
                {
                    ToggleWaitControls(false);
                    new VideoDownload().ShowDialog();
                    ytdl.SetStatus(Status.success);
                }

                //if (status == DownloadType.single)
                //    new VideoDownload().Show();
                //else
                //    new PlaylistDownload().Show();

            }
            else
            {
                ytdl.SetStatus(Status.invalidURL);
                new AlertDialog().ShowDialog();
            }
        }

        private void PasteEventHandler(object sender, RoutedEventArgs e)
        {
            if (Clipboard.ContainsText())
            {
                urlTextBox.Text = Clipboard.GetText(TextDataFormat.Text);
            }
        }

        private void ClearEventHandler(object sender, RoutedEventArgs e)
        {
            urlTextBox.Clear();
        }

        private void SettingsEventHandler(object sender, RoutedEventArgs e)
        {
            new Settings().ShowDialog();
        }

        private void ToggleWaitControls(bool show)
        {
            if (show)
            {
                this.progressBar.Visibility = Visibility.Visible;
                this.waitTxtBlock.Visibility = Visibility.Visible;
            }
            else
            {
                this.progressBar.Visibility = Visibility.Hidden;
                this.waitTxtBlock.Visibility = Visibility.Hidden;
            }
        }
    }
}
