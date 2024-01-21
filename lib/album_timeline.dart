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
  final String imagePath;
  final String thumbnailPath;
  final String userId;
  final String country;
  final double lat;
  final double lng;
  final String groupID;
  final String localtime;
  final String? geocodedCountry;
  final String? geocodedCity;

  AlbumTimeLine({
    required this.key,
    required this.id,
    required this.imagePath,
    required this.thumbnailPath,
    required this.userId,
    required this.country,
    required this.lat,
    required this.lng,
    required this.groupID,
    required this.localtime,
    this.geocodedCountry,
    this.geocodedCity,
  });


  factory AlbumTimeLine.fromJson(Map<String, dynamic> json) {
    return AlbumTimeLine(
      key: ValueKey(json['id']),
      id: json['id'].toString(),
      imagePath: json['imagePath'],
      thumbnailPath: json['thumbnailPath'],
      userId: json['userId'],
      country: json['imageCountry'],
      lat: double.tryParse(json['imageLat']) ?? 0.0,
      lng: double.tryParse(json['imageLng']) ?? 0.0,
      groupID: json['groupID'],
      localtime: DateTime.now().toString(), // DBにlocaltimeがない場合は現在時刻を使用
      geocodedCountry: null, // 仮のデフォルト値
      geocodedCity: null, // 仮のデフォルト値
    );
  }

  @override
  String toString() {
    return 'AlbumTimeLine('
        'key: $key, '
        'id: $id, '
        'imagePath: $imagePath, '
        'thumbnailPath: $thumbnailPath, '
        'userId: $userId, '
        'country: $country, '
        'lat: $lat, '
        'lng: $lng, '
        'groupID: $groupID, '
        'localtime: $localtime, '
        'geocodedCountry: $geocodedCountry, '
        'geocodedCity: $geocodedCity'
        ')';
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
    print(album.toString());
  }

  return albumList;
}

class AlbumTimeLineView extends StatefulWidget {
  final Size size;
  final List<AlbumTimeLine> albumList;
  final String lastSelectedAlbumGroupID;
  final Function(String) updateAlbumGroupIDCallback;

  AlbumTimeLineView({
    required this.size,
    required this.albumList,
    required this.lastSelectedAlbumGroupID,
    required this.updateAlbumGroupIDCallback,
  });

  @override
  _AlbumTimeLineViewState createState() => _AlbumTimeLineViewState();
}

class _AlbumTimeLineViewState extends State<AlbumTimeLineView> {
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
    print("MapUpdateService = $selectedItem");
    MapUpdateService.updateMapLocation(selectedItem);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final selectedAlbumIndexes = ref.watch(selectedAlbumIndexesProvider);
        print("selectedAlbumIndexes = $selectedAlbumIndexes");

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
              print("selectedItemIndex!!! = $selectedItemIndex");

              AlbumTimeLine selectedItem = selectedGroup[selectedItemIndex];
              print("selectedItemIndexBB = $selectedItemIndex");
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
                print("最後のグループID = ${groupKeys[index]}");
                String selectedGroupID = groupKeys[index];
                widget.updateAlbumGroupIDCallback(selectedGroupID); // コールバックを呼び出す
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= groupKeys.length) return null;
                return HorizontalAlbumGroup(
                  albumsInGroup: groupedAlbums[groupKeys[index]]!,
                  size: MediaQuery.of(context).size,
                  currentIndex: selectedIndexes[groupKeys[index]] ?? 0,
                  onHorizontalIndexChanged: (newIndex) {
                    setState(() {
                      selectedIndexes[groupKeys[index]] = newIndex;
                      // selectedAlbumIndexes を更新
                      ref.read(selectedAlbumIndexesProvider.notifier).state[groupKeys[index]] = newIndex;
                      print("横 = ${ref.read(selectedAlbumIndexesProvider)}");
                    });
                  },
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
    print("Updating map location for album index: $albumIndex");
    if (selectedGroup.isNotEmpty && albumIndex >= 0 && albumIndex < selectedGroup.length) {
      AlbumTimeLine selectedAlbumItem = selectedGroup[albumIndex];
      print("selectedAlbumItem = $selectedAlbumItem");
      double lat = selectedAlbumItem.lat;
      double lng = selectedAlbumItem.lng;
      print("lat = $lat / lng = $lng");
      // Update the map location
      MapController.instance.updateMapLocation(lat, lng);

    } else {
      print("Selected album item index out of range: $albumIndex");
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

  const HorizontalAlbumGroup({
    required this.albumsInGroup,
    required this.size,
    required this.currentIndex,
    required this.onHorizontalIndexChanged,
  });

  @override
  _HorizontalAlbumGroupState createState() => _HorizontalAlbumGroupState();
}

class _HorizontalAlbumGroupState extends State<HorizontalAlbumGroup> {
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
        return _buildAlbumItemWidget(context, widget.albumsInGroup[index]);
      },
    );
  }

  Widget _buildAlbumItemWidget(BuildContext context, AlbumTimeLine album) {
    // MediaQueryを使用して画面の幅の20%のサイズを計算
    double imageSize = MediaQuery.of(context).size.width * 0.2;

    // サムネイルのコンテナを生成
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5), // 両サイドに少しマージンを設定
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(album.thumbnailPath)),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(widget.size.width * 0.04),
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
  print("groupedAlbums = $groupedAlbums");
  return groupedAlbums;
}
