using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Forms;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace YTDL
{
    /// <summary>
    /// Interaction logic for VideoDownload.xaml
    /// </summary>
    public partial class VideoDownload : Window
    {
        private YoutubeDownloader ytdl;

        public VideoDownload()
        {
            InitializeComponent();

            ytdl = YoutubeDownloader.GetInstance();

            this.FontFamily = new System.Windows.Media.FontFamily("Poppins");

            thumbnail.Source = ytdl.GetThumbnail(0);
            titleLabel.Text = ytdl.GetVideoTitle();

            audioComboBox.ItemsSource = ytdl.audioOptions;
            audioComboBox.SelectedItem = ytdl.selectedAudioQuality;

            videoComboBox.ItemsSource = ytdl.videoOptions;
            videoComboBox.SelectedItem = ytdl.selectedVideoQuality;

            ToggleProgressControls(false);
        }

        private async void DownloadEventHandler(object sender, RoutedEventArgs e)
        {
            String filePath = null;

            if (Helper.downloadOption == DownloadOption.newLocation)
                filePath = Helper.DirectoryPicker();
            else if (Helper.downloadOption == DownloadOption.defaultLocation)
                filePath = Helper.GetDefaultDirectoryPath();

            if (filePath != null || filePath != "")
            {
                ToggleProgressControls(true);
                statusLbl.Content = "Downloading Audio ...";

                int status = await ytdl.DownloadAndProcessVideo(
                    audioComboBox.SelectedItem.ToString(),
                    videoComboBox.SelectedItem.ToString(),
                    filePath,
                    progressBar,
                    statusLbl
                );

                if (status == 0)
                {
                    ToggleProgressControls(false);
                    ytdl.SetStatus(Status.downloadSucceeded);
                }
                    
                else
                    ytdl.SetStatus(Status.failedToDownloadVideo);

                new AlertDialog().ShowDialog();
            }
        }

        private void ToggleProgressControls(bool show)
        {
            if (show)
            {
                this.progressBar.Visibility = Visibility.Visible;
                this.statusLbl.Visibility = Visibility.Visible;
            }
            else
            {
                this.progressBar.Visibility = Visibility.Hidden;
                this.statusLbl.Visibility = Visibility.Hidden;
            }
        }
    }
}
