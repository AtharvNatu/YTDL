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
            bool status = false;

            #if DEBUG
                status = await ytdl.SearchVideo("https://www.youtube.com/watch?v=3NCn1CCOXqE&list=PLPwbI_iIX3aR_rqjogPSCGdjx8cOrTC_-&index=2");
            #else
                status = await ytdl.SearchVideo(URLTxtBox.Text);
            #endif

            if (status)
            {
                new VideoDownload().Show();
            }
        }
    }
}
