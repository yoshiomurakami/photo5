import 'dart:async';
import 'dart:io';
import 'dart:ui'; // ぼかし効果を使うために必要
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'timeline_providers.dart';
import 'timeline_map_card.dart';
import 'chat_connection.dart';
import 'timeline_camera.dart';
import 'album_timeline.dart';
import 'package:flag/flag.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

// class LocaleCache {
//   static String? _cachedLocale;
//
//   static Future<String> getLocale() async {
//     if (_cachedLocale != null) {
//       return _cachedLocale!;
//     }
//
//     // データベースパスを取得
//     final dbPath = await getDatabasesPath();
//     final path = p.join(dbPath, 'images_database.db');
//     final database = openDatabase(path);
//
//     // android_metadataテーブルからロケール情報を取得
//     final List<Map<String, dynamic>> metadata = await (await database).query('android_metadata');
//     String locale = 'en_US'; // デフォルトのロケール
//     if (metadata.isNotEmpty) {
//       locale = metadata.first['locale'] as String;
//     }
//
//     _cachedLocale = locale;
//
//     debugPrint("locale = $locale");
//
//     return locale;
//   }
// }

class MapController {
  GoogleMapController? _controller;
  LatLng _currentLocation = const LatLng(0, 0);
  final Set<Marker> _markers = {};
  double _zoomLevel = 10; // 既存のズームレベル値をセット
  double get zoomLevel => _zoomLevel;

  // シングルトンインスタンス
  static final MapController _instance = MapController._internal();

  // プライベートコンストラクタ
  MapController._internal();

  // シングルトンインスタンスへのアクセス
  static MapController get instance => _instance;

  // void setCurrentLocation(LatLng location) {
  //   _currentLocation = location;
  // }

  // コンストラクターまたは別の適切な場所で、groupedItemsList の先頭アイテムに基づいて _currentLocation を設定するメソッド
  void setInitialLocation(List<List<TimelineItem>> groupedItemsList) {
    if (groupedItemsList.isNotEmpty && groupedItemsList[0].isNotEmpty) {
      TimelineItem firstItem = groupedItemsList[0][0];
      _currentLocation = LatLng(firstItem.lat, firstItem.lng);
    }
  }

  void onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  Future<void> updateMapLocation(double lat, double lng) async {
    final controller = _controller!;
    _currentLocation = LatLng(lat, lng);
    controller.animateCamera(
    // controller.moveCamera(
      CameraUpdate.newLatLng(_currentLocation),
    );
  }

  void zoomIn(LatLng target) {
    if (_zoomLevel <= 15) {
      _zoomLevel += 1;
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, _zoomLevel));
    }
    debugPrint("New_zoomLevel_in=$_zoomLevel");
  }

  void zoomOut(LatLng target) {
    if (_zoomLevel >= 2) {
      _zoomLevel -= 1;
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, _zoomLevel));
    }
    debugPrint("New_zoomLevel_out=$_zoomLevel");
  }

  // 新しいメソッドを追加
  void updateZoom(double newZoomLevel) {
    if (newZoomLevel >= 2.0 && newZoomLevel <= 15.0) {
      _zoomLevel = newZoomLevel;
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, _zoomLevel));
    }
  }

}

class ZoomControl extends StatefulWidget {
  final Size size;
  final double right;
  final double top;

  const ZoomControl({Key? key, required this.size, required this.right, required this.top}) : super(key: key);

  @override
  ZoomControlState createState() => ZoomControlState();
}

class ZoomControlState extends State<ZoomControl> {
  double _startPosition = 0;
  double _endPosition = 0;

  // ValueNotifierを追加
  final ValueNotifier<double> _zoomLevelNotifier = ValueNotifier<double>(2.0);

