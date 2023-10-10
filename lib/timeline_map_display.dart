import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
// import 'package:flutter/cupertino.dart';
// import 'timeline_photoview.dart';
import 'timeline_providers.dart';
import 'timeline_map_card.dart';
import 'chat_connection.dart';
import 'timeline_camera.dart';


class MapController {
  GoogleMapController? _controller;
  LatLng _currentLocation = LatLng(0, 0);
  Set<Marker> _markers = {};
  double _zoomLevel = 10; // 既存のズームレベル値をセット
  double get zoomLevel => _zoomLevel;
  Timer? _zoomTimer;


  // シングルトンインスタンス
  static final MapController _instance = MapController._internal();

  // プライベートコンストラクタ
  MapController._internal();

  // シングルトンインスタンスへのアクセス
  static MapController get instance => _instance;

  void setCurrentLocation(LatLng location) {
    _currentLocation = location;
  }

  void onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  Future<void> updateMapLocation(double lat, double lng) async {
    final controller = _controller!;
    _currentLocation = LatLng(lat, lng);
    controller.animateCamera(
      CameraUpdate.newLatLng(_currentLocation),
    );
  }

  void zoomIn(LatLng target) {
    if (_zoomLevel < 15) {
      _zoomLevel += 1;
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, _zoomLevel));
    }
  }

  void zoomOut(LatLng target) {
    if (_zoomLevel > 2) {
      _zoomLevel -= 1;
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, _zoomLevel));
    }
  }

  void startZoomingIn(LatLng target) {
    _zoomTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_zoomLevel < 15) {
        _zoomLevel += 1;
        _controller?.animateCamera(CameraUpdate.zoomIn());
      } else {
        timer.cancel();
      }
    });
  }

  void startZoomingOut(LatLng target) {
    _zoomTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_zoomLevel > 2) {
        _zoomLevel -= 1;
        _controller?.animateCamera(CameraUpdate.zoomOut());
      } else {
        timer.cancel();
      }
    });
  }

  void stopZooming() {
    _zoomTimer?.cancel();
  }
}

class MapDisplay extends ConsumerWidget {
  final LatLng currentLocation;
  final List<TimelineItem> timelineItems;
  final Size size;
  final PageController pageController;
  final bool programmaticPageChange;
  final Function updateTimeline;

  MapDisplay({
    required this.currentLocation,
    required this.timelineItems,
    required this.size,
    required this.pageController,
    required this.programmaticPageChange,
    required this.updateTimeline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MapDisplayStateful(
      currentLocation: currentLocation,
      timelineItems: timelineItems,
      size: size,
      pageController: pageController,
      programmaticPageChange: programmaticPageChange,
      updateTimeline: updateTimeline,
    );
  }
}

class _MapDisplayStateful extends ConsumerStatefulWidget {
  final LatLng currentLocation;
  final List<TimelineItem> timelineItems;
  final Size size;
  final PageController pageController;
  final bool programmaticPageChange;
  final Function updateTimeline;

  _MapDisplayStateful({
    required this.currentLocation,
    required this.timelineItems,
    required this.size,
    required this.pageController,
    required this.programmaticPageChange,
    required this.updateTimeline,
  });

  @override
  _MapDisplayState createState() => _MapDisplayState();
}

class _MapDisplayState extends ConsumerState<_MapDisplayStateful> {
  String? currentCardId;
  bool programmaticChange = false;
  // final PageController _pageController = PageController(viewportFraction: 1);
  // bool _programmaticPageChange = false;
  bool isFullScreen = false;
  late FixedExtentScrollController _pickerController;
  bool isScrolling = false;
  bool isFullScreenMode = false;
  List<CameraDescription>? _cameras;
  late CameraController _controller;
  ChatConnection chatConnection = ChatConnection();




  void _updateMapToSelectedItem(List<TimelineItem> items) {
    int index = _pickerController.selectedItem;

    // 範囲外アクセスを防ぐ
    if (index >= 0 && index < items.length) {
      print("Selected Item ID after stopped scrolling: ${items[index].id}");

      // Get the lat and lng of the selected item
      double lat = items[index].lat;
      double lng = items[index].lng;

      // Update the map location
      MapController.instance.updateMapLocation(lat, lng);
    } else {
      print("Selected index out of range: $index");
    }
  }


  Future<void> handleScroll(int step) async {
    final newCenterItem = await scrollTimeline(_pickerController, step, widget.timelineItems);
    setState(() {
      currentCardId = newCenterItem.id;  // newCenterItemのidを取得
    });
  }






