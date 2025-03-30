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
using System.Windows.Shapes;

namespace YTDL
{
    /// <summary>
    /// Interaction logic for AlertDialog.xaml
    /// </summary>
    public partial class AlertDialog : Window
    {
        private YoutubeDownloader ytdl;

        public AlertDialog()
        {
            InitializeComponent();
            ytdl = YoutubeDownloader.GetInstance();
            this.FontFamily = new System.Windows.Media.FontFamily("Poppins");

            msgTxtBlock.Text = ytdl.alertMessage;
            if (ytdl.GetStatus() == Status.invalidURL)
            {
                AddButtons(true, false);
            }
        }

        private void AddButtons(bool showOkButton, bool showCancelButton)
        {
            if (showOkButton)
            {
                ButtonContainer.Children.Clear();
                var okButton = new Button
                {
                    Content = "Ok",
                    //Background = new SolidColorBrush(Color.FromRgb(240, 240, 240)),
                    Width = 100,
                    Height = 30,
                    Margin = new Thickness(10)
                };
                okButton.Click += OkButton_Click;
                ButtonContainer.Children.Add(okButton);
            }
        }

        private void OkButton_Click(object sender, RoutedEventArgs e)
        {
            this.Close();
        }
    }
}
