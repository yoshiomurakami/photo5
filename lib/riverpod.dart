import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'timeline_screen.dart';
import 'package:geocoding/geocoding.dart';

final timelineProvider = FutureProvider.autoDispose<List<TimelineItem>>((ref) async {
  List<TimelineItem> timelineItems = await getTimeline();

  await updateGeocodedLocation(timelineItems); // 全レコード分のジオコーディングを更新

  print('Timeline Items: $timelineItems');
  return timelineItems;
});



Future<void> updateGeocodedLocation(List<TimelineItem> timelineItems) async {
  for (var item in timelineItems) {
    if (item.geocodedCity == null || item.geocodedCountry == null) {
      final geocodedLocation = await getGeocodedLocation(LatLng(item.lat, item.lng));
      item.geocodedCity = geocodedLocation['city'] ?? 'unknown';
      item.geocodedCountry = geocodedLocation['country'] ?? 'unknown';
    }
  }
}


Future<LatLng> determinePosition() async {
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  return LatLng(position.latitude, position.longitude);
}

Future<Map<String, String>> getGeocodedLocation(LatLng position) async {
  final places = await placemarkFromCoordinates(position.latitude, position.longitude);
  if (places.isNotEmpty) {
    final country = places[0].country ?? '';
    final city = places[0].locality ?? '';
    print('Geocoded location: $city, $country');
    return {'country': country, 'city': city};
  }
  return {'country': 'unknown', 'city': 'unknown'}; // エラーを返さずに未知の値を返す
}

Future<List<TimelineItem>> getTimelineWithGeocoding() async {
  List<TimelineItem> timelineItems = await getTimeline();
  await updateGeocodedLocation(timelineItems);
  return timelineItems;
}
