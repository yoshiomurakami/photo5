import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'album_photoview.dart';

class ImageDetail {
  final Uint8List thumbnail;
  final String imagePath;
  final String imageLat;
  final String imageLng;

  ImageDetail({required this.thumbnail, required this.imagePath, required this.imageLat, required this.imageLng});
}


class AlbumScreen extends StatefulWidget {
  @override
  _AlbumScreenState createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late Future<List<ImageDetail>> _imagesFuture;

  @override
  void initState() {
    super.initState();
    _imagesFuture = _loadImagesFromDatabase();
  }

  Future<List<ImageDetail>> _loadImagesFromDatabase() async {
    print("Loading images from the database...");

    // Open the database
    final db = await openDatabase(
      join(await getDatabasesPath(), 'images_database.db'),
    );

    print("Database opened successfully.");

    // Query the table for all images ordered by id in descending order
    final List<Map<String, dynamic>> maps = await db.query(
      'images',
      orderBy: 'id DESC',
    );

    print("Fetched ${maps.length} records from the database.");

    // Convert the list of maps into a list of ImageDetail
    List<ImageDetail> images = [];
    for (var map in maps) {
      final Uint8List bytes = await _loadImageAsBytes(map['thumbnailPath']);
      images.add(ImageDetail(
        thumbnail: bytes,
        imagePath: map['imagePath'], // Assuming 'imagePath' is the correct column name
        imageLat:map['imageLat'],
        imageLng:map['imageLng'],
      ));
      print("Added image from ${map['thumbnailPath']}.");
    }
    print("Successfully loaded all images.");

    return images;
  }


  Future<Uint8List> _loadImageAsBytes(String path) async {
    final file = File(path);
    Uint8List bytes = await file.readAsBytes();
    // Uint8List result = await FlutterImageCompress.compressWithList(
    //   bytes,
    //   format: CompressFormat.webp,
    // );
    return bytes;
    // return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Album')),
      body: FutureBuilder<List<ImageDetail>>(
        future: _imagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              // print the error message if the snapshot has an error
              return Center(child: Text('Error: ${snapshot.error.toString()}'));
            } else if (snapshot.hasData) {
              return GridView.builder(
                itemCount: snapshot.data!.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 4.0,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImagePage(
                            snapshot.data![index].imagePath,  // We only provide the image path now.
                          ),
                        ),
                      );

                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25.0),
                      child: Image.memory(
                        snapshot.data![index].thumbnail,
                        width: MediaQuery.of(context).size.width * 0.2,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              );
            } else {
              return Center(child: Text('No images found'));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }


}