  @override
  void initState() {
    super.initState();
    _zoomLevelNotifier.value = MapController.instance.zoomLevel.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    const double zoomTouchLength = 300;
    debugPrint("zoomTouchLength=$zoomTouchLength");

    return Positioned(
      right: widget.right,
      top: widget.top,
      child: GestureDetector(
        onVerticalDragStart: (details) {
          _startPosition = details.localPosition.dy;
        },
        onVerticalDragEnd: (details) {
          double difference = _endPosition - _startPosition;
          double zoomDelta;

          if (difference.abs() >= zoomTouchLength * 0.9) {
            zoomDelta = 13.0;
          } else if (difference.abs() >= zoomTouchLength * 0.01) {
            zoomDelta = 1.0 + (difference.abs() - zoomTouchLength * 0.1) * 12 / (zoomTouchLength * 0.8);
          } else {
            zoomDelta = 1.0;
          }

          double currentZoomLevel = _zoomLevelNotifier.value;

          if (difference > 0) {
            // Swipe down
            for (int i = 0; i < zoomDelta; i++) {
              if (currentZoomLevel > 2) {
                MapController.instance.zoomOut(MapController.instance._currentLocation);
                currentZoomLevel--;
              }
            }
          } else {
            // Swipe up
            for (int i = 0; i < zoomDelta; i++) {
              if (currentZoomLevel < 15) {
                MapController.instance.zoomIn(MapController.instance._currentLocation);
                currentZoomLevel++;
              }
            }
          }

          // Update the _zoomLevelNotifier value
          _zoomLevelNotifier.value = currentZoomLevel;
          debugPrint("currentZoomLevel=$currentZoomLevel");

          _startPosition = 0;
          _endPosition = 0;
        },
        onVerticalDragUpdate: (details) {
          _endPosition = details.localPosition.dy;
        },
        child: ValueListenableBuilder<double>(
          valueListenable: _zoomLevelNotifier,
          builder: (BuildContext context, double zoom, Widget? child) {
            return Container(
              width: widget.size.width,
              height: widget.size.height,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                border: Border.all(color: Colors.black, width: 2.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        // ズームインの処理
                        MapController.instance.updateZoom(15.0);
                        _zoomLevelNotifier.value = 15.0;
                      },
                      child: Icon(
                        Icons.location_city,
                        size: 20.0,
                        color: zoom == 15.0 ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        // ズームアウトの処理
                        MapController.instance.updateZoom(2.0);
                        _zoomLevelNotifier.value = 2.0;
                      },
                      child: Icon(
                        Icons.public,
                        size: 20.0,
                        color: zoom < 4.0 ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}

class JumpToTop extends StatefulWidget {
  final Size size;
  final VoidCallback onPressed;
  // final bool showBadge;
  final FixedExtentScrollController scrollController;  // 追加

  const JumpToTop({
    Key? key,
    required this.size,
    required this.onPressed,
    // this.showBadge = false,
    required this.scrollController,  // 追加
  }) : super(key: key);

  @override
  JumpToTopState createState() => JumpToTopState();
}

class JumpToTopState extends State<JumpToTop> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _positionController;
  Animation<double>? _positionAnimation;
  bool isCentered = true;
  String buttonText = '';
  ChatConnection chatConnection = ChatConnection();
  bool showCameraBadge = false;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _positionAnimation ??= Tween<double>(
        begin: MediaQuery.of(context).size.height / 2 - (widget.size.width * 0.18) / 2,
        end: MediaQuery.of(context).size.height * 0.05,
      ).animate(_positionController);

    // フレームの描画が完了した後に実行する処理をスケジュール
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // スクロールコントローラーがクライアントを持っていて、アイテムが存在することを確認
      if (widget.scrollController.hasClients) {
        bool isCameraButtonCentered = widget.scrollController.selectedItem == 0;
        // isCenteredの値に基づいて適切なメソッドを呼び出す
        if (isCentered != isCameraButtonCentered) {
          if (isCameraButtonCentered) {
            centerButton();
          } else {
            moveButton();
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
      value: 1.0,
    );

    _positionController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _positionController.addListener(() {
      _updateFadeControllerValue();
      if (_positionController.value > 0.5) {
        // ボタンが画面の下部に近づいたら
        setState(() {
          buttonText = 'expand_less'; // ここに変更したいテキストを設定
        });
      } else {
        setState(() {
          buttonText = '';
        });
      }
    });

    // スクロールコントローラーのリスナーを追加
    widget.scrollController.addListener(() {
      // 現在の選択アイテムに基づいてボタンの位置を更新
      bool isCameraButtonCentered = widget.scrollController.selectedItem == 0;
      if (isCentered != isCameraButtonCentered) {
        if (isCameraButtonCentered) {
          centerButton();
        } else {
          moveButton();
        }
      }
    });

    chatConnection.listenToCameraEvent(context, (Map<String, dynamic> data) {
      String event = data['event'];
      int? shootingRoomCount = data['shootingRoomCount'];
      debugPrint("listenToCameraEvent = $event");
      if (event == "someone_start_camera") {
        debugPrint("check_start_camera");
        setState(() {
          showCameraBadge = true;
        });
      } else if (event == "someone_leave_camera") {
        debugPrint("check_leave_camera");
        setState(() {
          if (shootingRoomCount != null && shootingRoomCount > 0) {
            showCameraBadge = true;
          } else {
            showCameraBadge = false;
          }
        });
      } else if (event == "existingUserLocations") {
        debugPrint("existingUserLocations is $data");

      } else if (event == "update_user_shootinglist") {
        debugPrint("update_user_shootinglist is $data");
      }
    });


  }

  // _pickerControllerの現在のアイテムに基づいてisCenteredを更新する
  void _pickerControllerListener() {
    bool isCameraButtonCentered = widget.scrollController.selectedItem == 0; // カメラボタンが中央にあるか
    if (isCentered != isCameraButtonCentered) {
      setState(() {
        isCentered = isCameraButtonCentered;
      });
    }
  }

  void _updateFadeControllerValue() {
    if (_positionController.isAnimating) {
      double fadeValue = 1 - (_positionController.value - 1).abs() * 2.0;

      _fadeController.value = fadeValue.clamp(0.0, 1.0);
    } else {
      _fadeController.value = 1.0;
    }
  }


  void centerButton() {
    setState(() {
      isCentered = true;
      _positionController.reverse(); // アニメーションを開始
    });
  }

  void moveButton() {
    setState(() {
      isCentered = false;
      _positionController.forward(); // アニメーションを開始
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _positionAnimation!,
      builder: (context, child) {
        return Positioned(
          bottom: _positionAnimation!.value,
          left: widget.size.width * 0.5 - (widget.size.width * 0.18) / 2,
          child: Stack(
            children: [
              FadeTransition(
                opacity: _fadeController,
                child: ElevatedButton(
                  onPressed: widget.onPressed,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: buttonText == 'expand_less' ? const Color(0xFFFFCC4D) : Colors.transparent,
                    side: const BorderSide(color: Colors.transparent, width: 2.0),
                    fixedSize: Size(widget.size.width * 0.18, widget.size.width * 0.18),
                    elevation: 0, // これで影をなくします
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: buttonText == 'expand_less'
                        ? Icon(Icons.expand_less, color: Colors.black, size: widget.size.width * 0.07)
                        : Text(
                      buttonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.size.width * 0.07,
                      ),
                    ),
                  ),
                ),
              ),

              if (showCameraBadge)
                Positioned(
                  top: 0,
                  right: 10,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

              // メッセージボックスを表示
              // if (showCameraBadge)
              //   Positioned(
              //     bottom: 0, // ボタンの下部に表示
              //     left: widget.size.width * 0.25, // 中央に配置
              //     child: Container(
              //       width: widget.size.width * 0.5, // 横幅はディスプレイの50％
              //       height: widget.size.height * 0.1, // 縦幅は10％
              //       decoration: BoxDecoration(
              //         color: Colors.blueGrey, // 背景色
              //         borderRadius: BorderRadius.circular(10), // 角を丸くする
              //       ),
              //       alignment: Alignment.center,
              //       child: Text(
              //         "メッセージ", // 表示するメッセージ
              //         style: TextStyle(color: Colors.white),
              //       ),
              //     ),
              //   ),
            ],
          ),
        );
      },
    );
  }


  @override
  void dispose() {
    _fadeController.dispose();
    _positionController.dispose();
    widget.scrollController.removeListener(_pickerControllerListener);
    super.dispose();
  }
}

class MapUpdateService {

  static void updateMapLocation(dynamic selectedItem, bool isMapVisible) {
    // showAlbumWheelScrollViewがtrueの場合は、マップの移動をさせない
    if (!isMapVisible) {
      return;
    }


    double lat, lng;

    // selectedItemがTimelineItemかAlbumTimeLineかに基づいてlatとlngを設定
    if (selectedItem is TimelineItem) {
      lat = selectedItem.lat;
      lng = selectedItem.lng;
    } else if (selectedItem is AlbumTimeLine) {
      lat = selectedItem.lat;
      lng = selectedItem.lng;
    } else {
      return;
    }

    // Update the map location
    MapController.instance.updateMapLocation(lat, lng);
  }


}

class ScrollToCenterService {
  static void scrollToCenter(FixedExtentScrollController pickerController, int tappedRowIndex) {
    const Duration duration = Duration(milliseconds: 150);
    const Curve curve = Curves.easeInOut;
    Future.delayed(const Duration(milliseconds: 150), ()
    {
      pickerController.animateToItem(
        tappedRowIndex,
        duration: duration,
        curve: curve,
      );
    });
  }
}



class MapDisplayStateful extends ConsumerStatefulWidget {
  final LatLng currentLocation;
  final List<TimelineItem> timelineItems;
  final Size size;
  final PageController pageController;

  const MapDisplayStateful({
    super.key,
    required this.currentLocation,
    required this.timelineItems,
    required this.size,
    required this.pageController,
  });

  @override
  MapDisplayState createState() => MapDisplayState();
}

class MapDisplayState extends ConsumerState<MapDisplayStateful> {
  late FixedExtentScrollController _scrollController;
  List<CameraDescription>? _cameras;
  late CameraController _controller;
  ChatConnection chatConnection = ChatConnection();
  final _jumpToTopKey = GlobalKey<JumpToTopState>();
  List<List<TimelineItem>> groupedItemsList = [];
  int centralRowIndex = 0;
  bool showAlbumWheelScrollView = false;
  List<AlbumTimeLine> _albumList = [];
  String _lastSelectedGroupID = 'camera';
  final Map<String, int> _lastSelectedIndexes = {};
  late FixedExtentScrollController _pickerController = FixedExtentScrollController(initialItem: 0);
  late Map<String, List<AlbumTimeLine>> groupedAlbums;
  late List<String> groupAlbumKeys;
  late List<String> groupKeys;
  String _lastSelectedAlbumGroupID = '';
  ValueNotifier<TimelineItem?> selectedItemNotifier = ValueNotifier<TimelineItem?>(null);
  ValueNotifier<bool> isScrollingNotifier = ValueNotifier<bool>(false);
  Timer? _debounce;
  bool isAlbumDataLoaded = false;
  bool _isDatabaseEmpty = true;

  TimelineItem? lastTappedItem;
  bool isDialogShowing = false;
  bool isMapVisible = false;
  ValueNotifier<File?> currentImageNotifier = ValueNotifier<File?>(null);
  ValueNotifier<bool> isMapVisibleNotifier = ValueNotifier<bool>(false); // 追加
  ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0); // 中央行のインデックスを保持するためのValueNotifier

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    debugPrint("Listener added to _pickerController");
    final chatNotifier = ref.read(chatNotifierProvider);
    chatNotifier.addPostedPhoto(
      context,
      widget.size,
      widget.pageController,
      _pickerController,
      widget.timelineItems,
      chatNotifier.selectedItemsMap,
      groupItemsByGroupId,
      toggleTimelineAndAlbum,
    );
    _initializeCamera();

    groupedAlbums = groupAlbumsByGroupId(_albumList);
    groupAlbumKeys = groupedAlbums.keys.toList();

    ConnectionWidgetsManager manager = ref.read(connectionWidgetsManagerProvider);
    manager.setOnPhotoTapCallback(scrollToTarget);

    _checkDatabaseEmpty();

    selectedItemNotifier.addListener(_loadNextImage);
  }

  @override
  void dispose() {
    _pickerController.dispose();
    chatConnection.removeListeners();
    _scrollController.dispose();
    _controller.dispose();
    _debounce?.cancel();
    isScrollingNotifier.dispose();
    selectedItemNotifier.removeListener(_loadNextImage);
    currentImageNotifier.dispose();
    selectedIndexNotifier.dispose(); // ValueNotifierの破棄
    super.dispose();
  }

  Future<void> _checkDatabaseEmpty() async {
    _isDatabaseEmpty = await isDatabaseEmpty();
    setState(() {});
  }

  Future<bool> isDatabaseEmpty() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'images_database.db');
    final database = openDatabase(path);

    final List<Map<String, dynamic>> maps = await (await database).query('images');

    return maps.isEmpty;
  }

  void _onScrollStarted() {
    if (!isScrollingNotifier.value) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        isScrollingNotifier.value = true;
        debugPrint("isScrolling = true;");
      });
    }
  }

