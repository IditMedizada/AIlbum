import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_app/features/user_auth/presentations/pages/createAlbum.dart';
import 'package:my_app/features/user_auth/presentations/widgets/albumItem.dart';
import 'package:my_app/main.dart';

class Albums extends StatefulWidget {
  const Albums({super.key});

  @override
  AlbumState createState() => AlbumState();
}

class AlbumState extends State<Albums> {
  final FirebaseStorage storage =
      FirebaseStorage.instanceFor(bucket: "gs://ailbum.appspot.com");
  List<Map<String, dynamic>> albumData = [];

  @override
  void initState() {
    super.initState();

    // Listen to data sent from the background service
    FlutterBackgroundService().on('sync_complete').listen((data) {
      if (data?["sync_complete"] == true) {
        isButtonEnabledNotifier.value = true; // Enable button
        print("Button enabled after sync completed");
      }
    });
    fetchAlbums();

  }
  Future<void> fetchAlbums() async {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      String albumsPath = '$userId/user_albums/'; // Define the path

      // Get the albums (folders) under the user's albums folder
      final ListResult albums = await storage.ref(albumsPath).listAll();

      List<Map<String, dynamic>> tempAlbumData = [];

      // Loop through each folder (album)
      for (var albumRef in albums.prefixes) {
        // String albumName = albumRef.name;
        String albumName = "hi!";
        String thumbnailUrl = '';

        // Fetch one image from the album to use as a thumbnail (first image in the folder)
        final ListResult photos = await albumRef.listAll();
        if (photos.items.isNotEmpty) {
          thumbnailUrl = await photos.items.first.getDownloadURL();
        }

        // Add album data
        tempAlbumData.add({
          'albumName': albumName,
          'thumbnailUrl': thumbnailUrl,
        });
      }

      setState(() {
        albumData = tempAlbumData; // Update the state with the album data
      });
    }
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Your Albums"),
    ),
    body: Column(
      children: [
        // Button for creating a new album
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ValueListenableBuilder<bool>(
            valueListenable: isButtonEnabledNotifier,
            builder: (context, isButtonEnabled, child) {
              return ElevatedButton(
                onPressed: isButtonEnabled
                    ? () {
                        // Navigate to CreateAlbum after the button is enabled
                        print("Navigating to Create Album page");
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CreateAlbum()),
                          (route) => false,
                        );
                      }
                    : null, // Disable button if isButtonEnabled is false
                child: const Text('Create New Album'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonEnabled ? Colors.blue : Colors.grey,
                ),
              );
            },
          ),
        ),

        // Display albums in a grid view
        Expanded(
          child: albumData.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: albumData.length,
                  itemBuilder: (context, index) {
                    final album = albumData[index];
                    return AlbumItem(
                      albumName: album['albumName'],
                      thumbnailUrl: album['thumbnailUrl'],
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
}
