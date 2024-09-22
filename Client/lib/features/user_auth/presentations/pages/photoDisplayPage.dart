// ignore_for_file: avoid_print

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:my_app/features/user_auth/presentations/pages/albums.dart';

class PhotoDisplayPage extends StatefulWidget {
  final String albumId;
  final String albumName;

  const PhotoDisplayPage({super.key, required this.albumId, required this.albumName});

  @override
  PhotoDisplayPageState createState() => PhotoDisplayPageState();
}

class PhotoDisplayPageState extends State<PhotoDisplayPage> {
  List<String> photoUrls = [];

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future <void> loadPhotos() async {

    try {
      final storage = FirebaseStorage.instanceFor(bucket: "gs://ailbum.appspot.com");
      Reference storageRef = storage.ref().child(widget.albumId);

        final ListResult result = await storageRef.listAll(); // Get all files in the path

        // Iterate over each item and get the download URL
        for (var ref in result.items) {
          final String url = await ref.getDownloadURL();
          setState(() {
            photoUrls.add(url);
          });
        }

    } catch (e) {
      print("Failed to load photos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
            leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const Albums()),(route)=>false);
    },
  ),
        title: Text(widget.albumName),
      ),
      body: photoUrls.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: photoUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  photoUrls[index],
                  fit: BoxFit.cover,
                );
              },
            ),
    );
  }
}