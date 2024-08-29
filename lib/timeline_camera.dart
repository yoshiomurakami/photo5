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
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
import 'chat_connection.dart';
import 'timeline_providers.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flag/flag.dart';

final cameraButtonKey = GlobalKey();

class CameraScreen extends ConsumerStatefulWidget {
  static const String routeName = '/camera';

  final CameraDescription camera;
  final String groupID;
  final int takePictureStartTime;
  final int shootingRoomCount;  // shootingRoomCount を追加

  CameraScreen({
    Key? key,
    required this.camera,
    required this.groupID,
    required this.takePictureStartTime,  // コンストラクタでtimestampを要求
    required this.shootingRoomCount,  // コンストラクタでshootingRoomCountを要求
  }) : super(key: ValueKey(takePictureStartTime));  // ValueKey を使って key を更新

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}


class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late bool _showImage;
  String? _imagePath;
  // String? _thumbnailPath;
  bool _uploading = false;
  bool _conversionCompleted = false;
  // bool _locationAvailable = false;
  String? _imageLat;
  String? _imageLng;
  String? _imageCountry;
  String? _uploadImagePath; // Add this for the upload image
  String? _uploadThumbnailPath; // Add this for the upload thumbnail
  String _timestamp ='';
  String _localTimestamp='';
  String _geocodedCountry='';
  String _geocodedArea='';
  String _geocodedCity='';

  // 新しい状態変数
  int now = 0;
  int triggerTime = 0;
  int delay = 0;
  late Timer countdownTimer;
  int remainingSeconds = 0;
  int userShootingListCount = 0; // データ件数を保持する状態変数

  bool _isControllerDisposed = false;

  // final ChatConnection chatConnection = ChatConnection();
  final ChatConnection chatConnection = ChatConnection()..connect();

  late final void Function(Map<String, dynamic>) eventHandler;

  late StreamSubscription _photoEventSubscription;

  List<Map<String, dynamic>> thumbnailData = [];

  List<Offset> emojiPositions = []; // 絵文字の位置を保持するリスト

  late AnimationController _animationController;
  late Animation<double> _animationFade;
  late Animation<double> _animationMove;
  bool _showLikeAnimation = false;

  // late Animation<double> _scaleAnimation; // スケールアニメーション用の変数を追加

  bool showTimer = false;

  // 他の変数と同じように国旗を保持するためのMapを定義します
  Map<String, String> userFlags = {};

  //タイマーシャッターを組み込んだinitstate
  @override
  void initState() {
    super.initState();
    // userShootingListCount = widget.shootingRoomCount - 1;
    // _controller = CameraController(
    //   widget.camera,
    //   ResolutionPreset.high,
    // );
    // _initializeControllerFuture = _controller.initialize().then((_) {
    //   setState(() {  // setStateを使用してUIの更新をトリガー
    //     now = DateTime.now().millisecondsSinceEpoch;
    //     triggerTime = widget.takePictureStartTime + 10000;  // デバイスAのタイムスタンプから10秒後
    //     delay = triggerTime - now;  // 残り時間を計算
    //     if (delay < 0) delay = 0;  // 遅延が負の場合は即時実行
    //     remainingSeconds = (delay / 1000).ceil(); // 残り時間を秒単位に変換して整数値に
    //     if (remainingSeconds > 30) remainingSeconds = 10; // 11秒以上にならないように制限
    //   });
    //
    //   // カウントダウンタイマーのセットアップ
    //   countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    //     if (remainingSeconds > 1) {
    //       setState(() {
    //         remainingSeconds--;
    //       });
    //     } else {
    //       timer.cancel();
    //     }
    //   });
    //
    //   Future.delayed(Duration(milliseconds: delay), () async {
    //     if (mounted && remainingSeconds > 0) {
    //       await _takePicture();
    //     }
    //   });
    // });




    setupCamera();
    setupSocketListeners();
    setupEventBusListener();



    _showImage = false;
    showTimer = false; // 初期状態ではタイマーを非表示

    // eventHandlerを初期化
    eventHandler = (Map<String, dynamic> data) {
      handleCameraEvent(data);
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // eventHandlerが初期化された後で使用する
      ref.read(connectionWidgetsManagerProvider).chatConnection.listenToCameraEvent(context, eventHandler);
    });



    WidgetsBinding.instance.addObserver(this);

    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == "AppLifecycleState.detached") {
        _leaveShootingRoom();
      }
      return;
    });

    // _photoEventSubscription = eventBus.stream.listen((data) {
    //   if (mounted) {
    //     // ScaffoldMessenger.of(context).showSnackBar(
    //     //     SnackBar(content: Text('新しい写真が追加されました！'), duration: Duration(seconds: 2))
    //     // );
    //     // debugPrint("Received photo data: $data");
    //
    //     // サムネイルデータをリストに追加
    //     setState(() {
    //       thumbnailData.add(data);
    //     });
    //   }
    // });

    // Socketイベントリスナーを設定
    // setupSocketListeners();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showLikeAnimation = false;  // アニメーション終了時に非表示にする
        });
      }
    });

    _animationFade = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50.0, // アニメーションの全体の中でこのTweenが占める割合
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50.0, // アニメーションの残りの部分
      ),
    ]).animate(_animationController);


    // ボタンの上部から画面の上部へ移動
    _animationMove = Tween(
        begin: 50.0,  // ボタンの中心から開始
        end: 100.0  // 画面の上端に向けて移動
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,  // 自然な動きに見えるようにeaseOutを使用
      ),
    );





    // スケールアニメーションの定義
    // _scaleAnimation = Tween<double>(begin: 2.0, end: 1.0).animate(
    //   CurvedAnimation(
    //     parent: _animationController,
    //     curve: Curves.easeOut, // イーズアウトカーブでスムーズに縮小
    //   ),
    // );

    _animationController.forward(); // アニメーションの開始



  }

  void setupCamera() {
    userShootingListCount = widget.shootingRoomCount - 1;
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          now = DateTime.now().millisecondsSinceEpoch;
          triggerTime = widget.takePictureStartTime + 10000;
          delay = triggerTime - now;
          if (delay < 0) delay = 0;
          remainingSeconds = (delay / 1000).ceil();
          if (remainingSeconds > 30) remainingSeconds = 10;
          // shootingRoomCountが2以上の場合、カウントダウンタイマーを開始
          if (widget.shootingRoomCount > 1) {
            showTimer = true; // 既に他のデバイスがカメラを起動していることを示す
            startCountdownTimer(); // カウントダウンタイマーを開始する処理
          }
        });

        // shootingRoomCountが2以上の場合のみ_takePictureを実行
        if (widget.shootingRoomCount > 1) {
          countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (mounted && remainingSeconds > 1) {
              setState(() {
                remainingSeconds--;
              });
            } else {
              timer.cancel();
            }
          });

          Future.delayed(Duration(milliseconds: delay), () async {
            if (mounted && remainingSeconds > 0) {
              await _takePicture();
            }
          });
        }
      }
    });
  }

  void startCountdownTimer() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && remainingSeconds > 1) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });

    Future.delayed(Duration(milliseconds: delay), () async {
      if (mounted && remainingSeconds > 0) {
        await _takePicture();
      }
    });
  }

  void setupEventBusListener() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String myUserID = prefs.getString('userID') ?? "";

    _photoEventSubscription = eventBus.stream.listen((data) async {
      debugPrint("_photoEventSubscription = $data");
      if (mounted) {
        // if (mounted && data['userID'] != myUserID) {
        // thumbnailDataが空の場合、または同じgroupIDがリスト内に存在する場合にのみ追加
        // if (thumbnailData.isEmpty || thumbnailData.any((item) => item['groupID'] == data['groupID'])) {
        // if (thumbnailData.isEmpty) {
        if (data['userID'] != myUserID) {
          setState(() {
            thumbnailData.insert(0, data);
          });
        }else{
          setState(() {
            thumbnailData.add(data);
          });
        }

        String imageUrl = 'https://photo5.world/${data["imageFilename"]}';
        String imageName = data['imageFilename'];

        // 保存処理が成功した後に _imagePath を更新
        bool saved = await saveOtherUserImage(imageUrl, imageName);
        debugPrint("Saved status: $saved");  // 保存の成功状態を確認するデバッグ出力
        if (saved && data['userID'] != myUserID) {
          setState(() {
            _imagePath = p.join('/data/user/0/com.unknwnphtgrphrs.photo5/app_flutter/uploadImage', imageName);
            debugPrint("_imagePath = $_imagePath");  // _imagePathが更新されたか確認するデバッグ出力
          });
        }

        Map<String, dynamic> photoInfo = {
          'systemId': data['_id'],
          'sequenceNumber': data['sequenceNumber'],
          'createdAt': data['createdAt'],
          'userID': data['userID'],
          'country': data['country'],
          'lat': data['lat'],
          'lng': data['lng'],
          'imageFilename': p.join('/data/user/0/com.unknwnphtgrphrs.photo5/app_flutter/uploadImage', imageName),
          'thumbnailFilename': p.join('/data/user/0/com.unknwnphtgrphrs.photo5/app_flutter/uploadThumb', imageName.replaceFirst('_photo.webp', '_thumb.webp')),
          'localtime': data['localtime'],
          'groupID': data['groupID'],
          'geocodedCountry': data['geocodedCountry'],
          'geocodedArea': data['geocodedArea'],
          'geocodedCity': data['geocodedCity'],
          'statement': data['statement']
        };

        if (data['userID'] != myUserID) {
          await insertImageData(photoInfo);
        }
      }
    });
  }


  Future<void> insertImageData(Map<String, dynamic> photoData) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'images_database.db');
    final database = await openDatabase(path);

    await database.insert(
        'images',
        {
          'systemId': photoData['systemId'], // 修正されたカラム名
          'sequenceNumber': photoData['sequenceNumber'],
          'createdAt': photoData['createdAt'],
          'userID': photoData['userID'],
          'country': photoData['country'],
          'lat': photoData['lat'],
          'lng': photoData['lng'],
          'imageFilename': photoData['imageFilename'],
          'thumbnailFilename': photoData['thumbnailFilename'],
          'localtime': photoData['localtime'],
          'groupID': photoData['groupID'],
          'geocodedCountry': photoData['geocodedCountry'],
          'geocodedArea': photoData['geocodedArea'],
          'geocodedCity': photoData['geocodedCity'],
          'statement': photoData['statement']
        },
        conflictAlgorithm: ConflictAlgorithm.replace
    );
  }


  void setupSocketListeners() {
    socket?.on('receive_tap_message', (data) {
      debugPrint('get!! receive_tap_message');
      debugPrint('Message: ${data['message']} from ${data['fromUserID']}');
      // 絵文字表示のためのランダム位置を設定
      final screenSize = MediaQuery.of(context).size;
      final double x = math.Random().nextDouble() * screenSize.width;
      final double y = math.Random().nextDouble() * (screenSize.height * 0.5); // 画面の上半分でランダム

      setState(() {
        emojiPositions.add(Offset(x, y));  // 新しい位置をリストに追加
      });
    });

    // assign_group_id イベントのリスナーを追加
    socket?.on('assign_group_id', (data) {
      if (mounted && data['shootingRoomCount'] > 1) {
        setState(() {
          showTimer = true; // 2台目がカメラを起動したときにタイマーを表示
          now = DateTime.now().millisecondsSinceEpoch;
          triggerTime = data['timestamp'] + 10000;
          delay = triggerTime - now;
          if (delay < 0) delay = 0;
          remainingSeconds = (delay / 1000).ceil();
          if (remainingSeconds > 30) remainingSeconds = 10;

          // タイマーを開始
          startCountdownTimer(); // カウントダウンタイマーの開始を関数化

          Future.delayed(Duration(milliseconds: delay), () async {
            if (mounted && remainingSeconds > 0) {
              await _takePicture();
            }
          });
        });
      }
    });

    socket?.on('camera_event', (data) {
      if (data['event'] == 'someone_leave_camera') {
        int shootingRoomCount = data['shootingRoomCount'];

        if (shootingRoomCount == 1 && mounted) {
          setState(() {
            // タイマーを停止し、カウントダウンを非表示にする
            countdownTimer.cancel();
            remainingSeconds = 0;
          });
        }
      }
    });

  }

  Future<bool> saveOtherUserImage(String imageUrl, String imageName) async {
    try {
      // サーバーから画像をダウンロード
      var photoResponse = await http.get(Uri.parse(imageUrl));
      var thumbResponse = await http.get(Uri.parse(imageUrl.replaceAll('_photo.webp', '_thumb.webp')));

      if (photoResponse.statusCode == 200 && thumbResponse.statusCode == 200) {
        // アプリケーションのドキュメントディレクトリを取得
        final Directory appDir = await getApplicationDocumentsDirectory();

        // 写真とサムネイルのディレクトリパス
        final String imageDirectoryPath = p.join(appDir.path, 'uploadImage');
        final String thumbDirectoryPath = p.join(appDir.path, 'uploadThumb');

        // ディレクトリが存在するか確認し、なければ作成
        await Directory(imageDirectoryPath).create(recursive: true);
        await Directory(thumbDirectoryPath).create(recursive: true);

        // 写真とサムネイルのフルファイルパスを構築
        final String photoFilePath = p.join(imageDirectoryPath, imageName);
        final String thumbFilePath = p.join(thumbDirectoryPath, imageName.replaceFirst('_photo.webp', '_thumb.webp'));

        // ファイルとして保存
        await File(photoFilePath).writeAsBytes(photoResponse.bodyBytes);
        await File(thumbFilePath).writeAsBytes(thumbResponse.bodyBytes);

        return true; // 保存成功
      }
    } catch (e) {
      debugPrint("Error saving image: $e");
    }
    return false; // 保存失敗
  }


  @override
  void dispose() {
    // ウィジェットが完全にディスポーズされる前に非同期操作を実行する
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _leaveShootingRoom();
        _disposeCameraController();
      }
    });
    countdownTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);  // Observerを削除
    _photoEventSubscription.cancel();
    socket?.off('receive_tap_message');
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _disposeCameraController() async {
    if (_controller.value.isInitialized) {
      await _controller.dispose();
    }
    _isControllerDisposed = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // アプリがバックグラウンドに移行したり、終了しようとしている場合
      _leaveShootingRoom();
      _disposeCameraController();
    } else if (state == AppLifecycleState.resumed) {
      // アプリがフォアグラウンドに戻った場合、カメラを再初期化する
      setupCamera();
    }
  }


  void _leaveShootingRoom() {
    ref.read(connectionWidgetsManagerProvider).chatConnection.emitEvent("leave_shooting_room");
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
      _leaveShootingRoom();
      _disposeCameraController();
      Navigator.pop(context);
    }
  }

  Future<void> _takePicture() async {
    final Directory tempDir = await getTemporaryDirectory();

    _timestamp = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    DateTime localTime = DateTime.now();
    String localTimestamp = DateFormat('EE, d MM, yyyy, HH:mm').format(localTime);

    // // 時差情報を取得
    // String timeZoneOffset = localTime.timeZoneOffset.isNegative
    //     ? '-${localTime.timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:${(localTime.timeZoneOffset.inMinutes.remainder(60)).abs().toString().padLeft(2, '0')}'
    //     : '+${localTime.timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:${(localTime.timeZoneOffset.inMinutes.remainder(60)).abs().toString().padLeft(2, '0')}';

    // 時差情報を付記したタイムスタンプ
    _localTimestamp = localTimestamp;

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
      // _thumbnailPath = thumbPath;

      // Update the image display
      setState(() {
        _showImage = true;
        _conversionCompleted = false;
      });

      // 画像の変換後、自動的にアップロードを実行
      await _convertImage(imgPath, thumbPath, int.parse(_timestamp), randomStr);

      if (_conversionCompleted && _uploadImagePath != null && _uploadThumbnailPath != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String userID = prefs.getString('userID') ?? "";

        // 自動アップロード
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
          _geocodedArea,
          _geocodedCity,
        );

        // アップロード後にleave_shooting_room
        if (mounted) {
          chatConnection.emitEvent("leave_shooting_room");
          // Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint("$e");
    }
  }





  Future<void> _convertImage(String imgPath, String thumbPath, int timestamp, String randomStr) async {


    // 疑似的な位置情報を生成
    Position fakePosition = Position(
      latitude: 48.862959685874486,
      longitude: 2.3129526537635354,
      timestamp: DateTime.now(), // 現在時刻を設定
      accuracy: 0, // 精度を適宜設定
      altitude: 0, // 標高を適宜設定
      heading: 0, // 向きを適宜設定
      speed: 0, // 速度を適宜設定
      speedAccuracy: 0, // 速度精度を適宜設定
    );

    // Fetch the user's current location.
    // Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    Position position = fakePosition;
    debugPrint('Current position: $position');
    _imageLat = position.latitude.toString();
    _imageLng = position.longitude.toString();


    // Fetch the user's current country.
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    _imageCountry = placemarks.first.isoCountryCode ?? 'Unknown';
    _geocodedCountry = placemarks.first.country ?? 'Unknown'; // 国名
    _geocodedArea = placemarks.first.administrativeArea ?? 'Unknown'; // 都市名
    _geocodedCity = placemarks.first.locality ?? 'Unknown'; // 都市名
    debugPrint('Placemarks: $placemarks');

    // Update _locationAvailable state
    // setState(() {
    //   _locationAvailable = true;
    // });

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
  Future<void> _progressUpload(String imagePath, String thumbnailPath, String userID, String localtimestamp, String imageCountry, String imageLat, String imageLng, String groupID, String geocodedCountry, String geocodedArea, String geocodedCity) async {
    Map<String, dynamic> newPhotoInfo = await _uploadImage(imagePath, thumbnailPath, groupID);

    if (newPhotoInfo!= {}) {  // 正しい sequenceNumber が取得できた場合
      await _saveImage(imagePath, thumbnailPath, newPhotoInfo);
    } else {
      // エラーハンドリング
      debugPrint("Error: Unable to get sequence number from upload response.");
    }

    debugPrint("groupID = $groupID");
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
    request.fields['groupID'] = widget.groupID;
    request.fields['geocodedCountry'] = _geocodedCountry;
    request.fields['geocodedArea'] = _geocodedArea;
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
// アップロードが成功した後の応答処理
        Map<String, dynamic> newPhotoInfo = {
          '_id': responseBody['photo']['_id'],
          'sequenceNumber': responseBody['photo']['sequenceNumber'].toString(),
          'createdAt': responseBody['photo']['createdAt'],
          'userID': responseBody['photo']['userID'],
          'country': responseBody['photo']['country'],
          'lat': double.parse(responseBody['photo']['lat'] ?? '0'),
          'lng': double.parse(responseBody['photo']['lng'] ?? '0'),
          'imageFilename': responseBody['photo']['imageFilename'],
          'thumbnailFilename': responseBody['photo']['thumbnailFilename'],
          'localtime': responseBody['photo']['localtime'],
          'groupID': responseBody['photo']['groupID'],
          'geocodedCountry': responseBody['photo']['geocodedCountry'],
          'geocodedArea': responseBody['photo']['geocodedArea'],
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


// _saveImage メソッド:アップロードしたファイルをデバイスフォルダに保存して、その情報をデバイスDBに保存する
  Future<void> _saveImage(String imagePath, String thumbnailPath, Map<String, dynamic> newPhotoInfo) async {
    final paths = await _saveFiles(imagePath, thumbnailPath);
    await _saveToDatabase(paths, newPhotoInfo);
  }

  //アップロードしたファイルをデバイスフォルダに保存する。
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
        'systemId':newPhotoInfo['_id'],
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
        'geocodedArea': newPhotoInfo['geocodedArea'],
        'geocodedCity': newPhotoInfo['geocodedCity'],
        'statement': newPhotoInfo['statement'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> _checkConnectivity(BuildContext context) async {
    // ここでは仮に常にtrueを返すようにしていますが、実際には通信状況をチェックして結果を返す必要があります。
    return true;
  }

  void handleCameraEvent(Map<String, dynamic> data) {
    if (!mounted) return;

    String event = data['event'];
    String userID = data['userID'];

    if (event == "someone_start_camera") {
      debugPrint("check_start_camera in camera $userID from ${data['countryCode']} total ${data['shootingRoomCount']}");

      setState(() {
        // userFlagsにuserIDをキーにしてcountryCodeを保存します
        userFlags[userID] = data['countryCode'];
      });

      handleUpdateUserShootingList(data);
    } else if (event == "someone_leave_camera") {
      debugPrint("check_leave_camera in camera $userID from ${data['countryCode']}");

      setState(() {
        // userFlagsからuserIDを削除します
        userFlags.remove(userID);
      });

      handleUpdateUserShootingList(data);

      if (data['shootingRoomCount'] == 1) {
        setState(() {
          // タイマーを停止し、カウントダウンを非表示にする
          countdownTimer.cancel();
          remainingSeconds = 0;
        });
      }
    } else if (event == "existingUserLocations") {
      debugPrint("existingUserLocations in camera is $data");
    } else if (event == "update_user_shootinglist") {
      debugPrint("handleUpdateUserShootingList(data) = $data");
    }
  }

  void handleUpdateUserShootingList(Map<String, dynamic> data) {
    setState(() {
      userShootingListCount = data['shootingRoomCount'] - 1;
    });
  }


  Widget buildThumbnail(Map<String, dynamic> thumbnailData, Size screenSize) {
    final thumbnailUrl = "https://photo5.world/${thumbnailData['thumbnailFilename']}";
    final String imagePath = "/data/user/0/com.unknwnphtgrphrs.photo5/app_flutter/uploadImage/${thumbnailData['imageFilename']}";

    final thumbnailSize = screenSize.width * 0.2; // 画面幅の20%
    final borderRadius = screenSize.width * 0.04; // 角丸の半径
    final margin = screenSize.width * 0.02; // 画面幅の2%をマージンとして設定

    return GestureDetector(
      onTap: () {
        setState(() {
          _imagePath = imagePath;  // タップされたサムネイルのフルサイズ画像パスを設定
          debugPrint("Updated _imagePath to: $_imagePath");
        });
      },
      child: Padding(
        padding: EdgeInsets.only(right: margin, left: margin),
        child: Container(
          width: thumbnailSize,
          height: thumbnailSize,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(thumbnailUrl),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }



  // void sendTapMessageToServer(List<dynamic> thumbnailData) {
  //   // for (var photoInfo in thumbnailData) {
  //   //   chatConnection.emitEvent('send_tap_message', {
  //   //     'userID': photoInfo['userID'],
  //   //     'groupID': photoInfo['groupID']
  //   //   });
  //   // }
  // }


  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenAspectRatio = MediaQuery.of(context).size.aspectRatio;

    return WillPopScope(
      onWillPop: () async {
        _navigateBack(context); // バックボタンが押されたときの処理
        return false; // デフォルトの動作をキャンセル
      },
      child: CurrentScreen(
        screenName: CameraScreen.routeName,
        child: Scaffold(
          body: FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (_controller.value.isInitialized && !_isControllerDisposed) {
                  final previewSize = _controller.value.previewSize!;
                  final previewAspectRatio = previewSize.height / previewSize.width;

                  double scale = 1.0;
                  if (previewAspectRatio > screenAspectRatio) {
                    scale = previewAspectRatio / screenAspectRatio;
                  } else {
                    scale = screenAspectRatio / previewAspectRatio;
                  }
                  return Stack(
                    children: [
                      // Camera preview scaled according to the aspect ratio
                      if (!_showImage && !_isControllerDisposed && _controller.value.isInitialized)
                        Center(
                          child: Transform.scale(
                            scale: scale,
                            child: AspectRatio(
                              aspectRatio: previewAspectRatio,
                              child: CameraPreview(_controller),
                            ),
                          ),
                        ),

                      // _showImageがtrueの場合、全画面の白い背景を表示
                      if (_showImage)
                        Positioned.fill(
                          child: Container(color: Colors.white),
                        ),

                      // Countdown Timer in the Center
                      if (!_showImage && showTimer && remainingSeconds > 0 && userShootingListCount > 0) // タイマーが有効な場合のみ表示
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            height: MediaQuery.of(context).size.width * 0.5,
                            alignment: Alignment.center,
                            color: Colors.black.withOpacity(0.5),
                            child: Text(
                              '$remainingSeconds',
                              style: const TextStyle(
                                fontSize: 48,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // メッセージを表示するコンテナ
                      if (!_showImage && !showTimer && userShootingListCount == 0)
                        Positioned(
                          bottom: MediaQuery.of(context).size.height * 0.2,
                          left: MediaQuery.of(context).size.width * 0.05,
                          child: Container(
                            height: MediaQuery.of(context).size.width * 0.2,
                            width: MediaQuery.of(context).size.width * 0.9,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '待機中\n画面タップで撮影できます',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                      // 国旗の表示
                      if (!_showImage && userFlags.isNotEmpty)
                        Positioned(
                          top: 50,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: userFlags.entries.map((entry) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Flag.fromString(
                                  entry.value,
                                  height: 30,
                                  width: 45,
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Backボタン
                      if (!_showImage) // 撮影前の状態でのみ表示
                        Positioned(
                          top: 50,
                          left: 20,
                          child: ElevatedButton(
                            onPressed: () {
                              _navigateBack(context);
                            },
                            child: const Text('Back'),
                          ),
                        ),

                      // Existing image or thumbnail display logic...

                      if (userShootingListCount >= 1)
                        Positioned(
                          bottom: MediaQuery.of(context).size.height * 0.05, // 画面の高さの5%
                          left: MediaQuery.of(context).size.width * 0.05, // 画面の幅の5%
                          height: MediaQuery.of(context).size.height * 0.04,
                          child: Container(
                            padding: const EdgeInsets.only(left: 5, top: 0, right: 15, bottom: 0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 1.5),
                              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height * 0.02),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text('\u{1F4F8}', style: TextStyle(color: Colors.black, fontSize: 16)),
                                const SizedBox(width: 10),
                                Text(
                                  '+$userShootingListCount',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
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
        ),
      ),
    );
  }

}

class CurrentScreen extends InheritedWidget {
  final String screenName;

  const CurrentScreen({
    Key? key,
    required this.screenName,
    required Widget child,
  }) : super(key: key, child: child);

  static CurrentScreen? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CurrentScreen>();
  }

  @override
  bool updateShouldNotify(CurrentScreen oldWidget) {
    return screenName != oldWidget.screenName;
  }

}

