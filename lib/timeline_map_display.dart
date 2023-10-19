import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
// import 'timeline_photoview.dart';
import 'timeline_providers.dart';
import 'timeline_map_card.dart';
import 'chat_connection.dart';
import 'timeline_camera.dart';


class MapController {
  GoogleMapController? _controller;
  LatLng _currentLocation = LatLng(0, 0);
  Set<Marker> _markers = {};
  double _zoomLevel = 15; // 既存のズームレベル値をセット
  double get zoomLevel => _zoomLevel;

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
    if (_zoomLevel <= 15) {
      _zoomLevel += 1;
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, _zoomLevel));
    }
    print("New_zoomLevel_in=$_zoomLevel");
  }

  void zoomOut(LatLng target) {
    if (_zoomLevel >= 2) {
      _zoomLevel -= 1;
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, _zoomLevel));
    }
    print("New_zoomLevel_out=$_zoomLevel");
  }

  // 新しいメソッドを追加
  void updateZoom(double newZoomLevel) {
    if (newZoomLevel >= 2.0 && newZoomLevel <= 15.0) {
      _zoomLevel = newZoomLevel;
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, _zoomLevel));
    }
  }
}

class ZoomControl extends StatefulWidget {
  final Size size;
  final double right;
  final double top;

  ZoomControl({required this.size, required this.right, required this.top});

  @override
  _ZoomControlState createState() => _ZoomControlState();
}

class _ZoomControlState extends State<ZoomControl> {
  double _startPosition = 0;
  double _endPosition = 0;

  // ValueNotifierを追加
  ValueNotifier<double> _zoomLevelNotifier = ValueNotifier<double>(2.0);

