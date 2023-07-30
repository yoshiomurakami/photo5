import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'album_screen.dart';
import 'timeline_photoview.dart';
import 'timeline_screen.dart';
import 'timeline_camera.dart';
import 'riverpod.dart';


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}


class _MainScreenState extends State<MainScreen> {
  GoogleMapController? _controller;
  LatLng _currentLocation = LatLng(0, 0); // Add this line
  Set<Marker> _markers = {};
  double _zoomLevel = 0; // Set the initial zoom level
  Timer? _zoomTimer;
  final PageController _pageController = PageController(); // add this line
  bool _programmaticPageChange = false;
  Future<List<CameraDescription>>? _camerasFuture;

  @override
  void initState() {
    super.initState();
    determinePosition();
    getTimeline().catchError((error) {
      print('Error fetching timeline: $error');
      return <TimelineItem>[];  // Returning an empty list in case of an error
    });
    _camerasFuture = availableCameras();
  }

  Future<void> _updateMapLocation(double lat, double lng) async {
    print("Updating map location to: $lat, $lng");
    final controller = _controller!;
    _currentLocation = LatLng(lat, lng);
    controller.moveCamera(
      CameraUpdate.newLatLng(_currentLocation),
    );
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

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
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
              getTimeline(),
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
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation,
                          zoom: _zoomLevel,
                        ),
                        markers: _markers,
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: false,
                        scrollGesturesEnabled: false,
                        padding: EdgeInsets.only(bottom: 0),
                      ),
                      Positioned(
                        top: size.height * 0.3,
                        left: size.width *0.0,
                        height: size.height * 0.3,
                        width: size.width,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: timelineItems.length,
                          onPageChanged: (index) {
                            if (!_programmaticPageChange) {
                              _updateMapLocation(timelineItems[index].lat, timelineItems[index].lng);
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
                                  _updateMapLocation(lat, lng);
                                  _pageController.animateToPage(
                                    result,
                                    duration: Duration(milliseconds: 500),
                                    curve: Curves.ease,
                                  );
                                }

                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: size.width*0.8,
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
                                            Text('Card ${timelineItems[index].id}'),
                                            Text('No. ${index}'),
                                            Text('lat is ${timelineItems[index].lat}'),
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
                                _zoomTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
                                  if (_zoomLevel < 15) {
                                    _zoomLevel += 1;
                                    _controller?.animateCamera(CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: LatLng(
                                            timelineItems[_pageController.page!.round()].lat,
                                            timelineItems[_pageController.page!.round()].lng
                                        ),
                                        zoom: _zoomLevel,
                                      ),
                                    ));
                                  } else {
                                    timer.cancel();
                                  }
                                });
                              },
                              onLongPressEnd: (details) {
                                _zoomTimer?.cancel();
                              },
                              child: FloatingActionButton(
                                heroTag: "mapZoomIn", // HeroTag設定
                                onPressed: () {
                                  if (_zoomLevel < 15) {
                                    _zoomLevel += 1;
                                    _controller?.animateCamera(CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: LatLng(
                                            timelineItems[_pageController.page!.round()].lat,
                                            timelineItems[_pageController.page!.round()].lng
                                        ),
                                        zoom: _zoomLevel,
                                      ),
                                    ));
                                  }
                                },
                                child: Icon(Icons.add),
                                mini: true,
                              ),
                            ),
                            SizedBox(height: 10),
                            GestureDetector(
                              onLongPress: () {
                                _zoomTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
                                  if (_zoomLevel > 3) {
                                    _zoomLevel -= 1;
                                    _controller?.animateCamera(CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: LatLng(
                                            timelineItems[_pageController.page!.round()].lat,
                                            timelineItems[_pageController.page!.round()].lng
                                        ),
                                        zoom: _zoomLevel,
                                      ),
                                    ));
                                  } else {
                                    timer.cancel();
                                  }
                                });
                              },
                              onLongPressEnd: (details) {
                                _zoomTimer?.cancel();
                              },
                              child: FloatingActionButton(
                                heroTag: "mapZoomOut", // HeroTag設定
                                onPressed: () {
                                  if (_zoomLevel > 3) {
                                    _zoomLevel -= 1;
                                    _controller?.animateCamera(CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: LatLng(
                                            timelineItems[_pageController.page!.round()].lat,
                                            timelineItems[_pageController.page!.round()].lng
                                        ),
                                        zoom: _zoomLevel,
                                      ),
                                    ));
                                  }
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "album", // HeroTag設定
        onPressed: _openAlbum,
        child: Icon(Icons.photo_album),
      ),
    );
  }
}



