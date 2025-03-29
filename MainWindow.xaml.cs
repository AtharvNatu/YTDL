using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using YoutubeExplode.Common;

namespace YTDL
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private YoutubeDownloader ytdl;

        public MainWindow()
        {
            InitializeComponent();
            ytdl = YoutubeDownloader.GetInstance();
        }

        private async void Button_Click(object sender, RoutedEventArgs e)
        {
            String url = URLTxtBox.Text;
            if (ytdl.IsValidUrl(url))
            {
                DownloadType status = await ytdl.SearchVideo(url);
                //DownloadType status = await ytdl.SearchVideo("https://www.youtube.com/playlist?list=PLPwbI_iIX3aRokbT-9j_MfiNcbCn_OtC1");
                //DownloadType status = await ytdl.SearchVideo("https://www.youtube.com/playlist?list=PLPwbI_iIX3aRdiCRnMtbcbUi0fZnck1H3");
                if (status == DownloadType.single)
                    new VideoDownload().Show();
                else
                    new PlaylistDownload().Show();
            }
            else
            {
                MessageBox.Show("Please Enter Valid URL !!!", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
}
    }
}
