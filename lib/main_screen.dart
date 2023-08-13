import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:flag/flag.dart';
import 'album_screen.dart';
import 'timeline_photoview.dart';
import 'timeline_screen.dart';
import 'timeline_camera.dart';
import 'riverpod.dart';
import 'chat_connection.dart';


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
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

class MapController {
  GoogleMapController? _controller;
  LatLng _currentLocation = LatLng(0, 0);
  Set<Marker> _markers = {};
  double _zoomLevel = 10; // 既存のズームレベル値をセット
  Timer? _zoomTimer;

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
      _controller?.animateCamera(CameraUpdate.zoomIn());
    }
  }

  void zoomOut(LatLng target) {
    if (_zoomLevel > 3) {
      _zoomLevel -= 1;
      _controller?.animateCamera(CameraUpdate.zoomOut());
    }
  }

  void startZoomingIn(LatLng target) {
    _zoomTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_zoomLevel < 15) {
        _zoomLevel += 1;
        _controller?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: _zoomLevel,
          ),
        ));
      } else {
        timer.cancel();
      }
    });
  }

  void startZoomingOut(LatLng target) {
    _zoomTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_zoomLevel > 3) {
        _zoomLevel -= 1;
        _controller?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: _zoomLevel,
          ),
        ));
      } else {
        timer.cancel();
      }
    });
  }

  void stopZooming() {
    _zoomTimer?.cancel();
  }
}

class _MainScreenState extends State<MainScreen> {
  final MapController _mapController = MapController(); // 新規MapControllerのインスタンスを生成
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
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          FutureBuilder<List<dynamic>>(
            future: Future.wait([
              determinePosition(),
              getTimelineWithGeocoding()
            ]),
            builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.hasData) {
                  LatLng _currentLocation = snapshot.data![0] as LatLng;
                  List<TimelineItem> timelineItems = snapshot.data![1] as List<TimelineItem>;

                  return Stack(
                    children: <Widget>[
                      GoogleMap(
                        onMapCreated: _mapController.onMapCreated, // ここでMapControllerを使用
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation,
                          zoom: 10,
                        ),
                        markers: _mapController._markers,
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: false,
                        scrollGesturesEnabled: false,
                        padding: EdgeInsets.only(bottom: 0),
                      ),
                      Positioned(
                        top: size.height * 0.3,
                        left: 0, // 左右中央の調整を削除
                        right: 0, // 左右中央の調整を削除
                        height: size.height * 0.3,
                        child: PageView.builder(
                          controller: _pageController,  // ここを修正
                          itemCount: timelineItems.length,
                          onPageChanged: (index) async {
                            if (!_programmaticPageChange) {
                              final item = timelineItems[index];
                              _mapController.updateMapLocation(item.lat, item.lng);

                              await updateGeocodedLocation(timelineItems);
                            }
                          },
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () async {
                                print('Navigating to image: ${timelineItems[index].imageFilename}');
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TimelineFullScreenImagePage(
                                      timelineItems.map((item) => item.imageFilename).toList(),
                                      index,
                                      key: UniqueKey(), // generate a new unique key
                                    ),
                                  ),
                                );
                                if (result is int) {
                                  final lat = timelineItems[result].lat;
                                  final lng = timelineItems[result].lng;
                                  _mapController.updateMapLocation(lat, lng);

                                  _programmaticPageChange = true; // プログラムによるページ変更の開始を示すフラグを設定します。

                                  _pageController.animateToPage(
                                    result,
                                    duration: Duration(milliseconds: 1000),
                                    curve: Curves.ease,
                                  ).then((_) {
                                    _programmaticPageChange = false; // アニメーションが終了したらフラグを解除します。
                                  });
                                }


                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: size.width*1.0,
                                    height: size.height * 0.15,
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ), // ここで角を丸く指定
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: <Widget>[
                                            // Text('Card ${timelineItems[index].id}'),
                                            Text('No. ${index}'),
                                            // Text('lat is ${timelineItems[index].lat}'),
                                            Text(timelineItems[index].geocodedCountry ?? 'Unknown'),
                                            Text(timelineItems[index].geocodedCity ?? 'Unknown'),
                                            getFlagCode(timelineItems[index].country) != null
                                                ? Flag.fromCode(
                                              getFlagCode(timelineItems[index].country)!,
                                              height: 20,
                                              width: 30,
                                            )
                                                : Container(),  // If getFlagCode returns null, return an empty container
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
                                          image: NetworkImage('https://photo5.world/${timelineItems[index].thumbnailFilename}'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      Positioned(
                        right: size.width * 0.05,
                        top: size.height * 0.5 + (size.height * 0.2),
                        child: Column(
                          children: [
                            GestureDetector(
                              onLongPress: () {
                                _mapController.startZoomingIn(_currentLocation);
                              },
                              onLongPressEnd: (details) {
                                _mapController.stopZooming();
                              },
                              child: FloatingActionButton(
                                heroTag: "mapZoomIn",
                                onPressed: () {
                                  _mapController.zoomIn(_currentLocation);
                                },
                                child: Icon(Icons.add),
                                mini: true,
                              ),
                            ),
                            SizedBox(height: 10),
                            GestureDetector(
                              onLongPress: () {
                                _mapController.startZoomingOut(_currentLocation);
                              },
                              onLongPressEnd: (details) {
                                _mapController.stopZooming();
                              },
                              child: FloatingActionButton(
                                heroTag: "mapZoomOut", // HeroTag設定
                                onPressed: () {
                                  _mapController.zoomOut(_currentLocation);
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

                } else {
                  return Center(child: Text('No data'));
                }
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),

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
        heroTag: "album", // HeroTag設定
        onPressed: _openAlbum,
        child: Icon(Icons.photo_album),
        // child: Text('Connections: $totalConnections'), // 例としてここに表示
      ),
    );
  }
}



