import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:validator_regex/validator_regex.dart';
import 'package:clipboard/clipboard.dart';

class Home extends StatefulWidget {

  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController urlText = TextEditingController();
  final yt = YoutubeExplode();

  List<String> videoQualities = [];
  List<double> videoSize = [];
  List<String> videoOptions = [];

  List<double> audioQualities = [];
  List<double> audioSize = [];
  List<String> audioOptions = [];

  late AudioOnlyStreamInfo audioTrack;

  String? selectedVideoQuality;
  String? selectedAudioQuality;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black, width: 1.5),
      borderRadius: BorderRadius.all(Radius.circular(30)),
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                const Image(
                  image: AssetImage("assets/images/youtube.png"),
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 10),
                const Text(
                  "YouTube Video Downloader",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins",
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            // URL Input and Search Button Section
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: TextField(
                    controller: urlText,
                    style: const TextStyle(color: Colors.black),
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: "Enter Video URL",
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontFamily: "Poppins",
                      ),
                      prefixIcon: const Icon(Icons.link_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: border,
                      enabledBorder: border,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontFamily: "Poppins",
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      label: const Text("Paste URL"),
                      icon: const Icon(Icons.content_paste_rounded),
                      onPressed: () {
                        FlutterClipboard.paste().then((value) {
                          setState(() {
                            urlText.text = value;
                          });
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontFamily: "Poppins",
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      label: const Text("Clear URL"),
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        urlText.clear();
                      },
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontFamily: "Poppins",
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      label: const Text("Search Video"),
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        if (urlText.text.isNotEmpty &&
                            Validator.url(urlText.text)) {
                          searchVideo(urlText.text);
                        }
                        else if (urlText.text.isEmpty) {
                          showAlertDialog(context, "Empty URL ... Please Enter Valid URL !!!");
                        }
                        else if (!Validator.url(urlText.text)) {
                          showAlertDialog(context, "Invalid URL ... Please Enter Valid URL !!!");
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
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

      clearCollections();

      await downloadAudioStream(manifest, video);

      await downloadVideoStream(manifest, video);

      showDownloadDialog(context, video);
    } catch (error) {
      showAlertDialog(context, error.toString());
    }
  }

  Future<void> downloadAudioStream(StreamManifest manifest, Video videoMetaData) async {
    // Code

    // Get the audio track with the highest bitrate.
    final streams = manifest.audioOnly;

    for (var streamInfo in streams) {
      audioQualities.add(streamInfo.bitrate.kiloBitsPerSecond);
      audioSize.add(streamInfo.size.totalMegaBytes);
    }

    // Sort lists
    audioSize.sort();
    audioQualities.sort();
    
    for (int i = 0; i < audioSize.length; i++) {
      audioOptions.add("${audioQualities.elementAt(i).toStringAsFixed(1)} Kbps : ${audioSize.elementAt(i).toStringAsFixed(1)} MB");
    }

    final audio = streams.withHighestBitrate();
    streams.elementAt(0).bitrate;
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

    // print('Quality: ${streamInfo.qualityLabel}, Codec: ${streamInfo.codec}, Bitrate: ${streamInfo.bitrate}, Size: ${streamInfo.size}');

    for (var streamInfo in streams) {
      if (streamInfo.qualityLabel != "144p") {
        String tempStr = "${streamInfo.qualityLabel} : ${streamInfo.size}";
        videoQualities.add(tempStr);
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

  // void showDownloadDialog(BuildContext context, Video videoMetaData) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(15),
  //         ),
  //         child: SizedBox(
  //           width: 600,
  //           height: 600,
  //           child: Padding(
  //             padding: const EdgeInsets.all(16.0), // Added padding around the entire dialog content
  //             child: Column(
  //               children: [
  //                 // Image Section
  //                 Container(
  //                   padding: const EdgeInsets.only(bottom: 16.0),
  //                   child: Image.network(
  //                     videoMetaData.thumbnails.standardResUrl,
  //                     width: 320,
  //                     height: 180,
  //                     fit: BoxFit.contain,
  //                   ),
  //                 ),
  //                 // Title Section
  //                 Padding(
  //                   padding: const EdgeInsets.symmetric(vertical: 8.0),
  //                   child: Text(
  //                     videoMetaData.title,
  //                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //                     textAlign: TextAlign.center,
  //                   ),
  //                 ),
  //                 // Dropdown Menu Section
  //                 Expanded(
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                     children: [
  //                       // Video Quality Dropdown
  //                       Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Text(
  //                             "Select Video Quality",
  //                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 241, 89, 115)),
  //                           ),
  //                           SizedBox(height: 8.0),
  //                           DropdownMenu<String>(
  //                             initialSelection: videoQualities.first,
  //                             enableSearch: false,
  //                             enableFilter: false,
  //                             onSelected: (String? newValue) {
  //                               setState(() {
  //                                 selectedVideoQuality = newValue;
  //                               });
  //                             },
  //                             dropdownMenuEntries: videoQualities.map<DropdownMenuEntry<String>>((String value) {
  //                               return DropdownMenuEntry<String>(value: value, label: value);
  //                             }).toList(),
  //                           ),
  //                         ],
  //                       ),
  //                       // Audio Quality Dropdown
  //                       Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Text(
  //                             "Select Audio Quality",
  //                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 241, 89, 115)),
  //                           ),
  //                           SizedBox(height: 8.0),
  //                           DropdownMenu<String>(
  //                             initialSelection: audioMap.keys.last,
  //                             enableSearch: false,
  //                             enableFilter: false,
  //                             onSelected: (String? newValue) {
  //                               setState(() {
  //                                 selectedAudioQuality = newValue;
  //                               });
  //                             },
  //                             dropdownMenuEntries: audioQualities.map<DropdownMenuEntry<String>>((String value) {
  //                               return DropdownMenuEntry<String>(value: value, label: value);
  //                             }).toList(),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 // Download Button Section
  //                 Padding(
  //                   padding: const EdgeInsets.only(top: 16.0),
  //                   child: ElevatedButton.icon(
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.blueGrey,
  //                       foregroundColor: Colors.white,
  //                       minimumSize: const Size(200, 50),
  //                       textStyle: TextStyle(
  //                         fontSize: 16,
  //                         fontFamily: "Poppins",
  //                         color: Colors.white,
  //                       ),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(30),
  //                       ),
  //                     ),
  //                     onPressed: () {
  //                       exit(0);
  //                     },
  //                     icon: Icon(Icons.download),
  //                     label: Text('Download'),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void showDownloadDialog(BuildContext context, Video videoMetaData) {
    // Code
    bool downloadClicked = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              SizedBox(
                width: 600,
                height: 600,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Close Button
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            if (downloadClicked) {
                              showExitConfirmationDialog(context);
                            } else {
                              clearCollections();
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                      // Image Section
                      Container(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Image.network(
                          videoMetaData.thumbnails.standardResUrl,
                          width: 320,
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Title Section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          videoMetaData.title,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Dropdown Menu Section
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Video Quality Dropdown
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Select Video Quality",
                                  style: TextStyle(fontSize: 18),
                                ),
                                SizedBox(height: 8.0),
                                DropdownMenu<String>(
                                  initialSelection: videoQualities.last,
                                  onSelected: (String? newValue) {
                                    setState(() {
                                      selectedVideoQuality = newValue;
                                    });
                                  },
                                  dropdownMenuEntries: videoQualities.map<DropdownMenuEntry<String>>((String value) {
                                    return DropdownMenuEntry<String>(
                                        value: value, label: value);
                                  }).toList(),
                                ),
                              ],
                            ),
                            // Audio Quality Dropdown
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Select Audio Quality",
                                  style: TextStyle(fontSize: 18),
                                ),
                                SizedBox(height: 8.0),
                                DropdownMenu<String>(
                                  initialSelection: audioOptions.last,
                                  onSelected: (String? newValue) {
                                    setState(() {
                                      selectedAudioQuality = newValue;

                                    });
                                  },
                                  dropdownMenuEntries: audioOptions.map<DropdownMenuEntry<String>>((String value) {
                                    return DropdownMenuEntry<String>(
                                        value: value, label: value);
                                  }).toList(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Download Button Section
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(200, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            downloadClicked = true;
                            // Trigger download operation
                          },
                          icon: Icon(Icons.download),
                          label: Text('Download'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Exit Download"),
          content: Text("Are you sure you want to stop downloading ?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
              },
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(); // Close main dialog
              },
              child: Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  void showAlertDialog(BuildContext context, String errMsg) {
    // Code
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Error'),
        content: Text(errMsg),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void clearCollections() {
    audioOptions.clear();
    audioSize.clear();
    audioQualities.clear();
    videoOptions.clear();
    videoSize.clear();
    videoQualities.clear();
  }

  @override
  void dispose() {
    urlText.dispose();
    super.dispose();
  }
}
