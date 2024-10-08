// ignore_for_file: avoid_print, file_names

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/features/client_side/presentations/pages/albums.dart';
import 'package:my_app/features/client_side/presentations/widgets/BaseScreen.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoDisplayPage extends StatefulWidget {
  final String albumId;
  final String albumName;

  const PhotoDisplayPage({super.key, required this.albumId, required this.albumName});

  @override
  PhotoDisplayPageState createState() => PhotoDisplayPageState();
}

class PhotoDisplayPageState extends State<PhotoDisplayPage> {
  List<String> photoUrls = [];
  int isDownloading = 0;
  final storage = FirebaseStorage.instanceFor(bucket: "gs://ailbum.appspot.com");

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  
  Future <void> loadPhotos() async {
    try {
       
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

Future<void> requestStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }
}


Future<void> downloadPhotosToPhone(String albumName) async {
  try {
     setState(() {
        isDownloading = 1;
      });
    // Ensure permission to write to storage is granted
    await requestStoragePermission();

    // Specify the directory on the phone where photos will be saved
    Directory directory = Directory('/storage/emulated/0/Pictures/Gallery/owner/$albumName');
    
    // If the directory doesn't exist, create it
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    
    // Get the reference to your album in Firebase Storage
    
    Reference storageRef = storage.ref().child(widget.albumId);
    final ListResult result = await storageRef.listAll(); // Get all files in the path
    // Iterate over each photo in the album
    for (Reference ref in result.items) {
      // Get the file name from the reference
      String fileName = ref.name;
      // Download the photo data
      final data = await ref.getData();
      // Save the photo to the specified directory on the phone
      File file = File('${directory.path}/$fileName');
      await file.writeAsBytes(data!);
       setState(() {
        isDownloading = 2;
        });
    }
    refreshGallery(widget.albumId);
    print("Photos downloaded successfully to: ${directory.path}");
  } catch (e) {
    print("Error downloading photos: $e");
  }
}
  
  

void refreshGallery(String albumName) async {
  final String path = '/storage/emulated/0/Pictures/Gallery/owner/$albumName';
  await const MethodChannel('com.example.app/media').invokeMethod('refreshGallery', path);
}

@override
Widget build(BuildContext context) {
  return BaseScreen(
    child: Scaffold(
      backgroundColor: Colors.transparent, // Make the background transparent to show the animated background
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Albums()),
              (route) => false,
            );
          },
        ),
        title: Text(
          widget.albumName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.5),
      ),
      body: photoUrls.isEmpty
          ? const Center(
              child: Text(
                'No photos available.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: photoUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            photoUrls[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: isDownloading == 0
                      ? ElevatedButton.icon(
                          onPressed: () => downloadPhotosToPhone(widget.albumName),
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text(
                            'Download Photos',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        )
                      : isDownloading == 1
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                            )
                          : ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Download Completed'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                ),
              ],
            ),
    ),
  );
  }
}