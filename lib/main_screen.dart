import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timeline_map_display.dart';
import 'timeline_providers.dart';
import 'chat_connection.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _MainScreenContent();
  }
}


class _MainScreenContent extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<_MainScreenContent> {
  final PageController _pageController = PageController(viewportFraction: 1); // ここでビューポートの幅を設定
  ChatConnection? chatConnection;


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    chatConnection?.disconnect(); // ここで disconnect メソッドを使用
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {

      // ChatNotifierからメッセージリストを取得
      final chatNotifier = ref.watch(chatNotifierProvider);
      final chatMessages = chatNotifier.messages;

      final Size size = MediaQuery.of(context).size;
      Widget timelineMapWidget = const Center(child: CircularProgressIndicator()); // 初期値を設定

      final timelineItemsAsyncValue = ref.watch(timelineProvider);
      timelineItemsAsyncValue.when(
        data: (items) {
          final timelineItems = items;
          final currentLocation = LatLng(timelineItems[0].lat, timelineItems[0].lng);
          timelineMapWidget = MapDisplayStateful(
            size: size,
            currentLocation: currentLocation,
            timelineItems: timelineItems,
            pageController: _pageController,
          );
        },
        loading: () => timelineMapWidget = const Center(child: CircularProgressIndicator()),
        error: (error, stack) => timelineMapWidget = Center(child: Text('Error: $error')),
      );

      return Scaffold(
        body: Stack(
          children: <Widget>[
            timelineMapWidget,
            const ConnectionNumber(),
            // メッセージを表示するためのウィジェットを追加
            Positioned(
              bottom: 10, // 適切な位置に配置
              left: 10,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 3,
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  chatMessages.isNotEmpty ? chatMessages.last : "No new connections",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }



}




