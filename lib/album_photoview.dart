import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FullScreenImagePage extends StatefulWidget {
  final String imagePath;
  final double imageLat;
  final double imageLng;

  FullScreenImagePage(this.imagePath, this.imageLat, this.imageLng);

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
    final deviceWidth = MediaQuery.of(context).size.width;
    final mapSize = deviceWidth * 0.2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<Uint8List>(
        future: imageBytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return Stack(
                children: <Widget>[
                  Center(
                    child: Image.memory(snapshot.data!),
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
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: mapSize,
                      height: mapSize,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(widget.imageLat, widget.imageLng),
                          zoom: 10.0,
                        ),
                      ),
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
