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

            //string path = Helper.GetDefaultDirectoryPath();
            //if (path == null || path == "")

        }

        private void SetDownloadLocationHandler(object sender, RoutedEventArgs e)
        {
            if ((bool)defaultRadioButton.IsChecked)
            {
                String filePath = Helper.DirectoryPicker();
                if (filePath != null)
                    Helper.SetDefaultDirectoryPath(filePath);
                Helper.downloadOption = DownloadOption.defaultLocation;
            }
               
            else if ((bool)newRadioButton.IsChecked)
                Helper.downloadOption = DownloadOption.newLocation;
        }
    }
}
