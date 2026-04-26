// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:io';



class GallerySync{
  // A list to store the selected photo files
  List<File> photoUrls = [];
  // Firebase Storage reference
  final storage = FirebaseStorage.instanceFor(bucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'));

  // Method to synchronize all photos from a specific album with Firebase Storage - will registaring in the first time
  Future<void> syncPhotos(String user) async {
    AssetPathEntity? mainAlbum = await findMainAlbum("test");
    if (mainAlbum != null) {
      int start = 0;
      // Set the batch size for fetching photos
      const pageSize = 10;

      while (true) {
        // Fetch a batch of photos
        final photos = await mainAlbum.getAssetListRange(start: start, end: start + pageSize);
        if (photos.isEmpty) break;

        // Process the batch of photos sequentially
        for (final photo in photos) {
          final file = await photo.file;
          if (file != null) {
            // Upload each photo sequentially
            await uploadUserPhoto(photo.title, user, file, photo.createDateTime.toIso8601String());
          }
        }

        start += pageSize;
      }

      // Notify the server after all photos are uploaded
      const serverBaseUrl = String.fromEnvironment('SERVER_BASE_URL', defaultValue: 'http://localhost:5000');
      final uri = Uri.parse('$serverBaseUrl/api/photos/process-photos');
      final response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user': user}));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print("All photos uploaded and server notified - gallery sync.");
      } else {
        print('Server request failed with status: ${response.statusCode}');
      }
    } else {
      print("Main album not found");
    }
  }

  // Method to upload photos in night mode, checking if they are already uploaded
  Future<void> nightModePhotoUploading(String user) async {
    AssetPathEntity? mainAlbum = await findMainAlbum("test");
    if (mainAlbum != null) {
      int start = 0;
      const pageSize = 10;
      
      while (true) {
        final photos = await mainAlbum.getAssetListRange(start: start, end: start + pageSize);
        if (photos.isEmpty) break;

      for (final photo in photos) {
            final file = await photo.file;
            if (file != null) {
              bool isExist = await isPhotoUploaded(photo.title, user);
              if(!isExist){
                await uploadUserPhoto(photo.title,user, file, photo.createDateTime.toIso8601String());
              }
            }
          }

        start += pageSize;
      }

  
      // Notify the server after all photos are uploaded
      print("send night mode to serverrrrr");
      const serverBaseUrl = String.fromEnvironment('SERVER_BASE_URL', defaultValue: 'http://localhost:5000');
      final uri = Uri.parse('$serverBaseUrl/api/photos/process-photos');
      final response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user': user}));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Server request succeeded.');
      } else {
        print('Server request failed with status: ${response.statusCode}');
      }
    } else {
      print("Main album not found");
    }
    
  }

 

  Future<bool> isPhotoUploaded(String? fileName, String user ) async {
      try {
        // Attempt to find the file in Firebase Storage
        final ref = storage.ref().child('$user/user_photos/$fileName');
        await ref.getDownloadURL();
        return true; // If the download URL is found, the file is already uploaded
      } catch (e) {
        return false; // If not found, the file is new and needs to be uploaded
      }
  }

   

  // Method to upload a user's photo to Firebase Storage
  Future<bool> uploadUserPhoto(String? fileName, String? user, File photo, String date) async {
    try {
      // Set the file path in storage
      Reference ref = storage.ref().child('$user/user_photos/$fileName');
      // Add metadata with the photo's date
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
  
  // Method to create a 'processed.json' file in Firebase Storage if it doesn't exist
 Future<void> createProcessedFile(String userId) async {
    try {
      // Step 1: Define the path for the processed.json file
      Reference processedFileRef = storage.ref().child('$userId/processed.json');

      // Step 2: Check if processed.json file already exists
      try {
        await processedFileRef.getDownloadURL();
        print('processed.json already exists for user $userId.');
        return; // Exit if the file already exists
      } catch (e) {
        print('processed.json does not exist, creating it now...');
      }

      // Step 3: If it doesn't exist, create processed.json with default content
      Map<String, dynamic> initialData = {'processed': false};
      String jsonData = jsonEncode(initialData);

      // Upload the processed.json file to Firebase Storage
      await processedFileRef.putString(jsonData, metadata: SettableMetadata(contentType: 'application/json'));

      print('processed.json file created for user $userId with initial status.');
    } catch (e) {
      print('Error creating processed.json file: $e');
    }
  }

  Future<bool?> checkProcessedStatus(String userId) async {
    try {
      // Step 1: Define the path for the processed.json file
      Reference processedFileRef = storage.ref().child('$userId/processed.json');

      // Step 2: Attempt to get the download URL for the processed.json file
      String downloadUrl = await processedFileRef.getDownloadURL();
      
      // Step 3: Fetch the processed.json content
      final response = await http.get(Uri.parse(downloadUrl));

      // Step 4: Check if the response is successful
      if (response.statusCode == 200) {
        // Step 5: Parse the JSON content
        Map<String, dynamic> jsonData = jsonDecode(response.body);

        // Step 6: Return the value of the 'processed' field
        return jsonData['processed'] as bool?;
      } else {
        print('Failed to load processed.json for user $userId. Status code: ${response.statusCode}');
        return null; // Return null if the request fails
      }
    } catch (e) {
      print('Error checking processed status for user $userId: $e');
      return null; // Return null in case of an error
    }
  }

  Future<AssetPathEntity?> findMainAlbum(String albumName)async{
   // Fetch albums from gallery
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);

    // Finding the album (if exists)
    for (final album in albums) {
      if (album.name == "test") {
        return album;
      }
    }
    return null;

}
}


