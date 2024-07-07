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

final albumDataProvider = FutureProvider<List<AlbumTimeLine>>((ref) async {
  return await fetchAlbumDataFromDB();
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

class AlbumTimeLineView extends ConsumerStatefulWidget {
  final Size size;
  final List<AlbumTimeLine> albumList;
  final String lastSelectedAlbumGroupID;
  final Function(String) updateAlbumGroupIDCallback;

  const AlbumTimeLineView({
    super.key,
    required this.size,
    required this.albumList,
    required this.lastSelectedAlbumGroupID,
    required this.updateAlbumGroupIDCallback,
  });

  @override
  AlbumTimeLineViewState createState() => AlbumTimeLineViewState();
}

class AlbumTimeLineViewState extends ConsumerState<AlbumTimeLineView> {
  late FixedExtentScrollController _scrollController;
  late Map<String, List<AlbumTimeLine>> groupedAlbums;
  late List<String> groupAlbumKeys;
  int centralRowIndex = 0;
  late Map<String, int> selectedIndexes; // 追加
  ValueNotifier<AlbumTimeLine?> selectedAlbumItemNotifier = ValueNotifier<AlbumTimeLine?>(null);
  bool isRestoringPosition = true; // 追加

  @override
  void initState() {
    super.initState();
    groupedAlbums = {};
    groupAlbumKeys = [];
    selectedIndexes = {};
    _scrollController = FixedExtentScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition();
    });
  }

  @override
  void dispose() {
    if (_scrollController.hasClients) {
      _saveScrollPosition();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      int groupIndex = _scrollController.selectedItem;
      int itemIndex = selectedIndexes[groupAlbumKeys[groupIndex]] ?? 0;
      ref.read(selectedAlbumIndexesProvider.notifier).update((state) {
        state[widget.lastSelectedAlbumGroupID] = groupIndex;
        state['itemIndex_${widget.lastSelectedAlbumGroupID}'] = itemIndex;
        debugPrint('Saved group index: $groupIndex, item index: $itemIndex');
        return state;
      });
    }
  }

  void _restoreScrollPosition() {
    final savedGroupIndex = ref.read(selectedAlbumIndexesProvider)[widget.lastSelectedAlbumGroupID] ?? 0;
    final savedItemIndex = ref.read(selectedAlbumIndexesProvider)['itemIndex_${widget.lastSelectedAlbumGroupID}'] ?? 0;
    debugPrint('Attempting to restore group index: $savedGroupIndex, item index: $savedItemIndex');

    // if (groupAlbumKeys.isNotEmpty && groupedAlbums.isNotEmpty) {
      final isValidGroupIndex = savedGroupIndex >= 0 && savedGroupIndex < groupAlbumKeys.length;
      final isValidItemIndex = isValidGroupIndex && savedItemIndex >= 0 && savedItemIndex < (groupedAlbums[groupAlbumKeys[savedGroupIndex]]?.length ?? 0);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isValidGroupIndex) {
          _scrollController.jumpToItem(savedGroupIndex);
        } else {
          _scrollController.jumpToItem(0); // デフォルト値
        }

        setState(() {
          if (isValidItemIndex) {
            selectedAlbumItemNotifier.value = groupedAlbums[groupAlbumKeys[savedGroupIndex]]?[savedItemIndex];
          } else if (groupedAlbums[groupAlbumKeys[savedGroupIndex]] != null && groupedAlbums[groupAlbumKeys[savedGroupIndex]]!.isNotEmpty) {
            selectedAlbumItemNotifier.value = groupedAlbums[groupAlbumKeys[savedGroupIndex]]!.first;
          }
          debugPrint('Restored group index: $savedGroupIndex, item index: $savedItemIndex');
          isRestoringPosition = false; // 復元が完了したらfalseに設定
          if (selectedAlbumItemNotifier.value != null) {
            MapUpdateService.updateMapLocation(selectedAlbumItemNotifier.value!);
          }
        });
      });
    // } else {
    //   setState(() {
    //     isRestoringPosition = false; // データがない場合でも復元処理を終了
    //   });
    // }
  }


  @override
  Widget build(BuildContext context) {
    final albumDataAsyncValue = ref.watch(albumDataProvider);

    return albumDataAsyncValue.when(
      data: (albumList) {
        groupedAlbums = groupAlbumsByGroupId(albumList);
        groupAlbumKeys = groupedAlbums.keys.toList();
        final selectedAlbumIndexes = ref.watch(selectedAlbumIndexesProvider);
        for (var groupID in groupAlbumKeys) {
          selectedIndexes[groupID] = selectedAlbumIndexes['itemIndex_$groupID'] ?? 0;
        }

        return WillPopScope(
          onWillPop: () async {
            _saveScrollPosition();
            return true;
          },
          child: AnimatedOpacity(
            opacity: isRestoringPosition ? 0 : 1,
            duration: Duration(milliseconds: 300),
            child: Stack(
              clipBehavior: Clip.none, // これを追加
              children: <Widget>[
                NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is ScrollEndNotification) {
                      int index = _scrollController.selectedItem;
                      List<AlbumTimeLine> selectedGroup = groupedAlbums[groupAlbumKeys[index]]!;
                      int selectedItemIndex = selectedIndexes[groupAlbumKeys[index]] ?? 0;
                      ref.read(selectedAlbumIndexesProvider.notifier).update((state) {
                        state[widget.lastSelectedAlbumGroupID] = index;
                        state['itemIndex_${widget.lastSelectedAlbumGroupID}'] = selectedItemIndex;
                        debugPrint('Updated group index: $index, item index: $selectedItemIndex');
                        return state;
                      });
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
                        selectedIndexes[groupAlbumKeys[index]] = selectedAlbumIndexes['itemIndex_${groupAlbumKeys[index]}'] ?? 0;
                        debugPrint("onSelectedItemChanged = ${selectedIndexes[groupAlbumKeys[index]]}");
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        return GestureDetector(
                          // onTap: () {
                          //   selectedAlbumItemNotifier.value = groupedAlbums[groupAlbumKeys[index]]![selectedIndexes[groupAlbumKeys[index]] ?? 0];
                          //   debugPrint("childDelegate: ListWheelChildBuilderDelegate");
                          // },
                          child: HorizontalAlbumGroup(
                            albumsInGroup: groupedAlbums[groupAlbumKeys[index]]!,
                            size: MediaQuery.of(context).size,
                            currentIndex: selectedIndexes[groupAlbumKeys[index]] ?? 0,
                            onHorizontalIndexChanged: (newIndex) {
                              setState(() {
                                selectedIndexes[groupAlbumKeys[index]] = newIndex;
                                ref.read(selectedAlbumIndexesProvider.notifier).update((state) {
                                  state['itemIndex_${groupAlbumKeys[index]}'] = newIndex;
                                  debugPrint('Updated horizontal index for group ${groupAlbumKeys[index]}: $newIndex');
                                  return state;
                                });
                              });
                            },
                          ),
                        );
                      },
                      childCount: groupedAlbums.length,
                    ),
                  ),
                ),
                ValueListenableBuilder<AlbumTimeLine?>(
                  valueListenable: selectedAlbumItemNotifier,
                  builder: (context, selectedItem, child) {
                    if (selectedItem == null || selectedItem.localtime.split(' ').length < 5) {
                      return const SizedBox();
                    }

                    final timeParts = selectedItem.localtime.split(' ');

                    return Positioned(
                      bottom: widget.size.height * 0.25 + 5,
                      left: widget.size.width * 0.15,
                      right: widget.size.width * 0.15,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: CustomPaint(
                              painter: BubblePainter(),
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: widget.size.width * 0.7,
                                ),
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 5),
                                    Text(
                                      '${selectedItem.geocodedCity ?? ''} ${selectedItem.geocodedCountry ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -10,
                            left: 0,
                            right: 0,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: buildFlagWidget(selectedItem.country),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
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
}

// タイムラインのHorizontalGroupedItemsに対応するアルバム専用ウィジェット
class HorizontalAlbumGroup extends StatefulWidget {
  final List<AlbumTimeLine> albumsInGroup;
  final Size size;
  final int currentIndex;
  final ValueChanged<int> onHorizontalIndexChanged;
  final void Function(AlbumTimeLine, int)? onTapCallback; // 型を変更

  const HorizontalAlbumGroup({
    super.key,
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
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.albumsInGroup.length,
      itemBuilder: (context, index) {
        return _buildAlbumItemWidget(context, widget.albumsInGroup[index], index);
      },
    );
  }

  Widget _buildAlbumItemWidget(BuildContext context, AlbumTimeLine album, int index) {
    double imageSize = MediaQuery.of(context).size.width * 0.2;

    return GestureDetector(
      onTap: () {
        debugPrint("Widget _buildAlbumItemWidget");
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
