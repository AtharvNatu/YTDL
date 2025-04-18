﻿using System;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace YTDL
{
    public partial class PlaylistDownload : Window
    {
        private YoutubeDownloader ytdl;

        public PlaylistDownload()
        {
            InitializeComponent();
            ytdl = YoutubeDownloader.GetInstance();
            LoadPlaylistData();
        }

        private void LoadPlaylistData()
        {
            titleLabel.Content = ytdl.playlistTitle;

            for (int i = 0; i < ytdl.playlistCount; i++)
            {
                var rowBorder = new Border
                {
                    CornerRadius = new CornerRadius(10),
                    BorderBrush = new SolidColorBrush(Colors.LightGray),
                    BorderThickness = new Thickness(1),
                    Margin = new Thickness(5, 5, 15, 5),
                    Background = new SolidColorBrush(Colors.White),
                    Padding = new Thickness(10),
                    Effect = new System.Windows.Media.Effects.DropShadowEffect
                    {
                        Color = Colors.Gray,
                        Direction = 320,
                        ShadowDepth = 4,
                        Opacity = 0.3
                    }
                };

                var rowGrid = new Grid { Margin = new Thickness(5) };

                rowGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(30) });    // Checkbox
                rowGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(150) });   // Image
                rowGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(400) });   // Title
                rowGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(200) });   // ComboBox 1
                rowGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(200) });   // ComboBox 2

                var checkbox = new CheckBox
                {
                    VerticalAlignment = VerticalAlignment.Center,
                    HorizontalAlignment = HorizontalAlignment.Center,
                    IsChecked = true
                };

                // Event handlers for checkbox
                checkbox.Checked += (evt, args) =>
                {
                    if (AreAllCheckboxesSelected())
                        SelectAllCheckbox.IsChecked = true;
                    UpdateSelectionCount();
                };

                checkbox.Unchecked += (evt, args) =>
                {
                    SelectAllCheckbox.IsChecked = false;
                    UpdateSelectionCount();
                };

                Grid.SetColumn(checkbox, 0);
                rowGrid.Children.Add(checkbox);

                // Add Image
                var img = new Image
                {
                    Width = 120,
                    Height = 80,
                    Source = ytdl.GetThumbnail(i),
                    Margin = new Thickness(5),
                    Stretch = Stretch.UniformToFill,
                    VerticalAlignment = VerticalAlignment.Center,
                    HorizontalAlignment = HorizontalAlignment.Center
                };
                Grid.SetColumn(img, 1);
                rowGrid.Children.Add(img);

                // Add Wrapping Title
                var textBlock = new TextBlock
                {
                    Text = ytdl.playlistVideos.ElementAt(i).Title,
                    TextWrapping = TextWrapping.Wrap,
                    MaxWidth = 400,
                    Margin = new Thickness(5),
                    Foreground = Brushes.Black,
                    FontSize = 14,
                    FontWeight = FontWeights.Medium,
                    VerticalAlignment = VerticalAlignment.Center,
                    HorizontalAlignment = HorizontalAlignment.Center
                };
                Grid.SetColumn(textBlock, 2);
                rowGrid.Children.Add(textBlock);

                // Video Qualities
                var combo1 = new ComboBox
                {
                    ItemsSource = ytdl.playlistVideoOptions.ElementAt(i),
                    SelectedItem = ytdl.selectedVideoQualities.ElementAt(i),
                    Margin = new Thickness(5),
                    Width = 150,
                    VerticalAlignment = VerticalAlignment.Center,
                    HorizontalAlignment = HorizontalAlignment.Center
                };
                Grid.SetColumn(combo1, 3);
                rowGrid.Children.Add(combo1);

                // Audio Qualities
                var combo2 = new ComboBox
                {
                    ItemsSource = ytdl.playlistAudioOptions.ElementAt(i),
                    SelectedItem = ytdl.selectedAudioQualities.ElementAt(i),
                    Margin = new Thickness(5),
                    Width = 150,
                    VerticalAlignment = VerticalAlignment.Center,
                    HorizontalAlignment = HorizontalAlignment.Center
                };
                Grid.SetColumn(combo2, 4);
                rowGrid.Children.Add(combo2);

                // Add Grid inside Border
                rowBorder.Child = rowGrid;

                // Add row to the container
                RowsContainer.Children.Add(rowBorder);

                // Update the selection count
                UpdateSelectionCount();
            }

            
        }

        private void AddRow_Click(object sender, RoutedEventArgs e)
        {
            
        }


        private bool AreAllCheckboxesSelected()
        {
            foreach (var child in RowsContainer.Children)
            {
                if (child is Border border && border.Child is Grid grid)
                {
                    var checkbox = grid.Children.OfType<CheckBox>().FirstOrDefault();
                    if (checkbox != null && checkbox.IsChecked == false)
                    {
                        return false;  // If at least one checkbox is not selected, return false
                    }
                }
            }
            return true;  // All checkboxes are selected
        }



        // Method to count selected checkboxes
        private void UpdateSelectionCount()
        {
            int selectedCount = 0;

            foreach (var child in RowsContainer.Children)
            {
                if (child is Border border && border.Child is Grid grid)
                {
                    var checkbox = grid.Children.OfType<CheckBox>().FirstOrDefault();
                    if (checkbox != null && checkbox.IsChecked == true)
                    {
                        selectedCount++;
                    }
                }
            }

            DownloadButton.Content = $"Download Videos ({selectedCount})";
        }


        // Select all checkboxes when "Select All" is checked
        private void SelectAllCheckbox_Checked(object sender, RoutedEventArgs e)
        {
            foreach (var child in RowsContainer.Children)
            {
                if (child is Border border && border.Child is Grid grid)
                {
                    var checkbox = grid.Children[0] as CheckBox;
                    if (checkbox != null)
                    {
                        checkbox.IsChecked = true;
                    }
                }
            }

            UpdateSelectionCount();
        }

        // Deselect all checkboxes when "Select All" is unchecked
        private void SelectAllCheckbox_Unchecked(object sender, RoutedEventArgs e)
        {
            foreach (var child in RowsContainer.Children)
            {
                if (child is Border border && border.Child is Grid grid)
                {
                    var checkbox = grid.Children[0] as CheckBox;
                    if (checkbox != null)
                    {
                        checkbox.IsChecked = false;
                    }
                }
            }

            UpdateSelectionCount();
        }
    }
}
