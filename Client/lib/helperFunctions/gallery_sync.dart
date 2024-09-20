// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings

import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';



class GallerySync{

  List<File> photoUrls = [];

  Future<void> syncPhotos(String user) async {
  final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
  AssetPathEntity? mainAlbum;

  // Finding the album
  for (final album in albums) {
    final photos = await album.getAssetListRange(start: 0, end: 1);
    if (photos.isNotEmpty && album.name == "test") {
      mainAlbum = album;
      break;
    }
  }

  if (mainAlbum != null) {
    int start = 0;
    const pageSize = 10;
    
    List<Future> uploadTasks = []; // A list to hold the upload tasks

    while (true) {
      final photos = await mainAlbum.getAssetListRange(start: start, end: start + pageSize);
      if (photos.isEmpty) break;

      for (final photo in photos) {
        final file = await photo.file;
        if (file != null && !photoUrls.any((url) => url == file.path)) {
          uploadTasks.add(uploadUserPhoto(photo.title, user, file, photo.createDateTime.toIso8601String()));
        }
      }

      start += pageSize;
    }

    // Wait for all uploads to complete in parallel
    await Future.wait(uploadTasks);

    // Notify the server after all photos are uploaded
    final uri = Uri.parse('http://192.168.1.36:5000/api/photos/process-photos');
    await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user': user}));

    print("All photos uploaded and server notified.");
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
                // setState(() {
                //   photoUrls.add(file); // Add the file to the list
                //   //add notification to server
                // });
              

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

      
    }

 

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

 

}