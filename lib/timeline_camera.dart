import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'chat_connection.dart';
import 'dart:convert';

final cameraButtonKey = GlobalKey();

class CameraScreen extends StatefulWidget {

  final CameraDescription camera;
  final String groupID;

  const CameraScreen({
    Key? key,
    required this.camera,
    required this.groupID,
  }) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late bool _showImage;
  String? _imagePath;
  String? _thumbnailPath;
  bool _uploading = false;
  bool _conversionCompleted = false;
  bool _locationAvailable = false;
  String? _imageLat;
  String? _imageLng;
  String? _imageCountry;
  String? _uploadImagePath; // Add this for the upload image
  String? _uploadThumbnailPath; // Add this for the upload thumbnail
  String _timestamp ='';
  String _localTimestamp='';
  String _geocodedCountry='';
  String _geocodedCity='';


  // final ChatConnection chatConnection = ChatConnection();
  final ChatConnection chatConnection = ChatConnection()..connect();


  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
    _showImage = false;
  }

  @override
  void dispose() {
    socket?.emit('leave_shooting_room');
    _controller.dispose();
    super.dispose();
  }

  // Generate a random string
  String _getRandomString(int length) {
    const randomChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const randStringLength = randomChars.length;
    final random = math.Random();

    return String.fromCharCodes(Iterable.generate(
        length, (_) => randomChars.codeUnitAt(random.nextInt(randStringLength))));
  }

  void _navigateBack(BuildContext context) async {
    if (_imagePath != null) {
      await File(_imagePath!).delete();
      _imagePath = null;
      _showImage = false;
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }




  Future<void> _takePicture() async {
    final Directory tempDir = await getTemporaryDirectory();

    _timestamp = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    _localTimestamp = DateFormat('EE, d MM, yyyy, HH:mm').format(DateTime.now());

    final String randomStr = _getRandomString(5);

    try {
      await _initializeControllerFuture;
      XFile pictureFile = await _controller.takePicture();

      // Get the extension from the MIME type
      final String? mimeType = lookupMimeType(pictureFile.path, headerBytes: [0xFF, 0xD8]);
      final String fileExtension = mimeType != null ? mimeType.substring(mimeType.lastIndexOf('/') + 1) : '.jpg';

      // Use 'photo' and 'thumb' as prefixes to distinguish image and thumbnail
      final String imgFileName = '${_timestamp}_${randomStr}_photo.$fileExtension';
      final String thumbFileName = '${_timestamp}_${randomStr}_thumb.$fileExtension';

      final String imgPath = p.join(tempDir.path, imgFileName);
      final String thumbPath = p.join(tempDir.path, thumbFileName);

      // Create directories and files if needed
      if (!await File(imgPath).exists()) {
        await File(imgPath).create(recursive: true);
      }
      if (!await File(thumbPath).exists()) {
        await File(thumbPath).create(recursive: true);
      }

      // Save the picture
      await pictureFile.saveTo(imgPath);

      // Set the path for the image and thumbnail
      _imagePath = imgPath;
      _thumbnailPath = thumbPath;

      // Update the image display
      setState(() {
        _showImage = true;
        _conversionCompleted = false;
      });

      // Call _convertImage() to convert image and thumbnail to webp format in the background
      _convertImage(imgPath, thumbPath, int.parse(_timestamp), randomStr);
    } catch (e) {
      debugPrint("$e");
    }
  }

  Future<void> _convertImage(String imgPath, String thumbPath, int timestamp, String randomStr) async {

    // Fetch the user's current location.
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    debugPrint('Current position: $position');
    _imageLat = position.latitude.toString();
    _imageLng = position.longitude.toString();


    // Fetch the user's current country.
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    _imageCountry = placemarks.first.isoCountryCode ?? 'Unknown';
    _geocodedCountry = placemarks.first.country ?? 'Unknown'; // 国名
    _geocodedCity = placemarks.first.administrativeArea ?? 'Unknown'; // 都市名
    debugPrint('Placemarks: $placemarks');

    // Update _locationAvailable state
    setState(() {
      _locationAvailable = true;
    });

    final Directory tempDir = await getTemporaryDirectory();

    // Convert the picture to webp
    final webpImgFileName = '${_timestamp}_${randomStr}_photo.webp';
    final webpImgPath = p.join(tempDir.path, webpImgFileName);
    await FlutterImageCompress.compressAndGetFile(
      imgPath,
      webpImgPath,
      format: CompressFormat.webp,
      quality: 90,
    );

    debugPrint('Image saved at: $webpImgPath');

    // Create a thumbnail from the image
    img.Image? image = img.decodeImage(File(imgPath).readAsBytesSync());

    // Crop to square
    int size = math.min(image!.width, image.height);
    int startX = (image.width - size) ~/ 2;
    int startY = (image.height - size) ~/ 2;
    img.Image square = img.copyCrop(image, x: startX, y: startY, width: size, height: size);

    // Resize to 1/4
    img.Image thumbnail = img.copyResize(square, width: image.width ~/ 4, height: image.width ~/ 4, interpolation: img.Interpolation.average);


    File(thumbPath).writeAsBytesSync(img.encodeJpg(thumbnail, quality: 90));

    // Convert the thumbnail to webp
    final webpThumbFileName = '${_timestamp}_${randomStr}_thumb.webp';
    final webpThumbPath = p.join(tempDir.path, webpThumbFileName);
    await FlutterImageCompress.compressAndGetFile(
      thumbPath,
      webpThumbPath,
      format: CompressFormat.webp,
      quality: 90,
    );

    debugPrint('Thumbnail saved at: $webpThumbPath');

    // Set the path for the image and thumbnail
    _uploadImagePath = webpImgPath;
    _uploadThumbnailPath = webpThumbPath;

    // Update the UI to show that the conversion has completed
    setState(() {
      _conversionCompleted = true;
    });
  }

// _progressUpload メソッドを修正
  Future<void> _progressUpload(String imagePath, String thumbnailPath, String userID, String localtimestamp, String imageCountry, String imageLat, String imageLng, String groupID, String geocodedCountry, String geocodedCity) async {
    Map<String, dynamic> newPhotoInfo = await _uploadImage(imagePath, thumbnailPath, groupID);

    if (newPhotoInfo!= {}) {  // 正しい sequenceNumber が取得できた場合
      await _saveImage(imagePath, thumbnailPath, newPhotoInfo);
    } else {
      // エラーハンドリング
      debugPrint("Error: Unable to get sequence number from upload response.");
    }

    debugPrint("groupID = $groupID");
  }

// _saveImage メソッド
  Future<void> _saveImage(String imagePath, String thumbnailPath, Map<String, dynamic> newPhotoInfo) async {
    final paths = await _saveFiles(imagePath, thumbnailPath);
    await _saveToDatabase(paths, newPhotoInfo);
  }

  Future<List<String>> _saveFiles(String imagePath, String thumbnailPath) async {
    final directory = await getApplicationDocumentsDirectory();

    //Create new directories for images and thumbnails.
    final imageDir = Directory('${directory.path}/uploadImage/');
    final thumbnailDir = Directory('${directory.path}/uploadThumb/');

    // Check if the directories exist. If not, create them.
    if (!await imageDir.exists()) {
      await imageDir.create();
    }
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create();
    }

    // Get the file name from the original path.
    String imageFileName = p.basename(imagePath);
    String thumbnailFileName = p.basename(thumbnailPath);

    // Copy the image and thumbnail to new directories with the original file name.
    final File newImageFile = File('${imageDir.path}/$imageFileName');
    final File newThumbnailFile = File('${thumbnailDir.path}/$thumbnailFileName');
    await File(imagePath).copy(newImageFile.path);
    await File(thumbnailPath).copy(newThumbnailFile.path);

    return [newImageFile.path, newThumbnailFile.path]; // return new paths
  }


