import 'package:flutter/material.dart';

class TimelineFullScreenImagePage extends StatefulWidget {
  final List<String> imageFilenames;
  final int initialIndex;

  TimelineFullScreenImagePage(this.imageFilenames, this.initialIndex);

  @override
  _TimelineFullScreenImagePageState createState() => _TimelineFullScreenImagePageState();
}

class _TimelineFullScreenImagePageState extends State<TimelineFullScreenImagePage> {

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
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
    );
  }
}

