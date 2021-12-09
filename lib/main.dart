import 'dart:async';
import 'dart:io';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/tap_bounce_container.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

Future <void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera App',
      home: CameraScreen(cameras: cameras),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({Key? key, required this.cameras,}) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isRecording = false;
  int selected=0;
  List <File> savedImage=[];

  initCamera(int cameraIdx) async{
    _controller = CameraController(
      widget.cameras[cameraIdx],
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller!.initialize();
  }

  @override
  void initState() {
    initCamera(selected);
    super.initState();
  }

  @override
  void dispose() {
    // 위젯의 생명주기 종료시 컨트롤러 역시 해제시켜줍니다.
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FLUTTER CAMERA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.flip_camera_ios),
            onPressed: () {
              if (widget.cameras.length > 1) {
                setState(() {
                  selected = selected == 0 ? 1 : 0;//Switch camera
                  initCamera(selected);
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('No secondary camera found'),
                  duration: const Duration(seconds: 2),
                ));
            }}
          )
        ],
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
          children: [
        FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // Future가 완료되면, 프리뷰를 보여줍니다.
              return Container(width:double.infinity,height: double.infinity,child: CameraPreview(_controller!));
            } else {
              // 그렇지 않다면, 진행 표시기를 보여줍니다.
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [

                  FloatingActionButton(
                      backgroundColor: Colors.blue,
                      onPressed: () async {
                        try {
                          await _initializeControllerFuture;
                          final picture = await _controller!.takePicture();
                          await GallerySaver.saveImage(picture.path);
                          File(picture.path).deleteSync();
                          print("저장성공");
                        } catch (e) {
                          print(e);
                        }
                      },
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      )),
                  SizedBox(
                    width: 10,
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.blue,
                    onPressed: () {
                      _recordVideo();
                    },
                    child: _isRecording
                        ? Icon(
                      Icons.stop,
                      color: Colors.white,
                    )
                        : Icon(
                      Icons.video_call_outlined,
                      color: Colors.white,
                    ),
                  ),

                ],
              ),
            ),
      ]
      ),
    );
  }

  _recordVideo() async {
    if (_isRecording) {
      try {
        showTopSnackBar(
          context,
          CustomSnackBar.info(
            message: "동영상 녹화 완료",
          ),
        );
        final video = await _controller!.stopVideoRecording();
        await GallerySaver.saveVideo(video.path);
        File(video.path).deleteSync();
        setState(() => _isRecording = false);
      } catch (e) {
        print(e);
      }
    } else {
      try {
        showTopSnackBar(
          context,
          CustomSnackBar.success(
            message: "동영상 녹화 시작",
          ),
        );
        await _initializeControllerFuture;
        await _controller!.startVideoRecording();
        setState(() => _isRecording = true);
      } catch (e) {
        print(e);
      }
    }
  }
}
