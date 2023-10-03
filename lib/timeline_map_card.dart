import 'package:flutter/material.dart';
// import 'package:flag/flag.dart';
import 'timeline_providers.dart';


class TimelineCard extends StatefulWidget {
  final TimelineItem item;
  final Size size;
  final FixedExtentScrollController controller;
  final int currentIndex;
  final FixedExtentScrollController pickerController;
  final List<TimelineItem> items;

  TimelineCard({
    Key? key,
    required this.item,
    required this.size,
    required this.controller,
    required this.currentIndex,
    required this.pickerController,
    required this.items,
  }) : super(key: key);

  @override
  _TimelineCardState createState() => _TimelineCardState();
}

class _TimelineCardState extends State<TimelineCard> {
  bool isDialogShown = false;
  int? currentSelectedItem;
  TimelineItem? centerItem;  // 追加

  @override
  void initState() {
    super.initState();
    currentSelectedItem = widget.currentIndex;
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(
              items: widget.items,
              initialIndex: widget.controller.selectedItem,
            ),
          ),
        );
      },
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
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/01.png',
                image: 'https://photo5.world/${widget.item.thumbnailFilename}',
                fit: BoxFit.cover,
                fadeInDuration: Duration(milliseconds: 300),
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class FullScreenImageViewer extends StatefulWidget {
  final List<TimelineItem> items;
  final int initialIndex;

  FullScreenImageViewer({required this.items, required this.initialIndex});

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  PageController _scrollController = PageController();

  @override
  void initState() {
    super.initState();
    _scrollController = PageController(initialPage: widget.initialIndex);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(  // 中央に配置するためのCenterウィジェットを追加
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,  // 画像の横幅をデバイスの90%に設定
          child: PageView.builder(
            controller: _scrollController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              int step = index - widget.controller.selectedItem;  // 新しいインデックスと現在のインデックスの差を取得
              scrollTimeline(widget.controller, step, widget.items);  // 下層のリストを移動させる
            },
            itemBuilder: (context, index) {
              TimelineItem currentItem = widget.items[index];
              return Image.network(
                'https://photo5.world/${currentItem.imageFilename}',
                fit: BoxFit.scaleDown,  // 画像のサイズがコンテナサイズより大きい場合に縮小するように変更
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;

                  return Container(
                    color: Colors.white,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              );
            },
          ),
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






// class FullScreenImageModal extends StatelessWidget {
//   final String imageFilename;
//
//   FullScreenImageModal({required this.imageFilename});
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//
//     return Material(
//       color: Colors.transparent,
//       child: Center(
//         child: Container(
//           width: size.width * 0.9,
//           height: size.height * 0.9,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16.0),
//             image: DecorationImage(
//               image: NetworkImage('https://photo5.world/$imageFilename'),
//               fit: BoxFit.contain,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }




