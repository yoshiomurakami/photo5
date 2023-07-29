// import 'dart:io';
import 'dart:async';
import 'dart:convert';
// import 'dart:math' as math;
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:camera/camera.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:image/image.dart' as img;
// import 'package:mime/mime.dart';
// import 'package:http_parser/http_parser.dart';
// import 'package:path/path.dart' as p;
// import 'package:sqflite/sqflite.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'album_screen.dart';
// import 'timeline_photoview.dart';
// import 'riverpod.dart';

class TimelineItem {
  final String id;
  final String userId;
  final String country;
  final double lat;
  final double lng;
  final String imageFilename;
  final String thumbnailFilename;
  final String localtime;

  TimelineItem({
    required this.id,
    required this.userId,
    required this.country,
    required this.lat,
    required this.lng,
    required this.imageFilename,
    required this.thumbnailFilename,
    required this.localtime,
  });

  // 新しいemptyという名前付きコンストラクタを追加します。
  // ただし、このコンストラクタは Map<String, dynamic> を返します。
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
      id: json['_id'] ?? '0', // Provide a default value in case of null
      userId: json['userID'] ?? 'dummy', // Provide a default value in case of null
      country: json['country'] ?? 'dummy', // Provide a default value in case of null
      lat: json['lat'] != null ? double.parse(json['lat']) : 0.0, // Check for null before parsing
      lng: json['lng'] != null ? double.parse(json['lng']) : 0.0, // Check for null before parsing
      imageFilename: json['imageFilename'] ?? 'dummy', // Provide a default value in case of null
      thumbnailFilename: json['thumbnailFilename'] ?? '03.png', // Provide a default value in case of null
      localtime: json['localtime'] ?? 'dummy', // Provide a default value in case of null
    );
  }

}

Future<List<TimelineItem>> getTimeline() async {
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
      body: requestBody,
    );

    // APIからのレスポンスをチェック
    if (response.statusCode == 200) {
      // 成功した場合、JSONをパースしてリストに変換
      List data = jsonDecode(response.body);

      // 現在の位置を取得します。
      Position devicePosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // 現在地を表す空の TimelineItem を作成します。ただし、これは Map<String, dynamic> の形で返されます。
      Map<String, dynamic> emptyTimelineItem = TimelineItem.empty(
        lat: devicePosition.latitude,
        lng: devicePosition.longitude,
      );

      // 空の TimelineItem をリストの先頭に追加します。
      data.insert(0, emptyTimelineItem);

      // デバッグ情報として、取得したデータを出力
      print('Received data: $data');
      return data.map((item) => TimelineItem.fromJson(item)).toList();
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