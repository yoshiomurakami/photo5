import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({Key? key}) : super(key: key);

  @override
  _AlbumScreenState createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  List<AlbumTimeLine> _albumData = [];
  List<AlbumTimeLine> _filteredAlbumList = [];

  bool _isLoading = true;
  bool _isSortedBySequence = false;

  @override
  void initState() {
    super.initState();
    _loadAlbumData();
  }

  Future<void> _loadAlbumData() async {
    List<AlbumTimeLine> albumList = await fetchAlbumDataFromDB();
    setState(() {
      _albumData = albumList;
      _filteredAlbumList = List.from(albumList); // 初期状態は全て表示
      _isLoading = false;
    });
  }

  Future<List<AlbumTimeLine>> fetchAlbumDataFromDB() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'images_database.db');
      final database = await openDatabase(path);

      final List<Map<String, dynamic>> maps = await database.query('images', orderBy: 'groupID DESC');
      List<AlbumTimeLine> albumList = [];

      for (var map in maps) {
        AlbumTimeLine album = AlbumTimeLine.fromJson(map);
        if (album.imagePath.isNotEmpty) {
          albumList.add(album);
        }
      }

      await database.close();
      return albumList;
    } catch (e) {
      print("Error fetching data from DB: $e");
      return [];
    }
  }

  void _filterByUserID(String userID) {
    setState(() {
      _filteredAlbumList = _albumData.where((album) => album.userID == userID).toList();
    });
  }

  void _sortBySequenceNumber() {
    setState(() {
      if (_isSortedBySequence) {
        _filteredAlbumList.sort((a, b) => a.id.compareTo(b.id)); // デフォルトのid順
      } else {
        _filteredAlbumList.sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber)); // sequenceNumber順
      }
      _isSortedBySequence = !_isSortedBySequence;
    });
  }

  Widget _buildAlbumItem(AlbumTimeLine item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImage(photo: item),
          ),
        );
      },
      child: Image.file(File(item.thumbPath)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アルバム'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: MasonryGridView.count(
            key: ValueKey(_filteredAlbumList.length),
            crossAxisCount: 4, // 1行に4つのサムネイル
            itemCount: _filteredAlbumList.length,
            itemBuilder: (BuildContext context, int index) =>
                _buildAlbumItem(_filteredAlbumList[index]),
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'filterBtn',
            onPressed: () {
              _filterByUserID('oYwHcGX5'); // userIDが'oYwHcGX5'の写真を表示
            },
            child: const Icon(Icons.filter_list),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'sortBtn',
            onPressed: _sortBySequenceNumber, // 並び順を変更
            child: const Icon(Icons.sort),
          ),
        ],
      ),
    );
  }
}

// サンプルのAlbumTimeLineモデル
class AlbumTimeLine {
  final String imagePath;
  final String thumbPath;
  final String groupID;
  final String userID;
  final int id;
  final int sequenceNumber;

  AlbumTimeLine({
    required this.imagePath,
    required this.thumbPath,
    required this.groupID,
    required this.userID,
    required this.id,
    required this.sequenceNumber,
  });

  factory AlbumTimeLine.fromJson(Map<String, dynamic> json) {
    return AlbumTimeLine(
      imagePath: json['imageFilename'],
      thumbPath: json['thumbnailFilename'],
      groupID: json['groupID'],
      userID: json['userID'],
      id: json['id'],
      sequenceNumber: json['sequenceNumber'],
    );
  }
}

// フルスクリーン画像表示用の画面
class FullScreenImage extends StatelessWidget {
  final AlbumTimeLine photo;

  const FullScreenImage({Key? key, required this.photo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フルサイズ画像'),
      ),
      body: Center(
        child: Image.file(File(photo.imagePath)),
      ),
    );
  }
}
