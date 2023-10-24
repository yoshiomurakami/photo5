import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'timeline_providers.dart';
import 'timeline_map_display.dart';

class TimelineMapWidget extends StatelessWidget {
  final List<TimelineItem> timelineItems; // コンストラクタで受け取る
  final LatLng currentLocation;
  final Size size;
  final PageController pageController;
  final bool programmaticPageChange;
  final Function updateGeocodedLocation;
  // final VoidCallback onCameraButtonPressed;

  TimelineMapWidget({
    required this.timelineItems,
    required this.currentLocation,
    required this.size,
    required this.pageController,
    required this.programmaticPageChange,
    required this.updateGeocodedLocation,
    // required this.onCameraButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    // カレントロケーションの設定
    MapController.instance.setCurrentLocation(currentLocation);

    return Stack(
      children: [
        // まず、背景として MapDisplay を配置
        MapDisplay(
          currentLocation: currentLocation,
          timelineItems: timelineItems,
          size: size,
          pageController: pageController,
          programmaticPageChange: programmaticPageChange,
          updateTimeline: updateGeocodedLocation,
        ),
        // 次に、CameraButton を配置
        // CameraButton(onPressed: onCameraButtonPressed),
      ],
    );
  }

}


