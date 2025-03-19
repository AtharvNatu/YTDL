import 'package:flutter/material.dart';
import 'home.dart';

class PlaylistDownload extends StatefulWidget {
  const PlaylistDownload({super.key});

  @override
  State<PlaylistDownload> createState() => _PlaylistDownloadState();
}

class _PlaylistDownloadState extends State<PlaylistDownload> {
  List<Item> items = List.generate(30, (index) {
    return Item(
      title: 'Video $index',
      videoOptions: ['Video 1', 'Video 2', 'Video 3'],
      audioOptions: ['Audio 1', 'Audio 2', 'Audio 3'],
      selectedVideo: 'Video 1',
      selectedAudio: 'Audio 1',
      isChecked: false,
    );
  });

  bool isAllSelected = true;

  // Scroll controller for smoother scrolling
  final ScrollController _scrollController = ScrollController();

  // Toggle the "Select All" checkbox
  void toggleSelectAll(bool? value) {
    setState(() {
      isAllSelected = value!;
      for (var item in items) {
        item.isChecked = isAllSelected;
      }
    });
  }

  // Handle checkbox changes for each item
  void toggleItemSelection(int index, bool? value) {
    setState(() {
      items[index].isChecked = value!;
      // Check if all items are selected
      isAllSelected = items.every((item) => item.isChecked);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Playlist Results"),
          backgroundColor: Colors.blueGrey,
          actions: <Widget>[
            TextButton(
              onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Home()),
              );
            },
            child: const Text("Back"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // "Select All" checkbox at the top
            CheckboxListTile(
              title: Text('Select All'),
              value: isAllSelected,
              onChanged: toggleSelectAll,
              controlAffinity: ListTileControlAffinity.leading, // Checkbox on the left
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0), // Padding for the list to prevent scrollbar collision
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true, // Make the scrollbar always visible when scrolling
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          // Checkbox for individual item (on the left of the image)
                          Checkbox(
                            value: items[index].isChecked,
                            onChanged: (value) => toggleItemSelection(index, value),
                          ),
                          // Image column (1st column)
                          Image.asset(
                            'assets/images/youtube.png', // Placeholder for image
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 8),
                          // Video title column (2nd column)
                          Expanded(
                            child: Text(items[index].title),
                          ),
                          SizedBox(width: 8),
                          // Video dropdown (3rd column)
                          DropdownButton<String>(
                            value: items[index].selectedVideo,
                            onChanged: (newValue) {
                              setState(() {
                                items[index].selectedVideo = newValue!;
                              });
                            },
                            items: items[index].videoOptions
                                .map((video) => DropdownMenuItem(
                              value: video,
                              child: Text(video),
                            ))
                                .toList(),
                          ),
                          SizedBox(width: 8),
                          // Audio dropdown (4th column)
                          DropdownButton<String>(
                            value: items[index].selectedAudio,
                            onChanged: (newValue) {
                              setState(() {
                                items[index].selectedAudio = newValue!;
                              });
                            },
                            items: items[index].audioOptions
                                .map((audio) => DropdownMenuItem(
                              value: audio,
                              child: Text(audio),
                            ))
                                .toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            // Buttons at the bottom close together
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Handle action for Button 1
                    print('Button 1 pressed');
                  },
                  child: Text('Download'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Item {
  String title;
  List<String> videoOptions;
  List<String> audioOptions;
  String selectedVideo;
  String selectedAudio;
  bool isChecked;

  Item({
    required this.title,
    required this.videoOptions,
    required this.audioOptions,
    required this.selectedVideo,
    required this.selectedAudio,
    required this.isChecked,
  });
}
