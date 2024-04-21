import 'package:flutter/material.dart';
import 'dart:convert';
// import 'dart:math';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flag/flag.dart';
// import 'dart:math' as math;
import 'timeline_providers.dart';
// import 'timeline_map_display.dart';
import 'l10n/l10n.dart';

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
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$totalConnections',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // totalConnectionsが0の場合は何も表示しない
      return const SizedBox.shrink();
    }
  }
}

class ConnectionWidgetsDisplay extends HookConsumerWidget {
  const ConnectionWidgetsDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionWidgetsManager = ref.watch(connectionWidgetsManagerProvider);
    // useEffect(() {
      connectionWidgetsManager.setupConnectionsListener(context);
    //   return connectionWidgetsManager.teardownConnectionsListener;
    // }, const []);

    final List<ConnectionWidgetData> connectionWidgetsData = connectionWidgetsManager.connectionWidgets;


    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).size.height * 0.1,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.22,
        decoration: BoxDecoration(
          color: Colors.grey[200]!.withOpacity(0.0),
          // borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          reverse: true, // スクロールを反転させる
          child: Column(
            children: connectionWidgetsData.map((data) {
              return Row(
                mainAxisAlignment: data.isRightAligned ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [Container(
                  margin: const EdgeInsets.only(bottom: 5, left: 15, right: 10), // 適切なマージンを設定
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
  final Map<String, ConnectionWidgetData> _connectionWidgetsMap = {};
  bool _isListenerSetup = false;  // リスナーが設定されたかを追跡するプライベート変数
  List<dynamic> existingUserLocations = [];  // クラスレベルでのリスト定義

  ConnectionWidgetsManager({required this.chatConnection}) {
    _loadCurrentUserID();
    // _setupCameraEventListener(); // ここでカメライベントリスナーを設定
    // _setupUserMapListener();
  }

  // void _setupUserMapListener() {
  //   chatConnection.on('existingUserLocations', (data) {
  //     // data['userLocations'] はユーザーの位置情報を含む配列です。
  //     var existingUserLocations = data['userLocations'] as List<dynamic>;
  //     debugPrint("Received ${existingUserLocations.length} users data from server.");
  //     for (var user in existingUserLocations) {
  //       debugPrint("User ID: ${user['userID']}, Lat: ${user['lat']}, Lng: ${user['lng']}");
  //       // ここで受け取った各ユーザーのデータに基づいて何らかの処理を行う
  //     }
  //     // 受け取った位置情報をもとに、アプリ内で必要な更新を行う
  //     notifyListeners();  // ビューを更新するためにリスナーに通知
  //   });
  // }

  // void _setupCameraEventListener() {

    // chatConnection.on('camera_event', (data) {
    //   String userID = data['userID'];
    //   String message;
    //   if (data['event'] == "someone_start_camera") {
    //     // "someone_start_camera"イベントが来た場合のメッセージ
    //     bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;
    //     String uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
    //     message = "一緒に撮ろう！";
    //     String commonMsg = 'what';
    //     var newWidget = _createConnectionWidget(context, data['countryCode'],data['userID'], message, commonMsg, isRightAligned, uniqueKey);
    //     debugPrint("data['countryCode'] =${data['countryCode']}");
    //     String uniqueUserID = '${userID}_camera';
    //     _connectionWidgetsMap[uniqueUserID] = ConnectionWidgetData(widget: newWidget, isRightAligned: isRightAligned);
    //
    //   } else if (data['event']  == "someone_leave_camera") {
    //     // "someone_leave_camera"イベントが来た場合のメッセージ
    //     // message = "カメラ停止 - 他のユーザーがカメラを停止しました";
    //     // "someone_leave_camera"イベントが来た場合、対応するメッセージウィジェットを削除
    //     String uniqueUserID = '${userID}_camera';
    //     if (_connectionWidgetsMap.containsKey(uniqueUserID)) {
    //       _connectionWidgetsMap.remove(uniqueUserID); // 特定の userID に対応するメッセージウィジェットを削除
    //     }
    //   } else {
    //     // その他のアクションに対するメッセージを定義
    //     message = "その他のイベント発生";
    //   }
    //
    //   // メッセージウィジェットを動的に生成して_mapに追加
    //   // String uniqueKey = "camera_event_${DateTime.now().millisecondsSinceEpoch}";
    //   // var newWidget = _createConnectionWidget("Info", uniqueKey, message);
    //   // var newWidget = _createConnectionWidget(data['countryCode'],data['userID'], message);
    //   // debugPrint("data['countryCode'] =${data['countryCode']}");
    //   // _connectionWidgetsMap[userID] = newWidget;
    //
    //   notifyListeners();
    // });
  // }



  Future<void> _loadCurrentUserID() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserID = prefs.getString('userID') ?? '';
  }

  // double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
  //   var earthRadius = 6371; // 地球の半径、キロメートル
  //   var dLat = _degreesToRadians(lat2 - lat1);
  //   var dLng = _degreesToRadians(lng2 - lng1);
  //   var a = sin(dLat / 2) * sin(dLat / 2) +
  //       cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
  //           sin(dLng / 2) * sin(dLng / 2);
  //   var c = 2 * atan2(sqrt(a), sqrt(1 - a));
  //   return earthRadius * c;
  // }

  // double _degreesToRadians(double degrees) {
  //   return degrees * pi / 180;
  // }

  void updateExistingUserLocations(List<dynamic> userLocations) {
    SharedPreferences.getInstance().then((prefs) {
      double myLat = prefs.getDouble('latitude') ?? 0.0;
      double myLng = prefs.getDouble('longitude') ?? 0.0;

      for (var user in userLocations) {
        double userLat = double.tryParse(user['lat']) ?? 0.0;
        double userLng = double.tryParse(user['lng']) ?? 0.0;
        double distance = Geolocator.distanceBetween(myLat, myLng, userLat, userLng);

        user['status'] = (distance <= 10000) ? '1' : '0';
        debugPrint("Updated User ID: ${user['userID']}, Distance: $distance, Status: ${user['status']}");
      }
    });
  }

  void setupConnectionsListener(BuildContext context) {

    // 既存ユーザーの位置情報を取得するリスナー
    chatConnection.on('existingUserLocations', (data) async {
      var existingUserLocations = data['userLocations'] as List<dynamic>;
      debugPrint("Received ${existingUserLocations.length} users data from server.");
      updateExistingUserLocations(existingUserLocations);
    });

    if (!_isListenerSetup) {
      _isListenerSetup = true;
    var l10n = L10n.of(context);
    chatConnection.on('connections', (data) {
      String action = data['action'];
      String userID = data['userID'];

      // 緯度と経度を double 型として取得
      // data['lat'] と data['lng'] が文字列として送られてくる可能性があるため、double.parseを使用
      double? chatLat = double.tryParse(data['lat']) ?? 0.0;
      double? chatLng = double.tryParse(data['lng']) ?? 0.0;
      // double? chatLat = 35.689594143552014;
      // double? chatLng = 100.70021608871818;
      debugPrint("chatlat = $chatLat /chatlng = $chatLng");

      SharedPreferences.getInstance().then((prefs) {
        // double myLat = prefs.getDouble('latitude') ?? 0.0;
        // double myLng = prefs.getDouble('longitude') ?? 0.0;
        double myLat = 90.97769452525533;
        double myLng = -175.3511541534225;
        debugPrint("mylat = $myLat /mylng = $myLng");

        // 2点間の距離を計算
        double distance = Geolocator.distanceBetween(myLat, myLng, chatLat, chatLng);
        debugPrint('Distance between points: ${distance.toStringAsFixed(2)} meters');

        // 新しいユーザーをexistingUserLocationsに追加する処理
        Map<String, dynamic> newUser = {
          'userID': userID,
          'lat': chatLat.toString(),
          'lng': chatLng.toString(),
          'status': distance <= 10000 ? '1' : '0'
        };

        existingUserLocations.add(newUser);
        debugPrint('existingUserLocations = $existingUserLocations');

        // currentUserIDが設定されていない場合、またはuserIDがcurrentUserIDと一致する場合、
        // さらにexistingUserLocations内にstatusが'0'のデータが少なくとも一つ存在する場合にif文を実行
        bool hasStatusZero = existingUserLocations.any((user) => user['status'] == '0');
        if ((currentUserID.isEmpty || userID == currentUserID) && hasStatusZero) {

        debugPrint("sendこんにちは！");
        bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;
        String uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
        String commonMsg = 'sayhello';
        if (l10n != null) {
          String msg = l10n.sayHello;
          debugPrint("tranced msgA = $msg");
          var newWidget = _createConnectionWidget(
              context, '', data['userID'], chatLat, chatLng, msg, commonMsg, isRightAligned,
              uniqueKey);
          _connectionWidgetsMap[uniqueKey] = ConnectionWidgetData(
              widget: newWidget, isRightAligned: isRightAligned);
        }
        // var newWidget = _createConnectionWidget('',data['userID'],'こんにちは！', isRightAligned, uniqueKey); // countryCode を _createConnectionWidget に渡す
        // _connectionWidgetsMap[userID] = ConnectionWidgetData(widget: newWidget, isRightAligned: isRightAligned);
        notifyListeners();
        return;
      }

      if (action == 'connected' && distance >= 10000) {
        // var message = "Connected: UserID=$userID, Country=${data['countryCode']}, Lat=${data['lat']}, Lng=${data['lng']}";
        bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;
        String uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
        String commonMsg = 'sayhello';
        debugPrint("print sayhello");
        if (l10n != null) {
          String msg = l10n.sayHello;
          debugPrint("tranced msgB = $msg");
          var newWidget = _createConnectionWidget(
              context, data['countryCode'], data['userID'], chatLat, chatLng, msg, commonMsg,
              isRightAligned,
              uniqueKey);
          _connectionWidgetsMap[uniqueKey] = ConnectionWidgetData(
              widget: newWidget, isRightAligned: isRightAligned);
        }
      } else if (action == 'disconnected' && distance >= 10000) {
        // _connectionWidgetsMap.remove(userID);
        bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;
        String uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
        String commonMsg = 'saygoodbye';
        if (l10n != null) {
          String msg = l10n.sayGoodbye;
          var newWidget = _createConnectionWidget(
              context, data['countryCode'], data['userID'], chatLat, chatLng, msg, commonMsg,
              isRightAligned,
              uniqueKey); // countryCode を _createConnectionWidget に渡す
          _connectionWidgetsMap[uniqueKey] = ConnectionWidgetData(
              widget: newWidget, isRightAligned: isRightAligned);
        }
      }
      notifyListeners();
    });

    chatConnection.on('receive_res_hellow', (data) {
      String userID = data['userID'];
      debugPrint("Received data: $data");
      // 非同期関数を呼び出して、SharedPreferencesからcountryCodeを取得しウィジェットを更新
      // updateWidgetWithCountryCode(data['userID'], data['countryCode']);
      bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;
      String uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
      String commonMsg = 'res_sayhello';
      if (l10n != null) {
        String msg = l10n.resSayHello;
        var newWidget = _createConnectionWidget(
            context, data['countryCode'], data['userID'], 0, 0, msg, commonMsg,
            isRightAligned,
            uniqueKey); // countryCode を _createConnectionWidget に渡す
        _connectionWidgetsMap[userID] = ConnectionWidgetData(
            widget: newWidget, isRightAligned: isRightAligned);
      }
      notifyListeners();
    });

      chatConnection.on('camera_event', (data) {
        String userID = data['userID'];
        // String message;
        if (data['event'] == "someone_start_camera") {
          // "someone_start_camera"イベントが来た場合のメッセージ
          bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;
          String uniqueKey = "message_${DateTime.now().millisecondsSinceEpoch}";
          String commonMsg = 'shotTogether';
          if (l10n != null) {
            String msg = l10n.shotTogether;
            var newWidget = _createConnectionWidget(
                context,
                data['countryCode'],
                data['userID'],
                0,
                0,
                msg,
                commonMsg,
                isRightAligned,
                uniqueKey);
            debugPrint("data['countryCode'] =${data['countryCode']}");
            String uniqueUserID = '${userID}_camera';
            _connectionWidgetsMap[uniqueUserID] = ConnectionWidgetData(
                widget: newWidget, isRightAligned: isRightAligned);
          }

        } else if (data['event']  == "someone_leave_camera") {
          // "someone_leave_camera"イベントが来た場合のメッセージ
          // message = "カメラ停止 - 他のユーザーがカメラを停止しました";
          // "someone_leave_camera"イベントが来た場合、対応するメッセージウィジェットを削除
          String uniqueUserID = '${userID}_camera';
          if (_connectionWidgetsMap.containsKey(uniqueUserID)) {
            _connectionWidgetsMap.remove(uniqueUserID); // 特定の userID に対応するメッセージウィジェットを削除
          }
        } else {
          // その他のアクションに対するメッセージを定義
          // message = "その他のイベント発生";
        }

        // メッセージウィジェットを動的に生成して_mapに追加
        // String uniqueKey = "camera_event_${DateTime.now().millisecondsSinceEpoch}";
        // var newWidget = _createConnectionWidget("Info", uniqueKey, message);
        // var newWidget = _createConnectionWidget(data['countryCode'],data['userID'], message);
        // debugPrint("data['countryCode'] =${data['countryCode']}");
        // _connectionWidgetsMap[userID] = newWidget;

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
    });
    }
  }

  void teardownConnectionsListener() {
    if (_isListenerSetup) {
      chatConnection.off('connections');
      // 他のイベントリスナーの解除も同様に行う
      _isListenerSetup = false;
    }
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



  Widget _createConnectionWidget(context, String countryCode, String userID, double lat, double lng, String msg, String commonMsg, bool isRightAligned, String uniqueKey) {
    var l10n = L10n.of(context);
    // メッセージ内容に応じて背景色を決定
    Color backgroundColor = commonMsg == 'shotTogether' ? const Color(0xFFFFCC4D) : Colors.white;

    Widget tail = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          // メッセージウィジェットが右側の時は右下の角を丸くする
          bottomRight: isRightAligned ? const Radius.circular(10) : Radius.zero,
          // メッセージウィジェットが左側の時は左下の角を丸くする
          bottomLeft: !isRightAligned ? const Radius.circular(10) : Radius.zero,
        ),
      ),
    );


    List<Widget> rowChildren = [];

    // countryCodeがnullではない場合のみ国旗をリストに追加
    if (countryCode != '' && isRightAligned) {
      Widget flagWidget = Container(
        padding: const EdgeInsets.all(1),
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Flag.fromString(
            countryCode,
            height: 14,
            width: 14,
            fit: BoxFit.cover,
          ),
        ),
      );

      // 国旗をメッセージの前に追加
      rowChildren.insert(0, flagWidget); // 右側に国旗を追加する場合
      rowChildren.insert(1, const SizedBox(width: 5)); // 国旗とテキストの間隔
    } else if(isRightAligned) {
      // countryCodeが無効（空文字列またはnull）の場合、絵文字を表示
      rowChildren.add(
        const Text(
          '😀', // カメラの絵文字
          style: TextStyle(
            fontSize: 14, // 絵文字のサイズを調整
          ),
        ),
      );
    }

    // テキストウィジェットを追加
    rowChildren.add(
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(left: 5),  // 左側に5ポイントの余白を設定
            child: Text(
              msg,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
              softWrap: true,  // テキストがコンテナを超える場合に改行する
            ),
          ),
        )
    );

    // isRightAlignedの条件に応じてアイコンまたは空のテキストを追加
    rowChildren.add(const SizedBox(width: 2)); // テキストとアイコンの間隔
    Widget messageWidget = const Text('', style: TextStyle(fontSize: 16)); // デフォルトは空のテキスト

    if (!isRightAligned) {
      if (commonMsg == 'shotTogether') {
        // messageWidget = const Text('\u{1F4F8}', style: TextStyle(fontSize: 16)); // 絵文字を表示
        messageWidget = Container(
          padding: const EdgeInsets.all(4),  // 内側の余白を設定
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFCC4D), // 形状を円形に設定
              border: Border.all(color: Colors.black, width: 0.5) // 黒い枠線を設定
          ),
          child: const Text(
            '\u{1F4F8}', // 手を挙げた絵文字
            style: TextStyle(
              fontSize: 14, // フォントサイズを16に設定
              color: Colors.black, // 文字色を黒に設定
            ),
          ),
        );
      } else if (commonMsg == 'sayhello') {
        // messageWidget = const Icon(Icons.comment, color: Colors.black, size: 16); // アイコンを表示
        messageWidget = Container(
          padding: const EdgeInsets.all(4),  // 内側の余白を設定
          decoration: BoxDecoration(
              color: Colors.white, // 背景色を白に設定
              shape: BoxShape.circle, // 形状を円形に設定
              border: Border.all(color: Colors.black, width: 0.5) // 黒い枠線を設定
          ),
          child: const Text(
            '\u{1F590}', // 手を挙げた絵文字
            style: TextStyle(
              fontSize: 14, // フォントサイズを16に設定
              color: Colors.black, // 文字色を黒に設定
            ),
          ),
        );
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
          debugPrint('onTapLat: $lat');
          debugPrint('onTapLng: $lng');
          debugPrint('onTapMessage: $msg');
          debugPrint('onTapMessage: $uniqueKey');
          debugPrint('onTapcommonMsg: $commonMsg');
          _resHellow(userID, currentUserID);
          // bool isRightAligned = currentUserID.isEmpty || userID == currentUserID;

          if (l10n != null && commonMsg == 'sayhello') {
            // String msg = l10n.res_sayHello;
            commonMsg = 'res_sayhello';
            var rewriteWidget = _createConnectionWidget(context, countryCode, countryCode, lat, lng, msg, commonMsg, isRightAligned, ''); // countryCode を _createConnectionWidget に渡す
            _connectionWidgetsMap[uniqueKey] = ConnectionWidgetData(widget: rewriteWidget, isRightAligned: false);
          }
          if (l10n != null && commonMsg == 'res_sayhello') {
            String newUniquekey = "message_${DateTime.now().millisecondsSinceEpoch}";
            commonMsg = 'res_sayhello';
            String msg = l10n.resSayHello;
            var newWidget = _createConnectionWidget(
                context, countryCode, currentUserID, lat, lng, msg, commonMsg, true,
                ''); // countryCode を _createConnectionWidget に渡す
            _connectionWidgetsMap[newUniquekey] =
                ConnectionWidgetData(widget: newWidget, isRightAligned: true);
          }
          notifyListeners();
        },
        child: messageWidget,
      ),
    );

    // 吹き出しのウィジェット
    // Widget bubble = Container(
    //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    //   decoration: BoxDecoration(
    //     color: backgroundColor,
    //     borderRadius: BorderRadius.circular(50),
    //     border: Border.all(color: Colors.black, width: 1.5),
    //   ),
    //   child: Row(
    //     mainAxisSize: MainAxisSize.min,
    //     crossAxisAlignment: CrossAxisAlignment.center,
    //     children: rowChildren,
    //   ),
    // );


    return Stack(
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.none, // Overflowを許容


      children: <Widget>[
        // 国旗をメッセージの外に配置
        if (!isRightAligned)
          Positioned(
            left: -15, // メッセージから左に25ピクセルずらす（調整が必要かもしれません）
            top: 5,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Flag.fromString(
                  countryCode,
                  height: 20,
                  width: 20,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

        if (!isRightAligned)
          Positioned(
            left: -15, // メッセージから左に25ピクセルずらす（調整が必要かもしれません）
            top: 5,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Flag.fromString(
                  countryCode,
                  height: 20,
                  width: 20,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

        // // 吹き出しのメイン部分のContainerウィジェット
        // Positioned(
        //   top: 20, // 吹き出しの尾のY軸の位置を調整
        //   left: isRightAligned ? null : 10, // 吹き出しの尾が左にある場合
        //   right: isRightAligned ? 0 : null, // 吹き出しの尾が右にある場合
        //   child: Transform.rotate(
        //     angle: isRightAligned ? 0 * math.pi / 180 : 0 * math.pi / 180, // 左方向に25度回転（マイナスをつける）
        //     child: tail,
        //   ),
        // ),
        Padding(
          padding: EdgeInsets.only(
            left: isRightAligned ? 0 : 15,
            right: isRightAligned ? 5 : 0,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: rowChildren,
                ),
              ),
              // 吹き出し部分の配置
              Positioned(
                left: isRightAligned ? null : -5, // 左寄せの場合は左に出す
                right: isRightAligned ? -5 : null, // 右寄せの場合は右に出す
                top: 10, // 下に位置させる
                child: tail,
              ),
            ],
          ),
        ),
      ],
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

// 吹き出しの尾を描画するためのCustomPainterクラス
// class _BubbleTailPainter extends CustomPainter {
//   final bool isRightAligned;
//   final Color color;
//
//   _BubbleTailPainter({required this.isRightAligned, required this.color});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.fill;
//
//     Path path = Path();
//     // 尾の位置が右側か左側かによって、パスを変更
//     if (isRightAligned) {
//       path.moveTo(size.width, size.height / 2);
//       path.lineTo(0, size.height);
//       path.lineTo(size.width, size.height);
//     } else {
//       path.moveTo(0, size.height / 2);
//       path.lineTo(size.width, 0);
//       path.lineTo(0, 0);
//     }
//     path.close();
//
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }


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



