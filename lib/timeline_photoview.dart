import 'package:flutter/material.dart';


class TimelineFullScreenImagePage extends StatefulWidget {
  final List<String> imageFilenames;
  final int initialIndex;

  TimelineFullScreenImagePage(this.imageFilenames, this.initialIndex);

  @override
  _TimelineFullScreenImagePageState createState() => _TimelineFullScreenImagePageState();
}

class _TimelineFullScreenImagePageState extends State<TimelineFullScreenImagePage> {
  late int currentIndex;  // 現在の画像のインデックスを保持

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  void nextImage() {
    setState(() {
      if (currentIndex < widget.imageFilenames.length - 1) {
        currentIndex++;
      }
    });
  }

  void previousImage() {
    setState(() {
      if (currentIndex > 0) {
        currentIndex--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx > 0) {
            previousImage();
          } else if (details.velocity.pixelsPerSecond.dx < 0) {
            nextImage();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.network(
              'https://photo5.world/${widget.imageFilenames[currentIndex]}',
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
            ),
            Positioned(
              left: 15.0,
              bottom: 15.0,
              child: FloatingActionButton(
                child: Icon(Icons.arrow_back, color: Colors.white),
                backgroundColor: Colors.transparent,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