  @override
  void initState() {
    super.initState();
    _pickerController = FixedExtentScrollController();
    final ChatNotifier = ref.read(chatNotifierProvider);
    ChatNotifier.addPostedPhoto(widget.pageController, _pickerController, widget.timelineItems);
    print('_pickerController initial item: ${_pickerController.initialItem}');
    _initializeCamera();
    // listenToCameraEventを呼び出す
    chatConnection.listenToCameraEvent(context, () {
      // 何かの処理... 今回は特に何もしない
    });
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.medium);
    }
  }

  void _openCamera(CameraDescription cameraDescription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(camera: cameraDescription),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final items = ref.watch(timelineAddProvider);
        ref.watch(chatNotifierProvider);


        return Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: MapController.instance.onMapCreated,
              initialCameraPosition: CameraPosition(
                target: widget.currentLocation,
                zoom: MapController.instance.zoomLevel,
              ),
              markers: MapController.instance._markers,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: false,
              scrollGesturesEnabled: false,
              padding: EdgeInsets.only(bottom: 0),
            ),
            Positioned(
              top: widget.size.height * 0.2,
              bottom: widget.size.height * 0.2,
              left: 0,
              right: 0,
              child: Container(
                // color: Colors.red,  // 一時的に背景色を設定（コメントアウトされています）
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification) {
                      print("Stopped scrolling");
                      _updateMapToSelectedItem(items);
                    }
                    return true;
                  },
                  child: ListWheelScrollView(
                    controller: _pickerController,
                    itemExtent: MediaQuery.of(context).size.height / 10,
                    diameterRatio: 1.25,
                    onSelectedItemChanged: (int index) {
                      print('_pickerController selected item: $index');
                      if (index > items.length - 5) {
                        ref.read(timelineAddProvider.notifier).addMoreItems();
                      }
                    },
                    magnification: 1.3,
                    useMagnifier: true,
                    physics: FixedExtentScrollPhysics(),
                    children: List<Widget>.generate(
                      items.length,
                          (int index) {
                        return Center(
                          child: TimelineCard(
                            key: items[index].key,
                            item: items[index],
                            size: widget.size,
                            controller: _pickerController,
                            currentIndex: index,
                            pickerController: _pickerController,
                            items: items,
                            onTapCallback: () {
                              setState(() {
                                isFullScreenMode = !isFullScreenMode;
                              });
                            },
                            onCameraButtonPressed: () {
                              if (_cameras != null && _cameras!.isNotEmpty) {
                                _openCamera(_cameras![0]);
                                chatConnection.sendMessage("someone_start_camera");
                              } else {
                                print("No available cameras found.");
                                // もしご希望であれば、ユーザーにエラーメッセージを表示する処理も追加できます。
                              }
                            },
                            // cameraDescription: snapshot.data!.first,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              right: widget.size.width * 0.05,
              top: (widget.size.height * 0.46) - (56.0 / 2),
              child: FloatingActionButton(
                heroTag: "timelineForwardOne",
                onPressed: () => handleScroll(1),
                backgroundColor: Colors.transparent, // 透明な背景
                elevation: 0, // 影をなくす
                child: Icon(
                  Icons.keyboard_double_arrow_up,
                  color: Colors.black,
                ),
              ),
            ),
            Positioned(
              right: widget.size.width * 0.05,
              top: (widget.size.height * 0.54) - (56.0 / 2),
              child: FloatingActionButton(
                heroTag: "timelineBackOne",
                onPressed: () => handleScroll(-1),
                backgroundColor: Colors.transparent, // 透明な背景
                elevation: 0, // 影をなくす
                child: Icon(
                  Icons.keyboard_double_arrow_down,
                  color: Colors.black,
                ),
              ),
            ),
            Positioned(
              right: widget.size.width * 0.05,
              top: widget.size.height * 0.5 + (widget.size.height * 0.2),
              child: Column(
                children: [
                  GestureDetector(
                    child: FloatingActionButton(
                      heroTag: "mapZoomIn",
                      onPressed: () {
                        MapController.instance.zoomIn(widget.currentLocation);
                      },
                      child: Icon(Icons.add),
                      mini: true,
                    ),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    child: FloatingActionButton(
                      heroTag: "mapZoomOut",
                      onPressed: () {
                        MapController.instance.zoomOut(widget.currentLocation);
                      },
                      child: Icon(Icons.remove),
                      mini: true,
                    ),
                  ),
                ],
              ),
            ),

            if (isFullScreenMode) // isFullScreenModeがtrueの場合だけFullScreenImageViewerを表示
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: FullScreenImageViewer(
                  items: items, // これはあなたのitemsリストを参照するものと仮定しています。
                  initialIndex: _pickerController.selectedItem, // これはあなたのコントローラの選択されたアイテムのインデックスを参照するものと仮定しています。
                  controller: _pickerController, // FullScreenImageViewerに必要な他のプロパティや設定も追加できます。
                  onTap: () {
                    setState(() {
                      isFullScreenMode = false;
                    });
                  },
                ),
              ),
            // Positioned(
            //   right: widget.size.width * 0.05,
            //   top: widget.size.height * 0.5 + (widget.size.height * 0.35),
            //   child: FloatingActionButton(
            //     heroTag: "displayFullScreen",
            //     onPressed: () {
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //           builder: (context) => TimelineFullScreenWidget(
            //             size: widget.size,
            //             currentLocation: widget.currentLocation,
            //             timelineItems: widget.timelineItems,
            //             pageController: _pageController,
            //             programmaticPageChange: _programmaticPageChange,
            //             updateGeocodedLocation: updateGeocodedLocation,
            //             currentCardId: currentCardId,
            //           ),
            //         ),
            //       );
            //     },
            //     child: Icon(Icons.fullscreen),
            //     mini: true,
            //   ),
            // ),
          ],
        );
      },
    );
  }


  @override
  void dispose() {
    _pickerController.dispose();
    super.dispose();
  }
}

// class CameraButton extends StatelessWidget {
//   final VoidCallback onPressed;
//
//   CameraButton({required this.onPressed});
//
//   @override
//   Widget build(BuildContext context) {
//     final Size size = MediaQuery.of(context).size;
//     return Positioned(
//       left: size.width * 0.4,
//       top: size.height * 0.9,
//       child: Container(
//         width: size.width * 0.2,
//         height: size.width * 0.2,
//         child: FloatingActionButton(
//           heroTag: "camera", // HeroTag設定
//           backgroundColor: Color(0xFFFFCC4D),
//           foregroundColor: Colors.black,
//           elevation: 0,
//           shape: CircleBorder(side: BorderSide(color: Colors.black, width: 2.0)),
//           child: Center(
//             child: Text(
//               '📷',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: size.width * 0.1,
//                 height: 1.0,
//               ),
//             ),
//           ),
//           onPressed: onPressed,
//         ),
//       ),
//     );
//   }
// }
