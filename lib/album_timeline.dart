import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:photo5/timeline_map_display.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';


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
      key: ValueKey(json['id']),
      id: json['id'].toString(),
      systemId: json['systemId'] ?? '', // デフォルト値設定
      sequenceNumber: json['sequenceNumber'] ?? 0, // デフォルト値設定
      createdAt: json['createdAt'] ?? '', // デフォルト値設定
      imagePath: json['imageFilename'],
      thumbnailPath: json['thumbnailFilename'],
      userID: json['userID'],
      country: json['country'],
      lat: double.tryParse(json['lat']) ?? 0.0,
      lng: double.tryParse(json['lng']) ?? 0.0,
      groupID: json['groupID'],
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

  // 結果をAlbumTimeLineのリストに変換
  List<AlbumTimeLine> albumList = List.generate(maps.length, (i) {
    return AlbumTimeLine.fromJson(maps[i]);
  });

  // 取得したデータをコンソールに出力
  for (var album in albumList) {
    debugPrint(album.toString());
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

  @override
  void initState() {
    super.initState();
    // _scrollController = FixedExtentScrollController();
    groupedAlbums = groupAlbumsByGroupId(widget.albumList);
    groupKeys = groupedAlbums.keys.toList();
    selectedIndexes = {}; // 空のMapで初期化
    // lastSelectedAlbumGroupIDからインデックスを計算
    int initialIndex = groupKeys.indexOf(widget.lastSelectedAlbumGroupID);
    if (initialIndex == -1) {
      initialIndex = 0; // もし見つからない場合は、初期インデックスを0に設定
    }
    _scrollController = FixedExtentScrollController(initialItem: initialIndex);

    List<AlbumTimeLine> selectedGroup = groupedAlbums[groupKeys[initialIndex]]!;
    int selectedItemIndex = selectedAlbumIndexes[groupKeys[initialIndex]] ?? 0;
    // ref.read(selectedAlbumIndexesProvider.notifier).state[groupKeys[initialIndex]] = selectedItemIndex;
    AlbumTimeLine selectedItem = selectedGroup[selectedItemIndex];
    debugPrint("MapUpdateService = $selectedItem");
    MapUpdateService.updateMapLocation(selectedItem);
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

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (notification is ScrollEndNotification) {
              int index = _scrollController.selectedItem;
              List<AlbumTimeLine> selectedGroup = groupedAlbums[groupKeys[index]]!;
              // 選択されたアイテムの更新
              int selectedItemIndex = selectedIndexes[groupKeys[index]] ?? 0;
              ref.read(selectedAlbumIndexesProvider.notifier).state[groupKeys[index]] = selectedItemIndex;
              debugPrint("selectedItemIndex!!! = $selectedItemIndex");

              AlbumTimeLine selectedItem = selectedGroup[selectedItemIndex];
              debugPrint("selectedItemIndexBB = $selectedItemIndex");
              MapUpdateService.updateMapLocation(selectedItem);
              // updateMapToSelectedAlbumItem(selectedGroup, selectedItemIndex);
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
                // 現在選択されているグループの選択インデックスを更新
                selectedIndexes[groupKeys[index]] = selectedAlbumIndexes[groupKeys[index]] ?? 0;
                debugPrint("最後のグループID = ${groupKeys[index]}");
                String selectedGroupID = groupKeys[index];
                widget.updateAlbumGroupIDCallback(selectedGroupID); // コールバックを呼び出す
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= groupKeys.length) return null;
                return GestureDetector(
                    onTap: () {
                      // // 現在の中央行を取得
                      // int currentCenterIndex = _scrollController.selectedItem;
                      //
                      // // タップされた行が中央行でない場合、スクロールセンターサービスを呼び出す
                      // if (centralRowIndex != currentCenterIndex) {
                      //   scrollToCenterService.scrollToCenter(_scrollController, index);
                      // } else {
                      //   print("Kick largeImage on Album");
                      // }
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
                      onTapCallback: (AlbumTimeLine album, int tappedItemIndex) {
                        int currentCenterIndex = _scrollController.selectedItem;
                        if (index != currentCenterIndex) {
                          ScrollToCenterService.scrollToCenter(_scrollController, index);
                        } else {
                          // 横位置（行の配列内のindex値）とcurrentIndex値を比較
                          int selectedIndex = selectedIndexes[groupKeys[index]] ?? 0;
                          if (tappedItemIndex == selectedIndex) {
                            debugPrint("OpenTappedItemImagePath=${groupedAlbums[groupKeys[index]]![tappedItemIndex].imagePath}");
                          } else {
                            //tappedItemIndexとselectedIndexの差分のアイテムの幅を横スクロールする。マイナス値であれば左から右へ。プラス値であれば右から左へ。
                            int skip = tappedItemIndex - selectedIndex;
                            if(skip > 0){
                              debugPrint("右から左へ$skip枚分移動");
                            }else{
                              debugPrint("左から右へ${skip * -1}枚分移動");
                            }
                          }
                        }
                      },
                    )


                );
              },
              childCount: groupedAlbums.length,
            ),
          ),
        );
      },
    );
  }


  void updateMapToSelectedAlbumItem(List<AlbumTimeLine> selectedGroup, int albumIndex) {
    debugPrint("Updating map location for album index: $albumIndex");
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
