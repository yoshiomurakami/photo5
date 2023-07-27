import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class TimelineFullScreenImagePage extends StatefulWidget {
  final String imageFilename;

  TimelineFullScreenImagePage(this.imageFilename);

  @override
  _TimelineFullScreenImagePageState createState() => _TimelineFullScreenImagePageState();
}

class _TimelineFullScreenImagePageState extends State<TimelineFullScreenImagePage> {
  Future<Uint8List>? imageBytes;

  @override
  void initState() {
    super.initState();
    imageBytes = _loadImageAsBytes(widget.imageFilename);
  }

  Future<Uint8List> _loadImageAsBytes(String filename) async {
    final url = 'https://photo5.world/$filename';
    print('Loading image from URL: $url'); // Add this
    final response = await http.get(Uri.parse(url));
    return response.bodyBytes;
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
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    left: 15.0,
                    bottom: 15.0,
                    child: FloatingActionButton(
                      child: Icon(Icons.arrow_back, color: Colors.white),
                      backgroundColor: Colors.transparent,
                      onPressed: () {
                        Navigator.pop(context);
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
