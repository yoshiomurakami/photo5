import 'package:flutter/material.dart';
import 'package:flag/flag.dart';
import 'timeline_providers.dart';

class TimelineCard extends StatelessWidget {
  final TimelineItem item;
  final Size size;

  TimelineCard({Key? key, required this.item, required this.size}) : super(key: key);

  FlagsCode? getFlagCode(String countryCode) {
    try {
      return FlagsCode.values.firstWhere(
              (e) => e.toString().split('.')[1].toUpperCase() == countryCode.toUpperCase());
    } catch (e) {
      return null;  // No matching country code found
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: size.width * 0.2,
      // color: Colors.pink,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          key: ValueKey(item.thumbnailFilename),
          width: size.width * 0.2,
          height: size.width * 0.2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size.width * 0.04),
            image: DecorationImage(
              image: NetworkImage('https://photo5.world/${item.thumbnailFilename}'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

}