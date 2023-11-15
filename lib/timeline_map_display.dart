import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
// import 'timeline_photoview.dart';
import 'timeline_providers.dart';
import 'timeline_map_card.dart';
import 'chat_connection.dart';
import 'timeline_camera.dart';


class MapController {
  GoogleMapController? _controller;
  LatLng _currentLocation = LatLng(0, 0);
  Set<Marker> _markers = {};
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

  ZoomControl({required this.size, required this.right, required this.top});

  @override
  _ZoomControlState createState() => _ZoomControlState();
}

class _ZoomControlState extends State<ZoomControl> {
  double _startPosition = 0;
  double _endPosition = 0;

  // ValueNotifierを追加
  ValueNotifier<double> _zoomLevelNotifier = ValueNotifier<double>(2.0);

  @override
  void initState() {
    super.initState();
    _zoomLevelNotifier.value = MapController.instance.zoomLevel.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final double zoomTouchLength = 300;
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
  final bool showBadge;

  JumpToTop({
    Key? key,
    required this.size,
    required this.onPressed,
    this.showBadge = false,
  }) : super(key: key);

  @override
  _JumpToTopState createState() => _JumpToTopState();
}

class _JumpToTopState extends State<JumpToTop> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _positionController;
  Animation<double>? _positionAnimation;
  double? _bottomPosition;
  bool isCentered = true;
  String buttonText = '';


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_positionAnimation == null) {
      _positionAnimation = Tween<double>(
        begin: MediaQuery.of(context).size.height / 2 - (widget.size.width * 0.15) / 2,
        end: MediaQuery.of(context).size.height * 0.05,
      ).animate(_positionController)
        ..addListener(() {
          setState(() {
            _bottomPosition = _positionAnimation!.value;

          });
        });
    }
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
          left: widget.size.width * 0.5 - (widget.size.width * 0.15 * 1.3) / 2,
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
                primary: buttonText == 'expand_less' ? Colors.white : Colors.transparent,

                // side: BorderSide(color: Colors.black, width: 2.0),
                side: BorderSide(color: Colors.transparent, width: 2.0),

                fixedSize: Size(widget.size.width * 0.15, widget.size.width * 0.15),
                elevation: 0, // これで影をなくします
              ),
            ),
          ),



          if (widget.showBadge)
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
    super.dispose();
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
  late FixedExtentScrollController _pickerController;
  bool isScrolling = false;
  bool isFullScreenMode = false;
  List<CameraDescription>? _cameras;
  late CameraController _controller;
  ChatConnection chatConnection = ChatConnection();
  final _jumpToTopKey = GlobalKey<_JumpToTopState>();
  bool showCameraBadge = false;
  late FixedExtentScrollController _scrollController;
  // int _horizontalIndex = 0;
  // int _selectedHorizontalIndex = 0;
  List<List<TimelineItem>> groupedItemsList = [];  // このように定義
  late Map<String, int> selectedItemsMap = {};
  int centralRowIndex = 0; // 初期値は適宜設定


  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    _pickerController = FixedExtentScrollController();
    _pickerController.addListener(_scrollListener);
    final ChatNotifier = ref.read(chatNotifierProvider);
    ChatNotifier.addPostedPhoto(widget.pageController, _pickerController, widget.timelineItems);

    _initializeCamera();
    // listenToCameraEventを呼び出す
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

    chatConnection.listenToRoomCount(context);
  }


  void _updateMapToSelectedItem(List<List<TimelineItem>> groupedItems, int mapIndex) {
    int groupIndex = _pickerController.selectedItem;

    // 範囲外アクセスを防ぐ
    if (groupIndex >= 0 && groupIndex < groupedItems.length) {
      // ここで選択されているグループ内のアイテムを取得
      List<TimelineItem> selectedGroup = groupedItems[groupIndex];
      print("selectedGroup = $selectedGroup");

      // // 新しいグループの現在の選択されたアイテムのインデックスを取得
      // int newSelectedIndex = _horizontalIndex;
      //
      // // インデックスが新しいグループの範囲を超えていれば、最後のアイテムのインデックスを設定
      // if (newSelectedIndex >= selectedGroup.length) {
      //   newSelectedIndex = selectedGroup.length - 1;
      // }
      // _selectedHorizontalIndex = newSelectedIndex;
      //
      // // _selectedHorizontalIndexが範囲外の場合の処理
      // if (_selectedHorizontalIndex >= selectedGroup.length) {
      //   _selectedHorizontalIndex = 0;
      // }

      TimelineItem selectedItem = selectedGroup[mapIndex];
      print("selectedItem = $selectedItem");
      print("Selected Item ID after stopped scrolling: ${selectedItem.id}");

      // Get the lat and lng of the selected item
      double lat = selectedItem.lat;
      double lng = selectedItem.lng;

      // Update the map location
      MapController.instance.updateMapLocation(lat, lng);
    } else {
      print("Selected group index out of range: $groupIndex");
    }
  }


  void _scrollListener() {
    if (_pickerController.selectedItem == 0) {
      _jumpToTopKey.currentState?.centerButton();
    } else {
      _jumpToTopKey.currentState?.moveButton();
    }
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

    var groupedItems = groupedMap.values.toList();

    for (var items in groupedItems) {
      print(items);
    }

    // マップの値をリストとして返す
    return groupedMap.values.toList();
  }

  void onTapCallback(TimelineItem item, int index) {
    scrollToCenter(index);
  }

  void scrollToCenter(int index) {
    final Duration duration = Duration(milliseconds: 300);
    final Curve curve = Curves.easeInOut;

    _pickerController.animateToItem(
      index,
      duration: duration,
      curve: curve,
    );
  }


  // void onCameraButtonPressed() {
  //   print("Camera button pressed!");
  //   // ここにカメラボタンが押されたときの処理を追加できます
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        final items = ref.watch(timelineAddProvider);
        ref.watch(chatNotifierProvider);
        List<List<TimelineItem>> groupedItemsList = groupItemsByGroupId(items);



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

            Positioned(
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
                      int index = _pickerController.selectedItem;
                      List<List<TimelineItem>> groupedItems = groupItemsByGroupId(items);
                      String groupID = groupedItemsList[index].first.groupID;
                      int selectedItemIndex = selectedItemsMap[groupID] ?? 0;
                      _updateMapToSelectedItem(groupedItems, selectedItemIndex);

                      setState(() {
                        centralRowIndex = index;
                        print("Central Row Index updated to: $centralRowIndex");
                      });
                    }
                    return true;
                  },
                    child: ListWheelScrollView(
                    controller: _pickerController,
                    itemExtent: MediaQuery.of(context).size.height / 10,
                    diameterRatio: 1.25,
                    onSelectedItemChanged: (int index) {
                      print('_pickerController selected item: $index');
                      if (index > items.length - 5) {
                        ref.read(timelineAddProvider.notifier).addMoreItems();
                      }
                    },
                    // magnification: 1.3,
                    // useMagnifier: false,
                    physics: FixedExtentScrollPhysics(),
                    children: List<Widget>.generate(
                      groupedItemsList.length, // groupIDごとにグルーピングされたアイテムのリストのリスト
                          (int index) {
                            return Center(
                              child: HorizontalGroupedItems(
                                itemsInGroup: groupedItemsList[index],
                                size: MediaQuery.of(context).size,
                                controller: _scrollController,
                                currentIndex: index,
                                pickerController: _pickerController,
                                items: items,
                                onTapCallback: (TimelineItem item) => onTapCallback(item, index),
                                // onCameraButtonPressed: onCameraButtonPressed,
                                centralRowIndex: centralRowIndex,
                                selectedItemsMap: selectedItemsMap,
                                onHorizontalIndexChanged: (int newIndex) {
                                  String groupID = groupedItemsList[index].first.groupID;
                                  selectedItemsMap[groupID] = newIndex;
                                  print("selectedItemsMap[groupID] = $newIndex");
                                },
                              ),
                            );
                      },
                    ),
                  ),
                ),
              ),
            ),
            JumpToTop(
              key: _jumpToTopKey,
              size: Size(widget.size.width, widget.size.height),
              showBadge: showCameraBadge,
              onPressed: () {
                // リストを最上部にスクロール
                _pickerController.animateToItem(
                  0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );

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
              },
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
    super.dispose();
  }

}