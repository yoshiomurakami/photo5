import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
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
    // controller.animateCamera(
    controller.moveCamera(
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
                backgroundColor: buttonText == 'expand_less' ? Colors.white : Colors.transparent,
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
    pickerController.animateToItem(
      tappedRowIndex,
      duration: duration,
      curve: curve,
    );
  }
}






// class MapDisplay extends ConsumerWidget {
//   final LatLng currentLocation;
//   final List<TimelineItem> timelineItems;
//   final Size size;
//   final PageController pageController;
//   // final bool programmaticPageChange;
//   // final Function updateTimeline;
//
//
//   const MapDisplay({super.key,
//     required this.currentLocation,
//     required this.timelineItems,
//     required this.size,
//     required this.pageController,
//     // required this.programmaticPageChange,
//     // required this.updateTimeline,
//   });
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return MapDisplayStateful(
//       currentLocation: currentLocation,
//       timelineItems: timelineItems,
//       size: size,
//       pageController: pageController,
//       // programmaticPageChange: programmaticPageChange,
//       // updateTimeline: updateTimeline,
//     );
//   }
// }

class MapDisplayStateful extends ConsumerStatefulWidget {
  final LatLng currentLocation;
  final List<TimelineItem> timelineItems;
  final Size size;
  final PageController pageController;



  const MapDisplayStateful({super.key,
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
  bool isFullScreenMode = false;
  List<CameraDescription>? _cameras;
  late CameraController _controller;
  ChatConnection chatConnection = ChatConnection();
  final _jumpToTopKey = GlobalKey<JumpToTopState>();
  List<List<TimelineItem>> groupedItemsList = [];  // このように定義
  int centralRowIndex = 0; // 初期値は適宜設定
  bool showNewListWheelScrollView = false;
  List<AlbumTimeLine> _albumList = [];  // アルバムデータを保持するためのリスト
  String _lastSelectedGroupID = 'camera';
  final Map<String, int> _lastSelectedIndexes = {};
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
    final chatNotifier = ref.read(chatNotifierProvider);
    chatNotifier.addPostedPhoto(widget.pageController, _pickerController, widget.timelineItems, chatNotifier.selectedItemsMap, groupItemsByGroupId, toggleTimelineAndAlbum);

    _initializeCamera();

    chatConnection.listenToRoomCount(context);
    chatConnection.newConnetction(context);

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
              padding: const EdgeInsets.only(bottom: 0),
            ),

            Positioned(
              top: widget.size.height * 0.5 - (MediaQuery.of(context).size.height / 8) / 2,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height / 8,
              child: Container(
                color: Colors.white.withOpacity(0.8),
              ),
            ),

            if (!showNewListWheelScrollView)Positioned(
              top: widget.size.height * 0.2,
              bottom: widget.size.height * 0.2,
              left: widget.size.width * -0.18, //0.15
              right: widget.size.width * -0.18, //0.15
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification is ScrollEndNotification) {
                    if (_pickerController.hasClients) {
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
                  onSelectedItemChanged: (int index)  async {
                    if (index + 1 == groupedItemsList.length) {
                      await ref.read(timelineAddProvider.notifier).addMoreItems();
                    }
                    String lastSelectedGroupID = groupedItemsList[index].first.groupID;
                    _lastSelectedIndexes[lastSelectedGroupID] = index;  // ここで最新のインデックスを保存
                  },
                  // magnification: 1.3,
                  // useMagnifier: false,
                  physics: const FixedExtentScrollPhysics(),
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
                              onTapCallback: (TimelineItem item) => ScrollToCenterService.scrollToCenter(_pickerController , index),
                              centralRowIndex: centralRowIndex,
                              chatNotifier: chatNotifier,
                              onHorizontalIndexChanged: (int newIndex) {
                                String groupID = groupedItemsList[index].first.groupID;
                                selectedItemsMap[groupID] = newIndex;
                              },
                            ),
                          );
                    },
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
                        } else {
                          debugPrint("Failed to get the group ID.");
                        }
                      });
                    } else {
                      debugPrint("No available cameras found.");
                    }
                  }
                } else {
                  // リストを最上部にスクロール
                  _pickerController.animateToItem(
                    0,
                    duration: const Duration(milliseconds: 300),
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
        // 対象のアイテムが見つかった場合
        if (targetIndex != -1) {
          // スクロールビューを更新して指定されたアイテムにスクロールする
          _pickerController = FixedExtentScrollController(initialItem: targetIndex);

          // マップ移動
          final chatNotifier = ref.watch(chatNotifierProvider);
          final selectedItemsMap = chatNotifier.selectedItemsMap;
          String groupID = groupedItemsList[targetIndex].first.groupID;
          int selectedItemIndex = selectedItemsMap[groupID] ?? 0;
          TimelineItem selectedItem = groupedItemsList[targetIndex][selectedItemIndex];
          MapUpdateService.updateMapLocation(selectedItem);
        }
      }

      if (showNewListWheelScrollView) {
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
    debugPrint("groupedMapAAA = $groupedMap");
    return groupedMap.values.toList();
  }

  void _loadAlbumData() async {

    // アルバムデータを非同期で取得し、状態を更新
    List<AlbumTimeLine> albumData = await fetchAlbumDataFromDB();

    // 100ミリ秒後にアルバムデータでリストを更新
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _albumList = albumData; // ここでalbumDataは新しいアルバムデータのリストです。
      });
    });
  }

}

