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
  final VoidCallback? onCameraButtonPressed;
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
    this.onCameraButtonPressed,
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

  const TimelineCard({
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




  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap: () {
      //   if (widget.onTapCallback != null) {
      //     widget.onTapCallback!(widget.item);
      //   }
      // },
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
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.18,
                    height: MediaQuery.of(context).size.width * 0.18,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFFFFCC4D),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: const CircleBorder(side: BorderSide(color: Colors.black, width: 1.3)),
                      onPressed: widget.onCameraButtonPressed,
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
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildImageWidget(context, widget.item.thumbnailFilename),
                  ],
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
            placeholder: const AssetImage('assets/placeholder_thumb.png'),
            image: FileImage(snapshot.data!),
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 300),
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
      debugPrint('Image download error: $e');
    }
  }
  return cachedImage;
}





