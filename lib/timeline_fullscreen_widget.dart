import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'timeline_providers.dart';
import 'timeline_fullscreen_display.dart';

class TimelineFullScreenWidget extends StatelessWidget {
  final List<TimelineItem> timelineItems; // コンストラクタで受け取る
  final LatLng currentLocation;
  final Size size;
  final PageController pageController;
  final bool programmaticPageChange;
  final Function updateGeocodedLocation;

  TimelineFullScreenWidget({
    required this.timelineItems,
    required this.currentLocation,
    required this.size,
    required this.pageController,
    required this.programmaticPageChange,
    required this.updateGeocodedLocation,
  });

  @override
  Widget build(BuildContext context) {
    // カレントロケーションの設定
    MapController.instance.setCurrentLocation(currentLocation);

    return FullScreenDisplay(
      currentLocation: currentLocation,
      timelineItems: timelineItems,
      size: size,
      pageController: pageController,
      programmaticPageChange: programmaticPageChange,
      updateTimeline: updateGeocodedLocation,
    );
  }
}