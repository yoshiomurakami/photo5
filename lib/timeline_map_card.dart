import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'timeline_providers.dart';
import 'chat_connection.dart';
import 'dart:async';


class HorizontalGroupedItems extends StatefulWidget {
  final List<TimelineItem> itemsInGroup;
  final Size size;
  final FixedExtentScrollController controller;
  final int currentIndex;
  final FixedExtentScrollController pickerController;
  final List<TimelineItem> items;
  final void Function(TimelineItem)? onTapCallback;
  // final VoidCallback? onCameraButtonPressed;
  final ValueChanged<int> onHorizontalIndexChanged;
  // final Map<String, int> selectedItemsMap;
  final int centralRowIndex; // 追加
  final ChatNotifier chatNotifier; // ChatNotifier を追加

  const HorizontalGroupedItems({super.key,
    required this.itemsInGroup,
    required this.size,
    required this.controller,
    required this.currentIndex,
    required this.pickerController,
    required this.items,
    this.onTapCallback,
    // this.onCameraButtonPressed,
    required this.onHorizontalIndexChanged,
    // required this.selectedItemsMap,
    required this.centralRowIndex, // 追加
    required this.chatNotifier, // ChatNotifier を引数として追加
  });

  @override
  HorizontalGroupedItemsState createState() => HorizontalGroupedItemsState();
}

class HorizontalGroupedItemsState extends State<HorizontalGroupedItems> {
  late PageController _scrollController;
  int centralRowIndex = 0;

  void _onScrollChange() {
    int newIndex = _scrollController.page!.round();
    String groupID = widget.itemsInGroup.first.groupID;
    widget.chatNotifier.selectedItemsMap[groupID] = newIndex; // ChatNotifier を使用するように変更
    if (widget.currentIndex == widget.centralRowIndex) {
      widget.onHorizontalIndexChanged(newIndex);
    }
  }

  void _updateScrollPosition() {
    String groupID = widget.itemsInGroup.first.groupID;
    int newSelectedIndex = widget.chatNotifier.selectedItemsMap[groupID] ?? 0;

    if (_scrollController.hasClients && _scrollController.page!.round() != newSelectedIndex) {
      _scrollController.animateToPage(
        newSelectedIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // groupID を取得
    String groupID = widget.itemsInGroup.first.groupID;

    // selectedItemsMap から現在のグループの最後に選択されたアイテムのインデックスを取得
    int initialPageIndex = widget.chatNotifier.selectedItemsMap[groupID] ?? 0;

    // PageController を初期化。以前のスクロール位置に基づいて initialPage を設定
    _scrollController = PageController(
      initialPage: initialPageIndex,
      viewportFraction: 0.165,
    );
    _scrollController.addListener(_onScrollChange);

    // ChatNotifierからの変更をリッスンし、PageControllerを更新
    widget.chatNotifier.addListener(() {
      String groupID = widget.itemsInGroup.first.groupID;
      int newPageIndex = widget.chatNotifier.selectedItemsMap[groupID] ?? 0;
      if (_scrollController.hasClients) {
        _scrollController.jumpToPage(newPageIndex);
      }
    });

    // ChatNotifierが更新されたときに呼ばれるリスナーを追加
    widget.chatNotifier.addListener(_updateScrollPosition);
  }

  @override
  void dispose() {
    // リスナーを削除
    widget.chatNotifier.removeListener(_updateScrollPosition);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // return LayoutBuilder(
    //   builder: (context, constraints) {
        // if (widget.itemsInGroup.length == 1) {
        //   return GestureDetector(
        //     onTap: () {
        //       if (widget.onTapCallback != null) {
        //         widget.onTapCallback!(widget.itemsInGroup[0]);
        //       }
        //     },
        //     child: Center(
        //       child: TimelineCard(
        //         item: widget.itemsInGroup[0],
        //         size: widget.size,
        //         controller: widget.controller,
        //         currentIndex: widget.currentIndex,
        //         pickerController: widget.pickerController,
        //         items: widget.items,
        //         onTapCallback: widget.onTapCallback,
        //         onCameraButtonPressed: widget.onCameraButtonPressed,
        //       ),
        //     ),
        //   );
        // }

        return PageView.builder(
          controller: _scrollController,
          itemCount: widget.itemsInGroup.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                if (widget.onTapCallback != null) {
                  widget.onTapCallback!(widget.itemsInGroup[index]);
                }
              },
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
                  // onCameraButtonPressed: widget.onCameraButtonPressed,
                ),
              ),
            );
          },
        );
      // },
    // );
  }

}






class TimelineCard extends StatefulWidget {
  final TimelineItem item;
  final Size size;
  final FixedExtentScrollController controller;
  final int currentIndex;
  final FixedExtentScrollController pickerController;
  final List<TimelineItem> items;
  final void Function(TimelineItem)? onTapCallback;
  // final VoidCallback? onCameraButtonPressed;