// _saveToDatabase メソッドで images テーブルに sequenceNumber を保存
  Future<void> _saveToDatabase(List<String> paths, Map<String, dynamic> newPhotoInfo) async {
    final db = await openDatabase(
      p.join(await getDatabasesPath(), 'images_database.db'),
      version: 1,
    );

    await db.insert(
      'images',
      {
        '_id':newPhotoInfo['_id'],
        'sequenceNumber': newPhotoInfo['sequenceNumber'],
        'createdAt': newPhotoInfo['createdAt'],
        'userID': newPhotoInfo['userID'],
        'country': newPhotoInfo['country'],
        'lat': newPhotoInfo['lat'],
        'lng': newPhotoInfo['lng'],
        'imageFilename': paths[0],
        'thumbnailFilename': paths[1],
        'localtime': newPhotoInfo['localtime'],
        'groupID': newPhotoInfo['groupID'],
        'geocodedCountry': newPhotoInfo['geocodedCountry'],
        'geocodedCity': newPhotoInfo['geocodedCity'],
        'statement': newPhotoInfo['statement'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>> _uploadImage(String imagePath, String thumbnailPath, String groupID) async {
    if (_uploading) return {}; // アップロード中の場合は、無効な値を返す

    setState(() {
      _uploading = true; // アップロード中フラグを立てる
    });

    // Check if location permission is granted, if not, request it.
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    // Check again if the permission is granted, if not, return an invalid value.
    if (await Permission.location.isDenied) {
      debugPrint('User denied location permission.');
      setState(() {
        _uploading = false; // アップロード中フラグを解除
      });
      return {};
    }

    var request = http.MultipartRequest('POST', Uri.parse('https://photo5.world/api/photo/upload'));
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imagePath,
      contentType: MediaType('image', 'jpeg'),
    ));

    request.files.add(await http.MultipartFile.fromPath(
      'thumbnail',
      thumbnailPath,
      contentType: MediaType('image', 'jpeg'),
    ));

    // Fetch user ID from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? "";

    // Add the extra data to the request.
    request.fields['createdAt'] = _timestamp;
    request.fields['photo_u_id'] = userID;
    request.fields['photo_country'] = _imageCountry ?? 'Unknown';
    request.fields['photo_lat'] = _imageLat ?? '';
    request.fields['photo_lng'] = _imageLng ?? '';
    request.fields['localtime'] = _localTimestamp;
    request.fields['localtime'] = _localTimestamp;
    request.fields['groupID'] = widget.groupID;
    request.fields['geocodedCountry'] = _geocodedCountry;
    request.fields['geocodedCity'] = _geocodedCity;


    debugPrint('Timestamp: $_timestamp');
    debugPrint('Local timestamp: $_localTimestamp');
    debugPrint('Add the extra data to the request_groupID: $groupID');

    // Check the connectivity status.
    bool isConnected = false;
    if (mounted) {
      isConnected = await _checkConnectivity(context);
    }

    if (!isConnected) {
      // If not connected, save the image and extra information to cache.
      // _saveDataLocally(imagePath, photoCountry, photoLat, photoLng, userID);
      if (mounted) {
        setState(() {
          _uploading = false; // アップロード中フラグを解除
        });
      }
      return {};
    }

    // If connected, send the request.
    try {
      var response = await http.Response.fromStream(await request.send());
      // ... 応答の処理 ...
      if (response.statusCode == 200) {
        debugPrint('Uploaded successfully.');
        Map<String, dynamic> responseBody = jsonDecode(response.body);
        // int sequenceNumber = responseBody['photo']['sequenceNumber'];

        // ここで新しい写真情報を取得し、chatConnectionを使用して送信
        Map<String, dynamic> newPhotoInfo = {
          '_id': responseBody['photo']['_id'],
          'sequenceNumber': responseBody['photo']['sequenceNumber'],
          'createdAt': responseBody['photo']['createdAt'],
          'userID': responseBody['photo']['userID'],
          'country': responseBody['photo']['country'],
          'lat': double.parse(responseBody['photo']['lat']),
          'lng': double.parse(responseBody['photo']['lng']),
          'imageFilename': responseBody['photo']['imageFilename'],
          'thumbnailFilename': responseBody['photo']['thumbnailFilename'],
          'localtime': responseBody['photo']['localtime'],
          'groupID': responseBody['photo']['groupID'],
          'geocodedCountry': responseBody['photo']['geocodedCountry'],
          'geocodedCity': responseBody['photo']['geocodedCity'],
          'statement': responseBody['photo']['statement'],
        };
        chatConnection.sendNewPhotoInfo(newPhotoInfo);

        return newPhotoInfo;
      } else {
        debugPrint('Upload failed.');
        return {};
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
      return {};
    } finally {
      setState(() {
        _uploading = false;
      });
    }
  }

  Future<bool> _checkConnectivity(BuildContext context) async {
    // ここでは仮に常にtrueを返すようにしていますが、実際には通信状況をチェックして結果を返す必要があります。
    return true;
  }


  @override
  Widget build(BuildContext context) {
    final screenAspectRatio = MediaQuery.of(context).size.aspectRatio;

    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_controller.value.isInitialized) {
              final previewSize = _controller.value.previewSize!;
              final previewAspectRatio = previewSize.height / previewSize.width;

              // Calculate the scaling factor
              double scale = 1.0;
              if (previewAspectRatio > screenAspectRatio) {
                scale = previewAspectRatio / screenAspectRatio;
              } else {
                scale = screenAspectRatio / previewAspectRatio;
              }

              return Stack(
                children: [
                  // Camera preview scaled according to the aspect ratio
                  Center(
                    child: Transform.scale(
                      scale: scale,
                      child: AspectRatio(
                        aspectRatio: previewAspectRatio,
                        child: CameraPreview(_controller),
                      ),
                    ),
                  ),
                  // The controls should be outside the scaled preview
                  if (!_showImage)  // Only show the buttons if _showImage is false
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _takePicture,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Row(
                        children: [
                          // ElevatedButton(
                          //   onPressed: _takePicture,
                          //   child: Text('Take Picture'),
                          // ),
                          ElevatedButton(
                            onPressed: () {
                              chatConnection.emitEvent("leave_shooting_room");

                              // カメラのリソースを解放
                              // _controller.dispose();

                              _navigateBack(context);
                            },
                            child: const Text('Back'),
                          ),

                        ],
                      ),
                    ),
                  _showImage && _imagePath != null
                      ? Positioned.fill(
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: ElevatedButton(
                            onPressed: (_conversionCompleted && _locationAvailable && !_uploading)
                                ? () async {
                              if (_uploadImagePath != null && _uploadThumbnailPath != null) {
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                String userID = prefs.getString('userID') ?? "";

                                // call _progressUpload with necessary arguments
                                await _progressUpload(
                                    _uploadImagePath!,
                                    _uploadThumbnailPath!,
                                    userID,
                                    _localTimestamp,
                                    _imageCountry ?? '',
                                    _imageLat ?? '',
                                    _imageLng ?? '',
                                    widget.groupID,
                                    _geocodedCountry,
                                    _geocodedCity,
                                );

                                // 送信後、カメラを終了する
                                // _controller.dispose();
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              }
                            }
                                : null,
                            child: const Text('Send'),  // Enable the button only if the conversion is completed
                          ),
                        ),

                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: ElevatedButton(
                            onPressed: () async {  // Make the handler asynchronous
                              if (_imagePath != null) {
                                var imgFile = File(_imagePath!);
                                if (await imgFile.exists()) {  // Check if the file exists before trying to delete it
                                  await imgFile.delete();
                                }
                                _imagePath = null;
                              }

                              if (_thumbnailPath != null) {
                                var thumbFile = File(_thumbnailPath!);
                                if (await thumbFile.exists()) {  // Check if the file exists before trying to delete it
                                  await thumbFile.delete();
                                }
                                _thumbnailPath = null;
                              }

                              setState(() {
                                _showImage = false;  // Reset the flag when the button is pressed
                              });
                            },
                            child: const Text('Back'),
                          ),
                        )
                      ],
                    ),
                  )
                      : const SizedBox(),
                ],
              );

            } else {
              return const SizedBox.shrink();
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}