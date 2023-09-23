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
      width: size.width * 0.5,
      height: size.height * 0.15,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              getFlagCode(item.country) != null
                  ? Flag.fromCode(
                getFlagCode(item.country)!,
                height: 20,
                width: 30,
              )
                  : Container(),
              SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.geocodedCountry ?? 'Unknown'),
                  Text(item.geocodedCity ?? 'Unknown'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
