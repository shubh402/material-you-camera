import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() async {
  // Initialize the camera.
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch(
          brightness: Brightness.dark,
          primarySwatch: Colors.blueGrey,
          accentColor: Colors.blue,
        ),
      ),
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isRecording = false;
  bool _showPreview = false;
  String? _qrText;

  @override
  void initState() {
    super.initState();

    // Initialize the camera controller.
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: true,
    );
    _initializeControllerFuture = _controller.initialize();

    // Listen for QR code scans.
    QrReaderController().onScanChanged = (text) {
      setState(() {
        _qrText = text;
      });
    };
  }

  @override
  void dispose() {
    // Dispose of the camera controller.
    _controller.dispose();

    super.dispose();
  }

  void _toggleCamera() async {
    // Toggle between photo and video mode.
    if (_controller.value.isRecordingVideo) {
      _stopRecording();
    } else {
      await _initializeControllerFuture;
      setState(() {
        _showPreview = true;
      });
    }
  }

  Future<void> _startRecording() async {
    // Start recording a video.
    if (_controller.value.isInitialized && !_controller.value.isRecordingVideo) {
      setState(() {
        _isRecording = true;
      });

      await _controller.startVideoRecording();

      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    // Stop recording a video.
    if (_controller.value.isRecordingVideo) {
      setState(() {
        _isRecording = true;
      });

      await _controller.stopVideoRecording();

      setState(() {
        _isRecording = false;
        _showPreview = false;
      });
    }
  }

  Future<void> _takePicture() async {
    // Take a picture.
    try {
      await _initializeControllerFuture;

      final path = '${DateTime.now().millisecondsSinceEpoch}.png';
      await _controller.takePicture(path);

      setState(() {
        _showPreview = true;
      });
    } catch (e) {
      print(e);
    }
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        CameraPreview(_controller),
        if (_qrText != null)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                               child: Text(
                  _qrText!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
          ),
        if (_showPreview)
          Positioned.fill(
            child: Image.file(
              File(_controller.value.previewPath!),
              fit: BoxFit.cover,
            ),
          ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.flash_on),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.camera_alt),
                onPressed: _takePicture,
              ),
              IconButton(
                icon: Icon(Icons.videocam),
                onPressed: _toggleCamera,
              ),
              IconButton(
                icon: Icon(Icons.qr_code),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => QrReaderView(
                      onScan: (text) {
                        setState(() {
                          _qrText = text;
                        });
                      },
                    ),
                  ));
                },
              ),
            ],
          ),
        ),
        if (_controller.value.isRecordingVideo)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Icon(Icons.circle, size: 96, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 96),
          SizedBox(height: 16),
          Text(
            'Camera access denied',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            child: Text('Grant permission'),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera App')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_controller.value.isInitialized) {
              return _buildCameraView();
            } else {
              return _buildPermissionDeniedView();
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class QrReaderView extends StatefulWidget {
  final void Function(String) onScan;

  const QrReaderView({Key? key, required this.onScan}) : super(key: key);

  @override
  _QrReaderViewState createState() => _QrReaderViewState();
}

class _QrReaderViewState extends State<QrReaderView> {
  final _controller = QrReaderController();

  @override
  void initState() {
    super.initState();

    // Start scanning for QR codes.
    _controller.startScanning();
  }

  @override
  void dispose() {
    // Stop scanning for QR codes.
    _controller.stopScanning();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan QR code')),
      body: Center(
        child: QrReaderView(
          controller: _controller,
          onScan: widget.onScan,
        ),
      ),
    );
  }
}
