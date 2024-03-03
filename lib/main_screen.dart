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

      // connectionWidgetsの更新にのみ反応するConsumerを別途設定
      // final connectionWidgets = ref.watch(connectionWidgetsManagerProvider).connectionWidgets;

      return Scaffold(
        body: Stack(
          children: <Widget>[
            timelineMapWidget,
            const ConnectionNumber(),
            ConnectionWidgetsDisplay(),
            // // ウィジェットを動的に配置
            // ...connectionWidgets.asMap().entries.map((entry) {
            //   int idx = entry.key; // ウィジェットのインデックス
            //   Widget widget = entry.value; // インデックスに対応するウィジェット
            //   return Positioned(
            //     bottom: 80 + (50.0 * idx), // ウィジェットごとに bottom の値を変更
            //     left: 10,
            //     child: widget,
            //   );
            // }).toList(),
          ],
        ),
      );
    });
  }




}




