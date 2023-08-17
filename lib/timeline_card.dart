import 'package:flutter/material.dart';
import 'timeline_providers.dart';

class TimelineCard extends StatelessWidget {
  final TimelineItem item;
  final int index;
  final Size size;

  TimelineCard({required this.item, required this.index, required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // タップ処理など
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // カード表示部分
          // サムネイル表示部分
        ],
      ),
    );
  }
}
