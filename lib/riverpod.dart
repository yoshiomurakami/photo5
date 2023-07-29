import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'timeline_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final timelineProvider = FutureProvider.autoDispose<List<TimelineItem>>((ref) async {
  return getTimeline();
});

Future<LatLng> determinePosition() async {
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  return LatLng(position.latitude, position.longitude);
}