  @override
  void initState() {
    super.initState();
    _zoomLevelNotifier.value = MapController.instance.zoomLevel.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final double zoomTouchLength = 300;
    print("zoomTouchLength=$zoomTouchLength");

    return Positioned(
      right: widget.right,
      top: widget.top,
      child: GestureDetector(
        onVerticalDragStart: (details) {
          _startPosition = details.localPosition.dy;
        },
        onVerticalDragEnd: (details) {
          double difference = _endPosition - _startPosition;
          double zoomDelta;

          if (difference.abs() >= zoomTouchLength * 0.9) {
            zoomDelta = 13.0;
          } else if (difference.abs() >= zoomTouchLength * 0.01) {
            zoomDelta = 1.0 + (difference.abs() - zoomTouchLength * 0.1) * 12 / (zoomTouchLength * 0.8);
          } else {
            zoomDelta = 1.0;
          }

          double currentZoomLevel = _zoomLevelNotifier.value;

          if (difference > 0) {
            // Swipe down
            for (int i = 0; i < zoomDelta; i++) {
              if (currentZoomLevel > 2) {
                MapController.instance.zoomOut(MapController.instance._currentLocation);
                currentZoomLevel--;
              }
            }
          } else {
            // Swipe up
            for (int i = 0; i < zoomDelta; i++) {
              if (currentZoomLevel < 15) {
                MapController.instance.zoomIn(MapController.instance._currentLocation);
                currentZoomLevel++;
              }
            }
          }

          // Update the _zoomLevelNotifier value
          _zoomLevelNotifier.value = currentZoomLevel;
          print("currentZoomLevel=$currentZoomLevel");

          _startPosition = 0;
          _endPosition = 0;
        },
        onVerticalDragUpdate: (details) {
          _endPosition = details.localPosition.dy;
        },
        child: ValueListenableBuilder<double>(
          valueListenable: _zoomLevelNotifier,
          builder: (BuildContext context, double zoom, Widget? child) {
            return Container(
              width: widget.size.width,
              height: widget.size.height,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                border: Border.all(color: Colors.black, width: 2.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        // ズームインの処理
                        MapController.instance.updateZoom(15.0);
                        _zoomLevelNotifier.value = 15.0;
                      },
                      child: Icon(
                        Icons.location_city,
                        size: 20.0,
                        color: zoom == 15.0 ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        // ズームアウトの処理
                        MapController.instance.updateZoom(2.0);
                        _zoomLevelNotifier.value = 2.0;
                      },
                      child: Icon(
                        Icons.public,
                        size: 20.0,
                        color: zoom < 4.0 ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}

class JumpToTop extends StatefulWidget {
  final Size size;
  final VoidCallback onPressed;

  JumpToTop({Key? key, required this.size, required this.onPressed}) : super(key: key);

  @override
  _JumpToTopState createState() => _JumpToTopState();
}


class _JumpToTopState extends State<JumpToTop> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _positionController;
  late Animation<double> _positionAnimation;
  double? _bottomPosition;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bottomPosition == null) {
      _bottomPosition = MediaQuery.of(context).size.height / 2 - (widget.size.width * 0.15) / 2;
    }
  }


  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
      value: 1.0,
    );

    _positionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _positionAnimation = Tween<double>(
      begin: 0,
      end: widget.size.height * 0.5 + 100, // 画面の半分 + 100px
    ).animate(_positionController);
  }

  void centerButton() {
    setState(() {
      _bottomPosition = MediaQuery.of(context).size.height / 2 - (widget.size.width * 0.15) / 2;
    });
  }

  void moveButton() {
    setState(() {
      _bottomPosition = (widget.size.width * 0.15) / 2; // この値を変更してボタンの下部の位置を調整します。
    });
  }




  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _positionAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: _bottomPosition,
          left: widget.size.width * 0.5 - (widget.size.width * 0.15) / 2,
          child: FadeTransition(
            opacity: _fadeController,
            child: ElevatedButton(
              child: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '📷',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.size.width * 0.07,
                  ),
                ),
              ),
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                primary: Color(0xFFFFCC4D),
                side: BorderSide(color: Colors.black, width: 2.0),
                fixedSize: Size(widget.size.width * 0.15, widget.size.width * 0.15),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _positionController.dispose();
    super.dispose();
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
  final _jumpToTopKey = GlobalKey<_JumpToTopState>();




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


  // void _handleScroll() {
  //   // リストビューの中央の位置を取得
  //   var centerPosition = _pickerController.offset + widget.size.height * 0.5;
  //
  //   // 中央のアイテムのインデックスを計算
  //   var itemHeight = MediaQuery.of(context).size.height / 10; // itemExtentとして設定されている
  //   var centerItemIndex = (centerPosition / itemHeight).round();
  //
  //   if (centerItemIndex == 0) {
  //     _jumpToTopKey.currentState!.fadeOut();
  //   } else {
  //     _jumpToTopKey.currentState!.fadeIn();
  //   }
  // }







  @override
  void initState() {
    super.initState();
    _pickerController = FixedExtentScrollController();
    _pickerController!.addListener(_scrollListener);
    final ChatNotifier = ref.read(chatNotifierProvider);
    ChatNotifier.addPostedPhoto(widget.pageController, _pickerController, widget.timelineItems);
    print('_pickerController initial item: ${_pickerController.initialItem}');
    _initializeCamera();
    // listenToCameraEventを呼び出す
    chatConnection.listenToCameraEvent(context, () {
      // 何かの処理... 今回は特に何もしない
    });
    chatConnection.listenToRoomCount(context);
  }

  void _scrollListener() {
    if (_pickerController.selectedItem == 0) {
      _jumpToTopKey.currentState?.centerButton();
    } else {
      _jumpToTopKey.currentState?.moveButton();
    }
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
              left: widget.size.width * 0.15,
              right: widget.size.width * 0.15,
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
                              // タップされたアイテムが中央のアイテムでない場合
                              if (_pickerController.selectedItem != index) {
                                _pickerController.animateToItem(
                                  index,
                                  duration: Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                setState(() {
                                  isFullScreenMode = !isFullScreenMode;
                                });
                              }
                            },
                            onCameraButtonPressed: () {
                              if (_cameras != null && _cameras!.isNotEmpty) {
                                _openCamera(_cameras![0]);
                                chatConnection.emitEvent("enter_shooting_room");
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

            // Positioned(
            //   right: (widget.size.width * 0.5) - (56.0 / 2) - (widget.size.width * 0.1 * 1.3) - (56.0 / 2),
            //   top: (widget.size.height * 0.46) - (56.0 / 2),
            //   child: FloatingActionButton(
            //     heroTag: "timelineForwardOne",
            //     onPressed: () => handleScroll(1),
            //     backgroundColor: Colors.transparent, // 透明な背景
            //     elevation: 0, // 影をなくす
            //     child: Icon(
            //       Icons.keyboard_double_arrow_up,
            //       color: Colors.black,
            //     ),
            //   ),
            // ),
            // Positioned(
            //   right: (widget.size.width * 0.5) - (56.0 / 2) - (widget.size.width * 0.1 * 1.3) - (56.0 / 2),
            //   top: (widget.size.height * 0.54) - (56.0 / 2),
            //   child: FloatingActionButton(
            //     heroTag: "timelineBackOne",
            //     onPressed: () => handleScroll(-1),
            //     backgroundColor: Colors.transparent, // 透明な背景
            //     elevation: 0, // 影をなくす
            //     child: Icon(
            //       Icons.keyboard_double_arrow_down,
            //       color: Colors.black,
            //     ),
            //   ),
            // ),
            // Positioned(
            //   right: widget.size.width * 0.05,
            //   top: widget.size.height * 0.5 + (widget.size.height * 0.2),
            //   child: Column(
            //     children: [
            //       GestureDetector(
            //         child: FloatingActionButton(
            //           heroTag: "mapZoomIn",
            //           onPressed: () {
            //             MapController.instance.zoomIn(widget.currentLocation);
            //           },
            //           child: Icon(Icons.add),
            //           mini: true,
            //         ),
            //       ),
            //       SizedBox(height: 10),
            //       GestureDetector(
            //         child: FloatingActionButton(
            //           heroTag: "mapZoomOut",
            //           onPressed: () {
            //             MapController.instance.zoomOut(widget.currentLocation);
            //           },
            //           child: Icon(Icons.remove),
            //           mini: true,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            ZoomControl(
              size: Size(widget.size.width * 0.1, widget.size.height * 0.15),
              right: widget.size.width * 0.05,
              top: (widget.size.height) - (widget.size.height * 0.3) ,
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
            JumpToTop(
              key: _jumpToTopKey,
              size: Size(widget.size.width, widget.size.height),
              onPressed: () {
                _pickerController.animateToItem(
                  0,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        );
      },
    );
  }


  @override
  void dispose() {
    _pickerController.dispose();
    // リスナーの解除処理
    chatConnection.removeListeners();
    _pickerController.removeListener(_scrollListener);
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
