
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_app/features/user_auth/presentations/pages/createAlbum.dart';
import 'package:my_app/features/user_auth/presentations/widgets/albumItem.dart';
import 'package:my_app/features/user_auth/presentations/widgets/photoItem.dart';
import 'package:my_app/main.dart';
import 'package:my_app/features/user_auth/presentations/pages/login_page.dart';
import 'package:http/http.dart' as http;

class Albums extends StatefulWidget {
  const Albums({super.key});

  @override
  AlbumState createState() => AlbumState();
}

class AlbumState extends State<Albums> {
  final FirebaseStorage storage =
      FirebaseStorage.instanceFor(bucket: "gs://ailbum.appspot.com");
  List<Map<String, dynamic>> albumData = [];
  List<String> photoUrls = []; // List to hold photo URLs
  // Create a state variable to track whether the checkbox is checked
  bool isChecked = false;
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
    fetchPhotos(); // Fetch photos after fetching albums
  }

  // Fetch albums from Firebase Storage
  Future<void> fetchAlbums() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    String albumsPath = '$userId/user_albums/'; // Define the path

    // Get the albums (folders) under the user's albums folder
    final ListResult albums = await storage.ref(albumsPath).listAll();

    List<Map<String, dynamic>> tempAlbumData = [];

    // Loop through each folder (album)
    for (var albumRef in albums.prefixes) {
      String albumName = albumRef.name;
      String albumId = '';
      if (albumName.contains('#')) {
        // Extract substring after the '#'
        albumId = albumName;
        albumName = albumName.split('#').last;
        if (albumName == 'default'){
          albumName = "";
        }
      } else {
        albumName = ""; // Default to the regular name if no '#' is found
      }
      String thumbnailUrl = '';

      // Fetch one image from the album to use as a thumbnail (first image in the folder)
      final ListResult photos = await albumRef.listAll();
      if (photos.items.isNotEmpty) {
        thumbnailUrl = await photos.items.first.getDownloadURL();
      }

      // Add album data
      tempAlbumData.add({
        'albumId' : albumId,
        'albumName': albumName,
        'thumbnailUrl': thumbnailUrl,
      });
    }

    setState(() {
      albumData = tempAlbumData; // Update the state with the album data
    });
  }

  // Fetch all photos from Firebase Storage
  Future<void> fetchPhotos() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    String photosPath = '$userId/user_photos/'; // Define the path to photos

    
    // Get all photos from the photos folder
      final ListResult photos = await storage.ref(photosPath).listAll();

      List<String> tempPhotoUrls = [];

      for (var photoRef in photos.items) {
        // Fetch the download URL for each photo
        String photoUrl = await photoRef.getDownloadURL();
        tempPhotoUrls.add(photoUrl); // Add URL to list

        setState(() {
          photoUrls = tempPhotoUrls; // Update the state with photo URLs
        });
      }   
   
  }

  // Method to send request to server to create default albums
Future<void> createDefaultAlbums() async {
  print("hii i am here!");
  final uri = Uri.parse('http://192.168.1.36:5000/api/photos/create-default-face-albums');
  String? user = FirebaseAuth.instance.currentUser?.uid;
  // Send the request as JSON
  var response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'user': user ?? '',
    }),
  );

  if (response.statusCode == 200) {
    print("finishhhhhhhhhhhhhhhhhhhhhhhh");
    fetchAlbums();
  } else {
    print("Failed to notify server ${response.statusCode}");
  }


}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: const Padding(
        padding: EdgeInsets.all(5.0),
        child: Image(
          image: AssetImage('assets/icon.png'),
          width: 100.0,  // Adjust the size as needed
          height: 100.0,
        ),
      ),
      // Add the logout icon button to the right side of the AppBar
      actions: [
        IconButton(
          icon: const Icon(Icons.logout), // Logout icon
          onPressed: () async {
            // Sign out from Firebase
            await FirebaseAuth.instance.signOut();

            // Navigate to the sign-in page after signing out
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()), // SignIn is your login page
              (route) => false, // Remove all routes from the stack
            );
          },
        ),
      ],
    ),
    body: Column(
      children: [
        // Button for creating a new album
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ValueListenableBuilder<bool>(
            valueListenable: isButtonEnabledNotifier,
            builder: (context, isButtonEnabled, child) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: isButtonEnabled
                        ? () {
                            // Navigate to CreateAlbum after the button is enabled
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CreateAlbum()),
                              (route) => false,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isButtonEnabled ? Colors.blue : Colors.grey,
                    ), // Disable button if isButtonEnabled is false
                    child: const Text('Create New Album'),
                  ),
                  const SizedBox(height: 10), // Add some spacing

                  // Checkbox for creating default albums
                  Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: isButtonEnabled
                            ? (bool? value) async {
                                setState(() {
                                  isChecked = value ?? false;
                                });

                                if (isChecked) {
                                  // Send a request to the server to create default albums
                                  await createDefaultAlbums();
                                }
                              }
                            : null, // Disable checkbox if isButtonEnabled is false
                      ),
                      const Text('Create Default Albums'),
                    ],
                  ),
                ],
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
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: albumData.length,
                  itemBuilder: (context, index) {
                    final album = albumData[index];
                    return AlbumItem(
                      albumId: album['albumId'],
                      albumName: album['albumName'],
                      thumbnailUrl: album['thumbnailUrl'],
                    );
                  },
                ),
        ),

        const Divider(), // Separator between albums and photos

        // Display all photos in a grid view
        Expanded(
          child: photoUrls.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: photoUrls.length,
                  itemBuilder: (context, index) {
                    return PhotoItem(
                      imageUrl: photoUrls[index],
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
}
