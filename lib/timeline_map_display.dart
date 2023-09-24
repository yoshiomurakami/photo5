import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final PageController _pageController = PageController(viewportFraction: 0.8); // ここでビューポートの幅を設定
  bool _programmaticPageChange = false;
  bool isFullScreen = false;

  @override
  void initState() {
    super.initState();
    final timelineNotifier = ref.read(timelineNotifierProvider);
    timelineNotifier.addPostedPhoto(widget.pageController, widget.timelineItems); // ここを変更
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
            Positioned(
              // top: widget.size.height * 0.5,
              // left: 0,
              // right: 0,
              // height: widget.size.height * 0.5,
              child: ListView.builder(
                itemCount: widget.timelineItems.length + 2, // +2 for dummy space at the top and bottom
                itemBuilder: (context, index) {
                  // Add dummy space at the top to center the first thumbnail
                  if (index == 0) {
                    return SizedBox(height: MediaQuery.of(context).size.height / 2 - (widget.size.height / 5 / 2));
                  }
                  // Add dummy space at the bottom to allow for scrolling
                  if (index == widget.timelineItems.length + 1) {
                    return SizedBox(height: MediaQuery.of(context).size.height / 2 - (widget.size.height / 5 / 2));
                  }

                  // Decrement the index by 1 for the actual items to account for the added dummy space
                  index -= 1;
                  return GestureDetector(
                    onTap: () async {
                      print('Navigating to image: ${widget.timelineItems[index].imageFilename}');
                      final returnedId = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TimelineFullScreenImagePage(
                            widget.timelineItems.map((item) => item.imageFilename).toList(),
                            widget.timelineItems.map((item) => item.id.toString()).toList(),
                            index,
                            key: UniqueKey(),
                            onTimelineItemsAdded: (newItems) {
                              setState(() {
                                widget.timelineItems.addAll(newItems);
                                currentCardId = widget.timelineItems[index].id;
                              });
                            },
                          ),
                        ),
                      );

                      if (returnedId != null) {
                        final targetIndex = widget.timelineItems.indexWhere((item) => item.id == returnedId);
                        if (targetIndex != -1) {
                          // ListViewでのスクロール位置の制御のためのコードはコメントアウトしました
                          // widget.scrollController.jumpTo(targetIndex * MediaQuery.of(context).size.height / 5);
                          final lat = widget.timelineItems[targetIndex].lat;
                          final lng = widget.timelineItems[targetIndex].lng;
                          MapController.instance.updateMapLocation(lat, lng);
                        }
                      }
                    },
                    child: TimelineCard(
                      key: widget.timelineItems[index].key,
                      item: widget.timelineItems[index],
                      size: widget.size,
                    ),
                  );
                },
                physics: BouncingScrollPhysics(),
                scrollDirection: Axis.vertical,
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
}

