import 'package:flutter/material.dart';
import 'package:flag/flag.dart';
import 'timeline_providers.dart';

class TimelineCard extends StatelessWidget {
  final TimelineItem item;
  final Size size;
  final FixedExtentScrollController controller; // これを追加
  final int currentIndex; // 追加

  TimelineCard({
    Key? key,
    required this.item,
    required this.size,
    required this.controller, // これも追加
    required this.currentIndex, // 追加
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        int centerIndex = controller.selectedItem;
        print("centerIndex=$centerIndex");
        print("currentIndex=$currentIndex");
        if (currentIndex == centerIndex) {
          print("This is center!");
          // 新しいモーダルを表示する
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FullScreenImageModal(imageFilename: item.imageFilename),
              fullscreenDialog: true,
            ),
          );
        }
      },
      child: Container(
        child: Align(
          alignment: Alignment.center,
          child: Container(
            key: ValueKey(item.thumbnailFilename),
            width: size.width * 0.2,
            height: size.width * 0.2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.width * 0.04),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size.width * 0.04),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/01.png',
                image: 'https://photo5.world/${item.thumbnailFilename}',
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

class FullScreenImageModal extends StatelessWidget {
  final String imageFilename;

  FullScreenImageModal({required this.imageFilename});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(1),  // 半透明の背景
      body: Center(
        child: Container(
          width: size.width * 0.9,
          height: size.height * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0), // 角丸
            image: DecorationImage(
              image: NetworkImage('https://photo5.world/$imageFilename'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

