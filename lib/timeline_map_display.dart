import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart' as p;
// import 'timeline_photoview.dart';
import 'timeline_providers.dart';
import 'timeline_map_card.dart';
import 'chat_connection.dart';
import 'timeline_camera.dart';
import 'album_timeline.dart';




class MapController {
  GoogleMapController? _controller;
  LatLng _currentLocation = const LatLng(0, 0);
  final Set<Marker> _markers = {};
  double _zoomLevel = 15; // 既存のズームレベル値をセット
  double get zoomLevel => _zoomLevel;

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
    if (_zoomLevel <= 15) {
      _zoomLevel += 1;
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, _zoomLevel));
    }
    print("New_zoomLevel_in=$_zoomLevel");
  }

  void zoomOut(LatLng target) {
    if (_zoomLevel >= 2) {
      _zoomLevel -= 1;
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, _zoomLevel));
    }
    print("New_zoomLevel_out=$_zoomLevel");
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
  _ZoomControlState createState() => _ZoomControlState();
}

class _ZoomControlState extends State<ZoomControl> {
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
    print("zoomTouchLength=$zoomTouchLength");

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
          print("currentZoomLevel=$currentZoomLevel");

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
  _JumpToTopState createState() => _JumpToTopState();
}

class _JumpToTopState extends State<JumpToTop> with TickerProviderStateMixin {
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
    if (_positionAnimation == null) {
      _positionAnimation = Tween<double>(
        begin: MediaQuery.of(context).size.height / 2 - (widget.size.width * 0.18) / 2,
        end: MediaQuery.of(context).size.height * 0.05,
      ).animate(_positionController);
    }

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

