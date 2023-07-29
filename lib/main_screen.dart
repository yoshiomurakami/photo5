// import 'dart:io';
import 'dart:async';
// import 'dart:convert';
// import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:camera/camera.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

// import 'package:geocoding/geocoding.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:image/image.dart' as img;
// import 'package:mime/mime.dart';
// import 'package:http_parser/http_parser.dart';
// import 'package:path/path.dart' as p;
// import 'package:sqflite/sqflite.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
import 'album_screen.dart';
import 'timeline_photoview.dart';
import 'timeline_screen.dart';
import 'timeline_camera.dart';
import 'riverpod.dart';



class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
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
//       top: size.height * 0.7,
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

// final timelineProvider = FutureProvider.autoDispose<List<TimelineItem>>((ref) async {
//   return getTimeline();
// });

// Future<LatLng> _determinePosition() async {
//   Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//   return LatLng(position.latitude, position.longitude);
// }

// class TimelineItem {
//   final String id;
//   final String userId;
//   final String country;
//   final double lat;
//   final double lng;
//   final String imageFilename;
//   final String thumbnailFilename;
//   final String localtime;
//
//   TimelineItem({
//     required this.id,
//     required this.userId,
//     required this.country,
//     required this.lat,
//     required this.lng,
//     required this.imageFilename,
//     required this.thumbnailFilename,
//     required this.localtime,
//   });
//
//   // 新しいemptyという名前付きコンストラクタを追加します。
//   // ただし、このコンストラクタは Map<String, dynamic> を返します。
//   static Map<String, dynamic> empty({
//     required double lat,
//     required double lng,
//   }) {
//     return {
//       '_id': '0',
//       'userId': 'dummy',
//       'country': 'dummy',
//       'lat': lat.toString(),
//       'lng': lng.toString(),
//       'imageFilename': 'dummy',
//       'thumbnailFilename': '03.png',
//       'localtime': 'dummy',
//     };
//   }
//
//   factory TimelineItem.fromJson(Map<String, dynamic> json) {
//     return TimelineItem(
//       id: json['_id'] ?? '0', // Provide a default value in case of null
//       userId: json['userID'] ?? 'dummy', // Provide a default value in case of null
//       country: json['country'] ?? 'dummy', // Provide a default value in case of null
//       lat: json['lat'] != null ? double.parse(json['lat']) : 0.0, // Check for null before parsing
//       lng: json['lng'] != null ? double.parse(json['lng']) : 0.0, // Check for null before parsing
//       imageFilename: json['imageFilename'] ?? 'dummy', // Provide a default value in case of null
//       thumbnailFilename: json['thumbnailFilename'] ?? '03.png', // Provide a default value in case of null
//       localtime: json['localtime'] ?? 'dummy', // Provide a default value in case of null
//     );
//   }
//
// }
//
// Future<List<TimelineItem>> _getTimeline() async {
//   try {
//     // SharedPreferencesからユーザーIDを取得
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String userId = prefs.getString('userID') ?? "";
//
//     // リクエストボディの作成
//     final requestBody = jsonEncode({'userId': userId});
//
//     // APIにPOSTリクエストを送信
//     final response = await http.post(
//       Uri.parse('https://photo5.world/api/timeline/getTimeline'),
//       headers: {'Content-Type': 'application/json'},
//       body: requestBody,
//     );
//
//     // APIからのレスポンスをチェック
//     if (response.statusCode == 200) {
//       // 成功した場合、JSONをパースしてリストに変換
//       List data = jsonDecode(response.body);
//
//       // 現在の位置を取得します。
//       Position devicePosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//
//       // 現在地を表す空の TimelineItem を作成します。ただし、これは Map<String, dynamic> の形で返されます。
//       Map<String, dynamic> emptyTimelineItem = TimelineItem.empty(
//         lat: devicePosition.latitude,
//         lng: devicePosition.longitude,
//       );
//
//       // 空の TimelineItem をリストの先頭に追加します。
//       data.insert(0, emptyTimelineItem);
//
//       // デバッグ情報として、取得したデータを出力
//       print('Received data: $data');
//       return data.map((item) => TimelineItem.fromJson(item)).toList();
//     } else {
//       // エラーが発生した場合、エラーをスロー
//       throw Exception('Failed to load timeline');
//     }
//   } catch (e, s) {
//     // print both the exception and the stacktrace
//     print('Exception details:\n $e');
//     print('Stacktrace:\n $s');
//     rethrow;  // throw the error again so it can be handled in the usual way
//   }
// }


