import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui' as ui;
import 'package:ytdl/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    WindowOptions windowOptions = const WindowOptions(
      size: ui.Size(900, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      fullScreen: false,
      title: "YTDL : YouTube Downloader",
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //! Root Widget
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YTDL : YouTube Video Downloader',
      home: const Home(),
    );
  }
}

