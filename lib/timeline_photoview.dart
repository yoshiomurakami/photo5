import 'package:flutter/material.dart';
import 'timeline_providers.dart';

class TimelineFullScreenImagePage extends StatefulWidget {
  final List<String> imageFilenames;
  final List<String> itemIds; // IDだけのリストを追加
  final int initialIndex;
  final Key key;
  final Function(List<TimelineItem>) onTimelineItemsAdded;

  TimelineFullScreenImagePage(
      this.imageFilenames,
      this.itemIds,  // この行を追加
      this.initialIndex,
      {required this.key, required this.onTimelineItemsAdded})
      : super(key: key);

  @override
  _TimelineFullScreenImagePageState createState() =>
      _TimelineFullScreenImagePageState();
}


class _TimelineFullScreenImagePageState extends State<TimelineFullScreenImagePage> {
  late PageController _pageController;
  Widget? imageWidget;
  int currentIndex = 0;
  List<String>?  itemIds;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex)
      ..addListener(() {
        currentIndex = _pageController.page!.round();
        print("Current Index Updated: $currentIndex");
      });
    currentIndex = widget.initialIndex;
    imageWidget = buildImageWidget();
    itemIds = List.from(widget.itemIds);  // null check 不要
  }

  Widget buildImageWidget() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.imageFilenames.length,
      onPageChanged: (index) async {
        if (index == widget.imageFilenames.length - 1) {
          print("more timelineItems");
          getMoreTimelineItems().then((newItems) {
            widget.onTimelineItemsAdded(newItems); // コールバックの呼び出し
            // TimelineItemオブジェクトから画像ファイル名を抽出
            List<String> newImageFilenames = newItems.map((item) => item.imageFilename).toList();
            setState(() {
              widget.imageFilenames.addAll(newImageFilenames); // 新しい画像ファイル名を現在のリストに追加
              imageWidget = buildImageWidget(); // これを追加して再構築する
              itemIds!.addAll(newItems.map((item) => item.id.toString()));
            });
          });
        }
      },

      itemBuilder: (context, index) {
        return Image.network(
          'https://photo5.world/${widget.imageFilenames[index]}',
          fit: BoxFit.cover,
          loadingBuilder:(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null ?
                loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        );
      },
    );
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          imageWidget ?? Container(),
          Positioned(
            left: 15.0,
            bottom: 15.0,
            child: FloatingActionButton(
              heroTag: "BackToMao",
              child: Icon(Icons.arrow_back, color: Colors.white),
              backgroundColor: Colors.transparent,
              onPressed: (){
                // String currentItemId = widget.itemIds[currentIndex];
                if (currentIndex < itemIds!.length) {
                  String currentItemId = itemIds![currentIndex];
                  Navigator.pop(context, currentItemId);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
