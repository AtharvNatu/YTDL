import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController urlText = TextEditingController();
  final yt = YoutubeExplode();

  List<String> videoQualities = [];
  List<String> audioQualities = [];

  String? selectedVideoQuality;
  String? selectedAudioQuality;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );

    const border = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black, width: 1.0),
      borderRadius: BorderRadius.all(Radius.circular(30)),
    );

    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 241, 89, 115),
          title: const Text(
            "YTDL : YouTube Downloader",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              fontFamily: "Poppins",
              color: Colors.white,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: style,
              onPressed: () {
                yt.close();
                exit(0);
              },
              child: const Text("Exit"),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Image(image: AssetImage("assets/images/youtube.png")),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: urlText,
                  style: const TextStyle(color: Colors.black),
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    hintText: "Enter Video URL",
                    hintStyle: const TextStyle(
                      color: Colors.black,
                      fontFamily: "Poppins",
                    ),
                    prefixIcon: const Icon(Icons.link_rounded),
                    prefixIconColor: Colors.black,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                      child: GestureDetector(
                        onTap: clearText,
                        child: Icon(
                          Icons.clear_rounded,
                          size: 24,
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: border,
                    enabledBorder: border,
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontFamily: "Poppins",
                        color: Colors.white,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    label: const Text("Select Image"),
                    icon: Image.asset("assets/images/search.png"),
                    onPressed: () {
                      if (urlText.text.isNotEmpty) {
                        searchVideo(urlText.text);
                      }
                    },
                  )),
            ],
          ),
        ));
  }

  void clearText() {
    urlText.clear();
  }

  Future<void> searchVideo(String url) async {
    // Code
    Directory('downloads').createSync();
    await download(url);
  }

  Future<void> download(String id) async {
    // Code
    try {
      // Get video metadata.
      final video = await yt.videos.get(id);

      // Get the video manifest.
      final manifest = await yt.videos.streamsClient.getManifest(id);

      await downloadAudioStream(manifest, video);

      await downloadVideoStream(manifest, video);

      _showDialog(context, video);

    } catch (e) {
      print("Error : $e");
    }
  }

  Future<void> downloadAudioStream(StreamManifest manifest, Video videoMetaData) async {
    // Code

    // Get the audio track with the highest bitrate.
    final streams = manifest.audioOnly;

    //* DEBUG
    if (kDebugMode) {
      for (var streamInfo in streams) {
        print('Quality: ${streamInfo.codec}, Bitrate: ${streamInfo.bitrate}, Size: ${streamInfo.size}');
        audioQualities.add(streamInfo.bitrate.toString());
      }
    }

    final audio = streams.withHighestBitrate();
    final audioStream = yt.videos.streamsClient.get(audio);

    // final fileName = '${videoMetaData.title}_audio_.${audio.container.name}'
    //     .replaceAll(r'\', '')
    //     .replaceAll('/', '')
    //     .replaceAll('*', '')
    //     .replaceAll('?', '')
    //     .replaceAll('"', '')
    //     .replaceAll('<', '')
    //     .replaceAll('>', '')
    //     .replaceAll(':', '')
    //     .replaceAll('|', '');
    // final file = File('downloads/$fileName');
    //
    // // Delete the file if exists.
    // if (file.existsSync()) {
    //   file.deleteSync();
    // }
    //
    // // Open the file in writeAppend.
    // final output = file.openWrite(mode: FileMode.writeOnlyAppend);
    //
    // // Track the file download status.
    // final len = audio.size.totalBytes;
    // var count = 0;
    //
    // // Create the message and set the cursor position.
    // final msg = 'Downloading ${videoMetaData.title}.${audio.container.name}';
    // stdout.writeln(msg);
    //
    // // Listen for data received.
    // await for (final data in audioStream) {
    //   // Keep track of the current downloaded data.
    //   count += data.length;
    //
    //   // Calculate the current progress.
    //   final progress = ((count / len) * 100).ceil();
    //
    //   print(progress.toStringAsFixed(2));
    //
    //   // Write to file.
    //   output.add(data);
    // }
    // await output.close();
  }

  Future<void> downloadVideoStream(StreamManifest manifest, Video videoMetaData) async {
    // Code

    // Get the video track
    final streams = manifest.videoOnly;

    //* DEBUG
    if (kDebugMode) {
      for (var streamInfo in streams) {
        print('Quality: ${streamInfo.qualityLabel}, Codec: ${streamInfo.codec}, Bitrate: ${streamInfo.bitrate}, Size: ${streamInfo.size}');
        videoQualities.add(streamInfo.qualityLabel);
      }
    }

    final video = streams.getAllVideoQualities();
    // final audioStream = yt.videos.streamsClient.get(audio);
    //
    // final fileName = '${videoMetaData.title}_video_.${audio.container.name}'
    //     .replaceAll(r'\', '')
    //     .replaceAll('/', '')
    //     .replaceAll('*', '')
    //     .replaceAll('?', '')
    //     .replaceAll('"', '')
    //     .replaceAll('<', '')
    //     .replaceAll('>', '')
    //     .replaceAll(':', '')
    //     .replaceAll('|', '');
    // final file = File('downloads/$fileName');
    //
    // // Delete the file if exists.
    // if (file.existsSync()) {
    //   file.deleteSync();
    // }
    //
    // // Open the file in writeAppend.
    // final output = file.openWrite(mode: FileMode.writeOnlyAppend);
    //
    // // Track the file download status.
    // final len = audio.size.totalBytes;
    // var count = 0;
    //
    // // Create the message and set the cursor position.
    // final msg = 'Downloading ${videoMetaData.title}.${audio.container.name}';
    // stdout.writeln(msg);
    //
    // // Listen for data received.
    // await for (final data in audioStream) {
    //   // Keep track of the current downloaded data.
    //   count += data.length;
    //
    //   // Calculate the current progress.
    //   final progress = ((count / len) * 100).ceil();
    //
    //   print(progress.toStringAsFixed(2));
    //
    //   // Write to file.
    //   output.add(data);
    // }
    // await output.close();
  }

  void _showDialog(BuildContext context, Video videoMetaData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: SizedBox(
            width: 600,
            height: 600,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(
                    videoMetaData.thumbnails.standardResUrl,
                    width: 300,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Group 1
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Select Video Quality", style: TextStyle(fontSize: 18)),
                          ...videoQualities.map((value) {
                            return Row(
                              children: [
                                Radio<String>(
                                  value: value,
                                  groupValue: selectedVideoQuality,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedVideoQuality = newValue;
                                    });
                                  },
                                ),
                                Text(value),
                              ],
                            );
                          }),
                        ],
                      ),
                      // Group 2
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Select Audio Quality", style: TextStyle(fontSize: 18)),
                          ...audioQualities.map((value) {
                            return Row(
                              children: [
                                Radio<String>(
                                  value: value,
                                  groupValue: selectedAudioQuality,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedAudioQuality = newValue;
                                    });
                                  },
                                ),
                                Text(value),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Handle download action
                    },
                    icon: Icon(Icons.download),
                    label: Text('Download'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    urlText.dispose();
    super.dispose();
  }
}
