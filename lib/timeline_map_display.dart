import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
// import 'timeline_photoview.dart';
import 'timeline_providers.dart';
import 'timeline_map_card.dart';
import 'chat_connection.dart';
import 'timeline_fullscreen_widget.dart';

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
  final PageController _pageController = PageController(viewportFraction: 1);
  bool _programmaticPageChange = false;
  bool isFullScreen = false;
  late FixedExtentScrollController _pickerController;
  bool isScrolling = false;


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


  @override
  void initState() {
    super.initState();
    _pickerController = FixedExtentScrollController();
    final ChatNotifier = ref.read(chatNotifierProvider);
    ChatNotifier.addPostedPhoto(widget.pageController, _pickerController, widget.timelineItems);
    print('_pickerController initial item: ${_pickerController.initialItem}');
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
              top: widget.size.height * 0.3,
              bottom: widget.size.height * 0.3,
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
                onPressed: () {
                  print("Current selected item: ${_pickerController.selectedItem}");
                  print("Total items: ${items.length}");

                  if (_pickerController.selectedItem <= items.length - 1) {
                    _pickerController.animateToItem(
                        _pickerController.selectedItem + 1,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut
                    );
                  }
                },
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
                onPressed: () {
                  if (_pickerController.selectedItem >= 0) {
                    _pickerController.animateToItem(
                        _pickerController.selectedItem - 1,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut
                    );
                  }
                },
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
            Positioned(
              right: widget.size.width * 0.05,
              top: widget.size.height * 0.5 + (widget.size.height * 0.35),
              child: FloatingActionButton(
                heroTag: "displayFullScreen",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TimelineFullScreenWidget(
                        size: widget.size,
                        currentLocation: widget.currentLocation,
                        timelineItems: widget.timelineItems,
                        pageController: _pageController,
                        programmaticPageChange: _programmaticPageChange,
                        updateGeocodedLocation: updateGeocodedLocation,
                        currentCardId: currentCardId,
                      ),
                    ),
                  );
                },
                child: Icon(Icons.fullscreen),
                mini: true,
              ),
            ),
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

//
// class SliderController extends StatefulWidget {
//   final VoidCallback onReachedTop;
//   final VoidCallback onReachedBottom;
//
//   SliderController({
//     required this.onReachedTop,
//     required this.onReachedBottom,
//   });
//
//   @override
//   _SliderControllerState createState() => _SliderControllerState();
// }
//
// class _SliderControllerState extends State<SliderController> {
//   double pointerValue = 0.5; // ポインターの初期位置は中央
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onVerticalDragUpdate: (details) {
//         setState(() {
//           pointerValue += details.delta.dy / (MediaQuery.of(context).size.height * 0.2);
//           pointerValue = pointerValue.clamp(0.0, 2.0);
//         });
//
//         if (pointerValue == 0.0) {
//           widget.onReachedTop.call();
//           pointerValue = 1.0;
//         } else if (pointerValue == 2.0) {
//           widget.onReachedBottom.call();
//           pointerValue = 1.0;
//         }
//       },
//       child: Container(
//         height: MediaQuery.of(context).size.width * 0.2,
//         width: 15, // Slider width
//         color: Colors.grey.shade200, // Slider background color
//         child: Align(
//           alignment: Alignment(0, pointerValue * 2 - 1),
//           child: Container(
//             height: 15, // Pointer height
//             width: 15, // Pointer width
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.blue, // Pointer color
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

