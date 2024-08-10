import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'timeline_providers.dart';
// import 'chat_connection.dart';
import 'dart:async';

class TimelineCard extends StatefulWidget {
  final TimelineItem item;
  final Size size;
  final FixedExtentScrollController controller;
  final int currentIndex;
  final FixedExtentScrollController pickerController;
  final List<TimelineItem> items;
  final void Function(TimelineItem)? onTapCallback;
  // final VoidCallback? onCameraButtonPressed;

  const TimelineCard({
    Key? key,
    required this.item,
    required this.size,
    required this.controller,
    required this.currentIndex,
    required this.pickerController,
    required this.items,
    this.onTapCallback,
    // required this.onCameraButtonPressed,
  }) : super(key: key);

  @override
  TimelineCardState createState() => TimelineCardState();
}

class TimelineCardState extends State<TimelineCard> {
  bool isDialogShown = false;
  int? currentSelectedItem;
  TimelineItem? centerItem;  // 追加
  bool isFullScreenMode = false;  // デフォルトは非表示

  @override
  void initState() {
    super.initState();
    currentSelectedItem = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTapCallback != null) {
          widget.onTapCallback!(widget.item);
        }
      },
      child: Align(
        alignment: Alignment.center,
        child: Container(
          key: ValueKey(widget.item.thumbnailFilename),
          // width: widget.size.width * 0.2,  // 正方形のサイズ
          // height: widget.size.width * 0.2,  // 正方形のサイズ
          // margin: EdgeInsets.symmetric(horizontal: 0.0),  // サムネイル同士の間隔を確保
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size.width * 0.04),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.size.width * 0.04),
            child
            //     ? Stack(
            //   children: <Widget>[
            //     Align(
            //       alignment: Alignment.center,
            //       child: SizedBox(
            //         child: FloatingActionButton(
            //           backgroundColor: const Color(0xFFFFCC4D),
            //           // foregroundColor: Colors.black,
            //           elevation: 0,
            //           shape: const CircleBorder(side: BorderSide(color: Colors.black, width: 1.3)),
            //           onPressed: () { },
            //           child: const Center(
            //             child: Text(
            //               '\u{1F4F8}',
            //               textAlign: TextAlign.center,
            //               style: TextStyle(
            //                 fontSize: 24,
            //                 height: 1.0,
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ],
            // )
                : _buildImageWidget(context, widget.item.thumbnailFilename),
          ),
        ),
      ),
    );
  }
}


Widget _buildImageWidget(BuildContext context, String thumbnailFilename) {
  double imageSize = MediaQuery.of(context).size.width * 0.2;

  return FutureBuilder<File>(
    future: _getCachedImage(thumbnailFilename),
    builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
      if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
        return _imageContainer(
          imageSize,
          AspectRatio(
            aspectRatio: 1, // 正方形に固定
            child: FadeInImage(
              placeholder: const AssetImage('assets/placeholder_thumb_transparent.png'),
              image: FileImage(snapshot.data!),
              fit: BoxFit.cover, // ここはカバーのままでも良い
              fadeInDuration: const Duration(milliseconds: 300),
            ),
          ),
        );
      } else {
        return _imageContainer(imageSize, _buildGreyThumbnail(imageSize));
      }
    },
  );
}


Widget _buildGreyThumbnail(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.grey.withOpacity(0.5),  // 半透明に設定
      borderRadius: BorderRadius.circular(size * 0.1),
    ),
  );
}


Widget _imageContainer(double size, Widget child) {
  return Container(
    // width: size,
    // height: size,
    // margin: const EdgeInsets.symmetric(horizontal: 8.0), // サムネイル同士の間隔を設定
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.1),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.1),
      child: child,
    ),
  );
}

Future<File> _getCachedImage(String filename) async {
  String cacheDirPath = (await getTemporaryDirectory()).path;
  File cachedImage = File('$cacheDirPath/$filename');

  if (!cachedImage.existsSync()) {
    // ネットワークから画像をダウンロードし、キャッシュに保存
    try {
      var url = 'https://photo5.world/$filename';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await cachedImage.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      // エラーハンドリング
      debugPrint('Image download error: $e');
      // リトライ処理
      return await _retryFetchImage(filename);
    }
  }
  return cachedImage;
}

Future<File> _retryFetchImage(String filename) async {
  String cacheDirPath = (await getTemporaryDirectory()).path;
  File cachedImage = File('$cacheDirPath/$filename');

  try {
    var url = 'https://photo5.world/$filename';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await cachedImage.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to load image on retry: ${response.statusCode}');
    }
  } catch (e) {
    // リトライのエラーハンドリング
    debugPrint('Image retry download error: $e');
  }

  return cachedImage;
}






