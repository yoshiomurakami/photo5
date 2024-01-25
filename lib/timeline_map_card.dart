import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
// import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final VoidCallback? onCameraButtonPressed;
  final ValueChanged<int> onHorizontalIndexChanged;
  // final Map<String, int> selectedItemsMap;
  final int centralRowIndex; // 追加
  final ChatNotifier chatNotifier; // ChatNotifier を追加

  HorizontalGroupedItems({
    required this.itemsInGroup,
    required this.size,
    required this.controller,
    required this.currentIndex,
    required this.pickerController,
    required this.items,
    this.onTapCallback,
    this.onCameraButtonPressed,
    required this.onHorizontalIndexChanged,
    // required this.selectedItemsMap,
    required this.centralRowIndex, // 追加
    required this.chatNotifier, // ChatNotifier を引数として追加
  });

  @override
  _HorizontalGroupedItemsState createState() => _HorizontalGroupedItemsState();
}

class _HorizontalGroupedItemsState extends State<HorizontalGroupedItems> {
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
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // void onTapCallback(TimelineItem item) {
  //   print("timeline_map_card.dart__Card was tapped!");
  //   print(item.imageFilename);
  // }

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
                  print("widget.itemsInGroup[index] = $index");
                }
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.0),
                child: TimelineCard(
                  item: widget.itemsInGroup[index],
                  size: widget.size,
                  controller: widget.controller,
                  currentIndex: widget.currentIndex,
                  pickerController: widget.pickerController,
                  items: widget.items,
                  onTapCallback: widget.onTapCallback,
                  onCameraButtonPressed: widget.onCameraButtonPressed,
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
  final VoidCallback? onCameraButtonPressed;

  TimelineCard({
    Key? key,
    required this.item,
    required this.size,
    required this.controller,
    required this.currentIndex,
    required this.pickerController,
    required this.items,
    this.onTapCallback,
    required this.onCameraButtonPressed,
  }) : super(key: key);

  @override
  _TimelineCardState createState() => _TimelineCardState();
}

class _TimelineCardState extends State<TimelineCard> {
  bool isDialogShown = false;
  int? currentSelectedItem;
  TimelineItem? centerItem;  // 追加
  bool isFullScreenMode = false;  // デフォルトは非表示

