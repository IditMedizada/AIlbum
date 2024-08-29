import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class GallerySync extends StatefulWidget {
  @override
  GallerySyncPage createState() => GallerySyncPage();
}

class GallerySyncPage extends State<GallerySync> {
  List<File> photoUrls = []; // List to track URLs of uploaded photos

  @override
  void initState() {
    super.initState();
    syncPhotos();
  }

  Future<void> syncPhotos() async {
    String? user = FirebaseAuth.instance.currentUser?.uid;

    // Retrieve all image albums
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    // Find the main album (or the first album with photos)
    AssetPathEntity? mainAlbum;
    for (final album in albums) {
      // Try to get some photos from the album to check if it contains any photos
      final photos = await album.getAssetListRange(start: 0, end: 1);
      if (photos.isNotEmpty) {
        mainAlbum = album;
        break;
      }
    }

    if (mainAlbum != null) {
      // Fetch all photos from the main album
      List<AssetEntity> allPhotos = [];
      int start = 0;
      const pageSize = 10; // Adjust page size as needed

      while (true) {
        final photos = await mainAlbum.getAssetListRange(start: start, end: start + pageSize);
        if (photos.isEmpty) break;
        allPhotos.addAll(photos);
        start += pageSize;
      }

      for (final photo in allPhotos) {
        final file = await photo.file;
        if (file != null && user != null) {
          if (!photoUrls.any((url) => url == file.path)) { // Avoid duplicates
            String? photoUrl = await uploadUserPhoto(user, file, photo.createDateTime.toIso8601String());
            if (photoUrl != null) {
              setState(() {
                photoUrls.add(file); // Add the URL to the list
              });
            }
          }
        }
      }
    } else {
      print("Main album not found");
    }
  }

  Future<String?> uploadUserPhoto(String user, File image, String date) async {
    final uri = Uri.parse('http://192.168.1.253:5000/api/photos');
    final request = http.MultipartRequest('POST', uri)
      ..fields['date'] = date
      ..fields['user'] = user
      ..files.add(await http.MultipartFile.fromPath('photo', image.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      // Assuming the server response contains the URL as plain text
      print("Upload Success, URL: $responseBody");
      return responseBody; // Return the URL
    } else {
      print("Failed to upload photo");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Album Sync'),
      ),
      body: Column(
        children: [
          Center(
            child: Text('Syncing Photos...'),
          ),
          Expanded(
            child: photoUrls.isEmpty
                ? Center(child: Text('No photos uploaded yet.'))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemCount: photoUrls.length,
                    itemBuilder: (context, index) {
                      return Image.file(photoUrls[index]); // Display image from URL
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
