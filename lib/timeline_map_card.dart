import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'timeline_providers.dart';
// import 'chat_connection.dart';
import 'dart:async';
import 'package:flag/flag.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
  TimelineItem? centerItem;
  bool isFullScreenMode = false;

  @override
  void initState() {
    super.initState();
    currentSelectedItem = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    // サムネイルサイズを基準に計算
    double thumbnailWidth = widget.size.width * 0.2;
    double borderRadius = thumbnailWidth * 0.04;
    double flagSize = thumbnailWidth * 0.25; // サムネイルの20%のサイズ
    double flagPosition = flagSize * 0.2;
    double textPosition = thumbnailWidth * 0.1;

    // localtimeから時間:分を抽出
    String time = '';
    if (widget.item.localtime != null && widget.item.localtime!.isNotEmpty) {
      List<String> parts = widget.item.localtime!.split(', ');
      if (parts.length == 4) {
        time = parts[3]; // '時間:分' 部分を取得
      }
    }

    return GestureDetector(
      onTap: () {
        if (widget.onTapCallback != null) {
          widget.onTapCallback!(widget.item);
        }
      },
      child: Align(
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none, // これにより、はみ出した部分も表示される
          children: [
            Container(
              key: ValueKey(widget.item.thumbnailFilename),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: _buildImageWidget(context, widget.item.thumbnailFilename),
              ),
            ),
            Positioned(
              top: flagPosition, // サムネイルの上に少し重なるように配置
              left: flagPosition,
              child: ClipOval(
                child: Container(
                  width: flagSize,
                  height: flagSize,
                  color: Colors.white, // 背景色を白に設定（縁取り効果）
                  child: Flag.fromString(
                    widget.item.country,
                    height: flagSize,
                    width: flagSize,
                    fit: BoxFit.cover,
                    flagSize: FlagSize.size_1x1,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: textPosition,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.center,
                child: AutoSizeText(
                  time, // 抽出した'時間:分'部分を表示
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24, // 初期フォントサイズ
                    height: 0.8, // 行間を指定
                  ),
                  maxLines: 1,
                  minFontSize: 20, // 最小フォントサイズを指定
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




Widget _imageContainer(double size, Widget child) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.1),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.1),
      child: Stack(
        children: [
          _buildGreyThumbnail(size), // デフォルトでグレーのサムネイルを背景として配置
          child, // 実際の画像を上に配置
        ],
      ),
    ),
  );
}

Widget _buildImageWidget(BuildContext context, String thumbnailFilename) {
  double imageSize = MediaQuery.of(context).size.width * 0.25;

  return FutureBuilder<File>(
    future: _getCachedImage(thumbnailFilename),
    builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
      return _imageContainer(
        imageSize,
        AnimatedOpacity(
          opacity: snapshot.connectionState == ConnectionState.done && snapshot.data != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: snapshot.connectionState == ConnectionState.done && snapshot.data != null
              ? Image.file(
            snapshot.data!,
            fit: BoxFit.cover,
          )
              : const SizedBox.shrink(), // データがない場合は空のウィジェットを表示
        ),
      );
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






