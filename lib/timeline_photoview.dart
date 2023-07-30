import 'package:flutter/material.dart';

class TimelineFullScreenImagePage extends StatefulWidget {
  final List<String> imageFilenames;
  final int initialIndex;
  final Key key;

  TimelineFullScreenImagePage(this.imageFilenames, this.initialIndex, {required this.key}): super(key: key);

  @override
  _TimelineFullScreenImagePageState createState() => _TimelineFullScreenImagePageState();
}

class _TimelineFullScreenImagePageState extends State<TimelineFullScreenImagePage> {
  late PageController _pageController;
  Widget? imageWidget;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex)
      ..addListener(() {
        currentIndex = _pageController.page!.round();
      });
    currentIndex = widget.initialIndex;
    imageWidget = buildImageWidget();
  }

  Widget buildImageWidget() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.imageFilenames.length,
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
              child: Icon(Icons.arrow_back, color: Colors.white),
              backgroundColor: Colors.transparent,
              onPressed: () {
                Navigator.pop(context, currentIndex);
              },
            ),
          ),
        ],
      ),
    );
  }
}
