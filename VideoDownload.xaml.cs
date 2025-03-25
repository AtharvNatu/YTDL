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

            thumbnail.Source = ytdl.GetThumbnail();

            audioComboBox.ItemsSource = ytdl.audioOptions;
            audioComboBox.SelectedItem = ytdl.selectedAudioQuality;

            videoComboBox.ItemsSource = ytdl.videoOptions;
            videoComboBox.SelectedItem = ytdl.selectedVideoQuality;
        }

        private String DirectoryPicker()
        {
            FolderBrowserDialog folderBrowserDialog = new FolderBrowserDialog();
            folderBrowserDialog.ShowNewFolderButton = true;
            DialogResult result = folderBrowserDialog.ShowDialog();
            if (result == System.Windows.Forms.DialogResult.OK)
                return folderBrowserDialog.SelectedPath;
            return null;
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            String filePath = DirectoryPicker();
            if (filePath != null)
            {
                ytdl.DownloadAndProcessVideo(audioComboBox.SelectedItem.ToString(), videoComboBox.SelectedItem.ToString(), filePath, progressBar, statusLbl);
            }
        }
    }
}
