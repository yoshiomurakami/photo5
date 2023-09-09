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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size.width * 1.0,
          height: size.height * 0.15,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text('No. ${item.id}'),
                  Text(item.geocodedCountry ?? 'Unknown'),
                  Text(item.geocodedCity ?? 'Unknown'),
                  getFlagCode(item.country) != null
                      ? Flag.fromCode(
                    getFlagCode(item.country)!,
                    height: 20,
                    width: 30,
                  )
                      : Container(),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.2 - size.width * 0.1,
          left: size.width * 0.3,
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
      ],
    );
  }
}