using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace YTDL
{
    enum DownloadOption
    {
        defaultLocation,
        newLocation,
    };

    internal class Helper
    {
        public static DownloadOption downloadOption;

        public static String DirectoryPicker()
        {
            FolderBrowserDialog folderBrowserDialog = new FolderBrowserDialog
            {
                Description = "Select Download Directory",
                ShowNewFolderButton = true
            };
            DialogResult result = folderBrowserDialog.ShowDialog();
            if (result == System.Windows.Forms.DialogResult.OK)
                return folderBrowserDialog.SelectedPath;
            return null;
        }

        public static void SetDefaultDirectoryPath(string path)
        {
            Properties.Settings.Default.DownloadDirectory = path;
            Properties.Settings.Default.Save();
        }
        
        public static string GetDefaultDirectoryPath()
        {
            return Properties.Settings.Default.DownloadDirectory;
        }
    }
}
