import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class AlbumTimeLine {
  final Key key;
  final String id;
  final String imagePath;
  final String thumbnailPath;
  final String userId;
  final String country;
  final double lat;
  final double lng;
  final String groupID;
  final String localtime;
  final String? geocodedCountry;
  final String? geocodedCity;

  AlbumTimeLine({
    required this.key,
    required this.id,
    required this.imagePath,
    required this.thumbnailPath,
    required this.userId,
    required this.country,
    required this.lat,
    required this.lng,
    required this.groupID,
    required this.localtime,
    this.geocodedCountry,
    this.geocodedCity,
  });


  factory AlbumTimeLine.fromJson(Map<String, dynamic> json) {
    return AlbumTimeLine(
      key: ValueKey(json['id']),
      id: json['id'].toString(),
      imagePath: json['imagePath'],
      thumbnailPath: json['thumbnailPath'],
      userId: json['userId'],
      country: json['imageCountry'],
      lat: double.tryParse(json['imageLat']) ?? 0.0,
      lng: double.tryParse(json['imageLng']) ?? 0.0,
      groupID: json['groupID'],
      localtime: DateTime.now().toString(), // DBにlocaltimeがない場合は現在時刻を使用
      geocodedCountry: null, // 仮のデフォルト値
      geocodedCity: null, // 仮のデフォルト値
    );
  }

  @override
  String toString() {
    return 'AlbumTimeLine('
        'key: $key, '
        'id: $id, '
        'imagePath: $imagePath, '
        'thumbnailPath: $thumbnailPath, '
        'userId: $userId, '
        'country: $country, '
        'lat: $lat, '
        'lng: $lng, '
        'groupID: $groupID, '
        'localtime: $localtime, '
        'geocodedCountry: $geocodedCountry, '
        'geocodedCity: $geocodedCity'
        ')';
  }
}

Future<List<AlbumTimeLine>> fetchAlbumDataFromDB() async {
  final dbPath = await getDatabasesPath();
  final path = p.join(dbPath, 'images_database.db');
  final database = openDatabase(path);

  final List<Map<String, dynamic>> maps = await (await database).query('images', orderBy: 'id DESC');

  // 結果をAlbumTimeLineのリストに変換
  List<AlbumTimeLine> albumList = List.generate(maps.length, (i) {
    return AlbumTimeLine.fromJson(maps[i]);
  });

  // 取得したデータをコンソールに出力
  for (var album in albumList) {
    print(album.toString());
  }

  return albumList;
}


class AlbumTimeLineView extends StatelessWidget {
  final double top;
  final double bottom;
  final double left;
  final double right;
  final List<AlbumTimeLine> albumList; // アルバムリスト
  final Size size; // 表示サイズ

  const AlbumTimeLineView({
    Key? key,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.albumList,
    required this.size,
  }) : super(key: key);


  Widget _buildAlbumItemWidget(BuildContext context, AlbumTimeLine albumItem) {
    double imageSize = size.width * 0.2; // 画像サイズを画面幅の20%に設定

    // ローカルに保存された画像のパスから画像を表示
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(albumItem.thumbnailPath)), // 直接FileImageを使用
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(imageSize * 0.2),
      ),
    );
  }

  // Widget _buildGreyThumbnail(double size) {
  //   // グレーのサムネイルを生成
  //   return Container(
  //     width: size,
  //     height: size,
  //     decoration: BoxDecoration(
  //       color: Colors.grey,
  //       borderRadius: BorderRadius.circular(size * 0.1),
  //     ),
  //   );
  // }
  //
  // Widget _imageContainer(double size, Widget child) {
  //   // 画像を表示するコンテナ
  //   return Container(
  //     width: size,
  //     height: size,
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(size * 0.2),
  //     ),
  //     child: ClipRRect(
  //       borderRadius: BorderRadius.circular(size * 0.2),
  //       child: child,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        child: ListWheelScrollView(
          itemExtent: MediaQuery.of(context).size.height / 10,
          diameterRatio: 1.25,
          children: albumList.map((albumItem) => _buildAlbumItemWidget(context, albumItem)).toList(),
        ),
      ),
    );
  }


// スクロールコントローラーの初期化やイベントリスナーの設定を行う


  void updateMapLocation(AlbumTimeLine selectedItem) {
    // 選択されたアイテムの位置情報に基づいてマップを更新するロジックをここに記述
  }
}