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
      final Size size = MediaQuery.of(context).size;
      // ここでは直接 List<TimelineItem> を取得
      final timelineItems = ref.watch(timelineAddProvider);

      Widget timelineMapWidget;
      if (timelineItems.isNotEmpty) {
        final currentLocation = LatLng(timelineItems[0].lat, timelineItems[0].lng);
        timelineMapWidget = MapDisplayStateful(
          size: size,
          currentLocation: currentLocation,
          timelineItems: timelineItems,
          pageController: _pageController,
        );
      } else {
        // リストが空の場合、ローディングインジケーターを表示
        timelineMapWidget = const Center(child: CircularProgressIndicator());
      }

      return Scaffold(
        body: Stack(
          children: <Widget>[
            timelineMapWidget,
            const ConnectionNumber(),
            const ConnectionWidgetsDisplay(),
          ],
        ),
      );
    });
  }
}