  @override
  void initState() {
    super.initState();
    currentSelectedItem = widget.currentIndex;
  }




  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap: () {
      //   if (widget.onTapCallback != null) {
      //     widget.onTapCallback!(widget.item);
      //   }
      // },
      child: Container(
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
              child: widget.item.id == "343hg5q0858jwir"
                  ? Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.18,
                      height: MediaQuery.of(context).size.width * 0.18,
                      child: FloatingActionButton(
                        backgroundColor: Color(0xFFFFCC4D),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: CircleBorder(side: BorderSide(color: Colors.black, width: 1.3)),
                        child: Center(
                          child: Text(
                            '\u{1F4F8}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              height: 1.0,
                            ),
                          ),
                        ),
                        onPressed: widget.onCameraButtonPressed,
                      ),
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center, // 写真を中央寄せにする
                children: <Widget>[
                  _buildImageWidget(context, widget.item.thumbnailFilename),
                  // SizedBox(width: 10), // 10ピクセルのスペースを追加
                  // _buildImageWidget(context, widget.item.thumbnailFilename),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


Widget _buildImageWidget(BuildContext context, String thumbnailFilename) {
  double imageSize = MediaQuery.of(context).size.width * 0.2;

  // 画像の読み込みが始まる前にグレーのサムネイルを表示
  return FutureBuilder<File>(
    future: _getCachedImage(thumbnailFilename),
    builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
      if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
        // フェードイン効果で画像を表示
        return _imageContainer(
          imageSize,
          FadeInImage(
            placeholder: AssetImage('assets/placeholder_thumb.png'),
            image: FileImage(snapshot.data!),
            fit: BoxFit.cover,
            fadeInDuration: Duration(milliseconds: 300),
          ),
        );
      } else {
        // ロード中の表示（グレーのサムネイル）
        return _imageContainer(imageSize, _buildGreyThumbnail(imageSize));
      }
    },
  );
}

Widget _buildGreyThumbnail(double size) {
  return Opacity(
    opacity: 0,  // 透明度を50%に設定
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(size * 0.1),
      ),
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



Future<File> _getCachedImage(String thumbnailFilename) async {
  String cacheDirPath = (await getTemporaryDirectory()).path;
  File cachedImage = File('$cacheDirPath/$thumbnailFilename');

  if (!cachedImage.existsSync()) {
    // ネットワークから画像をダウンロードし、キャッシュに保存
    try {
      var response = await http.get(Uri.parse('https://photo5.world/$thumbnailFilename'));
      if (response.statusCode == 200) {
        await cachedImage.writeAsBytes(response.bodyBytes);
      }
    } catch (e) {
      // エラーハンドリング
      print('Image download error: $e');
    }
  }
  return cachedImage;
}



// Future<void> _downloadAndCacheImage(String thumbnailFilename, File imageFile) async {
//   try {
//     var response = await http.get(Uri.parse('https://photo5.world/$thumbnailFilename'));
//     if (response.statusCode == 200) {
//       await imageFile.writeAsBytes(response.bodyBytes);
//     }
//   } catch (e) {
//     print('Image download error: $e');
//   }
// }
//
//
// Future<String?> _findOrDownloadImage(String thumbnailFilename) async {
//   String cacheDirPath = (await getTemporaryDirectory()).path;
//   File imageFile = File('$cacheDirPath/$thumbnailFilename');
//
//   if (!imageFile.existsSync()) {
//     // ネットワークから画像をダウンロードし、キャッシュに保存
//     try {
//       var response = await http.get(Uri.parse('https://photo5.world/$thumbnailFilename'));
//       if (response.statusCode == 200) {
//         await imageFile.writeAsBytes(response.bodyBytes);
//         return imageFile.path;
//       }
//     } catch (e) {
//       // ダウンロード失敗時のエラー処理
//       print('Image download error: $e');
//     }
//   }
//   return imageFile.existsSync() ? imageFile.path : null;
// }







class FullScreenImageViewer extends ConsumerWidget {
  final List<TimelineItem> items;
  final int initialIndex;
  final FixedExtentScrollController controller;
  final VoidCallback onTap; // タップ時のコールバック
  final VoidCallback? onNewPhotoReceived;

  FullScreenImageViewer({
    required this.items,
    required this.initialIndex,
    required this.controller,
    required this.onTap,
    this.onNewPhotoReceived,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _FullScreenImageViewerStateful(
      items: items,
      initialIndex: initialIndex,
      controller: controller,
      onTap: onTap,
      onNewPhotoReceived: onNewPhotoReceived,
    );
  }
}

class _FullScreenImageViewerStateful extends ConsumerStatefulWidget {
  final List<TimelineItem> items;
  final int initialIndex;
  final FixedExtentScrollController controller;
  final VoidCallback onTap; // タップ時のコールバック
  final VoidCallback? onNewPhotoReceived;

  _FullScreenImageViewerStateful({
    required this.items,
    required this.initialIndex,
    required this.controller,
    required this.onTap,
    this.onNewPhotoReceived,
  });

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends ConsumerState<_FullScreenImageViewerStateful> {
  PageController _scrollController = PageController();

  @override
  void initState() {
    super.initState();
    _scrollController = PageController(initialPage: widget.initialIndex);
    final chatNotifier = ref.read(chatNotifierProvider);
    chatNotifier.fullScreenImageViewerController = _scrollController;
  }

  @override
  void dispose() {
    Future.delayed(Duration.zero, () {
      final chatNotifier = ref.read(chatNotifierProvider);
      chatNotifier.fullScreenImageViewerController = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Material(
        color: Colors.transparent,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: PageView.builder(
                controller: _scrollController,
                itemCount: widget.items.length,
                scrollDirection: Axis.vertical,
                onPageChanged: (index) {
                  int step = index - widget.controller.selectedItem;
                  scrollTimeline(widget.controller, step, widget.items);
                },
                itemBuilder: (context, index) {
                  TimelineItem currentItem = widget.items[index];
                  return Container(
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: Colors.white, width: 2.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.0),
                        child: Image.network(
                          'https://photo5.world/${currentItem.imageFilename}',
                          fit: BoxFit.scaleDown,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(width: 0, height: 0);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }






  Widget buildImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white, width: 3.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Image.network(
          'https://photo5.world/${widget.items[widget.controller.selectedItem].imageFilename}',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}



Future<TimelineItem> scrollTimeline(FixedExtentScrollController controller, int step, List<TimelineItem> items) async {
  int currentItem = controller.selectedItem;
  int targetItem = currentItem + step;

  await controller.animateToItem(
      targetItem,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut
  );

  // アニメーションが完了した後に中央のアイテムを返す
  int centerIndex = controller.selectedItem;
  return items[centerIndex];
}




