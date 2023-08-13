import 'package:socket_io_client/socket_io_client.dart' as IO;


IO.Socket?socket;

class ChatConnection {

  void connect() {
    socket = IO.io('https://photo5.world', <String, dynamic>{
      'transports': ['websocket'],
      'path': '/api/socketio/',
      'autoConnect': true,
    });

    socket?.on('connect', (_) {
      print('Connected!');
    });

    // 接続数のイベントリスナー
    socket?.on('connections', (connections) {
      print('Total connections: $connections');
    });

    socket?.on('connect_error', (error) {
      print('Connection Error: $error');
    });

  }


  void sendMessage(String message) {
    socket?.emit('message', message);
  }

  void disconnect() {
    socket?.disconnect();
  }
}
