import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure that we have a camera available.
  final cameras = await availableCameras();
  if (cameras.isEmpty) {
    print('No cameras available');
    return;
  }

  // Select the first available camera.
  final camera = cameras.first;

  runApp(MaterialApp(
    title: 'Material You Camera',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      // Use the platform's brightness setting to determine the theme brightness.
      brightness: Brightness.light,
      // Use Material You colors for the app's primary color scheme.
      colorScheme: const ColorScheme.fromSwatch(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.light,
        // Use the Material You accent color for the app's secondary color scheme.
        accentColor: Colors.deepPurple,
      ),
    ),
    home: CameraApp(camera),
  ));
}

class CameraApp extends StatefulWidget {
  final CameraDescription camera;

  const CameraApp(this.camera, {Key? key}) : super(key: key);

  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    // Create a CameraController for the selected camera.
    _controller = CameraController(
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
      // Enable audio as well.
      enableAudio: true,
    );

    // Initialize the controller. Returns a Future.
       _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  void _takePicture() async {
    try {
      // Ensure that the camera is initialized before taking a picture.
      await _initializeControllerFuture;

      // Construct the path where the image should be saved using the
      // `join` function from the `path` package.
      final path = join(
        // Store the picture in the temporary directory.
        // Find the temp directory using the `path_provider` plugin.
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );

      // Attempt to take a picture and log any errors.
      XFile pictureFile = await _controller.takePicture();
      File savedFile = File(pictureFile.path);
      savedFile.renameSync(path);
    } catch (e) {
      print(e);
    }
  }

  void _startVideoRecording() async {
    try {
      // Ensure that the camera is initialized before recording.
      await _initializeControllerFuture;

      // Construct the path where the video should be saved using the
      // `join` function from the `path` package.
      final path = join(
        // Store the video in the temporary directory.
        // Find the temp directory using the `path_provider` plugin.
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.mp4',
      );

      // Start recording to a temporary file.
      await _controller.startVideoRecording(path);
    } catch (e) {
      print(e);
    }
  }

  void _stopVideoRecording() async {
    try {
      // Stop recording to a temporary file and retrieve the final path.
      XFile videoFile = await _controller.stopVideoRecording();
      String savedPath = videoFile.path;

      // Construct the path where the video should be saved using the
      // `join` function from the `path` package.
      final path = join(
        // Store the video in the temporary directory.
        // Find the temp directory using the `path_provider` plugin.
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.mp4',
      );

      // Rename the video file to the final path.
      File savedFile = File(savedPath);
      savedFile.renameSync(path);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material You Camera'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        tooltip: 'Take a picture',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