  const TimelineCard({
    Key? key,
    required this.item,
    required this.size,
    required this.controller,
    required this.currentIndex,
    required this.pickerController,
    required this.items,
    this.onTapCallback,
    // required this.onCameraButtonPressed,
  }) : super(key: key);

  @override
  TimelineCardState createState() => TimelineCardState();
}

class TimelineCardState extends State<TimelineCard> {
  bool isDialogShown = false;
  int? currentSelectedItem;
  TimelineItem? centerItem;  // 追加
  bool isFullScreenMode = false;  // デフォルトは非表示

  @override
  void initState() {
    super.initState();
    currentSelectedItem = widget.currentIndex;
  }

  // void _showFullSizeImage(BuildContext context, String imageUrl) {
  //   String imageFilename = imageUrl.split('/').last; // URLからファイル名を取得
  //
  //   showGeneralDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  //     transitionDuration: const Duration(milliseconds: 200),
  //     pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
  //       return Scaffold(
  //         backgroundColor: Colors.transparent,
  //         body: Center(
  //           child: FutureBuilder<File>(
  //             future: _getCachedImage(imageFilename),
  //             builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
  //               if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
  //                 return LayoutBuilder(
  //                   builder: (context, constraints) {
  //                     double maxWidth = constraints.maxWidth;
  //                     double maxHeight = constraints.maxHeight;
  //                     return Center(
  //                       child: ClipRRect(
  //                         // borderRadius: BorderRadius.circular(20), // 角丸の半径を指定
  //                         child: Image.file(
  //                           snapshot.data!,
  //                           fit: BoxFit.cover,
  //                           width: maxWidth,
  //                           height: maxHeight,
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 );
  //               } else {
  //                 return const Center(
  //                   child: CircularProgressIndicator(),
  //                 );
  //               }
  //             },
  //           ),
  //         ),
  //       );
  //     },
  //     transitionBuilder: (context, animation, secondaryAnimation, child) {
  //       return FadeTransition(
  //         opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
  //         child: child,
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTapCallback != null) {
          widget.onTapCallback!(widget.item);
        }
        // _showFullSizeImage(context, 'https://photo5.world/${widget.item.imageFilename}');
      },
      child: Align(
        alignment: Alignment.center,
        child: Container(
          key: ValueKey(widget.item.thumbnailFilename),
          width: widget.size.width * 0.2,
          height: widget.size.width * 0.2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size.width * 0.04),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.size.width * 0.04),
            child: widget.item.systemId == "shootbutton"
                ? Stack(
              children: <Widget>[
                  Align(
                  alignment: Alignment.center,
                    child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.18,
                    height: MediaQuery.of(context).size.width * 0.18,
                      child: FloatingActionButton(
                      backgroundColor: const Color(0xFFFFCC4D),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: const CircleBorder(side: BorderSide(color: Colors.black, width: 1.3)),
                      // onPressed: widget.onCameraButtonPressed,
                      onPressed: () {  },
                        child: const Center(
                          child: Text(
                          '\u{1F4F8}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
                : _buildImageWidget(context, widget.item.thumbnailFilename),
            ),
          ),
        ),
      );
  }
}


Widget _buildImageWidget(BuildContext context, String thumbnailFilename) {
  double imageSize = MediaQuery.of(context).size.width * 0.2;

  return FutureBuilder<File>(
    future: _getCachedImage(thumbnailFilename),
    builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
      if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
        return Stack(
          children: [
            _imageContainer(imageSize, _buildGreyThumbnail(imageSize)),
            _imageContainer(
              imageSize,
              FadeInImage(
                placeholder: const AssetImage('assets/placeholder_thumb_transparent.png'),
                image: FileImage(snapshot.data!),
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 300),
              ),
            ),
          ],
        );
      } else {
        return _imageContainer(imageSize, _buildGreyThumbnail(imageSize));
      }
    },
  );
}

Widget _buildGreyThumbnail(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.grey.withOpacity(0.5),  // 半透明に設定
      borderRadius: BorderRadius.circular(size * 0.1),
    ),
  );
}


Widget _imageContainer(double size, Widget child) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.1),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.1),
      child: child,
    ),
  );
}

Future<File> _getCachedImage(String filename) async {
  String cacheDirPath = (await getTemporaryDirectory()).path;
  File cachedImage = File('$cacheDirPath/$filename');

  if (!cachedImage.existsSync()) {
    // ネットワークから画像をダウンロードし、キャッシュに保存
    try {
      var url = 'https://photo5.world/$filename';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await cachedImage.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      // エラーハンドリング
      debugPrint('Image download error: $e');
      // リトライ処理
      return await _retryFetchImage(filename);
    }
  }
  return cachedImage;
}

Future<File> _retryFetchImage(String filename) async {
  String cacheDirPath = (await getTemporaryDirectory()).path;
  File cachedImage = File('$cacheDirPath/$filename');

  try {
    var url = 'https://photo5.world/$filename';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await cachedImage.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to load image on retry: ${response.statusCode}');
    }
  } catch (e) {
    // リトライのエラーハンドリング
    debugPrint('Image retry download error: $e');
  }

  return cachedImage;
}






