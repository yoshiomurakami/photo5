import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'timeline_photoview.dart';
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
    // final timelineNotifier = ref.read(timelineNotifierProvider);
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
  bool programmaticChange = false; // これを追加
  final PageController _pageController = PageController(viewportFraction: 1); // ここでビューポートの幅を設定
  bool _programmaticPageChange = false;
  bool isFullScreen = false;
  late ScrollController _scrollController; // Add this
  late FixedExtentScrollController _pickerController; // Add this
  bool isScrolling = false;


  void _updateMapToSelectedItem() {
    int index = _pickerController.selectedItem;

    print("Selected Item ID after stopped scrolling: ${widget.timelineItems[index].id}");

    // Get the lat and lng of the selected item
    double lat = widget.timelineItems[index].lat;
    double lng = widget.timelineItems[index].lng;

    // Update the map location
    MapController.instance.updateMapLocation(lat, lng);
  }

  @override
  void initState() {
    super.initState();
    final timelineNotifier = ref.read(timelineNotifierProvider);
    timelineNotifier.addPostedPhoto(widget.pageController, widget.timelineItems); // ここを変更
    _scrollController = ScrollController();  // これを追加
    _pickerController = FixedExtentScrollController(); // Initialize the controller
    ScrollActivity? lastActivity;  // 直前のScrollActivityを格納する変数を定義


  }

  @override
  Widget build(BuildContext context) {
    ref.watch(timelineNotifierProvider);
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
            Positioned.fill(
              child: NotificationListener<ScrollEndNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification) {
                    print("Stopped scrolling");
                    _updateMapToSelectedItem();
                  }
                  return true;
                },
                child: CupertinoPicker(
                  scrollController: _pickerController,
                  selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                    background: Colors.transparent,
                  ),
                  itemExtent: MediaQuery.of(context).size.height / 10,
                  diameterRatio: 1,
                  onSelectedItemChanged: (int index) {},
                  magnification: 1.1,
                  children: List<Widget>.generate(
                    widget.timelineItems.length,
                        (int index) {
                      return Center(
                        child: TimelineCard(
                          key: widget.timelineItems[index].key,
                          item: widget.timelineItems[index],
                          size: widget.size,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: widget.size.height * 0.4,
              child: ElevatedButton(
                onPressed: () {
                  if (_pickerController.selectedItem! > 0) {
                    _pickerController.animateToItem(
                        _pickerController.selectedItem! - 1,
                        duration: Duration(milliseconds: 300),  // Duration of the animation
                        curve: Curves.easeInOut  // Animation curve
                    );
                  }
                },
                child: Icon(Icons.arrow_upward),
              ),
            ),
            Positioned(
              left: 20,
              top: widget.size.height * 0.6,
              child: ElevatedButton(
                onPressed: () {
                  if (_pickerController.selectedItem! < widget.timelineItems.length - 1) {
                    _pickerController.animateToItem(
                        _pickerController.selectedItem! + 1,
                        duration: Duration(milliseconds: 300),  // Duration of the animation
                        curve: Curves.easeInOut  // Animation curve
                    );
                  }
                },
                child: Icon(Icons.arrow_downward),
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
              top: widget.size.height * 0.5 + (widget.size.height * 0.35), // 位置を調整
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
    //   },
    // );
  }

  @override
  void dispose() {
    _pickerController.dispose();  // Dispose the picker controller
    super.dispose();
  }
}