class _MainScreenState extends State<MainScreen> {
  GoogleMapController? _controller;

  // bool _isLoading = true;
  LatLng _currentLocation = LatLng(0, 0); // Add this line
  Set<Marker> _markers = {};
  double _zoomLevel = 0; // Set the initial zoom level
  Timer? _zoomTimer;
  final PageController _pageController = PageController(); // add this line
  bool _programmaticPageChange = false;
  // final Map<String, int> _markerIdToCardIndex = {}; // add this line
  // Camera initialization
  Future<List<CameraDescription>>? _camerasFuture;

  Future<Uint8List> _loadImageAsBytes(String filename) async {
    final url = 'https://photo5.world/$filename';
    print('Loading image from URL: $url');
    final response = await http.get(Uri.parse(url));
    return response.bodyBytes;
  }


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

  void _onMarkerTapped(int index) async {
    _programmaticPageChange = true;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    _programmaticPageChange = false;
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

  void _onZoomLevelChanged(double value) {
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation, // Set the LatLng you want to remain centered
          zoom: value,
        ),
      ),
    );
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
                        left: size.width *0.1,
                        height: size.height * 0.3,
                        width: size.width*0.8,
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
                              onTap: () {
                                print('Navigating to image: ${timelineItems[index].imageFilename}');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TimelineFullScreenImagePage(
                                      timelineItems.map((item) => item.imageFilename).toList(),
                                      index,
                                    ),
                                  ),

                                );
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: size.width,
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

