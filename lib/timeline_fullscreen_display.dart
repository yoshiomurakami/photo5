// import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'timeline_photoview.dart';
import 'timeline_providers.dart';
import 'timeline_fullscreen_card.dart';
// import 'chat_connection.dart';

// class MapController {
//   GoogleMapController? _controller;
//   LatLng _currentLocation = LatLng(0, 0);
//   Set<Marker> _markers = {};
//   double _zoomLevel = 10; // 既存のズームレベル値をセット
//   double get zoomLevel => _zoomLevel;
//   Timer? _zoomTimer;
//
//   // シングルトンインスタンス
//   static final MapController _instance = MapController._internal();
//
//   // プライベートコンストラクタ
//   MapController._internal();
//
//   // シングルトンインスタンスへのアクセス
//   static MapController get instance => _instance;
//
//   void setCurrentLocation(LatLng location) {
//     _currentLocation = location;
//   }
//
//   void onMapCreated(GoogleMapController controller) {
//     _controller = controller;
//   }
//
//   Future<void> updateMapLocation(double lat, double lng) async {
//     final controller = _controller!;
//     _currentLocation = LatLng(lat, lng);
//     controller.animateCamera(
//       CameraUpdate.newLatLng(_currentLocation),
//     );
//   }
//
//   void zoomIn(LatLng target) {
//     if (_zoomLevel < 15) {
//       _zoomLevel += 1;
//       _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, _zoomLevel));
//     }
//   }
//
//   void zoomOut(LatLng target) {
//     if (_zoomLevel > 2) {
//       _zoomLevel -= 1;
//       _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, _zoomLevel));
//     }
//   }
//
//   void startZoomingIn(LatLng target) {
//     _zoomTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
//       if (_zoomLevel < 15) {
//         _zoomLevel += 1;
//         _controller?.animateCamera(CameraUpdate.zoomIn());
//       } else {
//         timer.cancel();
//       }
//     });
//   }
//
//   void startZoomingOut(LatLng target) {
//     _zoomTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
//       if (_zoomLevel > 2) {
//         _zoomLevel -= 1;
//         _controller?.animateCamera(CameraUpdate.zoomOut());
//       } else {
//         timer.cancel();
//       }
//     });
//   }
//
//   void stopZooming() {
//     _zoomTimer?.cancel();
//   }
// }

class FullScreenDisplay extends ConsumerWidget {
  final LatLng currentLocation;
  final List<TimelineItem> timelineItems;
  final Size size;
  final PageController pageController;
  final bool programmaticPageChange;
  final Function updateTimeline;
  final String? currentCardId;

  FullScreenDisplay({
    required this.currentLocation,
    required this.timelineItems,
    required this.size,
    required this.pageController,
    required this.programmaticPageChange,
    required this.updateTimeline,
    required this.currentCardId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final timelineNotifier = ref.read(timelineNotifierProvider);
    return _FullScreenDisplayStateful(
      currentLocation: currentLocation,
      timelineItems: timelineItems,
      size: size,
      pageController: pageController,
      programmaticPageChange: programmaticPageChange,
      updateTimeline: updateTimeline,
      currentCardId: currentCardId,
    );
  }
}

class _FullScreenDisplayStateful extends ConsumerStatefulWidget {
  final LatLng currentLocation;
  final List<TimelineItem> timelineItems;
  final Size size;
  final PageController pageController;
  final bool programmaticPageChange;
  final Function updateTimeline;
  final String? currentCardId;

  _FullScreenDisplayStateful({
    required this.currentLocation,
    required this.timelineItems,
    required this.size,
    required this.pageController,
    required this.programmaticPageChange,
    required this.updateTimeline,
    required this.currentCardId,
  });

  @override
  _FullScreenDisplayState createState() => _FullScreenDisplayState();
}

class _FullScreenDisplayState extends ConsumerState<_FullScreenDisplayStateful> {
  String? currentCardId;
  bool programmaticChange = false;

  @override
  Widget build(BuildContext context) {
    // ref.watch(chatNotifierProvider);

    return Stack(
      children: <Widget>[
        // 画像の表示
        Positioned.fill(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              // TODO: スワイプのロジックを追加
            },
            child: InteractiveViewer(
              boundaryMargin: EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                'https://photo5.world/${widget.timelineItems.firstWhere((item) => item.id == widget.currentCardId, orElse: () => widget.timelineItems[2]).imageFilename}',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // 国旗と地名の表示
        Positioned(
          bottom: 10,
          left: 10,
          child: TimelineCard(
            item: widget.timelineItems.firstWhere((item) => item.id == widget.currentCardId, orElse: () => widget.timelineItems[2]),
            size: widget.size,
          ),
        ),
        // カメラボタン
        Positioned(
          right: 10,
          bottom: 10 + (2 * 60 + 2 * 10),  // 2つの他のボタンとの間隔を考慮
          child: FloatingActionButton(
            heroTag: "camera",
            onPressed: () {
              // カメラの起動ロジック
            },
            child: Icon(Icons.camera_alt),
            mini: true,
          ),
        ),
        // マップボタン
        Positioned(
          right: 10,
          bottom: 10 + (60 + 10),  // 1つの他のボタンとの間隔を考慮
          child: FloatingActionButton(
            heroTag: "map",
            onPressed: () {
              // マップ画面への遷移ロジック
            },
            child: Icon(Icons.map),
            mini: true,
          ),
        ),
        // アルバムボタン
        Positioned(
          right: 10,
          bottom: 10,
          child: FloatingActionButton(
            heroTag: "album",
            onPressed: () {
              // アルバム画面への遷移ロジック
            },
            child: Icon(Icons.photo_album),
            mini: true,
          ),
        ),
      ],
    );
  }
}


