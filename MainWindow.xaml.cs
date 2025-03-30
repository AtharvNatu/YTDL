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
        }

        private async void SearchEventHandler(object sender, RoutedEventArgs e)
        {
            String url = urlTextBox.Text;
            if (ytdl.IsValidUrl(url))
            {
                ytdl.SetStatus(Status.fetchingVideo);
                //var alertDialog = new AlertDialog().ShowDialog();

                DownloadType status = await ytdl.SearchVideo(url);
                //alertDialog.Close();

                if (status == DownloadType.single)
                    new VideoDownload().Show();
                else
                    new PlaylistDownload().Show();

                ytdl.SetStatus(Status.success);
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
    }
}
