import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flag/flag.dart';
import 'album_screen.dart';
import 'timeline_photoview.dart';
import 'timeline_camera.dart';
import 'timeline_providers.dart';
import 'chat_connection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.8); // ここでビューポートの幅を設定
  bool _programmaticPageChange = false;
  Future<List<CameraDescription>>? _camerasFuture;

  @override
  void initState() {
    super.initState();
    _camerasFuture = availableCameras();
  }

  void _openCamera(CameraDescription camera) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(camera: camera),
      ),
    );
  }

  void _openAlbum() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final Size size = MediaQuery.of(context).size;
      final timelineItemsAsyncValue = ref.watch(timelineProvider); // ここを修正
      Widget timelineMapWidget = Center(child: CircularProgressIndicator()); // 初期値を設定

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
          );
        },
        loading: () => timelineMapWidget = Center(child: CircularProgressIndicator()),
        error: (error, stack) => timelineMapWidget = Center(child: Text('Error: $error')),
      );

      return Scaffold(
        body: Stack(
          children: <Widget>[
            timelineMapWidget, // ここを修正しました
            FutureBuilder<List<CameraDescription>>(
              future: _camerasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    return CameraButton(onPressed: () => _openCamera(snapshot.data!.first));
                  } else {
                    return Text('No camera found');
                  }
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: ConnectionNumber(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: "album",
          onPressed: _openAlbum,
          child: Icon(Icons.photo_album),
        ),
      );
    });
  }

}

class TimelineMapWidget extends StatelessWidget {
  final List<TimelineItem> timelineItems; // コンストラクタで受け取る
  final LatLng currentLocation;
  final Size size;
  final PageController pageController;
  final bool programmaticPageChange;
  final Function updateGeocodedLocation;

  TimelineMapWidget({
    required this.timelineItems,
    required this.currentLocation,
    required this.size,
    required this.pageController,
    required this.programmaticPageChange,
    required this.updateGeocodedLocation,
  });

  @override
  Widget build(BuildContext context) {
    // カレントロケーションの設定
    MapController.instance.setCurrentLocation(currentLocation);

    return MapDisplay(
      currentLocation: currentLocation,
      timelineItems: timelineItems,
      size: size,
      pageController: pageController,
      programmaticPageChange: programmaticPageChange,
      updateTimeline: updateGeocodedLocation,
    );
  }
}


class MapController {
  GoogleMapController? _controller;
  LatLng _currentLocation = LatLng(0, 0);
  Set<Marker> _markers = {};
  double _zoomLevel = 2; // 既存のズームレベル値をセット
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

class MapDisplay extends StatefulWidget {
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
  _MapDisplayState createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  @override
  Widget build(BuildContext context) {
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
              if (!widget.programmaticPageChange) {
                final item = widget.timelineItems[index];
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
                        // widget.timelineItems,
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
                child: TimelineCard(item: widget.timelineItems[index], size: widget.size),
              );
            },
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
  }
}


class TimelineCard extends StatelessWidget {
  final TimelineItem item;
  final Size size;

  TimelineCard({required this.item, required this.size});

  FlagsCode? getFlagCode(String countryCode) {
    try {
      return FlagsCode.values.firstWhere(
              (e) => e.toString().split('.')[1].toUpperCase() == countryCode.toUpperCase());
    } catch (e) {
      return null;  // No matching country code found
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size.width * 1.0,
          height: size.height * 0.15,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text('No. ${item.id}'),
                  Text(item.geocodedCountry ?? 'Unknown'),
                  Text(item.geocodedCity ?? 'Unknown'),
                  getFlagCode(item.country) != null
                      ? Flag.fromCode(
                    getFlagCode(item.country)!,
                    height: 20,
                    width: 30,
                  )
                      : Container(),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.2 - size.width * 0.1,
          left: size.width * 0.3,
          child: Container(
            width: size.width * 0.2,
            height: size.width * 0.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.width * 0.04),
              image: DecorationImage(
                image: NetworkImage('https://photo5.world/${item.thumbnailFilename}'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ConnectionNumber extends StatefulWidget {
  @override
  _ConnectionNumberState createState() => _ConnectionNumberState();
}

class _ConnectionNumberState extends State<ConnectionNumber> {
  int totalConnections = 0;

  @override
  void initState() {
    super.initState();
    socket?.on('connections', (connections) {
      setState(() {
        totalConnections = connections;
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.black.withOpacity(0.5),
      child: Text('Connections: $totalConnections', style: TextStyle(color: Colors.white)),
    );
  }
}





