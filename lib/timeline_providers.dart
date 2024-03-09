import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
// import 'package:sqflite/sqflite.dart';

int currentPage = 0; // これで現在のページを追跡します

class TimelineItem {
  final Key key;
  final String systemId;
  final int sequenceNumber;
  final String userID;
  final String country;  // This is from DB
  final double lat;
  final double lng;
  final String imageFilename;
  final String thumbnailFilename;
  final String localtime;
  final String groupID;
  String? geocodedCountry;  // This is from geocoding
  String? geocodedCity;  // This is from geocoding
  final int statement;

  TimelineItem({
    required this.key,
    required this.systemId,
    required this.sequenceNumber,
    required this.userID,
    required this.country,
    required this.lat,
    required this.lng,
    required this.imageFilename,
    required this.thumbnailFilename,
    required this.localtime,
    required this.groupID,
    this.geocodedCountry,
    this.geocodedCity,
    required this.statement,
  });

  static Map<String, dynamic> empty({
    required double lat,
    required double lng,
  }) {
    return {
      'systemId': 'shootbutton',
      'sequenceNumber': 0,
      'userID': 'dummy',
      'country': 'dummy',
      'lat': lat.toString(),
      'lng': lng.toString(),
      'imageFilename': '03.png',
      'thumbnailFilename': '03.png',
      'localtime': 'dummy',
      'groupID': 'camera',
    };
  }

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      key: ValueKey(json['_key'] ?? '0'), // この行を追加
      systemId: json['_id'] ?? 'shootbutton',
      sequenceNumber: int.tryParse(json['sequenceNumber'].toString()) ?? 0,
      userID: json['userID'] ?? 'dummy',
      country: json['country'] ?? 'dummy',
      lat: (json['lat'] is String) ? double.parse(json['lat']) : (json['lat'] as double? ?? 0.0),
      lng: (json['lng'] is String) ? double.parse(json['lng']) : (json['lng'] as double? ?? 0.0),
      imageFilename: json['imageFilename'] ?? '03.png',
      thumbnailFilename: json['thumbnailFilename'] ?? '03.png',
      localtime: json['localtime'] ?? 'dummy',
      groupID: json['groupID'] ?? 'dummy',
      geocodedCountry: json['geocodedCountry'] as String?,  // デフォルト値としてnullを返す
      geocodedCity: json['geocodedCity'] as String?,  // デフォルト値としてnullを返す
      statement: int.tryParse(json['statement'].toString()) ?? 0,
    );
  }

  @override
  String toString() {
    return 'TimelineItem(systemId: $systemId, sequenceNumber: $sequenceNumber, userID: $userID, country: $country, lat: $lat, lng: $lng, imageFilename: $imageFilename, thumbnailFilename: $thumbnailFilename, localtime: $localtime, groupID : $groupID, geocodedCountry: $geocodedCountry, geocodedCity: $geocodedCity, statement: $statement)';
  }
}

class TimelineNotifier extends StateNotifier<List<TimelineItem>> {
  TimelineNotifier() : super([]) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    List<TimelineItem> initialData = await getTimeline();
    state = initialData;
    debugPrint("_loadInitialData is herehere");
  }

  Future<void> addMoreItems() async {
    List<TimelineItem> newItems = await getMoreTimelineItems();
    // 重複を避けるために、既にリストに存在するアイテムを除外
    var uniqueNewItems = newItems.where((newItem) => !state.any((existingItem) => existingItem.systemId == newItem.systemId)).toList();

    if (uniqueNewItems.isNotEmpty) {
      // 既存のリストに新しいアイテムを追加
      state = [...state, ...uniqueNewItems];
    }

    debugPrint("addMoreItems!");
  }
}


Future<Map<String, String>> getGeocodedLocation(LatLng position) async {
  // final places = await placemarkFromCoordinates(position.latitude, position.longitude);
  // if (places.isNotEmpty) {
  //   final country = places[0].country ?? '';
  //   final city = places[0].locality ?? '';
  //   print('Geocoded location: $city, $country');
  //   return {'country': country, 'city': city};
  // }
  return {'country': 'unknown', 'city': 'unknown'}; // エラーを返さずに未知の値を返す
}

