import 'dart:collection';
import 'dart:io';
import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:validator_regex/validator_regex.dart';
import 'package:clipboard/clipboard.dart';
import 'package:path_provider/path_provider.dart';

enum LoadingState { initial, audio, video, mux }

enum DownloadType { single, playlist }

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Code
  final TextEditingController urlText = TextEditingController();
  bool isUrlEntered = false;
  final yt = YoutubeExplode();

  List<String> videoQualities = [];
  List<double> videoSize = [];
  List<String> videoOptions = [];

  List<int> audioQualities = [];
  List<int> audioSize = [];
  List<String> audioOptions = [];

  Map<String, List<double>> videoMap = {};

  late UnmodifiableListView<AudioOnlyStreamInfo> audioStreams;
  late AudioOnlyStreamInfo audioTrack;

  late UnmodifiableListView<VideoOnlyStreamInfo> videoStreams;
  late VideoOnlyStreamInfo videoTrack;

  late File audioFile, videoFile;

  String? selectedVideoQuality = "";
  String? selectedAudioQuality = "";
  String directoryPath = "";
  String? audioFileName = "";
  String? videoFileName = "";
  String? outputFileName = "";

  late DownloadType downloadType;

  int playlistVideoCount = 0;
  late String playlistTitle, playlistAuthor;
  List<String> selectedVideoQualities = [];
  List<String> selectedAudioQualities = [];
  List<List<String>> playlistAudioOptions = [], playlistVideoOptions = [];

  @override
  void initState() {
    super.initState();
    urlText.addListener(() {
      final isUrlEntered = urlText.text.isNotEmpty;
      setState(() {
        this.isUrlEntered = isUrlEntered;
      });
    });
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
                      onPressed: isUrlEntered
                          ? () {
                              setState(() {
                                isUrlEntered = false;
                              });
                              if (urlText.text.isNotEmpty &&
                                  Validator.url(urlText.text)) {
                                searchVideo(urlText.text);
                              } else {
                                showAlertDialog(
                                  context,
                                  "Invalid URL ... Please Enter Valid URL !!!",
                                );
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> searchVideo(String url) async {
    // Code
    showLoadingDialog(context);

    if (url.contains("playlist")) {
      downloadType = DownloadType.playlist;
    } else {
      downloadType = DownloadType.single;
    }

    switch (downloadType) {
      case DownloadType.single:
        await getVideoMetaData(url);
      case DownloadType.playlist:
        await getPlaylistMetaData(url);
    }
  }

  Future<void> getVideoMetaData(String id) async {
    // Code
    try {
      // Get video metadata
      final video = await yt.videos.get(id);

      // Get the video manifest
      final manifest = await yt.videos.streamsClient.getManifest(id);

      clearCollections();

      await getAudioStream(manifest, video);

      await getVideoStream(manifest, video);

      showDownloadDialog(context, video);
    } catch (error) {
      showAlertDialog(context, error.toString());
    }
  }

  Future<void> getPlaylistMetaData(String id) async {

    // Variable Declarations
    List<Video> playlistVideos = [];

    // Code
    try {
      var playlist = await yt.playlists.get(id);

      playlistTitle = playlist.title;
      playlistAuthor = playlist.author;
      playlistVideoCount = playlist.videoCount!;

      selectedAudioQualities.clear();
      selectedVideoQualities.clear();

      await for (var video in yt.playlists.getVideos(playlist.id)) {
        playlistVideos.add(video);
        var manifest = await yt.videos.streamsClient.getManifest(video.id);
        await getAudioStream(manifest, video);
        await getVideoStream(manifest, video);
        playlistAudioOptions.add(List<String>.from(audioOptions));
        playlistVideoOptions.add(List<String>.from(videoOptions));
        clearCollections();
      }

      showDownloadPlaylistDialog(context, playlistVideos);

    } catch (error) {
      showAlertDialog(context, error.toString());
    }
  }

  Future<void> getAudioStream(StreamManifest manifest, Video videoMetaData) async
  {
    // Code

    // Get the audio track with the highest bitrate.
    audioStreams = manifest.audioOnly;

    for (var streamInfo in audioStreams) {
      if (streamInfo.codec.subtype != "webm") {
        audioQualities.add(streamInfo.bitrate.kiloBitsPerSecond.ceil());
        audioSize.add(streamInfo.size.totalMegaBytes.ceil());
      }
    }

    for (int i = 0; i < audioSize.length; i++) {
      audioOptions.add(
          "${audioQualities.elementAt(i).toString()} Kbps : ${audioSize.elementAt(i).toString()} MB");
    }

    int index = audioQualities.length;
    int largestBitrate = 0;
    for (int i = 0; i < audioQualities.length; i++) {
      int bitrate = audioQualities[i];
      if (bitrate > largestBitrate) {
        largestBitrate = bitrate;
        index = i;
      }
    }
    if (downloadType == DownloadType.single) {
      selectedAudioQuality = audioOptions[index];
    }
    else {
      selectedAudioQualities.add(audioOptions.elementAt(index));
    }

  }

  Future<void> getVideoStream(StreamManifest manifest, Video videoMetaData) async {
    // Code

    // Get the video track
    videoStreams = manifest.videoOnly;

    videoQualities.clear();
    videoSize.clear();
    videoOptions.clear();

    for (var streamInfo in videoStreams) {
      if (streamInfo.qualityLabel != "144p" &&
          streamInfo.codec.subtype != "webm") {
        videoQualities.add(streamInfo.qualityLabel);
        videoSize.add(streamInfo.size.totalMegaBytes);
        String tempStr = "${streamInfo.qualityLabel} : ${streamInfo.size}";
        videoOptions.add(tempStr);
      }
    }

    double smallestSize = double.infinity;
    int smallestSizeIndex = 0;

    for (int i = 0; i < videoQualities.length; i++) {
      if (videoQualities[i] == "1080p") {
        double size = videoSize[i];
        if (size < smallestSize) {
          smallestSize = size;
          smallestSizeIndex = i;
        }
      }
    }

    if (downloadType == DownloadType.single) {
      selectedVideoQuality = videoOptions.elementAt(smallestSizeIndex);
    }
    else {
      selectedVideoQualities.add(videoOptions.elementAt(smallestSizeIndex));
    }
  }

  void showDownloadDialog(BuildContext context, Video videoMetaData) {
    // Code
    bool downloadClicked = false;
    bool showProgress = false;
    double progress = 0.0;
    LoadingState loadingState = LoadingState.initial;
    String displayText = "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                                  null;
                                  // showExitConfirmationDialog(context);
                                } else {
                                  clearCollections();
                                  Navigator.of(context).pop();
                                  Navigator.of(context)
                                      .pop(); // Close Loading Dialog
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Poppins"),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.blueGrey,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: "Poppins"),
                                    ),
                                    SizedBox(height: 8.0),
                                    DropdownMenu<String>(
                                      initialSelection: selectedVideoQuality,
                                      onSelected: (String? newValue) {
                                        setState(() {
                                          selectedVideoQuality = newValue;
                                        });
                                      },
                                      dropdownMenuEntries: videoOptions
                                          .map<DropdownMenuEntry<String>>(
                                              (String value) {
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
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.blueGrey,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: "Poppins"),
                                    ),
                                    SizedBox(height: 8.0),
                                    DropdownMenu<String>(
                                      initialSelection: selectedAudioQuality,
                                      onSelected: (String? newValue) {
                                        setState(() {
                                          selectedAudioQuality = newValue;
                                        });
                                      },
                                      dropdownMenuEntries: audioOptions
                                          .map<DropdownMenuEntry<String>>(
                                              (String value) {
                                        return DropdownMenuEntry<String>(
                                            value: value, label: value);
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Progress Bar
                          if (showProgress)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6.0),
                              child: Column(
                                children: [
                                  Text(displayText,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontFamily: "Poppins",
                                        fontWeight: FontWeight.w600,
                                      )),
                                  SizedBox(height: 8.0),
                                  Builder(
                                    builder: (context) {
                                      switch (loadingState) {
                                        // For Audio and Video
                                        case LoadingState.audio:
                                        case LoadingState.video:
                                          return Column(
                                            children: [
                                              LinearProgressIndicator(
                                                  value: progress,
                                                  minHeight: 15,
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(30))),
                                              SizedBox(height: 8.0),
                                              Text(
                                                "${(progress * 100).toStringAsFixed(0)} %",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: "Poppins"),
                                              ),
                                            ],
                                          );

                                        case LoadingState.mux:
                                          return CircularProgressIndicator(
                                              color: Colors.red.shade400);

                                        default:
                                          return Container();
                                      }
                                    },
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
                              onPressed: () async {
                                directoryPath = openDirectoryPicker(
                                    "Select Directory To Download")!;

                                setState(() {
                                  downloadClicked = true;
                                  showProgress = true;
                                  loadingState = LoadingState.audio;
                                });

                                await downloadAudioTrack(
                                  videoMetaData,
                                  (double value) {
                                    setState(() {
                                      displayText = "Downloading Audio ...";
                                      progress = value;
                                    });
                                  },
                                );

                                setState(() {
                                  progress = 0.0;
                                  loadingState = LoadingState.video;
                                });

                                await downloadVideoTrack(
                                  videoMetaData,
                                  (double value) {
                                    setState(() {
                                      displayText = "Downloading Video ...";
                                      progress = value;
                                    });
                                  },
                                );

                                setState(() {
                                  displayText = "Processing ...";
                                  loadingState = LoadingState.mux;
                                });

                                // await processVideo(context);

                                setState(() {
                                  downloadClicked = false;
                                  progress = 0.0;
                                  showProgress = false;
                                });
                              },
                              icon: Icon(Icons.download),
                              label: Text(
                                'Download',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: "Poppins"),
                              ),
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
      },
    );
  }

  Future<void> downloadAudioTrack(Video videoMetaData, Function(double) onProgressUpdate) async {
    // Code
    final selectedAudioAttributes = selectedAudioQuality?.split(" : ");
    final selectedAudioBitrateList =
        selectedAudioAttributes!.elementAt(0).split(" ");
    final selectedAudioSizeList =
        selectedAudioAttributes.elementAt(1).split(" ");

    int selectedAudioBitrate = int.parse(selectedAudioBitrateList.elementAt(0));
    int selectedAudioSize = int.parse(selectedAudioSizeList.elementAt(0));

    for (var audioStreamOption in audioStreams) {
      int streamBitrate = audioStreamOption.bitrate.kiloBitsPerSecond.ceil();
      int streamSize = audioStreamOption.size.totalMegaBytes.ceil();
      if (selectedAudioBitrate == streamBitrate &&
          selectedAudioSize == streamSize) {
        audioTrack = audioStreamOption;
        break;
      }
    }

    final audioStream = yt.videos.streamsClient.get(audioTrack);
    audioFileName = '${videoMetaData.title}_audio_.${audioTrack.container.name}'
        .replaceAll(r'\', '_')
        .replaceAll('/', '_')
        .replaceAll('*', '_')
        .replaceAll('?', '_')
        .replaceAll('"', '_')
        .replaceAll('<', '_')
        .replaceAll('>', '_')
        .replaceAll(':', '_')
        .replaceAll('|', '_');

    outputFileName = '${videoMetaData.title}.${audioTrack.container.name}'
        .replaceAll(r'\', '_')
        .replaceAll('/', '_')
        .replaceAll('*', '_')
        .replaceAll('?', '_')
        .replaceAll('"', '_')
        .replaceAll('<', '_')
        .replaceAll('>', '_')
        .replaceAll(':', '_')
        .replaceAll('|', '_');

    audioFile = File('$directoryPath/$audioFileName');
    if (audioFile.existsSync()) {
      audioFile.deleteSync();
    }

    final output = audioFile.openWrite(mode: FileMode.writeOnlyAppend);
    final len = audioTrack.size.totalBytes;
    var count = 0;

    await for (final data in audioStream) {
      count += data.length;
      final currentProgress = ((count / len));
      onProgressUpdate(currentProgress);
      output.add(data);
    }

    await output.close();
  }

  Future<void> downloadVideoTrack(Video videoMetaData, Function(double) onProgressUpdate) async {
    // Code
    final selectedVideoAttributes = selectedVideoQuality?.split(" : ");
    final selectedVideoPixels = selectedVideoAttributes!.elementAt(0);
    final selectedVideoSize = selectedVideoAttributes.elementAt(1);

    for (var videoStreamInfo in videoStreams) {
      if (selectedVideoPixels == videoStreamInfo.qualityLabel &&
          selectedVideoSize == videoStreamInfo.size.toString()) {
        videoTrack = videoStreamInfo;
        break;
      }
    }

    final videoStream = yt.videos.streamsClient.get(videoTrack);
    videoFileName = '${videoMetaData.title}_video_.${videoTrack.container.name}'
        .replaceAll(r'\', '_')
        .replaceAll('/', '_')
        .replaceAll('*', '_')
        .replaceAll('?', '_')
        .replaceAll('"', '_')
        .replaceAll('<', '_')
        .replaceAll('>', '_')
        .replaceAll(':', '_')
        .replaceAll('|', '_');

    videoFile = File('$directoryPath/$videoFileName');
    if (videoFile.existsSync()) {
      videoFile.deleteSync();
    }

    final output = videoFile.openWrite(mode: FileMode.writeOnlyAppend);
    final len = videoTrack.size.totalBytes;
    var count = 0;

    await for (final data in videoStream) {
      count += data.length;
      final currentProgress = (count / len);
      onProgressUpdate(currentProgress);
      output.add(data);
    }

    await output.close();
  }

  Future<void> processVideo(BuildContext context) async {
    // Code
    final inputAudioStream = audioFile.absolute.path;
    final inputVideoStream = videoFile.absolute.path;
    final outputStream = "${videoFile.parent.absolute.path}/${outputFileName!}";

    final temp = File(outputStream);
    if (temp.existsSync()) {
      temp.deleteSync();
    }

    final arguments = [
      '-i',
      inputVideoStream,
      '-i',
      inputAudioStream,
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      outputStream,
    ];

    final process =
        await Process.start("ffmpeg.exe", arguments, runInShell: true);

    // Write to Log File
    Directory appDocsDir = await getApplicationDocumentsDirectory();
    String appDirPath = appDocsDir.path;
    final logFile = File('$appDirPath\\YTDL.log');
    final logSink = logFile.openWrite();
    process.stdout.transform(SystemEncoding().decoder).listen((data) {
      logSink.write(data);
    });
    process.stderr.transform(SystemEncoding().decoder).listen((data) {
      logSink.write(data);
    });

    final exitCode = await process.exitCode;
    if (exitCode == 0) {
      showMsgDialog(context, "Processing Finished Successfully ...");
      videoFile.deleteSync();
      audioFile.deleteSync();
    } else {
      showAlertDialog(context, "Failed To Process Video !!!");
    }

    await logSink.close();
  }

  void showDownloadPlaylistDialog(BuildContext context, List<Video> playlistMetadata) {
    List<bool> isSelected = List.filled(playlistMetadata.length, true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int selectedCount = isSelected.where((selected) => selected).length;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: SizedBox(
                width: 1200,
                height: 900,
                child: Column(
                  children: [
                    // Title and Close Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$playlistTitle by $playlistAuthor",
                            // "Playlist",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => {
                              Navigator.of(context).pop(),
                              Navigator.of(context).pop()
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    // Playlist ListView
                    Expanded(
                      child: ListView.builder(
                        itemCount: playlistMetadata.length,
                        itemBuilder: (context, index) {
                          var video = playlistMetadata[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Checkbox
                                  Checkbox(
                                    value: isSelected[index],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        isSelected[index] = value!;
                                      });
                                    },
                                  ),

                                  // Thumbnail and Title
                                  Row(
                                    children: [
                                      Image.network(
                                        video.thumbnails.standardResUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 12),
                                      // Title Wrapping Section
                                      SizedBox(
                                        width: 400, // Adjust the width as needed
                                        child: Text(
                                          video.title,
                                          maxLines: 3,  // Wrap in 2-3 lines
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Audio Quality Dropdown
                                  Column(
                                    children: [
                                      const Text("Audio Quality",
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      DropdownMenu<String>(
                                        initialSelection: selectedAudioQualities[index],
                                        onSelected: (String? newValue) {
                                          setState(() {
                                            selectedAudioQuality = newValue;
                                          });
                                        },
                                        dropdownMenuEntries: playlistAudioOptions[index]
                                            .map<DropdownMenuEntry<String>>(
                                                (String value) {
                                              return DropdownMenuEntry<String>(
                                                  value: value, label: value);
                                            }).toList(),
                                      ),
                                    ],
                                  ),

                                  // Video Quality Dropdown
                                  Column(
                                    children: [
                                      const Text("Video Quality",
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      DropdownMenu<String>(
                                        initialSelection: selectedVideoQualities[index],
                                        onSelected: (String? newValue) {
                                          setState(() {
                                            selectedVideoQuality = newValue;
                                          });
                                        },
                                        dropdownMenuEntries: playlistVideoOptions[index]
                                            .map<DropdownMenuEntry<String>>(
                                                (String value) {
                                              return DropdownMenuEntry<String>(
                                                  value: value, label: value);
                                            }).toList(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Download Button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: selectedCount > 0 ?
                            () async {
                          List<Video> selectedVideos = [];
                          for (int i = 0; i < playlistMetadata.length; i++) {
                            if (isSelected[i]) {
                              selectedVideos.add(playlistMetadata[i]);
                            }
                          }

                          if (selectedVideos.isNotEmpty) {
                            Navigator.of(context).pop(); // Close dialog
                            // await downloadSelectedVideos(context, selectedVideos, selectedAudioQualities, selectedVideoQualities);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("No videos selected")),
                            );
                          }
                        }: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 50),
                        ),
                        child: Text(
                          selectedCount == playlistMetadata.length
                              ? "Download All Videos"
                              : "Download $selectedCount Video(s)"
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
                Navigator.of(context).pop(); // Close loading dialog
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
        title: const Text(
          'Error',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: "Poppins",
              color: Colors.red),
        ),
        content: Text(
          errMsg,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, fontFamily: "Poppins"),
        ),
        actions: <Widget>[
          TextButton(
            autofocus: true,
            onPressed: () => {Navigator.of(context).pop()},
            child: const Text(
              'Ok',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: "Poppins",
                  color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void showMsgDialog(BuildContext context, String msg) {
    // Code
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(
          'Video Status',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: "Poppins",
              color: Colors.green),
        ),
        content: Text(
          msg,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, fontFamily: "Poppins"),
        ),
        actions: <Widget>[
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, 'Ok'),
            child: const Text(
              'Ok',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: "Poppins",
                  color: Colors.black),
            ),
          )
        ],
      ),
    );
  }

  void showLoadingDialog(BuildContext context) {
    // Code
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.blueGrey),
                SizedBox(width: 30.0),
                Text("Please Wait ...",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Poppins"),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  String? openDirectoryPicker(String title) {
    // Code
    String? path;

    DirectoryPicker picker = DirectoryPicker();
    picker.title = title;
    Directory? directory = picker.getDirectory();
    if (directory != null) {
      path = directory.path;
    }
    return path;
  }

  void clearCollections() {
    audioOptions.clear();
    audioSize.clear();
    audioQualities.clear();
    videoOptions.clear();
    videoQualities.clear();
    videoSize.clear();
  }

  @override
  void dispose() {
    urlText.dispose();
    yt.close();
    super.dispose();
  }
}
