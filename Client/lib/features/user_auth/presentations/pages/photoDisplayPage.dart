// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class PhotoDisplayPage extends StatefulWidget {
  final String albumId;

  const PhotoDisplayPage({super.key, required this.albumId});

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

  Future <List<String>> loadPhotos() async {

    try {
      // String? user = FirebaseAuth.instance.currentUser?.uid;
      List<String> imageUrls = [];
        final storageRef = FirebaseStorage.instance.ref().child('$this.albumId'); // Specify the path

        final ListResult result = await storageRef.listAll(); // Get all files in the path

        // Iterate over each item and get the download URL
        for (var ref in result.items) {
          final String url = await ref.getDownloadURL();
          imageUrls.add(url);
        }

      return imageUrls;
    } catch (e) {
      print("Failed to load photos: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Album Photos'),
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