import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timeline_photoview.dart';
import 'timeline_providers.dart';
import 'timeline_card.dart';
import 'chat_connection.dart';

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
  @override
  void initState() {
    super.initState();
    final timelineNotifier = ref.read(timelineNotifierProvider);
    timelineNotifier.addPostedPhoto(widget.pageController, widget.timelineItems); // ここを変更
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   onPostedPhoto();
    // });
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
              top: widget.size.height * 0.3,
              left: 0,
              right: 0,
              height: widget.size.height * 0.3,
              child: PageView.builder(
                controller: widget.pageController,
                itemCount: widget.timelineItems.length,
                onPageChanged: (index) async {
                  if (!programmaticChange) {
                    print("onPageChanged called. programmaticChange: $programmaticChange");
                    final item = widget.timelineItems[index];
                    setState(() {
                      currentCardId = item.id;  // IDを更新
                      print("表示したページ番号は = $currentCardId");
                    });
                    MapController.instance.updateMapLocation(item.lat, item.lng);

                    await widget.updateTimeline(widget.timelineItems);

                    if (index == widget.timelineItems.length - 1) {
                      print("more timelineItems");
                      getMoreTimelineItems().then((newItems) {
                        setState(() {
                          widget.timelineItems.addAll(newItems); // 新しいアイテムを現在のリストに追加
                        });
                      });
                    }
                  }else{
                    print("AAAonPageChanged called. programmaticChange: $programmaticChange");
                  }
              },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      print('Navigating to image: ${widget.timelineItems[index].imageFilename}');
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TimelineFullScreenImagePage(
                            widget.timelineItems.map((item) => item.imageFilename).toList(),
                            index,
                            key: UniqueKey(),
                            onTimelineItemsAdded: (newItems) {
                              setState(() {
                                widget.timelineItems.addAll(newItems);
                              });
                            },
                          ),
                        ),
                      );
                      if (result is int) {
                        widget.pageController.jumpToPage(result);
                        final lat = widget.timelineItems[result].lat;
                        final lng = widget.timelineItems[result].lng;
                        MapController.instance.updateMapLocation(lat, lng);
                      }
                    },
                    child: TimelineCard(key: widget.timelineItems[index].key, item: widget.timelineItems[index], size: widget.size),
                  );
                },
                pageSnapping: true,
                physics: BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
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
          ],
        );
    //   },
    // );
  }

  // 新しいカードを追加する際の処理を行うメソッド
  void onPostedPhoto() {

    programmaticChange = true; // ここで変更を開始

    // 1. 現在の表示インデックスを保存
    int? currentIndex = widget.pageController.page?.round();
    if (currentIndex == null) return;

    // 2. カード追加後の表示インデックスを設定
    int newIndex = currentIndex + 1;

    // 3. 新しいインデックスにページを移動
    widget.pageController.jumpToPage(newIndex);
    print("this is programmaticChange");

    programmaticChange = false; // ここで変更を終了
  }
}

