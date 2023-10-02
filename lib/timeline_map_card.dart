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

  @override
  void initState() {
    super.initState();
    currentSelectedItem = widget.currentIndex;
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        int centerIndex = widget.controller.selectedItem;
        if (widget.currentIndex == centerIndex) {
          showDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) => VerticalSwipeDetector(
              onSwipeUp: () => scrollTimeline(widget.pickerController, 1, widget.items.length),
              onSwipeDown: () => scrollTimeline(widget.pickerController, -1, widget.items.length),
              child: Dialog(
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
                        )
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

class VerticalSwipeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeUp;
  final VoidCallback onSwipeDown;

  VerticalSwipeDetector({
    required this.child,
    required this.onSwipeUp,
    required this.onSwipeDown,
  });

  @override
  _VerticalSwipeDetectorState createState() => _VerticalSwipeDetectorState();
}

class _VerticalSwipeDetectorState extends State<VerticalSwipeDetector> {
  final double swipeThreshold = 5.0;  // この値は調整可能です
  double? totalDragDelta;

  void _onVerticalDragStart(DragStartDetails details) {
    totalDragDelta = 0.0;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (totalDragDelta == null) return;  // この行を追加

    double newDelta = totalDragDelta! + details.primaryDelta!;
    totalDragDelta = newDelta;

    if (newDelta < -swipeThreshold) {
      print("Swiping up...");
    } else if (newDelta > swipeThreshold) {
      print("Swiping down...");
    }
  }


  void _onVerticalDragEnd(DragEndDetails details) {
    if (totalDragDelta! < -swipeThreshold) {
      widget.onSwipeUp();
      print("onSwipeUp");
    } else if (totalDragDelta! > swipeThreshold) {
      widget.onSwipeDown();
      print("onSwipeDown");
    }
    totalDragDelta = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: widget.child,
    );
  }
}


void scrollTimeline(FixedExtentScrollController controller, int step, int maxItems) {
  int currentItem = controller.selectedItem;
  int targetItem = currentItem + step;

  if (targetItem >= 0 && targetItem < maxItems) {
    controller.animateToItem(
        targetItem,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut
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