Future<LatLng> determinePosition() async {
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  return LatLng(position.latitude, position.longitude);
}

Future<List<TimelineItem>> getMoreTimelineItems() async {
  currentPage++; // ページ番号を増やす
  debugPrint('currentPage is $currentPage');
  List<TimelineItem> newItems = await getTimelinePage(currentPage);
  return newItems;
}

Future<List<TimelineItem>> getTimelinePage(int page) async { // この行を変更
  try {
    // SharedPreferencesからユーザーIDを取得
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? "";

    // APIにPOSTリクエストを送信
    final response = await http.post(
      Uri.parse('https://photo5.world/api/timeline/getTimeline'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userID': userID, 'page': page}), // ここでページ情報も送信
    );

    debugPrint("userID = $userID / page = $page");

    // APIからのレスポンスをチェック
    if (response.statusCode == 200) {
      // 成功した場合、JSONをパースしてリストに変換
      List data = jsonDecode(response.body);
      debugPrint('取得したばかりのReceived data: ${data.length} items. Details: $data');

      if (page == 0) { // 最初のページの場合のみ、現在地を取得
        // // 現在の位置を取得します。
        Position devicePosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        // double latitude = prefs.getDouble('latitude') ?? 0.0;
        // double longitude = prefs.getDouble('longitude') ?? 0.0;

        // 現在地を表す空の TimelineItem を作成します。ただし、これは Map<String, dynamic> の形で返されます。
        Map<String, dynamic> emptyTimelineItem = TimelineItem.empty(
          lat: devicePosition.latitude,
          lng: devicePosition.longitude,
        );

        // 空の TimelineItem をリストの先頭に追加します。
        data.insert(0, emptyTimelineItem);
      }

      // デバッグ情報として、取得したデータを出力
      debugPrint('Received data: ${data.length} items. Details: $data');

      var filteredData = data.where((item) => item['groupID'] != null).toList();

      List<TimelineItem> timelineItems = filteredData
          .map((item) => TimelineItem.fromJson(item))
          .toList();

      // ジオコーディング処理の追加
      await updateGeocodedLocation(timelineItems);

      debugPrint("timelineItemsAAA = $timelineItems");

      return timelineItems;
    } else {
      // エラーが発生した場合、エラーをスロー
      throw Exception('Failed to load timeline');
    }
  } catch (e, s) {
    // print both the exception and the stacktrace
    debugPrint('Exception details:\n $e');
    debugPrint('Stacktrace:\n $s');
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

// Future<List<TimelineItem>> getTimelineWithGeocoding() async {
//   List<TimelineItem> timelineItems = await getTimeline();
//   // await updateGeocodedLocation(timelineItems);
//   return timelineItems;
// }




class TimelineState {
  final List<TimelineItem> items;
  final bool isLoading;

  TimelineState({required this.items, this.isLoading = false});
}

// class TimelineAddNotifier extends StateNotifier<TimelineState> {
//   TimelineAddNotifier() : super(TimelineState(items: [])) {
//     _loadInitialData();
//   }
//
//   Future<void> _loadInitialData() async {
//     List<TimelineItem> initialData = await getTimeline();
//     state = TimelineState(items: initialData);
//   }
//
//   Future<void> addMoreItems() async {
//     state = TimelineState(items: state.items, isLoading: true);
//     List<TimelineItem> newItems = await getMoreTimelineItems();
//     state = TimelineState(items: [...state.items, ...newItems], isLoading: false);
//   }
// }

final timelineProvider = FutureProvider.autoDispose<List<TimelineItem>>((ref) async {
  List<TimelineItem> timelineItems = await getTimeline();
  // timelineItems = await getTimelineWithGeocoding();
  // await updateGeocodedLocation(timelineItems); // 全レコード分のジオコーディングを更新
  debugPrint("timelineProvider is here");
  return timelineItems;
});

final timelineAddProvider = StateNotifierProvider<TimelineNotifier, List<TimelineItem>>((ref) => TimelineNotifier());


final userIdProvider = StateProvider<String?>((ref) => null);