import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;


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

  // 新しい写真の情報をリッスンするメソッド
  void onNewPhoto(void Function(dynamic) callback) {
    socket?.on('new_photo', callback);
  }


  void sendMessage(String message) {
    socket?.emit('message', message);
  }

  void disconnect() {
    socket?.disconnect();
  }
}
