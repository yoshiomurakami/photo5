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

  bool isUpdating = false;

  // Getter for timelineItems
  // List<TimelineItem> get timelineItems => _timelineItems;



  // selectedItemsMap に新しい groupID を挿入する補助関数
  Map<String, int> insertIntoSelectedItemsMap(Map<String, int> originalMap, String newGroupId) {
    Map<String, int> updatedMap = {};
    String firstKey = originalMap.keys.first;
    updatedMap[firstKey] = originalMap[firstKey]!;
    updatedMap[newGroupId] = 0;  // 新しい groupID を追加
    originalMap.forEach((key, value) {
      if (key != firstKey) {
        updatedMap[key] = value;
      }
    });
    print("updatedMap! = $updatedMap");
    return updatedMap;
  }

  // // selectedItemsMap を更新するメソッド
  void updateSelectedItemsMap(String newGroupId) {
    if (!isUpdating) {
      selectedItemsMap = insertIntoSelectedItemsMap(selectedItemsMap, newGroupId);  // 修正箇所
      print("selectedItemsMap_here = $selectedItemsMap");
      notifyListeners();
    }
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
          // if (isNewRow) {
            // preUpdateSelectedItemsMap(timelineItems, newItem.groupID);
            // updateSelectedItemsMap(newItem.groupID);
            // print("selectedItemsMap!addphoto!!=$selectedItemsMap");
          // }

          // if (isNewRow) {
          //   int currentSelection = pickerController.selectedItem;
          //
          //   // 新しい行がリストに追加される前に、selectedItemsMapの更新と参照の適切な更新を行う
          //   shiftAndUpdateSelectedItemsMap(timelineItems, newItem.groupID);
          //
          //   // 新しいアイテムをリストに追加
          //   timelineItems.insert(1, newItem);
          //
          //   // pickerControllerの位置を即座に更新
          //   pickerController.jumpToItem(currentSelection + 1);
          //
          //   // UIのリフレッシュをトリガーする
          //   notifyListeners();
          // }


          if (isNewRow) {
            // カメラから戻ったときにpickerControllerが未構築のケースではcurrentSelection=0にしておく。
            int currentSelection = 0;
            if (pickerController.hasClients) {
              currentSelection = pickerController.selectedItem;
            } else {
              currentSelection = 0;
            }


            // 新しい行がリストに追加される前に、selectedItemsMapを更新
            // updateSelectedItemsMap(newItem.groupID);

            // 新しいアイテムをリストに追加
            timelineItems.insert(1, newItem);





            // if (currentSelection != 0){
            //   pickerController.jumpToItem(currentSelection + 1);
            // }
            // notifyListeners(); // 更新を通知
            // selectedItemsMapの参照を適切に更新
            // shiftSelectedItemsMap(timelineItems);

            // 遅延してpickerControllerの位置を更新
            // Future.delayed(Duration(milliseconds: 50), () {
            //   pickerController.jumpToItem(currentSelection + 1);
            //   notifyListeners(); // 更新を通知
            // });
          } else {
          // groupIDが一致する既存のアイテムが見つかった場合
          // groupIDが一致する最初のアイテムのインデックスを探す
          int insertIndex = timelineItems.indexWhere((item) => item.groupID == newItem.groupID);
          if (insertIndex != -1) {
            // 同じgroupIDを持つアイテムが見つかった場合、その位置に新しいアイテムを挿入
            timelineItems.insert(insertIndex + 1, newItem);
          }
          // UIの更新をトリガーする
          notifyListeners();
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

  void shiftSelectedItemsMap(List<TimelineItem> timelineItems) {
    Map<String, int> newMap = {};
    selectedItemsMap.forEach((groupID, index) {
      // インデックス値は変更せずに、groupIDの参照する行の位置を1つ下げる
      int newIndex = timelineItems.indexWhere((item) => item.groupID == groupID) + 1;
      newMap[groupID] = newIndex >= timelineItems.length ? 0 : index;  // インデックスを1つずらす
    });
    selectedItemsMap = newMap;
  }
}

final chatNotifierProvider = ChangeNotifierProvider<ChatNotifier>((ref) => ChatNotifier(ref));



