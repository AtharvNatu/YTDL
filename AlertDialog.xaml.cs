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
using System.Windows.Media.Animation;
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
        private SolidColorBrush redBrush, greenBrush, blueGrayBrush;

        public AlertDialog()
        {
            InitializeComponent();

            ytdl = YoutubeDownloader.GetInstance();
            this.FontFamily = new System.Windows.Media.FontFamily("Poppins");

            Status status = ytdl.GetStatus();

            redBrush = new SolidColorBrush(Color.FromRgb(254, 100, 89));
            greenBrush = new SolidColorBrush(Color.FromRgb(61, 212, 114));
            blueGrayBrush = new SolidColorBrush(Color.FromRgb(116, 147, 179));

            switch (status)
            {
                case Status.success:
                    msgTxtBlock.Foreground = greenBrush;
                    break;

                case Status.invalidURL:
                case Status.failedToFetchVideo:
                    msgTxtBlock.Foreground = redBrush;
                    AddButtons(true, false);
                    break;

                case Status.fetchingVideo:
                    msgTxtBlock.Foreground = blueGrayBrush;
                    AddSpinner();
                    break;

            }

            msgTxtBlock.Text = ytdl.alertMessage;
        }

        private void AddButtons(bool showOkButton, bool showCancelButton)
        {
            if (showOkButton && showCancelButton)
            {
                ButtonContainer.Children.Clear();

                var okButton = new Button
                {
                    Content = "Ok",
                    Width = 100,
                    Height = 30,
                    Background = greenBrush,
                    Margin = new Thickness(10)
                };
                okButton.Click += OkButton_Click;
                ButtonContainer.Children.Add(okButton);

                var cancelButton = new Button
                {
                    Content = "Cancel",
                    Width = 100,
                    Height = 30,
                    Background = redBrush,
                    Margin = new Thickness(10),
                };
                cancelButton.Click += CancelButton_Click;
                ButtonContainer.Children.Add(cancelButton);
            }
            else
            {
                ButtonContainer.Children.Clear();
                var okButton = new Button
                {
                    Content = "Ok",
                    Width = 100,
                    Height = 30,
                    Background = greenBrush,
                    Margin = new Thickness(10),
                };
                okButton.Click += OkButton_Click;
                ButtonContainer.Children.Add(okButton);
            }
        }

        private void OkButton_Click(object sender, RoutedEventArgs e)
        {
            this.Close();
        }

        private void CancelButton_Click(object sender, RoutedEventArgs e)
        {

        }

        private void AddSpinner()
        {
            ButtonContainer.Children.Clear();

            var spinner = new Canvas
            {
                Width = 60,
                Height = 60
            };

            var circle = new Path
            {
                Stroke = Brushes.DarkBlue,
                StrokeThickness = 4,
                Data = new EllipseGeometry(new Point(30, 30), 20, 20)
            };

            // Animation
            var rotateTransform = new RotateTransform();
            circle.RenderTransform = rotateTransform;
            circle.RenderTransformOrigin = new Point(0.5, 0.5);

            var animation = new DoubleAnimation
            {
                From = 0,
                To = 360,
                Duration = TimeSpan.FromSeconds(1),
                RepeatBehavior = RepeatBehavior.Forever
            };

            rotateTransform.BeginAnimation(RotateTransform.AngleProperty, animation);

            spinner.Children.Add(circle);

            ButtonContainer.Children.Add(spinner);
        }
    }
}
