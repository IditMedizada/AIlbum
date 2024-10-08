// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_app/features/client_side/presentations/pages/createAlbum.dart';
import 'package:my_app/features/client_side/presentations/pages/userId.dart';
import 'package:my_app/features/client_side/presentations/widgets/BaseScreen.dart';
import 'package:my_app/features/client_side/presentations/widgets/albumItem.dart';
import 'package:my_app/main.dart';
import 'package:my_app/features/client_side/presentations/pages/login_page.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';

class Albums extends StatefulWidget {
  const Albums({super.key});

  @override
  AlbumState createState() => AlbumState();
}

class AlbumState extends State<Albums> {
  final FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: "gs://ailbum.appspot.com");
  List<Map<String, dynamic>> albumData = [];
  List<File> photoUrls = [];
  bool isChecked = false;
  bool isLoading = true;
  double loadingProgress = 0.0;
  int count = 1;

  @override
  void initState() {
    super.initState();
    FlutterBackgroundService().on('sync_complete').listen((data) {
      if (data?["sync_complete"] == true) {
        isButtonEnabledNotifier.value = true;
      }
    });
    fetchPhotosFromGallery();
    fetchAlbums();
  }

  Future<void> fetchAlbums() async {
    try {
      count = 1;
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      String albumsPath = '$userId/user_albums/';

      final ListResult albums = await storage.ref(albumsPath).listAll();
      List<Map<String, dynamic>> tempAlbumData = [];

      for (var albumRef in albums.prefixes) {
        String albumName = albumRef.name;
        String albumId = '';
        if (albumName.contains('#')) {
          albumId = albumName;
          albumName = albumName.split('#').last;
          if (albumName == 'default') {
            albumName = "Default Album $count";
            count++;
          }
        } else {
          albumName = "";
        }
        String thumbnailUrl = '';
        final ListResult photos = await albumRef.listAll();
        if (photos.items.isNotEmpty) {
          thumbnailUrl = await photos.items.first.getDownloadURL();
        }

        tempAlbumData.add({
          'albumId': albumId,
          'albumName': albumName,
          'thumbnailUrl': thumbnailUrl,
        });
      }

      setState(() {
        albumData = tempAlbumData;
      });
    } catch (e) {
      print('Error fetching albums: $e');
    }
  }
 // Fetching photos from the device's gallery
  Future<void> fetchPhotosFromGallery() async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    AssetPathEntity? mainAlbum;

    // Finding the album (if exists)
    for (final album in albums) {
      if (album.name == "test") {
        mainAlbum = album;
        break;
      }
    }

    if (mainAlbum != null) {
      int start = 0;
      const pageSize = 10;

      while (true) {
        // Fetch a batch of photos
        final photos = await mainAlbum.getAssetListRange(start: start, end: start + pageSize);
        if (photos.isEmpty) break;

        final uploadTasks = photos.map((photo) async {
          final file = await photo.file;
          if (file != null) {
            setState(() {
              photoUrls.add(file); // Add the file to the list to display
            });
          }
        }).toList();

        // Wait for all to finish
        await Future.wait(uploadTasks);
        start += pageSize;
      }

      setState(() {
        isLoading = false;
      });
    } else {
      print("Main album not found");
    }
  }

  // Future<void> fetchPhotos() async {
  //   try {
  //     String? userId = FirebaseAuth.instance.currentUser?.uid;
  //     String photosPath = '$userId/user_photos/';

  //     final ListResult photos = await storage.ref(photosPath).listAll();
  //     List<String> tempPhotoUrls = [];

  //     for (var photoRef in photos.items) {
  //       String photoUrl = await photoRef.getDownloadURL();
  //       tempPhotoUrls.add(photoUrl);

  //       setState(() {
  //         photoUrls = tempPhotoUrls;
  //       });
  //     }
  //   } catch (e, stacktrace) {
  //     print('Error fetching photos: $e');
  //     print(stacktrace);
  //   }
  // }

  Future<void> createDefaultAlbums() async {
    try {
      final uri = Uri.parse('http://192.168.1.15:5000/api/photos/create-default-face-albums');
      String? user = FirebaseAuth.instance.currentUser?.uid;
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
        fetchAlbums();
        showSnackbar('Default albums created!');
      }
    } catch (e, stacktrace) {
      print('Error creating default albums: $e');
      print(stacktrace);
    }
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      child: Scaffold(

      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          'My Albums',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: () async {
              try {
                await resetUserId();
                FlutterBackgroundService().invoke("stopService");
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              } catch (e, stacktrace) {
                print('Error signing out: $e');
                print(stacktrace);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
                              try {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CreateAlbum()),
                                  (route) => false,
                                );
                              } catch (e, stacktrace) {
                                print('Error navigating to CreateAlbum: $e');
                                print(stacktrace);
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isButtonEnabled ? Colors.blueAccent : Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Create New Album',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged: isButtonEnabled
                              ? (bool? value) async {
                                  setState(() {
                                    isChecked = value ?? false;
                                  });

                                  if (isChecked) {
                                    await createDefaultAlbums();
                                  }
                                }
                              : null,
                        ),
                        const Text(
                          'Create Default Albums',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: albumData.isEmpty
                ? const Center(
                    child: Text(
                      'No albums found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  )
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
                        albumId: album['albumId'],
                        albumName: album['albumName'],
                        thumbnailUrl: album['thumbnailUrl'],
                        onAlbumDeleted: fetchAlbums,
                      );
                    },
                  ),
          ),
          const Divider(
            thickness: 4,
          ),
          Expanded(
            child: photoUrls.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: photoUrls.length,
                    itemBuilder: (context, index) {
                    return Image.file(
                        photoUrls[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
          ),
        ],
      ),
      )
    );
  }
}