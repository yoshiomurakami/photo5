import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class AlbumScreen extends StatefulWidget {
  @override
  _AlbumScreenState createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late Future<List<Uint8List>> _imagesFuture;

  @override
  void initState() {
    super.initState();
    _imagesFuture = _loadImagesFromDatabase();
  }

  Future<List<Uint8List>> _loadImagesFromDatabase() async {
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

    // Convert the list of maps into a list of Uint8List
    List<Uint8List> images = [];
    for (var map in maps) {
      final Uint8List bytes = await _loadImageAsBytes(map['thumbnailPath']);
      images.add(bytes);
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
      body: FutureBuilder<List<Uint8List>>(
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
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(25.0),
                    child: Image.memory(
                      snapshot.data![index],
                      width: MediaQuery.of(context).size.width * 0.2,
                      fit: BoxFit.cover,
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