  void _onScrollEnded() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      isScrollingNotifier.value = false;
      debugPrint("isScrolling = false;");
    });
  }

  void _showFullSizeImage(
      BuildContext context,
      String imageUrl,
      List<TimelineItem> itemsInGroup,
      int initialIndex,
      Map<String, int> selectedItemsMap) async {
    if (isDialogShowing) {
      return;
    }

    isDialogShowing = true;

    // データベースパスを取得
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'images_database.db');
    final database = openDatabase(path);

    // android_metadataテーブルからロケール情報を取得
    final List<Map<String, dynamic>> metadata = await (await database).query('android_metadata');
    String locale = 'en_US'; // デフォルトのロケール
    if (metadata.isNotEmpty) {
      locale = metadata.first['locale'] as String;
    }
    Intl.defaultLocale = locale;

    PageController pageController = PageController(initialPage: initialIndex);

    pageController.addListener(() {
      final pageIndex = pageController.page?.round() ?? initialIndex;
      if (pageIndex >= 0 && pageIndex < itemsInGroup.length) {
        selectedItemNotifier.value = itemsInGroup[pageIndex];
      }
    });

    showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: itemsInGroup.length,
                  itemBuilder: (context, index) {
                    String imageFilename = itemsInGroup[index].imageFilename.split('/').last;
                    return FutureBuilder<File>(
                      future: _getCachedImage(imageFilename),
                      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              double maxWidth = constraints.maxWidth;
                              double maxHeight = constraints.maxHeight;
                              return Center(
                                child: ClipRRect(
                                  child: Image.file(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    width: maxWidth,
                                    height: maxHeight,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.network('https://photo5.world/$imageFilename');
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        } else if (snapshot.hasError) {
                          return Image.network('https://photo5.world/$imageFilename');
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: isScrollingNotifier,
                builder: (context, isScrolling, child) {
                  if (!isScrolling) {
                    return ValueListenableBuilder<TimelineItem?>(
                      valueListenable: selectedItemNotifier,
                      builder: (context, selectedItem, child) {
                        if (selectedItem == null) {
                          return const SizedBox();
                        }

                        String formattedDate = _formatDateTime(selectedItem.localtime);

                        if (selectedItemsMap.containsKey(selectedItem.groupID) &&
                            selectedItemsMap[selectedItem.groupID]! >= 0 &&
                            selectedItemsMap[selectedItem.groupID]! < groupedItemsList.length) {
                          return Positioned(
                            bottom: MediaQuery.of(context).size.height * 0,
                            right: MediaQuery.of(context).size.width * 0,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Align(
                                  child: CustomPaint(
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                                      ),
                                      padding: const EdgeInsets.all(15),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const SizedBox(height: 5),
                                          Stack(
                                            children: [
                                              Text(
                                                "${selectedItem.geocodedCity} ${selectedItem.geocodedCountry}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ],
                                          ),
                                          Stack(
                                            children: [
                                              Text(
                                                formattedDate,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              ),
              Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop(pageController.page?.round());
                    isDialogShowing = false;
                  },
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.1,
                left: MediaQuery.of(context).size.width * 0.2,
                right: MediaQuery.of(context).size.width * 0.2,
                child: Container(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/titles.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
    ).then((finalIndex) {
      isDialogShowing = false;
      if (finalIndex != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          setState(() {
            final groupID = itemsInGroup[0].groupID;
            final groupIndex = groupedItemsList.indexWhere((group) => group.first.groupID == groupID);
            if (groupIndex != -1) {
              _pickerController.animateToItem(groupIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              final chatNotifier = ref.read(chatNotifierProvider);
              chatNotifier.selectedItemsMap[groupID] = finalIndex;
              selectedItemNotifier.value = itemsInGroup[finalIndex];
              MapUpdateService.updateMapLocation(selectedItemNotifier.value!, false);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpToItem(groupIndex);
                }
                // サムネイルリストの状態を更新するために通知を追加
                chatNotifier.notifyListeners();
              });
            }
          });
        });
      }
    });
  }

  String _formatDateTime(String dateTimeString) {
    // Custom parsing logic for the given format: "Sat, 3 08, 2024, 21:48"
    try {
      final parts = dateTimeString.split(', ');
      if (parts.length == 4) {
        // final dayOfWeek = parts[0]; // 曜日を取り出す
        final datePart = parts[1].split(' ');
        final day = int.parse(datePart[0]);
        final month = int.parse(datePart[1]);
        final year = int.parse(parts[2]);
        final timePart = parts[3].split(':');
        final hour = int.parse(timePart[0]);
        final minute = int.parse(timePart[1]);

        final dateTime = DateTime(year, month, day, hour, minute);
        final locale = Intl.defaultLocale; // デフォルトロケールを使用
        final dateFormat = DateFormat.yMMMMEEEEd(locale); // 曜日を含めた日付形式
        final timeFormat = DateFormat.Hm(locale); // デバイスのロケールに応じた時間形式

        return '${dateFormat.format(dateTime)}_${timeFormat.format(dateTime)}';
      } else {
        throw const FormatException("Invalid date format");
      }
    } catch (e) {
      return 'N/A';
    }
  }

  Future<File> _getCachedImage(String filename) async {
    String cacheDirPath = (await getTemporaryDirectory()).path;
    File cachedImage = File('$cacheDirPath/$filename');

    if (!cachedImage.existsSync()) {
      try {
        var url = 'https://photo5.world/$filename';
        var response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await cachedImage.writeAsBytes(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('Image download error: $e');
      }
    }
    return cachedImage;
  }

  void onThumbnailTap(TimelineItem tappedItem) {
    if (isMapVisibleNotifier.value == true && !showAlbumWheelScrollView) {
      final chatNotifier = ref.read(chatNotifierProvider);
      final selectedItemsMap = chatNotifier.selectedItemsMap;

      if (lastTappedItem == tappedItem) {
        final groupID = tappedItem.groupID;
        final itemsInGroup = groupedItemsList.firstWhere((group) => group.first.groupID == groupID);
        final initialIndex = itemsInGroup.indexOf(tappedItem);

        _showFullSizeImage(context, 'https://photo5.world/${tappedItem.imageFilename}', itemsInGroup, initialIndex, selectedItemsMap);
      } else {
        lastTappedItem = tappedItem;
      }
    } else {
      debugPrint("tappedItem");
      // isWhiteBoxVisibleNotifier.value = !isWhiteBoxVisibleNotifier.value;
    }
  }



  void _loadNextImage() async {
    final selectedItem = selectedItemNotifier.value;
    // インデックスが先頭であるかどうかを確認
    if (selectedItem != null && selectedItem.systemId != "shootbutton") {
      final imageFile = await _getCachedImage(selectedItem.imageFilename.split('/').last);
      if (mounted) {
        isMapVisibleNotifier.value = true; // 追加
        currentImageNotifier.value = imageFile;
      }
    } else {
      // 先頭の場合は画像を表示しない
      if (mounted) {
        isMapVisibleNotifier.value = false; // 追加
        currentImageNotifier.value = null;
      }
    }
  }

  Future<Map<String, String>> formatDateString(String dateString) async {
    DateTime dateTime;

    try {
      debugPrint("formatDateString called with dateString: $dateString");

      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'images_database.db');
      final database = await openDatabase(path);

      final List<Map<String, dynamic>> metadata = await database.query('android_metadata');
      String locale = 'en_US'; // デフォルトのロケール
      if (metadata.isNotEmpty) {
        locale = metadata.first['locale'] as String;
      }
      Intl.defaultLocale = locale;

      debugPrint("Locale set to: $locale");

      if (dateString == "dummy") {
        int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
        dateString = timestamp.toString();
      }

      int timestamp = int.parse(dateString);
      DateTime originalDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);

      Duration deviceOffset = DateTime.now().timeZoneOffset;
      debugPrint("deviceOffset = $deviceOffset");

      dateTime = originalDateTime.add(deviceOffset);

      debugPrint("dateTime after offset = $dateTime");

      final dateFormat = DateFormat.yMMMMEEEEd(locale);
      final timeFormat = DateFormat.Hm(locale);

      String formattedDate = dateFormat.format(dateTime);
      String formattedTime = timeFormat.format(dateTime);

      debugPrint("formattedDate = $formattedDate, formattedTime = $formattedTime");

      // 年、月、日、曜日を個別にフォーマット
      String formattedYear = DateFormat('yyyy', locale).format(dateTime);
      String formattedMonth = DateFormat('MMMM', locale).format(dateTime);
      String formattedDay = DateFormat('dd', locale).format(dateTime);
      String formattedWeekDay = DateFormat('EEE', locale).format(dateTime);

      return {
        'year': formattedYear,
        'month': formattedMonth,
        'day': formattedDay,
        'time': formattedTime,
        'weekday': formattedWeekDay,
      };

    } catch (e) {
      debugPrint('Error parsing date string: $dateString');
      debugPrint(e.toString());
      return {
        'year': 'N/A',
        'month': 'N/A',
        'day': 'N/A',
        'time': 'N/A',
        'weekday': 'N/A',
      };
    }
  }
















  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final items = ref.watch(timelineAddProvider);
        final chatNotifier = ref.watch(chatNotifierProvider);
        final selectedItemsMap = chatNotifier.selectedItemsMap;
        groupedItemsList = groupItemsByGroupId(items);
        MapController.instance.setInitialLocation(groupedItemsList);
        updateGroupedItemsList(items, chatNotifier);

        groupKeys = groupedItemsList.map((itemList) => itemList.first.groupID).toList();

        return Stack(
          children: [
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
              padding: const EdgeInsets.only(bottom: 0),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isMapVisibleNotifier,
              builder: (context, isMapVisible, child) {
                return Positioned.fill(
                  child: isMapVisible && !showAlbumWheelScrollView
                      ? Container(
                    color: Colors.black,
                  )
                      : const SizedBox.shrink(),
                );
              },
            ),

            ValueListenableBuilder<bool>(
              valueListenable: isMapVisibleNotifier,
              builder: (context, isMapVisible, child) {
                return isMapVisible && !showAlbumWheelScrollView
                    ? Positioned.fill(
                  child: ValueListenableBuilder<File?>(
                    valueListenable: currentImageNotifier,
                    builder: (context, currentImage, child) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: currentImage != null
                            ? Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: FileImage(currentImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                            : const SizedBox(),
                      );
                    },
                  ),
                )
                    : const SizedBox.shrink();
              },
            ),

            // if (showAlbumWheelScrollView)
            //   Positioned.fill(
            //     child: Container(
            //       color: Colors.red, // デバッグ用の背景色
            //     ),
            //   ),
            ValueListenableBuilder<bool>(
              valueListenable: isMapVisibleNotifier,
              builder: (context, isMapVisible, child) {
                if (isMapVisible) {
                  return Positioned(
                    // top: widget.size.height * 0,
                    // bottom: widget.size.height * 0,
                    // left: widget.size.width * 0,
                    // right: widget.size.width * 0,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // ぼかし効果を追加
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(0),
                          color: Colors.white.withOpacity(0), // 透明度を調整
                          // border: Border.all(
                          //   color: Colors.white,
                          //   width: 1,
                          // ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink(); // ウィジェットを表示しない場合は空のウィジェットを返す
                }
              },
            ),
            if (!showAlbumWheelScrollView)
              Positioned(
                top: widget.size.height * 0.3,
                bottom: widget.size.height * 0.3,
                left: widget.size.width * -0.18,
                right: widget.size.width * -0.18,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is ScrollStartNotification) {
                      _onScrollStarted();
                    } else if (notification is ScrollEndNotification) {
                      _onScrollEnded();
                      Future.delayed(const Duration(milliseconds: 10), () {
                        if (_pickerController.hasClients && groupedItemsList.isNotEmpty) {
                          int index = _pickerController.selectedItem;
                          if (index >= 0 && index < groupedItemsList.length) {
                            selectedIndexNotifier.value = index; // 中央行のインデックスを更新
                            String groupID = groupedItemsList[index].first.groupID;
                            int selectedItemIndex = selectedItemsMap[groupID] ?? 0;
                            if (selectedItemIndex >= 0 && selectedItemIndex < groupedItemsList[index].length) {
                              selectedItemNotifier.value = groupedItemsList[index][selectedItemIndex];
                              MapUpdateService.updateMapLocation(selectedItemNotifier.value!, false);
                              _lastSelectedGroupID = groupID;
                            }
                          }
                        }
                      });
                    }
                    return true;
                  },
                    child: Stack(
                      children: [
                        ListWheelScrollView(
                          controller: _pickerController,
                          itemExtent: MediaQuery.of(context).size.width * 0.2,
                          diameterRatio: 1.25,
                          onSelectedItemChanged: (int index) async {
                            if (index + 1 == groupKeys.length) {
                              await ref.read(timelineAddProvider.notifier).addMoreItems();
                            }
                            if (index >= 0 && index < groupKeys.length) {
                              String lastSelectedGroupID = groupKeys[index];
                              _lastSelectedIndexes[lastSelectedGroupID] = index;
                            }
                          },
                          physics: const FixedExtentScrollPhysics(),
                          children: List<Widget>.generate(
                            groupedItemsList.length,
                                (int index) {
                              String groupID = groupedItemsList[index].first.groupID;
                              int currentIndex = selectedItemsMap[groupID] ?? 0;
                              String dateString = groupedItemsList[index].first.createdAt; // 日付情報を取得
                              debugPrint("String dateString = $dateString");

                              return FutureBuilder<Map<String, String>>(
                                future: formatDateString(dateString), // 非同期関数を使用
                                builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    debugPrint('FutureBuilder error: ${snapshot.error}');
                                    return Center(child: Text('Error: ${snapshot.error}'));
                                  } else if (!snapshot.hasData) {
                                    debugPrint('FutureBuilder no data');
                                    return const Center(child: Text('No data'));
                                  } else {
                                    final formattedDate = snapshot.data!;
                                    return Stack(
                                      children: [
                                        Center(
                                          child: Stack(
                                            children: [
                                              HorizontalGroupedItems(
                                                itemsInGroup: groupedItemsList[index],
                                                size: MediaQuery.of(context).size,
                                                controller: _scrollController,
                                                currentIndex: currentIndex,
                                                pickerController: _pickerController,
                                                items: items,
                                                onTapCallback: (TimelineItem item) {
                                                  ScrollToCenterService.scrollToCenter(_pickerController, index);
                                                  if (_pickerController.selectedItem == index) {
                                                    Future.delayed(const Duration(milliseconds: 100), () {
                                                      onThumbnailTap(item);
                                                    });
                                                  }
                                                },
                                                centralRowIndex: centralRowIndex,
                                                chatNotifier: chatNotifier,
                                                onHorizontalIndexChanged: (int newIndex) {
                                                  if (groupedItemsList[index] == groupedItemsList[_pickerController.selectedItem]) {
                                                    selectedItemsMap[groupID] = newIndex;
                                                    selectedItemNotifier.value = groupedItemsList[index][newIndex];
                                                  }
                                                },
                                              ),
                                              IgnorePointer(
                                                child: Stack(
                                                  children: [
                                                    if (index != 0)
                                                      Positioned(
                                                        left: widget.size.width * 0.4, // 画面中央からデバイス横幅40%
                                                        top: MediaQuery.of(context).size.width * 0.10 - 10, // Positionedの上端からデバイス横幅10% - テキスト高さの半分(8)
                                                        child: Container(
                                                          alignment: Alignment.centerRight,
                                                          child: Text(
                                                            formattedDate['time']!,
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // 時:分のフォントサイズを大きく
                                                              fontWeight: FontWeight.bold,
                                                              shadows: [
                                                                Shadow(
                                                                  offset: Offset(2.0, 2.0),
                                                                  blurRadius: 3.0,
                                                                  color: Color.fromARGB(150, 0, 0, 0),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        IgnorePointer(
                          child: Center(
                            child: ValueListenableBuilder<int>(
                              valueListenable: selectedIndexNotifier,
                              builder: (context, selectedIndex, child) {
                                if (selectedIndex == 0 || selectedIndex >= groupedItemsList.length) {
                                  return const SizedBox.shrink(); // インデックス0または無効なインデックスは空のウィジェットを返す
                                }
                                String centralDateString = groupedItemsList[0].first.localtime;
                                return FutureBuilder<Map<String, String>>(
                                  future: formatDateString(centralDateString), // 非同期関数を使用
                                  builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      debugPrint('FutureBuilder error: ${snapshot.error}');
                                      return Center(child: Text('Error: ${snapshot.error}'));
                                    } else if (!snapshot.hasData) {
                                      debugPrint('FutureBuilder no data');
                                      return const Center(child: Text('No data'));
                                    } else {
                                      final centralFormattedDate = snapshot.data!;
                                      return Stack(
                                        children: [
                                          Positioned(
                                            top: widget.size.height * 0.1 + widget.size.width * 0.05 + 2, // テキスト全体の高さの半分を引く
                                            left: widget.size.width * 0.18,
                                            child: Container(
                                              height: widget.size.height * 0.2 - widget.size.width * 0.1,
                                              width: widget.size.width * 0.2,
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.all(0.0), // パディングを追加してテキストの周りに余白を確保
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.8), // 背景色を白に設定
                                                borderRadius: const BorderRadius.only(
                                                  topRight: Radius.circular(12.0), // 右上の角を丸める
                                                  bottomRight: Radius.circular(12.0), // 右下の角を丸める
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center, // 縦中央に配置
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    centralFormattedDate['year']!,
                                                    style: const TextStyle(
                                                      color: Colors.black, // テキストの色を黒に変更
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    centralFormattedDate['month']!,
                                                    style: const TextStyle(
                                                      color: Colors.black, // テキストの色を黒に変更
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    centralFormattedDate['weekday']!,
                                                    style: const TextStyle(
                                                      color: Colors.black, // テキストの色を黒に変更
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    centralFormattedDate['day']!,
                                                    style: const TextStyle(
                                                      color: Colors.black, // テキストの色を黒に変更
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),


                ),
              ),
            if (showAlbumWheelScrollView && _albumList.isNotEmpty)
              Positioned(
                top: widget.size.height * 0.3,
                bottom: widget.size.height * 0.3,
                left: 0,
                right: 0,
                child: AlbumTimeLineView(
                  size: MediaQuery.of(context).size,
                  albumList: _albumList,
                  lastSelectedAlbumGroupID: _lastSelectedAlbumGroupID,
                  updateAlbumGroupIDCallback: updateLastSelectedAlbumGroupID,
                ),
              ),
            Positioned(
              right: widget.size.width * 0.05,
              top: widget.size.height * 0.2,
              child: ElevatedButton(
                onPressed: _isDatabaseEmpty ? null : toggleTimelineAndAlbum,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDatabaseEmpty ? Colors.grey : Colors.blue,
                ),
                child: Text(showAlbumWheelScrollView ? 'タイムライン' : 'アルバム'),
              ),
            ),
            if (!showAlbumWheelScrollView)
              JumpToTop(
                key: _jumpToTopKey,
                size: Size(widget.size.width, widget.size.height),
                onPressed: () {
                  if (_jumpToTopKey.currentState!.isCentered) {
                    if (_cameras != null && _cameras!.isNotEmpty) {
                      chatConnection.emitEvent("enter_shooting_room");
                      _waitForGroupIdAndTimestamp().then((cameraData) {
                        if (cameraData != null) {
                          _openCamera(_cameras![0], cameraData);
                          debugPrint("cameraData['shootingRoomCount'] = $cameraData");
                        } else {
                          debugPrint("Failed to get the group ID and timestamp.");
                        }
                      }).catchError((error) {
                        debugPrint("Error fetching group ID and timestamp: $error");
                      });
                    } else {
                      debugPrint("No available cameras found.");
                    }
                  } else {
                    _pickerController.animateToItem(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                scrollController: _pickerController,
              ),
            ValueListenableBuilder<bool>(
              valueListenable: isMapVisibleNotifier,
              builder: (context, isMapVisible, child) {
                if (!isMapVisible || showAlbumWheelScrollView) {
                  return ZoomControl(
                    size: Size(widget.size.width * 0.1, widget.size.height * 0.15),
                    right: widget.size.width * 0.05,
                    top: (widget.size.height) - (widget.size.height * 0.5) - (widget.size.height * 0.075),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            // if (!showAlbumWheelScrollView)
            Positioned(
              top: widget.size.height * 0.1,
              left: widget.size.width * 0.2,
              right: widget.size.width * 0.2,
              child: Container(
                // height: widget.size.height * 0.2,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/titles.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  void scrollToTarget() {
    if (_pickerController.hasClients) {
      debugPrint("Callback from new_photo");
      _pickerController.animateToItem(
        1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {
        showAlbumWheelScrollView = false;
        if (selectedItemNotifier.value != null) {
          MapUpdateService.updateMapLocation(selectedItemNotifier.value!, false);
        } else {
          debugPrint("selectedItem is null");
        }
      });
    } else {
      debugPrint("ScrollController not attached to any scroll views.");
    }
  }

  void updateLastSelectedAlbumGroupID(String newGroupID) {
    setState(() {
      _lastSelectedAlbumGroupID = newGroupID;
      debugPrint("_lastSelectedAlbumGroupID = $_lastSelectedAlbumGroupID");
    });
  }

  void toggleTimelineAndAlbum() {
    setState(() {
      showAlbumWheelScrollView = !showAlbumWheelScrollView;
    });

    isMapVisibleNotifier.value = !isMapVisibleNotifier.value;


    if (showAlbumWheelScrollView) {
      _loadAlbumData();
    } else {
      int targetIndex = groupedItemsList.indexWhere((list) =>
          list.any((item) => item.groupID == _lastSelectedGroupID));
      if (targetIndex != -1) {
        _pickerController = FixedExtentScrollController(initialItem: targetIndex);

        final chatNotifier = ref.watch(chatNotifierProvider);
        final selectedItemsMap = chatNotifier.selectedItemsMap;
        String groupID = groupedItemsList[targetIndex].first.groupID;
        int selectedItemIndex = selectedItemsMap[groupID] ?? 0;
        TimelineItem selectedItem = groupedItemsList[targetIndex][selectedItemIndex];
        MapUpdateService.updateMapLocation(selectedItem, false);
      }
    }
  }

  Future<void> _loadAlbumData() async {
    List<AlbumTimeLine> albumData = await fetchAlbumDataFromDB();
    debugPrint('Fetched album data: ${albumData.length} items');

    setState(() {
      _albumList = albumData;
      isAlbumDataLoaded = true;
      debugPrint('_albumList updated: ${_albumList.length} items');
    });
  }

  Future<void> _checkAlbumDataExistence() async {
    bool isEmpty = await isDatabaseEmpty();
    setState(() {
      _isDatabaseEmpty = isEmpty;
    });
  }

  void updateGroupedItemsList(List<TimelineItem> items, ChatNotifier chatNotifier) {
    groupedItemsList = groupItemsByGroupId(items);
    for (var group in groupedItemsList) {
      String groupID = group.first.groupID;
      if (!chatNotifier.selectedItemsMap.containsKey(groupID)) {
        chatNotifier.selectedItemsMap[groupID] = 0;
      }
    }
  }

  Widget buildFlagWidget(String countryCode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black,
          width: 2.0,
        ),
      ),
      child: ClipOval(
        child: Container(
          color: Colors.white,
          height: 20,
          width: 20,
          child: Flag.fromString(
            countryCode,
            height: 20,
            width: 20,
            fit: BoxFit.cover,
            flagSize: FlagSize.size_1x1,
          ),
        ),
      ),
    );
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.medium);
    }
  }

  void _openCamera(CameraDescription cameraDescription, Map<String, dynamic> cameraData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          camera: cameraDescription,
          groupID: cameraData['groupID'],
          takePictureStartTime: cameraData['timestamp'],
          shootingRoomCount: cameraData['shootingRoomCount'],
        ),
      ),
    );

    await _checkAlbumDataExistence();
  }

  Future<Map<String, dynamic>?> _waitForGroupIdAndTimestamp() async {
    Completer<Map<String, dynamic>?> completer = Completer();

    chatConnection.on('assign_group_id', (data) {
      if (data is Map<String, dynamic>) {
        String groupID = data['groupID'];
        int timestamp = data['timestamp'];
        int shootingRoomCount = data['shootingRoomCount'];
        debugPrint("timestamp in map Display = $timestamp");

        completer.complete({'groupID': groupID, 'timestamp': timestamp, 'shootingRoomCount': shootingRoomCount});

        chatConnection.off('assign_group_id');
      } else {
        debugPrint('Received data is not in the expected format');
        completer.completeError('Invalid data format');
      }
    });

    return completer.future;
  }

  List<List<TimelineItem>> groupItemsByGroupId(List<TimelineItem> items) {
    Map<String, List<TimelineItem>> groupedMap = {};

    for (var item in items) {
      if (groupedMap.containsKey(item.groupID)) {
        groupedMap[item.groupID]!.add(item);
      } else {
        groupedMap[item.groupID] = [item];
      }
    }
    debugPrint("groupedMapAAA = $groupedMap");
    return groupedMap.values.toList();
  }
}

class HorizontalGroupedItems extends StatefulWidget {
  final List<TimelineItem> itemsInGroup;
  final Size size;
  final FixedExtentScrollController controller;
  final int currentIndex;
  final FixedExtentScrollController pickerController;
  final List<TimelineItem> items;
  final void Function(TimelineItem)? onTapCallback;
  final ValueChanged<int> onHorizontalIndexChanged;
  final int centralRowIndex;
  final ChatNotifier chatNotifier;

  const HorizontalGroupedItems({
    super.key,
    required this.itemsInGroup,
    required this.size,
    required this.controller,
    required this.currentIndex,
    required this.pickerController,
    required this.items,
    this.onTapCallback,
    required this.onHorizontalIndexChanged,
    required this.centralRowIndex,
    required this.chatNotifier,
  });

  @override
  HorizontalGroupedItemsState createState() => HorizontalGroupedItemsState();
}

class HorizontalGroupedItemsState extends State<HorizontalGroupedItems> {
  late PageController _scrollController;
  int centralRowIndex = 0;
  Timer? _tapTimer;
  bool _isTap = false;

  void _onScrollChange() {
    int newIndex = _scrollController.page!.round();
    String groupID = widget.itemsInGroup.first.groupID;
    widget.chatNotifier.selectedItemsMap[groupID] = newIndex;
    if (widget.currentIndex == widget.centralRowIndex) {
      widget.onHorizontalIndexChanged(newIndex);
    }
  }

  void _updateScrollPosition() {
    String groupID = widget.itemsInGroup.first.groupID;
    int newSelectedIndex = widget.chatNotifier.selectedItemsMap[groupID] ?? 0;

    if (_scrollController.hasClients && _scrollController.page!.round() != newSelectedIndex && widget.pickerController.hasClients) {
      _scrollController.animateToPage(
        newSelectedIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void updateScrollController(int index) {
    if (_scrollController.hasClients) {
      _scrollController.jumpToPage(index);
    }
  }

  @override
  void initState() {
    super.initState();

    String groupID = widget.itemsInGroup.first.groupID;
    int initialPageIndex = widget.chatNotifier.selectedItemsMap[groupID] ?? 0;

    _scrollController = PageController(
      initialPage: initialPageIndex,
      viewportFraction: 0.165,
    );
    _scrollController.addListener(_onScrollChange);

    widget.chatNotifier.addListener(_updateScrollPosition);
  }

  @override
  void dispose() {
    widget.chatNotifier.removeListener(_updateScrollPosition);
    _tapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _scrollController,
      itemCount: widget.itemsInGroup.length,
      itemBuilder: (context, index) {
        return Listener(
          onPointerDown: (event) {
            _isTap = true;
            _tapTimer = Timer(const Duration(milliseconds: 100), () {
              _isTap = false;
            });
          },
          onPointerUp: (event) {
            if (_isTap) {
              _tapTimer?.cancel();
              debugPrint("onPointerUp = ${_scrollController.page!.round()} , index = $index");
              if (_scrollController.page!.round() != index) {
                _scrollController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                final parentState = context.findAncestorStateOfType<MapDisplayState>();
                if (parentState != null) {
                  parentState.onThumbnailTap(widget.itemsInGroup[index]);
                }
              }
            }
          },
          child: GestureDetector(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: TimelineCard(
                item: widget.itemsInGroup[index],
                size: widget.size,
                controller: widget.controller,
                currentIndex: widget.currentIndex,
                pickerController: widget.pickerController,
                items: widget.items,
                onTapCallback: widget.onTapCallback,
              ),
            ),
          ),
        );
      },
    );
  }
}






class BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const borderRadius = 10.0;
    const arrowSize = 7.0;

    final path = Path()
      ..moveTo(borderRadius, 0)
      ..lineTo(size.width - borderRadius, 0)
      ..arcToPoint(
        Offset(size.width, borderRadius),
        radius: const Radius.circular(borderRadius),
      )
      ..lineTo(size.width, size.height - borderRadius - arrowSize)
      ..arcToPoint(
        Offset(size.width - borderRadius, size.height - arrowSize),
        radius: const Radius.circular(borderRadius),
      )
      ..lineTo(size.width / 2 + arrowSize * 0.5, size.height - arrowSize)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 - arrowSize * 0.5, size.height - arrowSize)
      ..lineTo(borderRadius, size.height - arrowSize)
      ..arcToPoint(
        Offset(0, size.height - borderRadius - arrowSize),
        radius: const Radius.circular(borderRadius),
      )
      ..lineTo(0, borderRadius)
      ..arcToPoint(
        const Offset(borderRadius, 0),
        radius: const Radius.circular(borderRadius),
      )
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0; // 線の太さを設定

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