// class CameraScreen extends StatefulWidget {
//
//   final CameraDescription camera;
//
//   const CameraScreen({
//     Key? key,
//     required this.camera,
//   }) : super(key: key);
//
//   @override
//   _CameraScreenState createState() => _CameraScreenState();
// }
//
// class _CameraScreenState extends State<CameraScreen> {
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;
//   late bool _showImage;
//   String? _imagePath;
//   String? _thumbnailPath;
//   bool _uploading = false;
//   bool _conversionCompleted = false;
//   bool _locationAvailable = false;
//   String? _imageLat;
//   String? _imageLng;
//   String? _imageCountry;
//   String? _uploadImagePath; // Add this for the upload image
//   String? _uploadThumbnailPath; // Add this for the upload thumbnail
//   String _timestamp ='';
//   String _localTimestamp='';
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = CameraController(
//       widget.camera,
//       ResolutionPreset.high,
//     );
//     _initializeControllerFuture = _controller.initialize();
//     _showImage = false;
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   // Generate a random string
//   String _getRandomString(int length) {
//     const _randomChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
//     const _randStringLength = _randomChars.length;
//     final _random = math.Random();
//
//     return String.fromCharCodes(Iterable.generate(
//         length, (_) => _randomChars.codeUnitAt(_random.nextInt(_randStringLength))));
//   }
//
//   void _navigateBack(BuildContext context) async {
//     if (_imagePath != null) {
//       await File(_imagePath!).delete();
//       _imagePath = null;
//       _showImage = false;
//     }
//     Navigator.pop(context);
//   }
//
//
//
//   Future<void> _takePicture() async {
//     final Directory tempDir = await getTemporaryDirectory();
//
//     _timestamp = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
//     _localTimestamp = DateFormat('EE, d MM, yyyy, HH:mm').format(DateTime.now());
//
//     final String randomStr = _getRandomString(5);
//
//     try {
//       await _initializeControllerFuture;
//       XFile pictureFile = await _controller.takePicture();
//
//       // Get the extension from the MIME type
//       final String? mimeType = lookupMimeType(pictureFile.path, headerBytes: [0xFF, 0xD8]);
//       final String fileExtension = mimeType != null ? mimeType.substring(mimeType.lastIndexOf('/') + 1) : '.jpg';
//
//       // Use 'photo' and 'thumb' as prefixes to distinguish image and thumbnail
//       final String imgFileName = '${_timestamp}_${randomStr}_photo.$fileExtension';
//       final String thumbFileName = '${_timestamp}_${randomStr}_thumb.$fileExtension';
//
//       final String imgPath = p.join(tempDir.path, imgFileName);
//       final String thumbPath = p.join(tempDir.path, thumbFileName);
//
//       // Create directories and files if needed
//       if (!await File(imgPath).exists()) {
//         await File(imgPath).create(recursive: true);
//       }
//       if (!await File(thumbPath).exists()) {
//         await File(thumbPath).create(recursive: true);
//       }
//
//       // Save the picture
//       await pictureFile.saveTo(imgPath);
//
//       // Set the path for the image and thumbnail
//       _imagePath = imgPath;
//       _thumbnailPath = thumbPath;
//
//       // Update the image display
//       setState(() {
//         _showImage = true;
//         _conversionCompleted = false;
//       });
//
//       // Call _convertImage() to convert image and thumbnail to webp format in the background
//       _convertImage(imgPath, thumbPath, int.parse(_timestamp), randomStr);
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   Future<void> _convertImage(String imgPath, String thumbPath, int timestamp, String randomStr) async {
//
//     // Fetch the user's current location.
//     Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
//     print('Current position: $position');
//     _imageLat = position.latitude.toString();
//     _imageLng = position.longitude.toString();
//
//     // Fetch the user's current country.
//     List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
//     _imageCountry = placemarks.first.isoCountryCode ?? 'Unknown';
//     print('Placemarks: $placemarks');
//
//     // Update _locationAvailable state
//     setState(() {
//       _locationAvailable = true;
//     });
//
//     final Directory tempDir = await getTemporaryDirectory();
//
//     // Convert the picture to webp
//     final webpImgFileName = '${_timestamp}_${randomStr}_photo.webp';
//     final webpImgPath = p.join(tempDir.path, webpImgFileName);
//     await FlutterImageCompress.compressAndGetFile(
//       imgPath,
//       webpImgPath,
//       format: CompressFormat.webp,
//       quality: 90,
//     );
//
//     print('Image saved at: $webpImgPath');
//
//     // Create a thumbnail from the image
//     img.Image? image = img.decodeImage(File(imgPath).readAsBytesSync());
//
//     // Crop to square
//     int size = math.min(image!.width, image.height);
//     int startX = (image.width - size) ~/ 2;
//     int startY = (image.height - size) ~/ 2;
//     img.Image square = img.copyCrop(image, x: startX, y: startY, width: size, height: size);
//
//     // Resize to 1/4
//     img.Image thumbnail = img.copyResize(square, width: image.width ~/ 4, height: image.width ~/ 4, interpolation: img.Interpolation.average);
//
//
//     File(thumbPath)..writeAsBytesSync(img.encodeJpg(thumbnail, quality: 90));
//
//     // Convert the thumbnail to webp
//     final webpThumbFileName = '${_timestamp}_${randomStr}_thumb.webp';
//     final webpThumbPath = p.join(tempDir.path, webpThumbFileName);
//     await FlutterImageCompress.compressAndGetFile(
//       thumbPath,
//       webpThumbPath,
//       format: CompressFormat.webp,
//       quality: 90,
//     );
//
//     print('Thumbnail saved at: $webpThumbPath');
//
//     // Set the path for the image and thumbnail
//     _uploadImagePath = webpImgPath;
//     _uploadThumbnailPath = webpThumbPath;
//
//     // Update the UI to show that the conversion has completed
//     setState(() {
//       _conversionCompleted = true;
//     });
//   }
//
//   Future<void> _progressUpload(String imagePath, String thumbnailPath, String userId, String imageCountry, String imageLat, String imageLng) async {
//     await _saveImage(imagePath, thumbnailPath, userId, imageCountry, imageLat, imageLng);
//     await _uploadImage(imagePath, thumbnailPath);
//   }
//
//   Future<void> _saveImage(String imagePath, String thumbnailPath, String userId, String imageCountry, String imageLat, String imageLng) async {
//     final paths = await _saveFiles(imagePath, thumbnailPath);
//     await _saveToDatabase(paths, userId, imageCountry, imageLat, imageLng);
//   }
//
//   Future<List<String>> _saveFiles(String imagePath, String thumbnailPath) async {
//     final directory = await getApplicationDocumentsDirectory();
//
//     //Create new directories for images and thumbnails.
//     final imageDir = Directory('${directory.path}/uploadImage/');
//     final thumbnailDir = Directory('${directory.path}/uploadThumb/');
//
//     // Check if the directories exist. If not, create them.
//     if (!await imageDir.exists()) {
//       await imageDir.create();
//     }
//     if (!await thumbnailDir.exists()) {
//       await thumbnailDir.create();
//     }
//
//     // Get the file name from the original path.
//     String imageFileName = p.basename(imagePath);
//     String thumbnailFileName = p.basename(thumbnailPath);
//
//     // Copy the image and thumbnail to new directories with the original file name.
//     final File newImageFile = File('${imageDir.path}/$imageFileName');
//     final File newThumbnailFile = File('${thumbnailDir.path}/$thumbnailFileName');
//     await File(imagePath).copy(newImageFile.path);
//     await File(thumbnailPath).copy(newThumbnailFile.path);
//
//     return [newImageFile.path, newThumbnailFile.path]; // return new paths
//   }
//
//
//   Future<void> _saveToDatabase(List<String> paths, String userId, String imageCountry, String imageLat, String imageLng) async {
//     // Open the database or create it if it doesn't exist
//     final database = openDatabase(
//       p.join(await getDatabasesPath(), 'images_database.db'),
//       onCreate: (db, version) {
//         // Create images table if it doesn't exist
//         return db.execute(
//           "CREATE TABLE images(id INTEGER PRIMARY KEY, imagePath TEXT, thumbnailPath TEXT, userId TEXT, imageCountry TEXT, imageLat TEXT, imageLng TEXT)",
//         );
//       },
//       version: 1,
//     );
//
//     final db = await database;
//
//     // Insert the data into the table
//     try {
//       int id = await db.insert(
//         'images',
//         {
//           'imagePath': paths[0], // new image path
//           'thumbnailPath': paths[1], // new thumbnail path
//           'userId': userId,
//           'imageCountry': imageCountry,
//           'imageLat': imageLat,
//           'imageLng': imageLng
//         },
//         conflictAlgorithm: ConflictAlgorithm.replace,
//       );
//       print('Inserted row id: $id');
//     } catch (e) {
//       print('Error occurred while inserting into the database: $e');
//     }
//   }
//
//
//   Future<void> _uploadImage(String imagePath, String thumbnailPath) async {
//     if (_uploading) return; // アップロード中の場合は処理しない
//
//     setState(() {
//       _uploading = true; // アップロード中フラグを立てる
//     });
//
//     // Check if location permission is granted, if not, request it.
//     if (await Permission.location.isDenied) {
//       await Permission.location.request();
//     }
//
//     // Check again if the permission is granted, if not, return from the function.
//     if (await Permission.location.isDenied) {
//       print('User denied location permission.');
//       setState(() {
//         _uploading = false; // アップロード中フラグを解除
//       });
//       return;
//     }
//
//     var request = http.MultipartRequest('POST', Uri.parse('https://photo5.world/api/photo/upload'));
//     request.files.add(await http.MultipartFile.fromPath(
//       'image',
//       imagePath,
//       contentType: MediaType('image', 'jpeg'),
//     ));
//
//     request.files.add(await http.MultipartFile.fromPath(
//       'thumbnail',
//       thumbnailPath,
//       contentType: MediaType('image', 'jpeg'),
//     ));
//
//     // Fetch user ID from SharedPreferences
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String userId = prefs.getString('userID') ?? "";
//
//     // Add the extra data to the request.
//     request.fields['createdAt'] = _timestamp;
//     request.fields['photo_u_id'] = userId;
//     request.fields['photo_country'] = _imageCountry ?? 'Unknown';
//     request.fields['photo_lat'] = _imageLat ?? '';
//     request.fields['photo_lng'] = _imageLng ?? '';
//     request.fields['localtime'] = _localTimestamp;
//
//     print('Timestamp: $_timestamp');
//     print('Local timestamp: $_localTimestamp');
//
//     // Check the connectivity status.
//     if (!await _checkConnectivity(context)) {
//       // If not connected, save the image and extra information to cache.
//       // _saveDataLocally(imagePath, photoCountry, photoLat, photoLng, userId);
//       setState(() {
//         _uploading = false; // アップロード中フラグを解除
//       });
//       return;
//     }
//
//     // If connected, send the request.
//     try {
//       var response = await http.Response.fromStream(await request.send());
//       print('Status code: ${response.statusCode}');
//       print('Response body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         print('Uploaded successfully.');
//       } else {
//         print('Upload failed.');
//       }
//     } catch (e) {
//       print('Upload failed: $e');
//     } finally {
//       setState(() {
//         _uploading = false; // アップロード中フラグを解除
//       });
//     }
//   }
//
//   Future<bool> _checkConnectivity(BuildContext context) async {
//     // ここでは仮に常にtrueを返すようにしていますが、実際には通信状況をチェックして結果を返す必要があります。
//     return true;
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     final screenAspectRatio = MediaQuery.of(context).size.aspectRatio;
//
//     return Scaffold(
//       body: FutureBuilder<void>(
//         future: _initializeControllerFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             if (_controller.value.isInitialized) {
//               final previewSize = _controller.value.previewSize!;
//               final previewAspectRatio = previewSize.height / previewSize.width;
//
//               // Calculate the scaling factor
//               double scale = 1.0;
//               if (previewAspectRatio > screenAspectRatio) {
//                 scale = previewAspectRatio / screenAspectRatio;
//               } else {
//                 scale = screenAspectRatio / previewAspectRatio;
//               }
//
//               return Stack(
//                 children: [
//                   // Camera preview scaled according to the aspect ratio
//                   Center(
//                     child: Transform.scale(
//                       scale: scale,
//                       child: AspectRatio(
//                         aspectRatio: previewAspectRatio,
//                         child: CameraPreview(_controller),
//                       ),
//                     ),
//                   ),
//                   // The controls should be outside the scaled preview
//                   if (!_showImage)  // Only show the buttons if _showImage is false
//                     Positioned(
//                       bottom: 0,
//                       left: 0,
//                       child: Row(
//                         children: [
//                           ElevatedButton(
//                             onPressed: _takePicture,
//                             child: Text('Take Picture'),
//                           ),
//                           ElevatedButton(
//                             onPressed: () => _navigateBack(context),
//                             child: Text('Back'),
//                           ),
//                         ],
//                       ),
//                     ),
//                   _showImage && _imagePath != null
//                       ? Positioned.fill(
//                     child: Stack(
//                       children: <Widget>[
//                         Positioned.fill(
//                           child: Image.file(
//                             File(_imagePath!),
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         Positioned(
//                             bottom: 20,
//                             left: 20,
//                             child: ElevatedButton(
//                               child: Text('Send'),
//                               onPressed: (_conversionCompleted && _locationAvailable && !_uploading)
//                                   ? () async {  // make it asynchronous
//                                 if (_uploadImagePath != null && _uploadThumbnailPath != null) {
//                                   SharedPreferences prefs = await SharedPreferences.getInstance();
//                                   String userId = prefs.getString('userID') ?? "";
//
//                                   // call _progressUpload with necessary arguments
//                                   _progressUpload(
//                                       _uploadImagePath!,
//                                       _uploadThumbnailPath!,
//                                       userId,
//                                       _imageCountry ?? 'Unknown',
//                                       _imageLat ?? '',
//                                       _imageLng ?? ''
//                                   );
//                                 }
//                               }
//                                   : null,  // Enable the button only if the conversion is completed
//                             )
//                         ),
//                         Positioned(
//                           bottom: 20,
//                           right: 20,
//                           child: ElevatedButton(
//                             onPressed: () async {  // Make the handler asynchronous
//                               if (_imagePath != null) {
//                                 var imgFile = File(_imagePath!);
//                                 if (await imgFile.exists()) {  // Check if the file exists before trying to delete it
//                                   await imgFile.delete();
//                                 }
//                                 _imagePath = null;
//                               }
//
//                               if (_thumbnailPath != null) {
//                                 var thumbFile = File(_thumbnailPath!);
//                                 if (await thumbFile.exists()) {  // Check if the file exists before trying to delete it
//                                   await thumbFile.delete();
//                                 }
//                                 _thumbnailPath = null;
//                               }
//
//                               setState(() {
//                                 _showImage = false;  // Reset the flag when the button is pressed
//                               });
//                             },
//                             child: Text('Back'),
//                           ),
//                         )
//                       ],
//                     ),
//                   )
//                       : SizedBox(),
//                 ],
//               );
//
//             } else {
//               return SizedBox.shrink();
//             }
//           } else {
//             return Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//     );
//   }
// }

