import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatConnection {
  late IO.Socket socket;

  void connect() {
    socket = IO.io('https://photo5.world', <String, dynamic>{
      'transports': ['websocket'],
      'path': '/api/socketio/',
      'autoConnect': false,
    });

    socket.on('connect', (_) {
      print('Connected!');
    });

    socket.on('connect_error', (error) {
      print('Connection Error: $error');
    });

    // 手動で接続を開始
    socket.connect();
  }


  void sendMessage(String message) {
    socket.emit('message', message);
  }

  void disconnect() {
    socket.disconnect();
  }
}
