using System;
using System.Collections.Generic;
using System.IO;
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
        private SolidColorBrush redBrush, greenBrush;


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

            greenBrush = new SolidColorBrush(Color.FromRgb(76, 177, 58));
            redBrush = new SolidColorBrush(Color.FromRgb(241, 51, 51));

            ToggleStatusControls(false);

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
                ToggleStatusControls(true);

                // Download Audio
                prg1.Visibility = Visibility.Visible;
                status1.FontWeight = System.Windows.FontWeights.Bold;
                status1.Foreground = redBrush;

                bool audioDownloadStatus = await ytdl.DownloadAudioTrack(audioComboBox.SelectedItem.ToString(), filePath);
                if (audioDownloadStatus)
                {
                    prg1.Visibility = Visibility.Hidden;
                    img1.Visibility = Visibility.Visible;
                    status1.Foreground = greenBrush;

                    // Download Video
                    prg2.Visibility = Visibility.Visible;
                    status2.FontWeight = System.Windows.FontWeights.Bold;
                    status2.Foreground = redBrush;
                    bool videoDownloadStatus = await ytdl.DownloadVideoTrack(videoComboBox.SelectedItem.ToString(), filePath);
                    if (videoDownloadStatus)
                    {
                        prg2.Visibility = Visibility.Hidden;
                        img2.Visibility = Visibility.Visible;
                        status2.Foreground = greenBrush;

                        // Process Video
                        prg3.Visibility = Visibility.Visible;
                        status3.FontWeight = System.Windows.FontWeights.Bold;
                        status3.Foreground = redBrush;
                        bool processingStatus = await ytdl.ProcessTracks(filePath);
                        if (processingStatus)
                        {
                            prg3.Visibility = Visibility.Hidden;
                            img3.Visibility = Visibility.Visible;
                            status3.Foreground = greenBrush;

                            // Delete Raw Files
                            prg4.Visibility = Visibility.Visible;
                            status4.FontWeight = System.Windows.FontWeights.Bold;
                            status4.Foreground = redBrush;
                            bool deleteStatus = ytdl.DeleteRawFiles();
                            if (deleteStatus)
                            {
                                prg4.Visibility = Visibility.Hidden;
                                img4.Visibility = Visibility.Visible;
                                status4.Foreground = greenBrush;
                                ytdl.SetStatus(Status.downloadSucceeded);
                            }
                            else
                                ytdl.SetStatus(Status.failedToDownloadVideo);
                        }
                        else
                            ytdl.SetStatus(Status.failedToDownloadVideo);
                    }
                    else
                        ytdl.SetStatus(Status.failedToDownloadVideo);
                }
                else
                    ytdl.SetStatus(Status.failedToDownloadVideo);

                new AlertDialog().ShowDialog();
            }
        }

        private void BackEventHandler(object sender, RoutedEventArgs e)
        {
            this.Close();
        }

        private void ToggleStatusControls(bool show)
        {
            if (show)
            {
                rect.Visibility = Visibility.Visible;
                status1.Visibility = Visibility.Visible;
                status2.Visibility = Visibility.Visible;
                status3.Visibility = Visibility.Visible;
                status4.Visibility = Visibility.Visible; 
            }
            else
            {
                rect.Visibility = Visibility.Hidden;
                status1.Visibility = Visibility.Hidden;
                status2.Visibility = Visibility.Hidden;
                status3.Visibility = Visibility.Hidden;
                status4.Visibility = Visibility.Hidden;
                img1.Visibility = Visibility.Hidden;
                img2.Visibility = Visibility.Hidden;
                img3.Visibility = Visibility.Hidden;
                img4.Visibility = Visibility.Hidden;
                prg1.Visibility = Visibility.Hidden;
                prg2.Visibility = Visibility.Hidden;
                prg3.Visibility = Visibility.Hidden;
                prg4.Visibility = Visibility.Hidden;
            }
        }
    }
}
