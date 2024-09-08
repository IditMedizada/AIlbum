// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings

import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:my_app/features/user_auth/presentations/pages/createAlbum.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class GallerySync extends StatefulWidget {
  const GallerySync({super.key});

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

    // Retrieve all image albums
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    // Find the main album (or the first album with photos)
    AssetPathEntity? mainAlbum;
    for (final album in albums) {
      // Try to get some photos from the album to check if it contains any photos
      final photos = await album.getAssetListRange(start: 0, end: 1);
      if (photos.isNotEmpty && album.name == "test") {
        mainAlbum = album;
        break;
      }

    }

    if (mainAlbum != null) {
    int start = 0;
    const pageSize = 10; // Adjust page size as needed

    while (true) {
      String? user = FirebaseAuth.instance.currentUser?.uid;
      final photos = await mainAlbum.getAssetListRange(start: start, end: start + pageSize);
      if (photos.isEmpty){
         final uri = Uri.parse('http://192.168.1.241:5000/api/photos/process-photos');
              print("user: $user");
              final response = await http.post(
                uri,
                headers: {'Content-Type': 'application/json'},  // Set the content type to JSON
                body: jsonEncode({'user': user}),  // Encode the body as JSON
              );              
              if (response.statusCode == 200) {
                print("Server notified of new uploads " +(response.body));
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const CreateAlbum()),(route)=>false);
                break;

              } else {
                print("Failed to notify server");
              }

      } 

      for (final photo in photos) {
        final file = await photo.file;
        if (file != null && user != null) {

          if (!photoUrls.any((url) => url == file.path)) { // Avoid duplicates
            bool isUploaded = await uploadUserPhoto(photo.title,user, file, photo.createDateTime.toIso8601String());
            if (isUploaded) {
              setState(() {
                photoUrls.add(file); // Add the file to the list
              });
             

            }
          }
        }
      }

      start += pageSize;
    }
  } else {
    print("Main album not found");
  }
  }


 

  Future<void> uploadNewPhotos(String user) async {
    // Retrieve all image albums
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    // Find the main album (or the first album with photos)
    AssetPathEntity? mainAlbum;
    for (final album in albums) {
      // Try to get some photos from the album to check if it contains any photos
      final photos = await album.getAssetListRange(start: 0, end: 1);
      if (photos.isNotEmpty && album.name == "test") {
        mainAlbum = album;
        break;
      }

    }

     if (mainAlbum != null) {
      int start = 0;
      const pageSize = 10; // Adjust page size as needed

      while (true) {
        String? user = FirebaseAuth.instance.currentUser?.uid;
        final photos = await mainAlbum.getAssetListRange(start: start, end: start + pageSize);
        if (photos.isEmpty){
                break;
        } 

        for (final photo in photos) {
          final file = await photo.file;
          if (file != null && user != null) {

            if (!photoUrls.any((url) => url == file.path)) { // Avoid duplicates
            bool isExist = await isPhotoUploaded(file, user);
            if(!isExist){
              bool isUploaded = await uploadUserPhoto(photo.title,user, file, photo.createDateTime.toIso8601String());
              if (isUploaded) {
                setState(() {
                  photoUrls.add(file); // Add the file to the list
                  //add notification to server
                });
              

              }
            }
          
            }
          }
        }

        start += pageSize;
      }
    } else {
      print("Main album not found");
    }

      // bool isUploaded = false;
      // final directory = await getExternalStorageDirectory();
      // final picturesDir = Directory('${directory?.path}/Pictures');
      // print("hii i am here!");
      // if (picturesDir.existsSync()) {
      //   final List<FileSystemEntity> files = picturesDir.listSync(recursive: true);
      //   for (FileSystemEntity file in files) {
      //     if (file is File) {
      //       // Check if the file is a photo by its extension
      //       if (isPhoto(file)) {
      //         // Check if this photo is already uploaded
      //         if (!await isPhotoUploaded(file, user)) {
      //           // Upload the new photo to Firebase Storage
      //           isUploaded = await uploadPhoto(file, user);
      //           if(isUploaded){
      //              setState(() {
      //               photoUrls.add(file); // Add the file to the list
      //             });
      //           }
      //         }
      //       }
      //     }
      //   }
      //   if(isUploaded){
      //          final uri = Uri.parse('http://192.168.243.147:5000/api/photos/process-photos');
      //         print("user: $user");
      //         final response = await http.post(
      //           uri,
      //           headers: {'Content-Type': 'application/json'},  // Set the content type to JSON
      //           body: jsonEncode({'user': user}),  // Encode the body as JSON
      //         );              
      //         print(response.statusCode);
      //         if (response.statusCode == 200) {
      //           print("Server notified of new uploads " +(response.body));
      //         } else {
      //           print("Failed to notify server");
      //         }
      //   }
      // } else {
      //   print("Pictures directory not found!");
      // }
    }

  // bool isPhoto(File file) {
  //   final String extension = file.path.split('.').last.toLowerCase();
  //   return ['jpg', 'jpeg', 'png', 'gif'].contains(extension);
  // }

  Future<bool> isPhotoUploaded(File file, String user ) async {
      try {
        final storage = FirebaseStorage.instanceFor(bucket: "gs://ailbum.appspot.com");

        // Attempt to find the file in Firebase Storage
        final ref = storage.ref().child('$user/user_photos/$file.jpg');
        await ref.getDownloadURL();
        return true; // If the download URL is found, the file is already uploaded
      } catch (e) {
        return false; // If not found, the file is new and needs to be uploaded
      }
    }

    // Future<bool> uploadPhoto(File file, String user) async {
    //   try {
    //     final storage = FirebaseStorage.instanceFor(bucket: "gs://ailbum.appspot.com");

    //     final ref = storage.ref().child('$user/user_photos/$file.jpg');
    //     await ref.putFile(file);
    //     print("Uploaded: ${file.path}");
    //     return true;
    //   } catch (e) {
    //     print("Failed to upload ${file.path}: $e");
    //     return false;
    //   }
    // }

    Future<bool> uploadUserPhoto(String? fileName, String? user, File photo, String date) async {
  try {
    final storage = FirebaseStorage.instanceFor(bucket: "gs://ailbum.appspot.com");

    Reference ref = storage.ref().child('$user/user_photos/$fileName');
    UploadTask uploadTask = ref.putFile(photo, SettableMetadata(
      customMetadata: {'photoDate': date},
    ));

    await uploadTask.whenComplete(() => print("Upload complete"));

    return true; // Return true if upload completes successfully
  } catch (e) {
    print("Upload failed: $e");
    return false; // Return false if an error occurs
  }
}

  // Future<String?> uploadUserPhoto(String user, File image, String date) async {
  //   final uri = Uri.parse('http://192.168.1.253:5000/api/photos');
  //   final request = http.MultipartRequest('POST', uri)
  //     ..fields['date'] = date
  //     ..fields['user'] = user
  //     ..files.add(await http.MultipartFile.fromPath('photo', image.path));
  //   final response = await request.send();
  //   if (response.statusCode == 200) {
  //     final responseBody = await response.stream.bytesToString();
  //     // Assuming the server response contains the URL as plain text
  //     print("Upload Success, URL: $responseBody");
  //     return responseBody; // Return the URL
  //   } else {
  //     print("Failed to upload photo");
  //     return null;
  //   }
  // }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Album Sync'),
      ),
      body: Column(
        children: [
          const Center(
            child: Text('Syncing Photos...'),
          ),
          Expanded(
            child: photoUrls.isEmpty
                ? const Center(child: Text('No photos uploaded yet.'))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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