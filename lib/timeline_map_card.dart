import 'package:flutter/material.dart';
// import 'package:flag/flag.dart';
import 'timeline_providers.dart';


class TimelineCard extends StatefulWidget {
  final TimelineItem item;
  final Size size;
  final FixedExtentScrollController controller;
  final int currentIndex;

  TimelineCard({
    Key? key,
    required this.item,
    required this.size,
    required this.controller,
    required this.currentIndex,
  }) : super(key: key);

  @override
  _TimelineCardState createState() => _TimelineCardState();
}

class _TimelineCardState extends State<TimelineCard> {
  bool isDialogShown = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        int centerIndex = widget.controller.selectedItem;
        if (widget.currentIndex == centerIndex) {
          showDialog(
            context: context,
            barrierColor: Colors.transparent,  // 透明なモーダルバリア
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: Colors.white, width: 3.0),  // 白い枠縁
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.network(
                      'https://photo5.world/${widget.item.imageFilename}',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );
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




