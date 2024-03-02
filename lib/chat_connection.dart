import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'timeline_providers.dart';
// import 'timeline_map_display.dart';

io.Socket?socket;

// このProviderを使用して、アプリのどこからでもshootingGroupIdを参照・更新できます。
// final shootingGroupIdProvider = StateProvider<String?>((ref) => null);

class ChatConnection {

  // 任意のイベントのリスナーを追加するメソッド
  void on(String eventName, void Function(dynamic) callback) {
    socket?.on(eventName, callback);
  }

  // 任意のイベントのリスナーを削除するメソッド
  void off(String eventName) {
    socket?.off(eventName);
  }

  Future<void> connect() async {
    // SharedPreferencesからuserID、国コード、緯度、経度を取得
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? "";
    String countryCode = prefs.getString('countryCode') ?? ""; // 国コードの取得
    double lat = prefs.getDouble('latitude') ?? 0.0; // 緯度の取得
    double lng = prefs.getDouble('longitude') ?? 0.0; // 経度の取得

    // userIDが空でないことを確認
    if (userID.isEmpty || countryCode.isEmpty) {
      debugPrint('UserID or Country Code is empty. Please ensure they are set before connecting.');
      return;
    }

    // 緯度経度が正しく取得できていることを確認
    if (lat == 0.0 || lng == 0.0) {
      debugPrint('Latitude or Longitude is not set correctly.');
      return;
    }

    socket = io.io('https://photo5.world', <String, dynamic>{
      'transports': ['websocket'],
      'path': '/api/socketio/',
      'autoConnect': true,
      'query': {
        'userID': userID, // ここでuserIDをサーバーに送信
        'countryCode': countryCode, // 国コードをサーバーに送信
        'lat': lat.toString(), // 緯度をサーバーに送信
        'lng': lng.toString(), // 経度をサーバーに送信
      },
    });

    // 接続成功時のイベントリスナー
    socket?.on('connect', (_) {
      debugPrint('Connected to server with userID: $userID, countryCode: $countryCode, lat: $lat, lng: $lng');
    });

    socket?.on('connect_error', (error) {
      debugPrint('Connection Error: $error');
    });

    socket?.on('disconnect', (_) => debugPrint('Disconnected from server'));
  }


  // 新しい写真の情報をサーバーに送信するメソッド
  void sendNewPhotoInfo(Map<String, dynamic> newPhotoInfo) {
    debugPrint('Sending photo info: ${jsonEncode(newPhotoInfo)}');
    socket?.emit('new_photo', jsonEncode(newPhotoInfo));
    debugPrint('Photo info sent.');
  }

  void onNewPhoto(void Function(dynamic) callback, {Function? onReceived}) {
    socket?.on('new_photo', (data) {
      debugPrint("Type of data: ${data.runtimeType}");
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
      debugPrint('Received camera_event with data: $data');
      callback(data);
    });
  }

