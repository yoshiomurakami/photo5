import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timeline_providers.dart';
import 'timeline_map_display.dart';

IO.Socket?socket;

class ChatConnection {

  // void connect({Function? onNewPhoto}){
  void connect(){
      socket = IO.io('https://photo5.world', <String, dynamic>{
      'transports': ['websocket'],
      'path': '/api/socketio/',
      'autoConnect': true,
    });

    socket?.on('connect', (_) {
      print('Connected!');
    });

    socket?.on('connect_error', (error) {
      print('Connection Error: $error');
    });

    socket?.on('disconnect', (_) => print('Disconnected from server'));
  }

  // 新しい写真の情報をサーバーに送信するメソッド
  void sendNewPhotoInfo(Map<String, dynamic> photoInfo) {
    print('Sending photo info: ${jsonEncode(photoInfo)}');
    socket?.emit('new_photo', jsonEncode(photoInfo));
    print('Photo info sent.');
  }

  void onNewPhoto(void Function(dynamic) callback, {Function? onReceived}) {
    socket?.on('new_photo', (data) {
      print("Type of data: ${data.runtimeType}");
      if (data is String) {
        data = jsonDecode(data);
      }
      callback(data);
      onReceived?.call();
    });
  }


  void sendMessage(String message) {
    socket?.emit('message', message);
  }

  void disconnect() {
    socket?.disconnect();
  }
}

class ConnectionNumber extends StatefulWidget {
  @override
  _ConnectionNumberState createState() => _ConnectionNumberState();
}

class _ConnectionNumberState extends State<ConnectionNumber> {
  int totalConnections = 0;

  @override
  void initState() {
    super.initState();
    socket?.on('connections', (connections) {
      setState(() {
        totalConnections = connections;
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.black.withOpacity(0.5),
      child: Text('Connections: $totalConnections', style: TextStyle(color: Colors.white)),
    );
  }
}


class TimelineNotifier extends ChangeNotifier {

  final ChangeNotifierProviderRef<Object?> ref;

  TimelineNotifier(this.ref);

  final ChatConnection chatConnection = ChatConnection(); // ChatConnectionのインスタンスを作成

  // List<TimelineItem> _timelineItems = [];

  // Getter for timelineItems
  // List<TimelineItem> get timelineItems => _timelineItems;

  void addPostedPhoto(PageController pageController, List<TimelineItem> timelineItems) {
    chatConnection.connect();
    chatConnection.onNewPhoto((data) async {
      print("onNewPhoto=$data");

      try {
        double latitude = data['lat'];
        double longitude = data['lng'];

        // 地名情報の取得
        List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;

          // 受信データ配列に地名情報を追加
          data['geocodedCity'] = place.locality ?? "Unknown";
          data['geocodedCountry'] = place.country ?? "Unknown";

          // 更新された配列情報を出力
          print("Updated Data with Geocoding=$data");

          // Convert the updated data to a TimelineItem object
          TimelineItem newItem = TimelineItem.fromJson(data);
          print("maked_TimelineItem newItem=$newItem");

          // printTimelineItems();
          final timelineItems = await ref.read(timelineProvider.future);

          // Add the new item to the beginning of the list
          timelineItems.insert(1, newItem);
          print("added_timelineItems=$timelineItems");

          // Notify listeners about the change
          notifyListeners();

          // 現在のページインデックスを取得
          int? currentIndex = pageController.page?.round();
          print("currentIndex=$currentIndex");
          if (currentIndex != null && currentIndex != 0) {
            print("currentIndex=$currentIndex");
            // 現在のインデックスを1増やして次のページへ移動
            currentIndex = ++currentIndex;
            pageController.jumpToPage(currentIndex);

            // 移動後のカードのアイテムを取得
            var nextItem = timelineItems[currentIndex];

            // アイテムが持つlatとlngを使用してマップ位置を更新
            MapController.instance.updateMapLocation(nextItem.lat, nextItem.lng);
            print("currentIndex_after=$nextItem");
          }


        } else {
          print("Geocoding returned no results.");
        }
      } catch (e) {
        print("Error in geocoding: $e");
      }
    },onReceived: () {
      print("新しい写真が受信されました！");


    });
  }
}

final timelineNotifierProvider = ChangeNotifierProvider<TimelineNotifier>((ref) => TimelineNotifier(ref));



