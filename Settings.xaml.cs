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
    /// Interaction logic for Settings.xaml
    /// </summary>
    public partial class Settings : Window
    {
        public Settings()
        {
            InitializeComponent();

            this.FontFamily = new System.Windows.Media.FontFamily("Poppins");

            applyButton.IsEnabled = false;
            pathTxt.Visibility = Visibility.Hidden;

            //string path = Helper.GetDefaultDirectoryPath();
            //if (path == null || path == "")

        }

        private void SetDownloadLocationHandler(object sender, RoutedEventArgs e)
        {
            if (!(bool)defaultRadioButton.IsChecked && !(bool)newRadioButton.IsChecked)
            {
                new AlertDialog("Please select any 1 of the options !").ShowDialog();
            }

            if ((bool)defaultRadioButton.IsChecked)
            {
                String filePath = Helper.DirectoryPicker();
                if (filePath != null)
                {
                    pathTxt.Text = "Download Path : " + filePath;
                    pathTxt.Visibility = Visibility.Visible;
                    Helper.SetDefaultDirectoryPath(filePath);
                    Helper.downloadOption = DownloadOption.defaultLocation;
                }
            }
               
            else if ((bool)newRadioButton.IsChecked)
                Helper.downloadOption = DownloadOption.newLocation;
        }

        private void defaultRadioButton_Checked(object sender, RoutedEventArgs e)
        {
            applyButton.IsEnabled = true;
            applyButton.Content = "Select Directory";
        }

        private void newRadioButton_Checked(object sender, RoutedEventArgs e)
        {
            applyButton.IsEnabled = true;
            applyButton.Content = "Apply";
        }
    }
}
