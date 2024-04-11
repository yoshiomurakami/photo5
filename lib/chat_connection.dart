import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:geocoding/geocoding.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flag/flag.dart';
import 'timeline_providers.dart';
// import 'timeline_map_display.dart';

io.Socket?socket;

typedef CameraActionCallback = void Function();

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

  void listenToCameraEvent(BuildContext context, void Function(Map<String, dynamic>) callback) {
    socket?.on('camera_event', (data) {
      debugPrint('Received camera_event with data: $data');
      callback(data);
    });
  }

  // void listenToLeaveShootingRoomEvent(BuildContext context, void Function() callback) {
  //   socket?.on('leave_shooting_room', (data) {
  //     debugPrint('Received leave_shooting_room event with data: $data');
  //
  //     // ここで context を使用してSnackBarを表示します。
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("Received message: $data"),
  //         duration: const Duration(seconds: 3),
  //       ),
  //     );
  //     callback();
  //   });
  // }

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

    socket?.on('connections', (data) {
      int connections = data['count'] - 1;
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

    if (totalConnections >= 1) {
      return Positioned(
        left: widget.left ?? leftMargin,
        bottom: widget.bottom ?? bottomMargin,
        height: screenHeight * 0.04,
        child: Container(
          padding: const EdgeInsets.only(left: 5, top: 0, right: 15, bottom: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(screenHeight * 0.02),
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
              const SizedBox(width: 10),
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
    } else {
      // totalConnectionsが0の場合は何も表示しない
      return SizedBox.shrink();
    }
  }
}

class ConnectionWidgetsDisplay extends HookConsumerWidget {
  const ConnectionWidgetsDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionWidgetsManager = ref.watch(connectionWidgetsManagerProvider);
    final List<ConnectionWidgetData> connectionWidgetsData = connectionWidgetsManager.connectionWidgets;

    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).size.height * 0.1,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.2,
        decoration: BoxDecoration(
          color: Colors.grey[200]!.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(5),
        child: SingleChildScrollView(
          reverse: true, // スクロールを反転させる
          child: Column(
            children: connectionWidgetsData.map((data) {
              return Row(
                mainAxisAlignment: data.isRightAligned ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [Container(
                  margin: EdgeInsets.only(bottom: 5, left: 10, right: 10), // 適切なマージンを設定
                  child: data.widget,
                )],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}



class ConnectionWidgetData {
  final Widget widget;
  final bool isRightAligned;

  ConnectionWidgetData({required this.widget, required this.isRightAligned});
}

class ConnectionWidgetsManager extends ChangeNotifier {
  final ChatConnection chatConnection;
  String currentUserID = ''; // 現在のユーザーIDを格納
  Map<String, ConnectionWidgetData> _connectionWidgetsMap = {};

  ConnectionWidgetsManager({required this.chatConnection}) {
    _loadCurrentUserID();
    _setupConnectionsListener();
    _setupCameraEventListener(); // ここでカメライベントリスナーを設定
  }

  void _setupCameraEventListener() {
    chatConnection.on('camera_event', (data) {
      String userID = data['userID'];
      String message;
      if (data['event'] == "someone_start_camera") {
        // "someone_start_camera"イベントが来た場合のメッセージ
        bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;
        String uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
        message = "一緒に撮ろう！";
        var newWidget = _createConnectionWidget(data['countryCode'],data['userID'], message, isRightAligned, uniqueKey);
        debugPrint("data['countryCode'] =${data['countryCode']}");
        String uniqueUserID = userID + '_camera';
        _connectionWidgetsMap[uniqueUserID] = ConnectionWidgetData(widget: newWidget, isRightAligned: isRightAligned);

      } else if (data['event']  == "someone_leave_camera") {
        // "someone_leave_camera"イベントが来た場合のメッセージ
        // message = "カメラ停止 - 他のユーザーがカメラを停止しました";
        // "someone_leave_camera"イベントが来た場合、対応するメッセージウィジェットを削除
        String uniqueUserID = userID + '_camera';
        if (_connectionWidgetsMap.containsKey(uniqueUserID)) {
          _connectionWidgetsMap.remove(uniqueUserID); // 特定の userID に対応するメッセージウィジェットを削除
        }
      } else {
        // その他のアクションに対するメッセージを定義
        message = "その他のイベント発生";
      }

      // メッセージウィジェットを動的に生成して_mapに追加
      // String uniqueKey = "camera_event_${DateTime.now().millisecondsSinceEpoch}";
      // var newWidget = _createConnectionWidget("Info", uniqueKey, message);
      // var newWidget = _createConnectionWidget(data['countryCode'],data['userID'], message);
      // debugPrint("data['countryCode'] =${data['countryCode']}");
      // _connectionWidgetsMap[userID] = newWidget;

      notifyListeners();
    });
  }



  Future<void> _loadCurrentUserID() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserID = prefs.getString('userID') ?? '';
  }

  void _setupConnectionsListener() {
    chatConnection.on('connections', (data) {
      String action = data['action'];
      String userID = data['userID'];

      // currentUserIDが設定されていない場合、またはuserIDがcurrentUserIDと一致する場合は処理をスキップ
      if (currentUserID.isEmpty || userID == currentUserID) {
        // debugPrint("sendこんにちは！");
        bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;
        String uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
        var newWidget = _createConnectionWidget('',data['userID'],'こんにちは！', isRightAligned, uniqueKey); // countryCode を _createConnectionWidget に渡す
        _connectionWidgetsMap[userID] = ConnectionWidgetData(widget: newWidget, isRightAligned: isRightAligned);
        notifyListeners();
        return;
      }

      if (action == 'connected') {
        // var message = "Connected: UserID=$userID, Country=${data['countryCode']}, Lat=${data['lat']}, Lng=${data['lng']}";
        bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;
        String uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
        var newWidget = _createConnectionWidget(data['countryCode'],data['userID'],'こんにちは！', isRightAligned, uniqueKey); // countryCode を _createConnectionWidget に渡す
        _connectionWidgetsMap[uniqueKey] = ConnectionWidgetData(widget: newWidget, isRightAligned: isRightAligned);

      } else if (action == 'disconnected') {
        // _connectionWidgetsMap.remove(userID);
        bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;
        String uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
        var newWidget = _createConnectionWidget(data['countryCode'],data['userID'],'またね！', isRightAligned, uniqueKey); // countryCode を _createConnectionWidget に渡す
        _connectionWidgetsMap[uniqueKey] = ConnectionWidgetData(widget: newWidget, isRightAligned: isRightAligned);

      }
      notifyListeners();
    });

    chatConnection.on('receive_res_hellow',(data) {
      String userID = data['userID'];
      debugPrint("Received data: $data");
      // 非同期関数を呼び出して、SharedPreferencesからcountryCodeを取得しウィジェットを更新
      // updateWidgetWithCountryCode(data['userID'], data['countryCode']);
      bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;
      String uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
      var newWidget = _createConnectionWidget(data['countryCode'], data['userID'], '返信！', isRightAligned, uniqueKey); // countryCode を _createConnectionWidget に渡す
      _connectionWidgetsMap[userID] = ConnectionWidgetData(widget: newWidget, isRightAligned: isRightAligned);

      notifyListeners();
    });

    // chatConnection.on('room_count', (data) {
    //   String actionMessage = data['action'] == "entered" ? "入室" : "退出";
    //   String message = "$actionMessage - Number of users in \"shooting\" room: ${data['count']}";
    //
    //   // ユニークなキーを生成する（例: 現在時刻を利用）
    //   String uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
    //
    //   // メッセージウィジェットを生成して_mapに追加
    //   var newWidget = _createConnectionWidget("Info", uniqueKey, message); // countryCodeはInfoで固定
    //   _connectionWidgetsMap[uniqueKey] = newWidget;
    //
    //   notifyListeners(); // 変更をリスナーに通知
    // });
  }

  // Future<void> updateWidgetWithCountryCode(String userID, String countryCode) async {
  //
  //   debugPrint("Received countryCode: $countryCode for userID: $userID");
  //
  //   var newWidget = _createConnectionWidget(countryCode, userID, '一緒に撮ろう！');
  //   _connectionWidgetsMap[userID] = newWidget;
  //   notifyListeners();
  //
  //   // 3秒待機後にメッセージを削除
  //   Future.delayed(Duration(seconds: 3), () {
  //     // メッセージがまだ存在する場合のみ削除
  //     if (_connectionWidgetsMap.containsKey(userID)) {
  //       _connectionWidgetsMap.remove(userID);
  //       notifyListeners();
  //     }
  //   });
  // }



  Widget _createConnectionWidget(String countryCode, String userID, String msg, bool isRightAligned, String uniqueKey) {
    // メッセージ内容に応じて背景色を決定
    Color backgroundColor = msg == '一緒に撮ろう！' ? Color(0xFFFFCC4D) : Colors.white;

    List<Widget> rowChildren = [];

    // countryCodeがnullではない場合のみ国旗をリストに追加
    if (countryCode != '') {
      rowChildren.add(
        Container(
          padding: const EdgeInsets.all(1), // 縁取りの太さを調整
          decoration: const BoxDecoration(
            color: Colors.grey, // 縁取りの色
            shape: BoxShape.circle, // 円形の縁取り
          ),
          child: ClipOval(
            child: Flag.fromString(
              countryCode, // 国コード
              height: 16,
              width: 16, // 円形にするために幅と高さを同じにする
              fit: BoxFit.cover,
            ),
          ),
        ),
      );

      // 国旗とテキストの間隔
      rowChildren.add(const SizedBox(width: 5));
    } else {
      // countryCodeが無効（空文字列またはnull）の場合、絵文字を表示
      rowChildren.add(
        Text(
          '😀', // カメラの絵文字
          style: TextStyle(
            fontSize: 16, // 絵文字のサイズを調整
          ),
        ),
      );
    }

    // テキストウィジェットを追加
    rowChildren.add(
      Text(
        msg, // 表示したいテキスト
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
        ),
      ),
    );

    // isRightAlignedの条件に応じてアイコンまたは空のテキストを追加
    rowChildren.add(const SizedBox(width: 2)); // テキストとアイコンの間隔
    Widget messageWidget = const Text('', style: TextStyle(fontSize: 12)); // デフォルトは空のテキスト

    if (!isRightAligned) {
      if (msg == '一緒に撮ろう！') {
        messageWidget = Text('\u{1F4F8}', style: TextStyle(fontSize: 12)); // 絵文字を表示
      } else if (msg == 'こんにちは！') {
        messageWidget = Icon(Icons.reply, color: Colors.black, size: 12); // アイコンを表示
      }
    }

    // GestureDetectorを追加
    rowChildren.add(
      GestureDetector(
        onTap: () {
          // ここでウィジェットに関する情報をデバッグプリント
          debugPrint('onTapUserID: $userID');
          debugPrint('onTapCurrentUserID: $currentUserID');
          debugPrint('onTapCountryCode: $countryCode');
          debugPrint('onTapMessage: $msg');
          debugPrint('onTapMessage: $uniqueKey');
          _resHellow(userID, currentUserID);
          // bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;

          var rewriteWidget = _createConnectionWidget(countryCode, countryCode, msg+' ', isRightAligned, ''); // countryCode を _createConnectionWidget に渡す
          _connectionWidgetsMap[uniqueKey] = ConnectionWidgetData(widget: rewriteWidget, isRightAligned: false);

          String new_uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
          var newWidget = _createConnectionWidget(countryCode, currentUserID, '返信に返信', true, ''); // countryCode を _createConnectionWidget に渡す
          _connectionWidgetsMap[new_uniqueKey] = ConnectionWidgetData(widget: newWidget, isRightAligned: true);
          notifyListeners();
        },
        child: messageWidget,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // 内部の余白
      decoration: BoxDecoration(
        color: backgroundColor, // 条件によって背景色を設定
        borderRadius: BorderRadius.circular(50), // 境界の角を丸くする
        border: Border.all(color: Colors.black, width: 1.5), // 黒色の境界線
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // 内容に合わせてRowのサイズを調整
        crossAxisAlignment: CrossAxisAlignment.center, // 子ウィジェットを上下中央に配置
        children: rowChildren,
      ),
    );
  }







  // void _resHellow(String userID) {
  //   // Socketを使用してメッセージを送信
  //   socket?.emit('res_hellow', {'userID': userID,'countryCode': countryCode});
  //   debugPrint("_resHellow");
  // }

  void _resHellow(String userID, String fromUserID) async {
    final countryCode = await getCurrentCountryCode() ?? 'デフォルトのcountryCode'; // countryCodeがnullの場合のデフォルト値
    socket?.emit('res_hellow', {'userID': userID, 'countryCode': countryCode, 'fromUserID':fromUserID});
    debugPrint("_resHellow with countryCode: $countryCode");
  }


  List<ConnectionWidgetData> get connectionWidgets => _connectionWidgetsMap.values.toList();


}



final connectionWidgetsManagerProvider = ChangeNotifierProvider<ConnectionWidgetsManager>((ref) {
  // ChatConnectionインスタンスを取得または生成
  final chatConnection = ChatConnection();
  return ConnectionWidgetsManager(chatConnection: chatConnection);
});

Future<String?> getCurrentUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userID');
}

Future<String?> getCurrentCountryCode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('countryCode');
}

class ChatNotifier extends ChangeNotifier {
  final ChatConnection chatConnection;
  // final List<String> _messages = [];
  final ChangeNotifierProviderRef ref;

  ChatNotifier({required this.chatConnection, required this.ref});

  PageController? fullScreenImageViewerController;

  List<List<TimelineItem>> groupedItemsList = [];

  Map<String, int> selectedItemsMap = {};

  bool isUpdating = false;

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

}

final chatNotifierProvider = ChangeNotifierProvider<ChatNotifier>((ref) {
  // 外部から ChatConnection のインスタンスを渡す場合（例えば、グローバル変数や他のプロバイダーから取得）
  // この例では、新しい ChatConnection インスタンスを直接作成しています
  final chatConnection = ChatConnection();
  return ChatNotifier(chatConnection: chatConnection,ref: ref);
});



