import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:photo5/timeline_map_display.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flag/flag.dart';


final selectedAlbumIndexesProvider = StateProvider<Map<String, int>>((ref) {
  return {}; // 初期状態
});

Map<String, int> selectedAlbumIndexes = {};

class AlbumTimeLine {
  final Key key;
  final String id;
  final String systemId; // 追加
  final int sequenceNumber; // 追加
  final String createdAt; // 追加
  final String imagePath;
  final String thumbnailPath;
  final String userID;
  final String country;
  final double lat;
  final double lng;
  final String groupID;
  final String localtime;
  final String? geocodedCountry;
  final String? geocodedCity;
  final int statement; // 追加

  AlbumTimeLine({
    required this.key,
    required this.id,
    required this.systemId, // 追加
    required this.sequenceNumber, // 追加
    required this.createdAt, // 追加
    required this.imagePath,
    required this.thumbnailPath,
    required this.userID,
    required this.country,
    required this.lat,
    required this.lng,
    required this.groupID,
    required this.localtime,
    this.geocodedCountry,
    this.geocodedCity,
    required this.statement, // 追加
  });

  factory AlbumTimeLine.fromJson(Map<String, dynamic> json) {
    return AlbumTimeLine(
      key: ValueKey(json['id'].toString()),
      id: json['id'].toString(),
      systemId: json['systemId'] ?? '', // デフォルト値設定
      sequenceNumber: json['sequenceNumber'] ?? 0, // デフォルト値設定
      createdAt: json['createdAt'] ?? '', // デフォルト値設定
      imagePath: json['imageFilename'] ?? '', // デフォルト値を空文字列に設定
      thumbnailPath: json['thumbnailFilename'] ?? '', // デフォルト値を空文字列に設定
      userID: json['userID'] ?? '', // デフォルト値を空文字列に設定
      country: json['country'] ?? '', // デフォルト値を空文字列に設定
      lat: double.tryParse(json['lat']?.toString() ?? '0.0') ?? 0.0,
      lng: double.tryParse(json['lng']?.toString() ?? '0.0') ?? 0.0,
      groupID: json['groupID'] ?? '', // デフォルト値を空文字列に設定
      localtime: json['localtime'] ?? DateTime.now().toString(), // デフォルト値設定
      geocodedCountry: json['geocodedCountry'], // null許容
      geocodedCity: json['geocodedCity'], // null許容
      statement: json['statement'] ?? 0, // デフォルト値設定
    );
  }

}


Future<List<AlbumTimeLine>> fetchAlbumDataFromDB() async {
  final dbPath = await getDatabasesPath();
  final path = p.join(dbPath, 'images_database.db');
  final database = openDatabase(path);

  final List<Map<String, dynamic>> maps = await (await database).query('images', orderBy: 'groupID DESC');

  List<AlbumTimeLine> albumList = [];

  for (var map in maps) {
    AlbumTimeLine album = AlbumTimeLine.fromJson(map);
    // imagePathが空でないアルバムのみをリストに追加
    if (album.imagePath.isNotEmpty) {
      albumList.add(album);
    }
  }

  return albumList;
}


class AlbumTimeLineView extends StatefulWidget {
  final Size size;
  final List<AlbumTimeLine> albumList;
  final String lastSelectedAlbumGroupID;
  final Function(String) updateAlbumGroupIDCallback;
  // final void Function(AlbumTimeLine)? onTapCallback;

  const AlbumTimeLineView({super.key,
    required this.size,
    required this.albumList,
    required this.lastSelectedAlbumGroupID,
    required this.updateAlbumGroupIDCallback,
    // this.onTapCallback,

  });

  @override
  AlbumTimeLineViewState createState() => AlbumTimeLineViewState();
}

class AlbumTimeLineViewState extends State<AlbumTimeLineView> {
  late FixedExtentScrollController _scrollController;
  late Map<String, List<AlbumTimeLine>> groupedAlbums;
  late List<String> groupKeys;
  int centralRowIndex = 0;
  late Map<String, int> selectedIndexes; // 追加

  // 選択されたアルバムアイテムを追跡するValueNotifier
  ValueNotifier<AlbumTimeLine?> selectedAlbumItemNotifier = ValueNotifier<AlbumTimeLine?>(null);