  void listenToLeaveShootingRoomEvent(BuildContext context, void Function() callback) {
    socket?.on('leave_shooting_room', (data) {
      debugPrint('Received leave_shooting_room event with data: $data');

      // ここで context を使用してSnackBarを表示します。
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Received message: $data"),
          duration: const Duration(seconds: 3),
        ),
      );
      callback();
    });
  }

  void listenToShootingRoomMessages(BuildContext context) {
    socket?.on('shooting', (data) {
      // "shooting" ルームからのメッセージを処理
      debugPrint('Received message from "shooting" room: $data');
    });
  }

  void listenToRoomCount(BuildContext context) {
    socket?.on('room_count', (data) {
      debugPrint('Number of users in "shooting" room: ${data['count']}');

      String actionMessage = data['action'] == "entered" ? "入室" : "退出";

      // ここで context を使用してSnackBarを表示します。
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$actionMessage - Number of users in \"shooting\" room: ${data['count']}"),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  // void newConnetction(BuildContext context) {
  //   socket?.on('connections', (data) {
  //     debugPrint('newConnections: $data');
  //
  //     // ここで context を使用してSnackBarを表示します。
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("newConnections: $data"),
  //         duration: const Duration(seconds: 3),
  //       ),
  //     );
  //   });
  // }

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

  const ConnectionNumber({super.key, this.left, this.bottom});

  @override
  ConnectionNumberState createState() => ConnectionNumberState();
}

class ConnectionNumberState extends State<ConnectionNumber> {
  int totalConnections = 0;

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {

    socket?.on('connections', (data) {
      int connections = data['count'];
      setState(() {
        totalConnections = connections;
      });
    });


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
        padding: const EdgeInsets.only(left: 5, top: 0, right: 15, bottom: 0),  // 左側のpaddingを0に、右側のpaddingを調整
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              '😀',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 10),  // この値は、アイコンと数字の間のスペースを調整するために変更できます
            Text(
              '$totalConnections',
              style: const TextStyle(
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
  final ChatConnection chatConnection;
  final List<String> _messages = [];
  final ChangeNotifierProviderRef ref;
  Map<String, Widget> connectionWidgetsMap = {}; // ユーザーIDとウィジェットのマップ


  // 新しいウィジェット情報を格納するリスト
  // List<Widget> connectionWidgets = [];

  // コンストラクタで ChatConnection と ref を受け取る
  ChatNotifier({required this.chatConnection, required this.ref}) {
    _setupConnectionsListener();
  }

  void _setupConnectionsListener() {
    chatConnection.on('connections', (data) {
      String action = data['action'];
      String userID = data['userID'];
      String countryCode = data['countryCode'];
      String lat = data['lat'];
      String lng = data['lng'];

      if (action == 'connected') {
        var message = "Connected: UserID=$userID, Country=$countryCode, Lat=$lat, Lng=$lng";
        var newWidget = _createConnectionWidget(message);
        connectionWidgetsMap[userID] = newWidget;
      } else if (action == 'disconnected') {
        connectionWidgetsMap.remove(userID);
      }
      notifyListeners();
    });
  }

  Widget _createConnectionWidget(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<String> get messages => _messages;

  void addMessage(String message) {
    _messages.add(message);
    notifyListeners();
  }

  // final ChangeNotifierProviderRef<Object?> ref;

  // final ChatConnection chatConnection = ChatConnection(); // ChatConnectionのインスタンスを作成

  PageController? fullScreenImageViewerController;

  List<List<TimelineItem>> groupedItemsList = [];

  // ChatNotifier(this.ref);

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
    debugPrint("updatedMap! = $updatedMap");
    return updatedMap;
  }

  // // selectedItemsMap を更新するメソッド
  void updateSelectedItemsMap(String newGroupId) {
    if (!isUpdating) {
      selectedItemsMap = insertIntoSelectedItemsMap(selectedItemsMap, newGroupId);  // 修正箇所
      debugPrint("selectedItemsMap_here = $selectedItemsMap");
      notifyListeners();
    }
  }


  void addPostedPhoto(PageController pageController, FixedExtentScrollController pickerController, List<TimelineItem> timelineItems,Map<String, int> selectedItemsMap,List<List<TimelineItem>> Function(List<TimelineItem>) groupItemsByGroupId,VoidCallback toggleTimelineAndAlbum) {

    chatConnection.connect();
    chatConnection.onNewPhoto((data) async {
      debugPrint("onNewPhoto=$data");

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
          debugPrint("Updated Data with Geocoding=$data");

          TimelineItem newItem = TimelineItem.fromJson(data);
          debugPrint("maked_TimelineItem newItem=$newItem");

          final timelineItems = ref.read(timelineAddProvider);

          // groupIDが一致する既存のアイテムが存在するか確認
          bool isNewRow = !timelineItems.any((item) => item.groupID == newItem.groupID);

          if (isNewRow) {

            // toggleTimelineAndAlbum();
            // Future.delayed(Duration(milliseconds: 50), () {
            //   toggleTimelineAndAlbum();
            // });

              // 新しいアイテムをリストに追加
              timelineItems.insert(1, newItem);

            // selectedItemsMapの参照を適切に更新
            // shiftSelectedItemsMap(timelineItems);
            // notifyListeners(); // 更新を通知
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
          debugPrint("Geocoding returned no results.");
        }
      } catch (e) {
        debugPrint("Error in geocoding: $e");
      }
    },onReceived: () {
      debugPrint("新しい写真が受信されました！");


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

  // ウィジェットリストを取得するメソッド
  List<Widget> get connectionWidgets => connectionWidgetsMap.values.toList();

  // void newConnection() {
  //   socket?.on('connections', (data) {
  //     addMessage("New Connection: $data");
  //   });
  // }

  // メッセージリスト
  // List<String> _messages = [];

  // メッセージリストへの読み取り専用アクセスを提供
  // List<String> get messages => _messages;

  // 新しいメッセージをリストに追加するメソッド
  // void addMessage(String message) {
  //   _messages.add(message);
  //   notifyListeners();
  // }

}

final chatNotifierProvider = ChangeNotifierProvider<ChatNotifier>((ref) {
  // 外部から ChatConnection のインスタンスを渡す場合（例えば、グローバル変数や他のプロバイダーから取得）
  // この例では、新しい ChatConnection インスタンスを直接作成しています
  final chatConnection = ChatConnection();
  return ChatNotifier(chatConnection: chatConnection,ref: ref);
});



