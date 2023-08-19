import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

int currentPage = 0; // これで現在のページを追跡します

class TimelineItem {
  final String id;
  final String userId;
  final String country;  // This is from DB
  final double lat;
  final double lng;
  final String imageFilename;
  final String thumbnailFilename;
  final String localtime;
  String? geocodedCountry;  // This is from geocoding
  String? geocodedCity;  // This is from geocoding

  TimelineItem({
    required this.id,
    required this.userId,
    required this.country,
    required this.lat,
    required this.lng,
    required this.imageFilename,
    required this.thumbnailFilename,
    required this.localtime,
    this.geocodedCountry,
    this.geocodedCity,
  });

  static Map<String, dynamic> empty({
    required double lat,
    required double lng,
  }) {
    return {
      '_id': '0',
      'userId': 'dummy',
      'country': 'dummy',
      'lat': lat.toString(),
      'lng': lng.toString(),
      'imageFilename': 'dummy',
      'thumbnailFilename': '03.png',
      'localtime': 'dummy',
    };
  }

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      id: json['_id'] ?? '0',
      userId: json['userID'] ?? 'dummy',
      country: json['country'] ?? 'dummy',
      lat: json['lat'] != null ? double.parse(json['lat']) : 0.0,
      lng: json['lng'] != null ? double.parse(json['lng']) : 0.0,
      imageFilename: json['imageFilename'] ?? 'dummy',
      thumbnailFilename: json['thumbnailFilename'] ?? '03.png',
      localtime: json['localtime'] ?? 'dummy',
      geocodedCountry: null,  // Set null as default
      geocodedCity: null,  // Set null as default
    );
  }
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

Future<LatLng> determinePosition() async {
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  return LatLng(position.latitude, position.longitude);
}

Future<List<TimelineItem>> getMoreTimelineItems() async {
  currentPage++; // ページ番号を増やす
  print('currentPage is $currentPage');
  List<TimelineItem> newItems = await getTimelinePage(currentPage);
  return newItems;
}

Future<List<TimelineItem>> getTimelinePage(int page) async { // この行を変更
  try {
    // SharedPreferencesからユーザーIDを取得
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userID') ?? "";

    // リクエストボディの作成
    final requestBody = jsonEncode({'userId': userId});

    // APIにPOSTリクエストを送信
    final response = await http.post(
      Uri.parse('https://photo5.world/api/timeline/getTimeline'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'page': page}), // ここでページ情報も送信
    );

    // APIからのレスポンスをチェック
    if (response.statusCode == 200) {
      // 成功した場合、JSONをパースしてリストに変換
      List data = jsonDecode(response.body);
      // print('取得したばかりのReceived data: ${data.length} items. Details: $data');

      if (page == 0) { // 最初のページの場合のみ、現在地を取得
        // 現在の位置を取得します。
        Position devicePosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        // 現在地を表す空の TimelineItem を作成します。ただし、これは Map<String, dynamic> の形で返されます。
        Map<String, dynamic> emptyTimelineItem = TimelineItem.empty(
          lat: devicePosition.latitude,
          lng: devicePosition.longitude,
        );

        // 空の TimelineItem をリストの先頭に追加します。
        data.insert(0, emptyTimelineItem);
      }

      // デバッグ情報として、取得したデータを出力
      print('Received data: ${data.length} items. Details: $data');

      List<TimelineItem> timelineItems = data.map((item) => TimelineItem.fromJson(item)).toList();

      // ジオコーディング処理の追加
      await updateGeocodedLocation(timelineItems);

      return timelineItems;
    } else {
      // エラーが発生した場合、エラーをスロー
      throw Exception('Failed to load timeline');
    }
  } catch (e, s) {
    // print both the exception and the stacktrace
    print('Exception details:\n $e');
    print('Stacktrace:\n $s');
    rethrow;  // throw the error again so it can be handled in the usual way
  }
}

Future<List<TimelineItem>> getTimeline() async {
  return await getTimelinePage(currentPage);
}

Future<void> updateGeocodedLocation(List<TimelineItem> timelineItems) async {
  for (var item in timelineItems) {
    if (item.geocodedCity == null || item.geocodedCountry == null) {
      final geocodedLocation = await getGeocodedLocation(LatLng(item.lat, item.lng));
      item.geocodedCity = geocodedLocation['city'] ?? 'unknown';
      item.geocodedCountry = geocodedLocation['country'] ?? 'unknown';
    }
  }
}

Future<List<TimelineItem>> getTimelineWithGeocoding() async {
  List<TimelineItem> timelineItems = await getTimeline();
  await updateGeocodedLocation(timelineItems);
  return timelineItems;
}

final timelineProvider = FutureProvider.autoDispose<List<TimelineItem>>((ref) async {
  List<TimelineItem> timelineItems = await getTimeline();
  // timelineItems = await getTimelineWithGeocoding();

  await updateGeocodedLocation(timelineItems); // 全レコード分のジオコーディングを更新

  print('Timeline Items: $timelineItems');
  return timelineItems;
});