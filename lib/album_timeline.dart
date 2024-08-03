import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:photo5/timeline_map_display.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flag/flag.dart';
import 'package:flutter/scheduler.dart';


final selectedAlbumItemProvider = StateProvider<AlbumTimeLine?>((ref) {
  return null; // 初期値はnull
});

final selectedAlbumIndexesProvider = StateProvider<Map<String, int>>((ref) {
  return {}; // 初期状態
});

final albumDataProvider = FutureProvider<List<AlbumTimeLine>>((ref) async {
  return await fetchAlbumDataFromDB();
});

Map<String, int> selectedAlbumIndexes = {};

// AlbumTimeLine? _lastTappedAlbum;

final lastTappedAlbumProvider = StateProvider<AlbumTimeLine?>((ref) => null);

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
  late Map<String, int> selectedIndexes;
  ValueNotifier<AlbumTimeLine?> selectedAlbumItemNotifier = ValueNotifier<AlbumTimeLine?>(null);
  bool isRestoringPosition = true;
  // AlbumTimeLine? _lastTappedAlbum;

  @override
  void initState() {
    super.initState();
    groupedAlbums = groupAlbumsByGroupId(widget.albumList);
    groupAlbumKeys = groupedAlbums.keys.toList();
    selectedIndexes = {};
    _scrollController = FixedExtentScrollController();

    // スクロールイベントをリスンして、スワイプ移動を検出
    _scrollController.addListener(() {
      if (_scrollController.position.isScrollingNotifier.value) {
        // スワイプが検出されたら lastTappedAlbum をクリア
        ref.read(lastTappedAlbumProvider.notifier).state = null;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition();
    });
  }

  @override
  void didUpdateWidget(covariant AlbumTimeLineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.albumList != oldWidget.albumList) {
      setState(() {
        groupedAlbums = groupAlbumsByGroupId(widget.albumList);
        groupAlbumKeys = groupedAlbums.keys.toList();
        isRestoringPosition = false;
      });
    }
  }

  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      int groupIndex = _scrollController.selectedItem;
      int itemIndex = selectedIndexes[groupAlbumKeys[groupIndex]] ?? 0;
      ref.read(selectedAlbumIndexesProvider.notifier).update((state) {
        state[widget.lastSelectedAlbumGroupID] = groupIndex;
        state['itemIndex_${widget.lastSelectedAlbumGroupID}'] = itemIndex;
        return state;
      });
    }
  }

  void _restoreScrollPosition() {
    final savedGroupIndex = ref.read(selectedAlbumIndexesProvider)[widget.lastSelectedAlbumGroupID] ?? 0;
    final savedItemIndex = ref.read(selectedAlbumIndexesProvider)['itemIndex_${widget.lastSelectedAlbumGroupID}'] ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (groupAlbumKeys.isEmpty || groupedAlbums.isEmpty) {
        setState(() {
          isRestoringPosition = false;
        });
        return;
      }

      final isValidGroupIndex = savedGroupIndex >= 0 && savedGroupIndex < groupAlbumKeys.length;
      final isValidItemIndex = isValidGroupIndex && savedItemIndex >= 0 && savedItemIndex < (groupedAlbums[groupAlbumKeys[savedGroupIndex]]?.length ?? 0);

      if (isValidGroupIndex) {
        _scrollController.jumpToItem(savedGroupIndex);
      } else {
        _scrollController.jumpToItem(0);
      }

      setState(() {
        if (isValidItemIndex) {
          selectedAlbumItemNotifier.value = groupedAlbums[groupAlbumKeys[savedGroupIndex]]?[savedItemIndex];
        } else if (groupedAlbums[groupAlbumKeys[savedGroupIndex]] != null && groupedAlbums[groupAlbumKeys[savedGroupIndex]]!.isNotEmpty) {
          selectedAlbumItemNotifier.value = groupedAlbums[groupAlbumKeys[savedGroupIndex]]!.first;
        }
        isRestoringPosition = false;
        if (selectedAlbumItemNotifier.value != null) {
          MapUpdateService.updateMapLocation(selectedAlbumItemNotifier.value!, true);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _saveScrollPosition();
        return true;
      },
      child: AnimatedOpacity(
        opacity: isRestoringPosition ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollEndNotification) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    int index = _scrollController.selectedItem;
                    List<AlbumTimeLine> selectedGroup = groupedAlbums[groupAlbumKeys[index]]!;
                    int selectedItemIndex = selectedIndexes[groupAlbumKeys[index]] ?? 0;
                    ref.read(selectedAlbumIndexesProvider.notifier).update((state) {
                      state[widget.lastSelectedAlbumGroupID] = index;
                      state['itemIndex_${widget.lastSelectedAlbumGroupID}'] = selectedItemIndex;
                      return state;
                    });
                    AlbumTimeLine selectedItem = selectedGroup[selectedItemIndex];
                    selectedAlbumItemNotifier.value = selectedItem;
                    MapUpdateService.updateMapLocation(selectedItem, true);
                    ref.read(lastTappedAlbumProvider.notifier).state = selectedItem;
                  });
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
                    // _lastTappedAlbum = groupedAlbums[groupAlbumKeys[index]]?[selectedIndexes[groupAlbumKeys[index]] ?? 0];
                  });
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    return HorizontalAlbumGroup(
                      albumsInGroup: groupedAlbums[groupAlbumKeys[index]]!,
                      size: MediaQuery.of(context).size,
                      currentIndex: selectedIndexes[groupAlbumKeys[index]] ?? 0,
                      onHorizontalIndexChanged: (newIndex) {
                        setState(() {
                          selectedIndexes[groupAlbumKeys[index]] = newIndex;
                          ref.read(selectedAlbumIndexesProvider.notifier).update((state) {
                            state['itemIndex_${groupAlbumKeys[index]}'] = newIndex;
                            return state;
                          });
                        });
                      },
                      onTapCallback: (album, albumIndex) {
                        int groupIndex = groupAlbumKeys.indexOf(album.groupID);
                        if (_scrollController.hasClients) {
                          _scrollController.animateToItem(groupIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                        selectedAlbumItemNotifier.value = album;
                      },
                      ref: ref,
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

                // final timeParts = selectedItem.localtime.split(' ');

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
  }
}

class HorizontalAlbumGroup extends StatefulWidget {
  final List<AlbumTimeLine> albumsInGroup;
  final Size size;
  final int currentIndex;
  final ValueChanged<int> onHorizontalIndexChanged;
  final void Function(AlbumTimeLine, int)? onTapCallback;
  final WidgetRef ref;

  const HorizontalAlbumGroup({
    super.key,
    required this.albumsInGroup,
    required this.size,
    required this.currentIndex,
    required this.onHorizontalIndexChanged,
    this.onTapCallback,
    required this.ref,
  });

  @override
  HorizontalAlbumGroupState createState() => HorizontalAlbumGroupState();
}

class HorizontalAlbumGroupState extends State<HorizontalAlbumGroup> {
  late PageController _pageController;
  Map<String, File> imageCache = {};
  Map<String, File> thumbnailCache = {};
  bool isDialogShowing = false;
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    currentPageIndex = widget.currentIndex;
    _pageController = PageController(
      initialPage: widget.currentIndex,
      viewportFraction: 0.23,
    );
    _pageController.addListener(() {
      int newIndex = _pageController.page!.round();
      if (newIndex != currentPageIndex) {
        setState(() {
          currentPageIndex = newIndex;
        });
        widget.onHorizontalIndexChanged(newIndex);
      }
    });
    _cacheImages();

    // Restore the scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedItemIndex = widget.ref.read(selectedAlbumIndexesProvider)['itemIndex_${widget.albumsInGroup[0].groupID}'] ?? 0;
      _pageController.jumpToPage(savedItemIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _cacheImages() async {
    for (var album in widget.albumsInGroup) {
      String thumbnailFilename = album.thumbnailPath.split('/').last;
      thumbnailCache[thumbnailFilename] = await _getImageFile(thumbnailFilename, true);
    }
  }

  Future<File> _getImageFile(String imageFilename, bool isThumbnail) async {
    final dir = isThumbnail ? await getApplicationDocumentsDirectory() : await getTemporaryDirectory();
    final filePath = '${dir.path}/$imageFilename';
    final file = File(filePath);

    if (await file.exists()) {
      return file;
    } else {
      try {
        final url = 'https://photo5.world/$imageFilename';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          return file;
        } else {
          throw Exception('Failed to load image from server: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Failed to load image from server: $e');
      }
    }
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
    String thumbnailFilename = album.thumbnailPath.split('/').last;

    return GestureDetector(
      onTap: () {
        if (widget.onTapCallback != null) {
          widget.onTapCallback!(album, index);
        }
        if (widget.ref.read(lastTappedAlbumProvider) == album) {
          _showFullSizeImage(context, album.imagePath, widget.albumsInGroup, index);
        } else {
          widget.ref.read(lastTappedAlbumProvider.notifier).state = album;
          if (_pageController.hasClients) {
            _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size.width * 0.04),
        ),
        child: thumbnailCache.containsKey(thumbnailFilename)
            ? ClipRRect(
          borderRadius: BorderRadius.circular(widget.size.width * 0.04),
          child: Image.file(
            thumbnailCache[thumbnailFilename]!,
            fit: BoxFit.cover,
            width: imageSize,
            height: imageSize,
          ),
        )
            : FutureBuilder<File>(
          future: _getImageFile(thumbnailFilename, true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              thumbnailCache[thumbnailFilename] = snapshot.data!;
              return ClipRRect(
                borderRadius: BorderRadius.circular(widget.size.width * 0.04),
                child: Image.file(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  width: imageSize,
                  height: imageSize,
                ),
              );
            } else if (snapshot.hasError) {
              return _loadImageFromNetwork(thumbnailFilename, imageSize);
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _loadImageFromNetwork(String imageFilename, double imageSize) {
    final url = 'https://photo5.world/$imageFilename';
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.size.width * 0.04),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: imageSize,
        height: imageSize,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.error,
              color: Colors.red,
            ),
          );
        },
      ),
    );
  }

  void _showFullSizeImage(BuildContext context, String imageUrl, List<AlbumTimeLine> albumsInGroup, int initialIndex) {
    if (isDialogShowing) {
      return;
    }

    isDialogShowing = true;

    PageController pageController = PageController(initialPage: initialIndex);

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
                  itemCount: albumsInGroup.length,
                  itemBuilder: (context, index) {
                    String imageFilename = albumsInGroup[index].imagePath.split('/').last;
                    return FutureBuilder<File>(
                      future: _getImageFile(imageFilename, false),
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
            widget.onHorizontalIndexChanged(finalIndex);
            _pageController.jumpToPage(finalIndex);
          });
        });
      }
    });
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
