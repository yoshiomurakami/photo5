import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class FullScreenImagePage extends StatefulWidget {
  final String imagePath;
  // final String itemId; // 追加

  FullScreenImagePage(this.imagePath); // 修正


  @override
  _FullScreenImagePageState createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  Future<Uint8List>? imageBytes;

  @override
  void initState() {
    super.initState();
    imageBytes = _loadImageAsBytes(widget.imagePath);
  }

  Future<Uint8List> _loadImageAsBytes(String path) async {
    final file = File(path);
    Uint8List bytes = await file.readAsBytes();
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<Uint8List>(
        future: imageBytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return Stack(
                fit: StackFit.expand, // Add this
                children: <Widget>[
                  Image.memory(
                    snapshot.data!,
                    fit: BoxFit.contain,
                  ),
                  Positioned(
                    left: 15.0,
                    bottom: 15.0,
                    child: FloatingActionButton(
                      heroTag: "BackToAlbum",
                      child: Icon(Icons.arrow_back, color: Colors.white),
                      backgroundColor: Colors.transparent,
                      onPressed: () {
                        Navigator.pop(context, widget.imagePath); // itemIdを戻り値として使用
                      },
                    ),
                  ),
                ],
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

}
