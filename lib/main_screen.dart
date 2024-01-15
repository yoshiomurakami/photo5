// import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'album_screen.dart';
import 'timeline_camera.dart';
import 'timeline_map_widget.dart';
import 'timeline_providers.dart';
import 'chat_connection.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _MainScreenContent();
  }
}


class _MainScreenContent extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<_MainScreenContent> {
  final PageController _pageController = PageController(viewportFraction: 1); // ここでビューポートの幅を設定
  bool _programmaticPageChange = false;
  // Future<List<CameraDescription>>? _camerasFuture;
  ChatConnection? chatConnection;

  // String? latestPhotoChange;


  @override
  void initState() {
    super.initState();
    // _camerasFuture = availableCameras();
  }

  @override
  void dispose() {
    chatConnection?.disconnect(); // ここで disconnect メソッドを使用
    super.dispose();
  }

  void _openCamera(CameraDescription cameraDescription, String groupID) { // groupIDを引数として追加
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          camera: cameraDescription,
          groupID: groupID, // CameraScreenにgroupIDを渡す
        ),
      ),
    );
  }

  // void _openAlbum() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => AlbumScreen(),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final Size size = MediaQuery.of(context).size;
      Widget timelineMapWidget = const Center(child: CircularProgressIndicator()); // 初期値を設定

      final timelineItemsAsyncValue = ref.watch(timelineProvider);
      timelineItemsAsyncValue.when(
        data: (items) {
          final timelineItems = items;
          final currentLocation = LatLng(timelineItems[0].lat, timelineItems[0].lng);
          timelineMapWidget = TimelineMapWidget(
            size: size,
            currentLocation: currentLocation,
            timelineItems: timelineItems,
            pageController: _pageController,
            programmaticPageChange: _programmaticPageChange,
            updateGeocodedLocation: updateGeocodedLocation,
            // onCameraButtonPressed: () async {
            //   List<CameraDescription>? cameras = await _camerasFuture;
            //   if (cameras != null && cameras.isNotEmpty) {
            //     _openCamera(cameras.first);
            //   }
            // },
          );
        },
        loading: () => timelineMapWidget = Center(child: CircularProgressIndicator()),
        error: (error, stack) => timelineMapWidget = Center(child: Text('Error: $error')),
      );

      return Scaffold(
        body: Stack(
          children: <Widget>[
            timelineMapWidget,
            // FutureBuilder<List<CameraDescription>>(
            //   future: _camerasFuture,
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.done) {
            //       if (snapshot.hasData) {
            //         return CameraButton(onPressed: () => _openCamera(snapshot.data!.first));
            //       } else {
            //         return Text('No camera found');
            //       }
            //     } else {
            //       return CircularProgressIndicator();
            //     }
            //   },
            // ),
            ConnectionNumber(),
            // if (latestPhotoChange != null)
            //   Positioned(
            //     top: 10,
            //     left: 10,
            //     child: Text(latestPhotoChange!),
            //   ),
          ],
        ),
        // floatingActionButton: FloatingActionButton(
        //   heroTag: "album",
        //   onPressed: _openAlbum,
        //   child: Icon(Icons.photo_album),
        // ),
      );
    });
  }


}




