import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timeline_providers.dart';
// import 'timeline_map_display.dart';

IO.Socket?socket;

// このProviderを使用して、アプリのどこからでもshootingGroupIdを参照・更新できます。
final shootingGroupIdProvider = StateProvider<String?>((ref) => null);

class ChatConnection {

  // 任意のイベントのリスナーを追加するメソッド
  void on(String eventName, void Function(dynamic) callback) {
    socket?.on(eventName, callback);
  }

  // 任意のイベントのリスナーを削除するメソッド
  void off(String eventName) {
    socket?.off(eventName);
  }

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

  // void onCameraEvent(void Function(dynamic) callback) {
  //   socket?.on('camera_event', (data) {
  //     callback(data);
  //   });
  // }

  void listenToCameraEvent(BuildContext context, void Function(String) callback) {
    socket?.on('camera_event', (data) {
      print('Received camera_event with data: $data');
      callback(data);
    });
  }

  void listenToLeaveShootingRoomEvent(BuildContext context, void Function() callback) {
    socket?.on('leave_shooting_room', (data) {
      print('Received leave_shooting_room event with data: $data');

      // ここで context を使用してSnackBarを表示します。
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Received message: $data"),
          duration: Duration(seconds: 3),
        ),
      );
      callback();
    });
  }

  void listenToShootingRoomMessages(BuildContext context) {
    socket?.on('shooting', (data) {
      // "shooting" ルームからのメッセージを処理
      print('Received message from "shooting" room: $data');
    });
  }

  void listenToRoomCount(BuildContext context) {
    socket?.on('room_count', (data) {
      print('Number of users in "shooting" room: ${data['count']}');

      String actionMessage = data['action'] == "entered" ? "入室" : "退出";

      // ここで context を使用してSnackBarを表示します。
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$actionMessage - Number of users in \"shooting\" room: ${data['count']}"),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }


  void emitEvent(String eventName) {
    socket?.emit(eventName);
  }

  void sendMessage(String message) {
    socket?.emit('message', message);
  }

  void removeListeners() {
    socket?.off('camera_event');
    socket?.off('room_count');
  }

  void disconnect() {
    socket?.disconnect();
  }
}

class ConnectionNumber extends StatefulWidget {
  final double? left;
  final double? bottom;

  ConnectionNumber({this.left, this.bottom});

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
    double screenWidth = MediaQuery.of(context).size.width;
    double leftMargin = screenWidth * 0.05;  // 画面の横幅の5%
    double screenHeight = MediaQuery.of(context).size.height;
    double bottomMargin = screenHeight * 0.05;  // 画面の横幅の5%

    return Positioned(
      left: widget.left ?? leftMargin,
      bottom: widget.bottom ?? bottomMargin,
      // width: 150,
      height: screenWidth * 0.1,
      child: Container(
        padding: EdgeInsets.only(left: 5, top: 0, right: 15, bottom: 0),  // 左側のpaddingを0に、右側のpaddingを調整
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '😀',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            ),
            SizedBox(width: 10),  // この値は、アイコンと数字の間のスペースを調整するために変更できます
            Text(
              '$totalConnections',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

}


class ChatNotifier extends ChangeNotifier {

  final ChangeNotifierProviderRef<Object?> ref;

  final ChatConnection chatConnection = ChatConnection(); // ChatConnectionのインスタンスを作成

  PageController? fullScreenImageViewerController;

  List<List<TimelineItem>> groupedItemsList = [];

  ChatNotifier(this.ref);

  Map<String, int> selectedItemsMap = {};

  // Getter for timelineItems
  // List<TimelineItem> get timelineItems => _timelineItems;



  // selectedItemsMap に新しい groupID を挿入する補助関数
  Map<String, int> insertIntoSelectedItemsMap(Map<String, int> originalMap, String newGroupId) {
    // 新しい Map を作成
    Map<String, int> updatedMap = {};

    // 最初の要素を追加
    String firstKey = originalMap.keys.first;
    updatedMap[firstKey] = originalMap[firstKey]!;

    // 新しい groupID を追加
    updatedMap[newGroupId] = 0;

    // 残りの要素を追加
    originalMap.forEach((key, value) {
      if (key != firstKey) {
        updatedMap[key] = value;
      }
    });

    return updatedMap;
  }

  // selectedItemsMap を更新するメソッド
  void updateSelectedItemsMap(Map<String, int> originalMap, String newGroupId) {
    selectedItemsMap = insertIntoSelectedItemsMap(selectedItemsMap, newGroupId);
    print("selectedItemsMap_here = $selectedItemsMap");
    notifyListeners();
  }

  void addPostedPhoto(PageController pageController, FixedExtentScrollController pickerController, List<TimelineItem> timelineItems,Map<String, int> selectedItemsMap,List<List<TimelineItem>> Function(List<TimelineItem>) groupItemsByGroupId) {
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

          TimelineItem newItem = TimelineItem.fromJson(data);
          print("maked_TimelineItem newItem=$newItem");

          final timelineItems = await ref.read(timelineAddProvider);

          // groupIDが一致する既存のアイテムが存在するか確認
          bool isNewRow = !timelineItems.any((item) => item.groupID == newItem.groupID);

          // 新しいアイテムをリストに追加する前に、selectedItemsMap を更新
          if (isNewRow) {
            updateSelectedItemsMap(selectedItemsMap, newItem.groupID);
            // print("selectedItemsMap!addphoto!!=$selectedItemsMap");
          }

          // 新しいアイテムをリストに追加
          if (isNewRow) {
            // 新しい行が生成される場合はリストの先頭に追加
            timelineItems.insert(1, newItem);
          } else {
            // groupIDが一致する最初のアイテムのインデックスを探す
            int insertIndex = timelineItems.indexWhere((item) => item.groupID == newItem.groupID);
            if (insertIndex != -1) {
              // 同じgroupIDを持つアイテムが見つかった場合、その位置に新しいアイテムを挿入
              timelineItems.insert(insertIndex, newItem);
            } else {
              // 同じgroupIDを持つアイテムがない場合、新しい行としてリストの先頭に追加
              timelineItems.insert(1, newItem);
            }
          }
          print("added_timelineItems=$timelineItems");

          groupedItemsList = groupItemsByGroupId(timelineItems);


          int? currentIndex;
          if (pageController.hasClients) {
            currentIndex = pageController.page?.round();
          } else {
            currentIndex = pickerController.selectedItem; // この行を変更
          }

          if (currentIndex != null && currentIndex != 0) {
            if (isNewRow) {
              currentIndex = ++currentIndex;
              pickerController.jumpToItem(currentIndex);
            } else {
              pickerController.jumpToItem(currentIndex);
            }
          } else {
            // pickerController.jumpToItem(0);
          }

          // Notify listeners about the change
          notifyListeners();

          // 新しい画像が受信された際の上層リストビューの処理
          // if (fullScreenImageViewerController != null && fullScreenImageViewerController!.hasClients) {
          //   int? currentIndex = fullScreenImageViewerController!.page?.round();
          //   if (currentIndex != null && currentIndex != 0) {
          //     currentIndex = ++currentIndex;
          //     fullScreenImageViewerController!.jumpToPage(currentIndex); // アニメーションなしでジャンプ
          //   }
          // }


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

final chatNotifierProvider = ChangeNotifierProvider<ChatNotifier>((ref) => ChatNotifier(ref));



