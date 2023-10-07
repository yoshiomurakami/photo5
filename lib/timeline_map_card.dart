import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timeline_providers.dart';
import 'chat_connection.dart';
import 'dart:ui' as ui;
import 'dart:async';


class TimelineCard extends StatefulWidget {
  final TimelineItem item;
  final Size size;
  final FixedExtentScrollController controller;
  final int currentIndex;
  final FixedExtentScrollController pickerController;
  final List<TimelineItem> items;
  final VoidCallback? onTapCallback;

  TimelineCard({
    Key? key,
    required this.item,
    required this.size,
    required this.controller,
    required this.currentIndex,
    required this.pickerController,
    required this.items,
    required this.onTapCallback,
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
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => FullScreenImageViewer(
        //       items: widget.items,
        //       initialIndex: widget.controller.selectedItem,
        //       controller: widget.controller,  // controllerを渡す
        //     ),
        //   ),
        // );
        if (widget.onTapCallback != null) {
          widget.onTapCallback!();
        }
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
                        borderRadius: BorderRadius.circular(16.0),
                        child: Image.network(
                          'https://photo5.world/${currentItem.imageFilename}',
                          fit: BoxFit.scaleDown,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.transparent,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
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

  Future<ui.Image> _loadImage(String imageUrl) async {
    final Completer<ui.Image> completer = Completer();
    final NetworkImage image = NetworkImage(imageUrl);
    image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
            (ImageInfo image, bool synchronousCall) {
          final ui.Image img = image.image;
          completer.complete(img);
        },
      ),
    );
    return completer.future;
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