  @override
  void initState() {
    super.initState();
    // _scrollController = FixedExtentScrollController();
    groupedAlbums = groupAlbumsByGroupId(widget.albumList);
    groupKeys = groupedAlbums.keys.toList();
    selectedIndexes = {}; // 空のMapで初期化
    // 最新のアイテムをデフォルトとして設定
    int initialIndex = 0;  // 最新のアイテム（リストの末尾）

    // lastSelectedAlbumGroupIDが有効な場合、そのインデックスを使用
    if (groupKeys.contains(widget.lastSelectedAlbumGroupID)) {
      initialIndex = groupKeys.indexOf(widget.lastSelectedAlbumGroupID);
    }
    _scrollController = FixedExtentScrollController(initialItem: initialIndex);

    List<AlbumTimeLine> selectedGroup = groupedAlbums[groupKeys[initialIndex]]!;
    int selectedItemIndex = selectedAlbumIndexes[groupKeys[initialIndex]] ?? 0;
    AlbumTimeLine selectedItem = selectedGroup[selectedItemIndex];
    debugPrint("MapUpdateService = $selectedItem");
    MapUpdateService.updateMapLocation(selectedItem);

    _initializeAlbums();
  }

  void _initializeAlbums() {
    groupedAlbums = groupAlbumsByGroupId(widget.albumList);
    groupKeys = groupedAlbums.keys.toList();
    selectedIndexes = {};
    int initialIndex = groupKeys.contains(widget.lastSelectedAlbumGroupID) ? groupKeys.indexOf(widget.lastSelectedAlbumGroupID) : 0;
    _scrollController = FixedExtentScrollController(initialItem: initialIndex);
    // 初期選択アイテムを設定
    selectedAlbumItemNotifier.value = groupedAlbums[groupKeys[initialIndex]]?.first;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final selectedAlbumIndexes = ref.watch(selectedAlbumIndexesProvider);
        debugPrint("selectedAlbumIndexes = $selectedAlbumIndexes");

        // selectedAlbumIndexes に基づいて centralRowIndex を更新
        for (var groupID in groupKeys) {
          selectedIndexes[groupID] = selectedAlbumIndexes[groupID] ?? 0;
        }

        return Stack(
          children: <Widget>[
            NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollEndNotification) {
                  int index = _scrollController.selectedItem;
                  List<AlbumTimeLine> selectedGroup = groupedAlbums[groupKeys[index]]!;
                  int selectedItemIndex = selectedIndexes[groupKeys[index]] ?? 0;
                  ref.read(selectedAlbumIndexesProvider.notifier).state[groupKeys[index]] = selectedItemIndex;
                  AlbumTimeLine selectedItem = selectedGroup[selectedItemIndex];
                  selectedAlbumItemNotifier.value = selectedItem;
                  MapUpdateService.updateMapLocation(selectedItem);
                }
                return true;
              },
              child: ListWheelScrollView.useDelegate(
                controller: _scrollController,
                itemExtent: MediaQuery.of(context).size.width * 0.2,
                diameterRatio: 1.25,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (int index) {
                  setState(() {
                    centralRowIndex = index;
                    selectedIndexes[groupKeys[index]] = selectedAlbumIndexes[groupKeys[index]] ?? 0;
                  });
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        selectedAlbumItemNotifier.value = groupedAlbums[groupKeys[index]]![selectedIndexes[groupKeys[index]] ?? 0];
                      },
                      child: HorizontalAlbumGroup(
                        albumsInGroup: groupedAlbums[groupKeys[index]]!,
                        size: MediaQuery.of(context).size,
                        currentIndex: selectedIndexes[groupKeys[index]] ?? 0,
                        onHorizontalIndexChanged: (newIndex) {
                          setState(() {
                            selectedIndexes[groupKeys[index]] = newIndex;
                            ref.read(selectedAlbumIndexesProvider.notifier).state[groupKeys[index]] = newIndex;
                          });
                        },
                      ),
                    );
                  },
                  childCount: groupedAlbums.length,
                ),
              ),
            ),
            // Positioned(
            //   bottom: widget.size.height * 0.25 + widget.size.width * 0.2,
            //   left: widget.size.width * 0.3,
            //   // right: widget.size.width * 0.15,
            ValueListenableBuilder<AlbumTimeLine?>(
              valueListenable: selectedAlbumItemNotifier,
              builder: (context, selectedItem, child) {
                if (selectedItem == null || selectedItem.localtime.split(' ').length < 5) {
                  return const SizedBox();
                }

                // localtimeを分割して必要な部分を取得
                final timeParts = selectedItem.localtime.split(' ');

                return Positioned(
                  bottom: widget.size.height * 0.3 + widget.size.width * 0.1 + 5, // ウィジェットの高さの半分上方向に移動
                  left: widget.size.width * 0.33,
                  // right: widget.size.width * -0.2,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        painter: BubblePainter(),

                        child: Container(
                          width: widget.size.width * 0.7,
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 20, // 固定の高さを設定
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    timeParts[4], // 時間：分だけを表示
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                height: 20, // 固定の高さを設定
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    selectedItem.geocodedCountry ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 20, // 固定の高さを設定
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    selectedItem.geocodedCity ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                height: 20, // 固定の高さを設定
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${timeParts[0]} ${timeParts[1]} ${timeParts[2]} ${timeParts[3]}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: -15, // 上部に半分ほど重ねる
                        left: (widget.size.width * 0.7) / 2 - 15, // ウィジェットの中央に配置
                        child: buildFlagWidget(selectedItem.country),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            selectedAlbumItemNotifier.value = null; // 詳細情報ウィジェットを閉じる
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),


            // ),
          ],
        );
      },
    );
  }





  void updateMapToSelectedAlbumItem(List<AlbumTimeLine> selectedGroup, int albumIndex) {
    if (selectedGroup.isNotEmpty && albumIndex >= 0 && albumIndex < selectedGroup.length) {
      AlbumTimeLine selectedAlbumItem = selectedGroup[albumIndex];
      debugPrint("selectedAlbumItem = $selectedAlbumItem");
      double lat = selectedAlbumItem.lat;
      double lng = selectedAlbumItem.lng;
      debugPrint("lat = $lat / lng = $lng");
      // Update the map location
      MapController.instance.updateMapLocation(lat, lng);

    } else {
      debugPrint("Selected album item index out of range: $albumIndex");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}




// タイムラインのHorizontalGroupedItemsに対応するアルバム専用ウィジェット
class HorizontalAlbumGroup extends StatefulWidget {
  final List<AlbumTimeLine> albumsInGroup;
  final Size size;
  final int currentIndex;
  final ValueChanged<int> onHorizontalIndexChanged;
  final void Function(AlbumTimeLine, int)? onTapCallback; // 型を変更

  const HorizontalAlbumGroup({super.key,
    required this.albumsInGroup,
    required this.size,
    required this.currentIndex,
    required this.onHorizontalIndexChanged,
    this.onTapCallback,
  });

  @override
  HorizontalAlbumGroupState createState() => HorizontalAlbumGroupState();
}


class HorizontalAlbumGroupState extends State<HorizontalAlbumGroup> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // viewportFractionに0.2を設定することで、画面の幅の20%のサイズのアイテムを表示します。
    _pageController = PageController(
      initialPage: widget.currentIndex,
      viewportFraction: 0.165,
    );
    _pageController.addListener(() {
      int newIndex = _pageController.page!.round();
      if (newIndex != widget.currentIndex) {
        widget.onHorizontalIndexChanged(newIndex);
      }
    });

  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // PageViewでサムネイルを表示
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.albumsInGroup.length,
      itemBuilder: (context, index) {

        // サムネイルを生成
        return _buildAlbumItemWidget(context, widget.albumsInGroup[index], index);
      },
    );
  }

  Widget _buildAlbumItemWidget(BuildContext context, AlbumTimeLine album, int index) {
    double imageSize = MediaQuery.of(context).size.width * 0.2;

    return GestureDetector(
      onTap: () {
        if (widget.onTapCallback != null) {
          widget.onTapCallback!(album, index);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(album.thumbnailPath)),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(widget.size.width * 0.04),
        ),
      ),
    );
  }

}



// アルバムデータのグループ化
Map<String, List<AlbumTimeLine>> groupAlbumsByGroupId(List<AlbumTimeLine> albums) {
  Map<String, List<AlbumTimeLine>> groupedAlbums = {};
  for (var album in albums) {
    if (!groupedAlbums.containsKey(album.groupID)) {
      groupedAlbums[album.groupID] = [];
    }
    groupedAlbums[album.groupID]!.add(album);
  }
  debugPrint("groupedAlbums = $groupedAlbums");
  return groupedAlbums;
}



Widget buildFlagWidget(String countryCode) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white, // 背景を白で設定
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.black, // アウトラインの色
        width: 2.0, // アウトラインの太さ
      ),
    ),
    child: ClipOval(
      child: Container(
        color: Colors.white, // ここも白で塗りつぶし
        height: 30,
        width: 30,
        child: Flag.fromString(
          countryCode,
          height: 30,
          width: 30,
          fit: BoxFit.cover,
          flagSize: FlagSize.size_1x1,
        ),
      ),
    ),
  );
}