    chatConnection.listenToCameraEvent(context, (String data) {
      if (data == "someone_start_camera") {
        setState(() {
          showCameraBadge = true;
        });
      } else if (data == "someone_leave_camera") {
        setState(() {
          showCameraBadge = false;
        });
      }
    });

  }

  // _pickerControllerの現在のアイテムに基づいてisCenteredを更新する
  void _pickerControllerListener() {
    bool isCameraButtonCentered = widget.scrollController.selectedItem == 0; // カメラボタンが中央にあるか
    print("isCentered = $isCentered");
    if (isCentered != isCameraButtonCentered) {
      setState(() {
        isCentered = isCameraButtonCentered;
      });
    }
  }

  void _updateFadeControllerValue() {
    if (_positionController.isAnimating) {
      double fadeValue = 1 - (_positionController.value - 1).abs() * 2.0;

      _fadeController.value = fadeValue.clamp(0.0, 1.0) as double;
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
              child: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
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
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                // primary: buttonText == 'expand_less' ? Colors.white : Color(0xFFFFCC4D),
                backgroundColor: buttonText == 'expand_less' ? Colors.white : Colors.transparent,

                // side: BorderSide(color: Colors.black, width: 2.0),
                side: BorderSide(color: Colors.transparent, width: 2.0),

                fixedSize: Size(widget.size.width * 0.18, widget.size.width * 0.18),
                elevation: 0, // これで影をなくします
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
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
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

  static void updateMapLocation(dynamic selectedItem) {
    print("selectedItemAA = $selectedItem");
    double lat, lng;

    // selectedItemがTimelineItemかAlbumTimeLineかに基づいてlatとlngを設定
    if (selectedItem is TimelineItem) {
      lat = selectedItem.lat;
      lng = selectedItem.lng;
    } else if (selectedItem is AlbumTimeLine) {
      lat = selectedItem.lat;
      lng = selectedItem.lng;
    } else {
      // 不正な型の場合は何もしない
      print("Unsupported item type for map update.");
      return;
    }

    // Update the map location
    MapController.instance.updateMapLocation(lat, lng);
  }
}

class scrollToCenterService {
  static void scrollToCenter(FixedExtentScrollController pickerController, int tappedRowIndex) {
    final Duration duration = Duration(milliseconds: 150);
    final Curve curve = Curves.easeInOut;

    // 現在中央にある行のインデックスを取得
    int currentCenterIndex = pickerController.selectedItem;

    // タップされた行がすでに中央にあるかどうかをチェック
    if (tappedRowIndex == currentCenterIndex) {
      // 中央にある場合はメッセージを出力
      print("Kick largeImage on Timeline");
    } else {
      // 中央にない場合はその行を中央にスクロール
      pickerController.animateToItem(
        tappedRowIndex,
        duration: duration,
        curve: curve,
      );
    }
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
  bool programmaticChange = false;
  bool isFullScreen = false;
  // late FixedExtentScrollController _pickerController;
  late FixedExtentScrollController _scrollController;
  bool isScrolling = false;
  bool isFullScreenMode = false;
  List<CameraDescription>? _cameras;
  late CameraController _controller;
  ChatConnection chatConnection = ChatConnection();
  final _jumpToTopKey = GlobalKey<_JumpToTopState>();
  // bool showCameraBadge = false;
  // int _horizontalIndex = 0;
  // int _selectedHorizontalIndex = 0;
  List<List<TimelineItem>> groupedItemsList = [];  // このように定義
  // late Map<String, int> selectedItemsMap = {};
  int centralRowIndex = 0; // 初期値は適宜設定
  bool showNewListWheelScrollView = false;
  bool isCustomListActive = false; // カスタムリストの表示フラグ
  List<AlbumTimeLine> _albumList = [];  // アルバムデータを保持するためのリスト
  String _lastSelectedGroupID = 'camera';
  Map<String, int> _lastSelectedIndexes = {};
  // Map<String, Key> _lastSelectedKeys = {};
  // Map<Key, int> keyToIndexMap = {};
  late FixedExtentScrollController _pickerController = FixedExtentScrollController(initialItem: 0);

  late Map<String, List<AlbumTimeLine>> groupedAlbums;
  late List<String> groupKeys;
  String _lastSelectedAlbumGroupID = ''; // 初期値は空文字列


  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    // _pickerController = FixedExtentScrollController();
    _pickerController.addListener(_scrollListener);
    final ChatNotifier = ref.read(chatNotifierProvider);
    ChatNotifier.addPostedPhoto(widget.pageController, _pickerController, widget.timelineItems, ChatNotifier.selectedItemsMap, groupItemsByGroupId, toggleTimelineAndAlbum);

    _initializeCamera();

    chatConnection.listenToRoomCount(context);

    // _albumList は、アルバムデータのリストを保持する変数です
    groupedAlbums = groupAlbumsByGroupId(_albumList);
    groupKeys = groupedAlbums.keys.toList();
  }



  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        // timelineAddProvider から items を取得
        final items = ref.watch(timelineAddProvider);

        // ChatNotifier から selectedItemsMap を取得
        final chatNotifier = ref.watch(chatNotifierProvider);
        final selectedItemsMap = chatNotifier.selectedItemsMap;
        print("?selectedItemsMap = $selectedItemsMap");

        // groupedItemsList を生成
        List<List<TimelineItem>> groupedItemsList = groupItemsByGroupId(items);

        // groupedItemsList が更新された際に selectedItemsMap も更新
        updateGroupedItemsList(items, chatNotifier);  // 修正

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
              top: widget.size.height * 0.5 - (MediaQuery.of(context).size.height / 8) / 2,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height / 8,
              child: Container(
                color: Colors.white.withOpacity(0.5),
              ),
            ),

            if (!showNewListWheelScrollView)Positioned(
              top: widget.size.height * 0.2,
              bottom: widget.size.height * 0.2,
              left: widget.size.width * -0.18, //0.15
              right: widget.size.width * -0.18, //0.15
              child: Container(
                // color: Colors.red,  // 一時的に背景色を設定（コメントアウトされています）
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is ScrollEndNotification) {
                      // スクロールが完全に停止した場合の処理
                      if (_pickerController.hasClients) {
                        // 選択アイテムを取得しマップ移動
                        int index = _pickerController.selectedItem;
                        String groupID = groupedItemsList[index].first.groupID;
                        int selectedItemIndex = selectedItemsMap[groupID] ?? 0;
                        TimelineItem selectedItem = groupedItemsList[index][selectedItemIndex];
                        MapUpdateService.updateMapLocation(selectedItem);
                        // 最後に選択されたgroupIDを更新
                        _lastSelectedGroupID = groupID;
                      }
                    }
                    return true;
                  },
                    child: ListWheelScrollView(
                    controller: _pickerController,
                    itemExtent: MediaQuery.of(context).size.width * 0.2,
                    diameterRatio: 1.25,
                    onSelectedItemChanged: (int index) {
                      print('_pickerController selected item: ${groupedItemsList.length}');
                      print("index = $index");
                      if (index > groupedItemsList.length - 5) {
                        ref.read(timelineAddProvider.notifier).addMoreItems();
                      }
                      String lastSelectedGroupID = groupedItemsList[index].first.groupID;
                      print("qaqaqa groupID = $lastSelectedGroupID");
                      _lastSelectedIndexes[lastSelectedGroupID] = index;  // ここで最新のインデックスを保存
                      print("qaqaqa _lastSelectedGroupID = $lastSelectedGroupID");

                      // Key itemKey = groupedItemsList[index].first.key;  // 選択されたアイテムのkeyを取得
                      // _lastSelectedKeys[groupID] = itemKey;  // keyを保存

                      // for (int i = 0; i < groupedItemsList.length; i++) {
                      //   keyToIndexMap[groupedItemsList[i].first.key] = i;
                      // }

                      // setState(() {
                      //   print("www");
                      // });
                    },
                    // magnification: 1.3,
                    // useMagnifier: false,
                    physics: FixedExtentScrollPhysics(),
                    children: List<Widget>.generate(
                      groupedItemsList.length, // groupIDごとにグルーピングされたアイテムのリストのリスト
                          (int index) {
                            String groupID = groupedItemsList[index].first.groupID;
                            int currentIndex = selectedItemsMap[groupID] ?? 0;
                            return Center(
                              child: HorizontalGroupedItems(
                                itemsInGroup: groupedItemsList[index],
                                size: MediaQuery.of(context).size,
                                controller: _scrollController,
                                currentIndex: currentIndex,
                                pickerController: _pickerController,
                                items: items,
                                onTapCallback: (TimelineItem item) => scrollToCenterService.scrollToCenter(_pickerController , index),
                                centralRowIndex: centralRowIndex,
                                chatNotifier: chatNotifier,
                                onHorizontalIndexChanged: (int newIndex) {
                                  // ここはそのままでOKです。HorizontalGroupedItems内で処理される
                                  String groupID = groupedItemsList[index].first.groupID;
                                  selectedItemsMap[groupID] = newIndex;
                                  print("selectedItemsMap[groupID] = $selectedItemsMap");
                                },
                              ),
                            );
                      },
                    ),
                  ),
                ),
              ),
            ),  //タイムライン
            if (showNewListWheelScrollView && _albumList.isNotEmpty)
              Positioned(
                top: widget.size.height * 0.2,
                bottom: widget.size.height * 0.2,
                left: widget.size.width * -0.18,
                right: widget.size.width * -0.18,
                child: AlbumTimeLineView(
                  size: MediaQuery.of(context).size,
                  albumList: _albumList,
                  lastSelectedAlbumGroupID: _lastSelectedAlbumGroupID,
                  updateAlbumGroupIDCallback: updateLastSelectedAlbumGroupID,
                ),
              ),
            // 切り替えボタン
            Positioned(
              right: widget.size.width * 0.05,
              top: widget.size.height * 0.3,
              child: ElevatedButton(
                onPressed:toggleTimelineAndAlbum,
                child: Text(showNewListWheelScrollView ? 'タイムライン' : 'アルバム'),
              ),
            ),
            if (!showNewListWheelScrollView)JumpToTop(
              key: _jumpToTopKey,
              size: Size(widget.size.width, widget.size.height),
              // showBadge: showCameraBadge,
              onPressed: () {
                if (_jumpToTopKey.currentState!.isCentered) {
                  // カメラボタンが中央にある場合のみカメラを起動
                  if (_jumpToTopKey.currentState?.isCentered == true) {
                    if (_cameras != null && _cameras!.isNotEmpty) {
                      chatConnection.emitEvent("enter_shooting_room");
                      _waitForGroupId().then((groupID) {
                        if(groupID != null) {
                          _openCamera(_cameras![0], groupID);
                          print("get groupID = $groupID");
                        } else {
                          print("Failed to get the group ID.");
                        }
                      });
                    } else {
                      print("No available cameras found.");
                    }
                  }
                } else {
                  // リストを最上部にスクロール
                  _pickerController.animateToItem(
                    0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              scrollController: _pickerController,
            ),
            ZoomControl(
              size: Size(widget.size.width * 0.1, widget.size.height * 0.15),
              right: widget.size.width * 0.05,
              top: (widget.size.height) - (widget.size.height * 0.3) ,
            ),

            if (isFullScreenMode) // isFullScreenModeがtrueの場合だけFullScreenImageViewerを表示
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: FullScreenImageViewer(
                  items: items, // これはあなたのitemsリストを参照するものと仮定しています。
                  initialIndex: _pickerController.selectedItem, // これはあなたのコントローラの選択されたアイテムのインデックスを参照するものと仮定しています。
                  controller: _pickerController, // FullScreenImageViewerに必要な他のプロパティや設定も追加できます。
                  onTap: () {
                    setState(() {
                      isFullScreenMode = false;
                    });
                  },
                ),
              ),

          ],
        );
      },
    );
  }




  @override
  void dispose() {
    _pickerController.dispose();
    // リスナーの解除処理
    chatConnection.removeListeners();
    _pickerController.removeListener(_scrollListener);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void updateLastSelectedAlbumGroupID(String newGroupID) {
    setState(() {
      _lastSelectedAlbumGroupID = newGroupID;
    });
  }

  void toggleTimelineAndAlbum() {

    setState(() {
      showNewListWheelScrollView = !showNewListWheelScrollView;
      // updateMapBasedOnCurrentSelection(); // マップの位置を更新する
    });

      if (!showNewListWheelScrollView) {
        // 現在のリストから、目的のgroupIDを持つアイテムのインデックスを探す
        int targetIndex = groupedItemsList.indexWhere((list) =>
            list.any((item) => item.groupID == _lastSelectedGroupID));
        print("wawawa _lastSelectedGroupID = $_lastSelectedGroupID");
        print("wawawa targetIndex = $targetIndex");

        // 対象のアイテムが見つかった場合
        if (targetIndex != -1) {
          // スクロールビューを更新して指定されたアイテムにスクロールする
          _pickerController = FixedExtentScrollController(initialItem: targetIndex);

          // マップ移動
          final chatNotifier = ref.watch(chatNotifierProvider);
          final selectedItemsMap = chatNotifier.selectedItemsMap;
          // int index = _pickerController.selectedItem;
          String groupID = groupedItemsList[targetIndex].first.groupID;
          int selectedItemIndex = selectedItemsMap[groupID] ?? 0;
          TimelineItem selectedItem = groupedItemsList[targetIndex][selectedItemIndex];
          MapUpdateService.updateMapLocation(selectedItem);
        }
      }

      if (showNewListWheelScrollView) {
        //アルバムに切り替えたときの行指定とマップ移動は、class _AlbumTimeLineViewStateのinitstateに記述してある。
        //ここではアルバムデータを呼び出す処理のみ記述。

        // setState(() {
        //   _albumList = [];
        // });
        _loadAlbumData();
      }
  }


  void updateGroupedItemsList(List<TimelineItem> items, ChatNotifier chatNotifier) {
    groupedItemsList = groupItemsByGroupId(items);
    for (var group in groupedItemsList) {
      String groupID = group.first.groupID;
      if (!chatNotifier.selectedItemsMap.containsKey(groupID)) {
        chatNotifier.selectedItemsMap[groupID] = 0;
        // print("selectedItemsMap?? = ${chatNotifier.selectedItemsMap}");
      }
    }
  }


  void _scrollListener() {
    // 現在選択されているアイテムのインデックスを取得
    int currentIndex = _pickerController.selectedItem;

    // カメラボタン（先頭のアイテム）が選択されているかどうかを確認
    if (currentIndex == 0) {
      _jumpToTopKey.currentState?.centerButton();
    } else {
      _jumpToTopKey.currentState?.moveButton();
    }

    // // タイムラインの選択状態を保存
    // _lastSelectedIndexes[_lastSelectedGroupID] = currentIndex;
    // print("_lastSelectedIndexes[_lastSelectedGroupID] = $currentIndex");
  }



  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.medium);
    }
  }

  void _openCamera(CameraDescription cameraDescription, String groupID) { // groupIDを引数として追加
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          camera: cameraDescription,
          groupID: groupID, // CameraScreenにgroupIDを渡す
        ),
      ),
    );
  }

  // このメソッドはサーバーからcurrentShootingGroupIDを待つ
  Future<String?> _waitForGroupId() async {
    Completer<String?> completer = Completer();

    // 'assign_group_id' イベントのリスナーを設定
    chatConnection.on('assign_group_id', (data) {
      completer.complete(data as String?);
      // イベントリスナーを解除
      chatConnection.off('assign_group_id');
    });

    return completer.future;
  }

  List<List<TimelineItem>> groupItemsByGroupId(List<TimelineItem> items) {
    // groupIDをキーとして持つマップを作成
    Map<String, List<TimelineItem>> groupedMap = {};

    for (var item in items) {
      if (groupedMap.containsKey(item.groupID)) {
        groupedMap[item.groupID]!.add(item);
      } else {
        groupedMap[item.groupID] = [item];
      }
    }
    // マップの値をリストとして返す
    return groupedMap.values.toList();
  }

  // void callbackScrollToCenter(int index) {
  //   scrollToCenter(index);
  // }

  // void scrollToCenter(int index) {
  //   final Duration duration = Duration(milliseconds: 150);
  //   final Curve curve = Curves.easeInOut;
  //
  //   _pickerController.animateToItem(
  //     index,
  //     duration: duration,
  //     curve: curve,
  //   );
  // }

  void _loadAlbumData() async {

    // アルバムデータを非同期で取得し、状態を更新
    List<AlbumTimeLine> albumData = await fetchAlbumDataFromDB();

    // 100ミリ秒後にアルバムデータでリストを更新
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _albumList = albumData; // ここでalbumDataは新しいアルバムデータのリストです。
      });
    });
  }

}

